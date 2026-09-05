# Cached Weather Notice — Design Spec

**Date:** 2026-08-09
**Feature:** Show a localized SnackBar whenever the app displays weather data from the local cache (no live connection available)
**Status:** Approved

---

## 1. Overview

When the app cannot reach the network, it silently falls back to the last cached weather (`WeatherResult.isCached == true`). The user is never told that the displayed data is stale — the data origin is not signaled. The failure modes that produce cached data are:

- Cold start while offline (cache present) — `_onFetchWeather` short-circuits after `isConnected()` returns false (weather_forecast_bloc.dart:72-77).
- Fetch failing while online (network/server error) with cache present — the Dio/generic catch blocks re-emit the cached `WeatherLoaded` (weather_forecast_bloc.dart:84-108).
- Location switch while offline / on fetch failure — same `_onFetchWeather` path triggered from `LocationSelected` / `LocationFavoritesLoaded`.
- Pull-to-refresh failing while the currently displayed result is already cached — `_onRefreshWeather` re-emits the loaded state with `isFetching: false` (weather_forecast_bloc.dart:146-158).

This spec adds a SnackBar shown every time a *final* weather state backed by cached data is displayed. The signal already exists end-to-end: `loadCachedWeather()` builds `WeatherResult(isCached: true)` (weather_repository_impl.dart:20), the bloc exposes it through `WeatherLoaded.result.isCached`, and the screen already intercepts bloc states with `BlocListener`. **No domain, data or bloc logic changes are required** — this is a presentation-only enhancement.

---

## 2. Approach

Trigger on the transition *into* a final cached `WeatherLoaded` state (`isCached == true && !isFetching`), detected in `_WeatherScreenState` via two complementary mechanisms:

1. **`initState` post-frame check** — if the state is *already* a final cached `WeatherLoaded` at first build (possible because `FetchWeatherEvent` is dispatched at `runApp` time in main.dart:30 and may complete before the screen subscribes), show the SnackBar. Mirrors the existing empty-state check at weather_screen.dart:31-39.
2. **`BlocListener<WeatherForecastBloc>`** — a dedicated `listenWhen` fires on every later transition *into* a final cached state, covering refresh fallback and location-switch fallback.

Why no bloc changes: `result.isCached` already carries the origin; adding a state flag or a one-shot event would duplicate information the presentation layer can already read, and would force changes to `WeatherForecastState` and all its switch sites for no behavioral gain.

---

## 3. Rejected Alternatives

- **A. Add an `isOffline` flag (or a dedicated "came from cache" one-shot event) to the bloc state.** Rejected: the presentation layer already has everything it needs in `WeatherLoaded.result.isCached`; extra state/events broaden the test surface and every switch over `WeatherForecastState` without improving UX. The message does not need to distinguish *offline* from *online-but-fetch-failed* — in both cases the user sees cached data and must be told so.
- **B. Persistent "cached" badge in the header.** Rejected: the user explicitly asked for a startup SnackBar; a persistent badge is a larger UI change with no request behind it (YAGNI). Can be revisited later if "stale data" signaling becomes a recurring concern.

---

## 4. Architecture & Component Changes

### 4.1 `lib/features/weather_forecast/presentation/utils/cached_weather_feedback.dart` — new file

Small, stateless feedback helper mirroring the existing `gps_error_feedback.dart` pattern (location feature):

```dart
void showCachedWeatherSnackBar(BuildContext context, AppLocalisation l10n) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(content: Text(l10n.weatherCachedDataMessage)),
  );
}
```

- Uses `hideCurrentSnackBar()` first so a lingering fallback-search or GPS snackbar is replaced rather than stacked (same convention as `_showFallbackSearchSnackBar`, weather_screen.dart:240-247).
- No action button (decision: informational only; retry is already available via pull-to-refresh).

### 4.2 `lib/features/weather_forecast/presentation/screens/weather_screen.dart` — detection

In `_WeatherScreenState`:

- Add a small private predicate:

```dart
bool _showsCachedData(WeatherForecastState state) =>
    state is WeatherLoaded && state.result.isCached && !state.isFetching;
```

- **`initState` post-frame** — extend the existing callback so that when the weather state is already a final cached `WeatherLoaded`, `showCachedWeatherSnackBar(context, l10n)` is called.
- **`BlocListener<WeatherForecastBloc>`** — add a `listenWhen` that returns true only when the current state is a final cached `WeatherLoaded` and it is *not* the same settled cached result as before:

```dart
listenWhen: (previous, current) {
  if (!_showsCachedData(current)) return false;
  if (previous is WeatherLoaded &&
      !previous.isFetching &&
      previous.result == current.result) {
    return false; // same cached result re-displayed (e.g. ApplySettingsEvent)
  }
  return true;
},
listener: (context, state) {
  final l10n = AppLocalisation.of(context)!;
  showCachedWeatherSnackBar(context, l10n);
},
```

The `previous.result == current.result` guard prevents spurious re-triggers from `ApplySettingsEvent`, which rebuilds `WeatherLoaded` with a new `settings` value but the identical `result` (Equatable-equal). Every genuine cache fallback changes the result object, transitions out of `isFetching: true`, or both — and therefore fires.

Covered cases:

| Scenario | Transition | SnackBar |
|---|---|---|
| Cold start offline, cache present | `WeatherInitial` → `WeatherLoaded(cached, fetching)` → `WeatherLoaded(cached)` | yes |
| Fetch fails online, cache present | `WeatherLoaded(cached, fetching)` → `WeatherLoaded(cached)` | yes |
| Location switch, cache fallback | → `WeatherLoaded(cached, fetching)` → `WeatherLoaded(cached)` | yes |
| Refresh fails, current result cached | `WeatherLoaded(cached)` → `WeatherLoaded(cached, fetching)` → `WeatherLoaded(cached)` | yes |
| Refresh fails, current result fresh | fallback re-emits fresh `WeatherLoaded` | no |
| Settings change on cached result | same `result`, new `settings` | no |
| Fresh data / error / empty | — | no |

### 4.3 Localization — `app_localisation.dart` + 4 implementations

New abstract getter `weatherCachedDataMessage`:

| Locale | Value |
|---|---|
| `en` | "No internet connection. Showing cached data." |
| `fr` | « Connexion impossible. Données affichées depuis le cache. » |
| `es` | « Sin conexión. Mostrando datos guardados. » |
| `ar` | « تعذّر الاتصال. عرض البيانات المخزّنة. » |

---

## 5. Data Flow

```
FetchWeatherEvent (cold start / location switch)
  → _onFetchWeather loads cache → emit WeatherLoaded(cached, isFetching: true)
  → isConnected() == false (or fetch throws)
  → emit WeatherLoaded(cached, isFetching: false)
  → _WeatherScreenState listener matches (final + cached + new result)
  → showCachedWeatherSnackBar → ScaffoldMessenger shows localized SnackBar
```

If the bloc already settled before the screen subscribed, the `initState` post-frame check reads the same settled state and shows the SnackBar directly — no transition is missed in either timing.

---

## 6. Error Handling

- No new error paths. The SnackBar is informational; the existing error states (`WeatherError`), empty-state sheet and fallback-search snackbar are untouched.
- If the weather state is cached but still `isFetching: true` (loading overlay visible), no SnackBar is shown yet — it appears only once the state settles.
- `ApplySettingsEvent` on a cached result must not re-show the SnackBar (guarded by the `result` equality check).

---

## 7. Testing Strategy

TDD; `flutter analyze` (zero warnings) and `flutter test` must pass.

**`test/features/weather_forecast/presentation/screens/weather_screen_test.dart`** (modify — existing mocks/helpers reused):

1. *offline + cache present → SnackBar with cached-data message* — `isConnected: () async => false`, `loadCachedWeather` returns cached result; asserts the localized message text.
2. *fresh data → no SnackBar* — online + successful fetch; asserts message absent.
3. *refresh fails on a cached result → SnackBar shown again* — starts cached, `RefreshWeatherEvent`, fetch throws; asserts message present.
4. *settings change on a cached result → no SnackBar re-trigger* — cached state, `ApplySettingsEvent`; asserts message absent.
5. *message localized in French* — `locale: Locale('fr')`; asserts the French string.

Existing weather-screen tests must stay green unchanged.

---

## 8. Commands

| Step | Command |
|---|---|
| Static analysis | `flutter analyze` |
| Weather screen tests | `flutter test test/features/weather_forecast/presentation/screens/weather_screen_test.dart` |
| Full test suite | `flutter test` |
| Manual smoke check | `flutter run` (toggle airplane mode with cached data) |

---

## 9. Non-Goals / Out of Scope

- No changes to `WeatherForecastBloc`, events, states, `WeatherRepository`, `WeatherResult` or any data/domain layer.
- No persistent "stale data" indicator in the header or cards.
- No retry action on the SnackBar (pull-to-refresh already exists).
- No change to the empty-state onboarding sheet or fallback-search snackbar flow.
