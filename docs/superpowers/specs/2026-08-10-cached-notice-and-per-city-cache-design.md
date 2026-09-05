# Cached Notice Refinement & Per-City Cache — Design Spec

**Date:** 2026-08-10
**Feature:** Refine the cached-data SnackBar behavior and make the weather cache per-city
**Status:** Approved

---

## 1. Overview

Two intertwined UX defects are addressed:

1. **Repeated cached-data SnackBar.** The "showing cached data" message re-appears on a
   failed pull-to-refresh. Today the message fires on *every* transition into a settled
   cached `WeatherLoaded` state, including refresh failures — which re-enters the same
   transition as a genuine cache load and is indistinguishable at the presentation layer.
   The message should appear **only** when a *load* (startup or city switch) settles on
   cached data. A failed refresh must instead show a dedicated network/refresh error
   message ("Network error. Please try again later.").

2. **Global weather cache.** `DbHelper` stores a single weather row with no coordinates
   (`db_helper.dart:39-65`), so switching to another city while offline displays the
   previously cached city's weather. The cache must be stored and loaded per city.

---

## 2. Problem Details

### 2.1 Cached-data message fires on refresh failure

`_WeatherScreenState` detects cached data via
`state is WeatherLoaded && state.result.isCached && !state.isFetching` in two places:
`initState` post-frame (weather_screen.dart:36-39) and a `BlocListener.listenWhen`
(weather_screen.dart:111-123). The `listenWhen` guard
(`!previous.isFetching && previous.result == current.result`) was designed to avoid
re-triggers on `ApplySettingsEvent`, but it cannot distinguish:

- a genuine cache *load* (`FetchWeatherEvent`), and
- a failed *refresh* (`RefreshWeatherEvent`),

because both traverse the identical transition
`WeatherLoaded(cached, isFetching: true) → WeatherLoaded(cached, isFetching: false)`
and the cache being global yields the same `result` object. The event context lives only
in the BLoC, so the presentation layer must receive a signal from it.

### 2.2 Cache is global

`saveWeather` calls `_box.removeAll()` then writes one row; `loadWeather` reads
`_box.getAll().first`. No coordinates are stored, so the cache cannot be scoped to a city.

---

## 3. Approach

- **Per-city cache in the data layer.** Add `latitude`/`longitude` columns to
  `WeatherCacheEntity` (ObjectBox schema, regenerated with `dart run build_runner build`;
  ObjectBox migrates existing stores automatically). Store and query by coordinates
  normalized to 4 decimal places (~11 m) on both save and load to tolerate float drift.
- **Event-context signal in the BLoC state.** Add a transient `WeatherNotice`
  (`none | cachedData | refreshError`) to `WeatherLoaded`. The BLoC is the only component
  that knows which event settled the state, so it encodes the resulting notice. The
  presentation layer reacts to `notice` transitions.

No changes are required to `WeatherEmpty`, `WeatherError`, `WeatherInitial`, or the
`WeatherStateX` extension.

---

## 4. Architecture & Component Changes

### 4.1 `lib/core/config/db_helper/weather_cache_entity.dart` — add coordinates

```dart
@Entity()
class WeatherCacheEntity {
  @Id()
  int id;
  String jsonData;
  int savedAt;
  double latitude;
  double longitude;

  WeatherCacheEntity({
    required this.id,
    required this.jsonData,
    required this.savedAt,
    required this.latitude,
    required this.longitude,
  });
}
```

Regenerate `generated/objectbox.g.dart` with `dart run build_runner build`.

### 4.2 `lib/core/config/db_helper/db_helper.dart` — per-city save/load

- Add a private normalization helper (round to 4 decimals).
- `saveWeather(WeatherModel model, {required double latitude, required double longitude})`:
  query for the existing row matching the normalized coordinates, remove it, then `put`
  a fresh row carrying the normalized coordinates.
- `loadWeather({required double latitude, required double longitude, int? maxAgeMillis})`:
  query for the row matching the normalized coordinates; return `null` when absent or
  expired; decode via `WeatherModel.fromCacheJson`.
- `clearWeather()` unchanged (`_box.removeAll()`).

### 4.3 `lib/features/weather_forecast/domain/repositories/weather_repository.dart`

```dart
abstract class WeatherRepository {
  Future<WeatherResult> fetchWeather({required double latitude, required double longitude});
  Future<WeatherResult?> loadCachedWeather({required double latitude, required double longitude});
  Future<void> clearCachedWeather();
}
```

### 4.4 `lib/features/weather_forecast/data/repositories/weather_repository_impl.dart`

- `loadCachedWeather` forwards the coordinates to `_dbHelper.loadWeather`.
- `fetchWeather` saves the fresh model under the requested coordinates.

### 4.5 `lib/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart`

Add `enum WeatherNotice { none, cachedData, refreshError }` to
`weather_forecast_state.dart`. `WeatherLoaded` gains:

```dart
final WeatherNotice notice; // default WeatherNotice.none
```

included in the constructor, `copyWith` and `props`.

Emission rules — the intermediate/loading state and any non-matching outcome always reset
`notice` to `none`:

| Event | Intermediate (loading) | Success | Failure |
|---|---|---|---|
| `FetchWeatherEvent` | `none` | `none` (fresh) | `cachedData` when cached data is displayed |
| `RefreshWeatherEvent` | `none` | `none` | `refreshError` |
| `ApplySettingsEvent` | — | `none` | — |

`_onRefreshWeather` keeps the currently displayed result on failure (as today) but emits
it with `notice: WeatherNotice.refreshError`.

### 4.6 Localization — `weatherRefreshErrorMessage`

New key added to all four ARB files (`lib/core/l10n/arb/intl_*.arb`), then regenerate via
`flutter gen-l10n`:

| Locale | Value |
|---|---|
| `en` | "Network error. Please try again later." |
| `fr` | « Erreur réseau. Veuillez réessayer plus tard. » |
| `es` | "Error de red. Inténtelo de nuevo más tarde." |
| `ar` | « خطأ في الشبكة. يرجى المحاولة لاحقًا. » |

The existing `weatherCachedDataMessage` key is reused unchanged.

### 4.7 `lib/features/weather_forecast/presentation/utils/cached_weather_feedback.dart`

Add a sibling helper next to `showCachedWeatherSnackBar`:

```dart
void showRefreshErrorSnackBar(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalisation.of(context)!;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(content: Text(l10n.weatherRefreshErrorMessage)),
  );
}
```

### 4.8 `lib/features/weather_forecast/presentation/screens/weather_screen.dart`

- Remove `_showsCachedData` and the result-equality `listenWhen`.
- `initState` post-frame: show the cached SnackBar when the already-settled state is
  `WeatherLoaded` with `notice == WeatherNotice.cachedData` (startup case; `refreshError`
  cannot occur before the screen can trigger a refresh).
- Replace the dedicated cached-data `BlocListener<WeatherForecastBloc>`:

```dart
listenWhen: (previous, current) =>
    current is WeatherLoaded &&
    current.notice != WeatherNotice.none &&
    (previous is! WeatherLoaded || previous.notice != current.notice),

listener: (context, state) {
  if (state.notice == WeatherNotice.cachedData) {
    showCachedWeatherSnackBar(context);
  } else if (state.notice == WeatherNotice.refreshError) {
    showRefreshErrorSnackBar(context);
  }
},
```

The intermediate loading emission (`notice == none`) between two notices guarantees the
`previous.notice != current.notice` guard fires exactly once per notice.

---

## 5. Data Flow

```
FetchWeatherEvent (startup / city switch)
  → resolve lat/lon → loadCachedWeather(lat, lon)   // per-city
  → offline or fetch failure + cache present
  → emit WeatherLoaded(cached, notice: cachedData)
  → _WeatherScreenState listenWhen (none → cachedData)
  → showCachedWeatherSnackBar

RefreshWeatherEvent (pull-to-refresh)
  → fetch fails, displayed result kept
  → emit WeatherLoaded(result, isFetching: false, notice: refreshError)
  → _WeatherScreenState listenWhen (none → refreshError)
  → showRefreshErrorSnackBar
```

If the bloc already settled on `cachedData` before the screen subscribes, the `initState`
post-frame check reads the same state and shows the SnackBar directly.

---

## 6. Error Handling

- No new error paths. The `WeatherError` full-screen state and the empty-state
  onboarding/fallback-search flows are untouched.
- A refresh failure shows the dedicated `weatherRefreshErrorMessage` whether the displayed
  result is cached or fresh; the data remains visible.
- `ApplySettingsEvent` resets `notice` to `none` and must not re-trigger any SnackBar.
- Per-city cache lookup that misses (city never cached) falls back to the existing
  `WeatherEmpty` flow (no cached-data message).

---

## 7. Testing Strategy

TDD; `flutter analyze` (zero warnings) and `flutter test` must pass.

- **`test/core/config/db_helper/db_helper_test.dart`** (modify): update `saveWeather` /
  `loadWeather` signatures; add per-city roundtrip, miss → `null`, and two-cities
  independence cases.
- **`test/features/weather_forecast/data/repositories/weather_repository_impl_test.dart`**
  (modify): assert coordinates are forwarded to `saveWeather` / `loadWeather`.
- **`test/features/weather_forecast/presentation/blocs/weather_forecast_bloc_test.dart`**
  (modify): update `loadCachedWeather` stubs; assert `notice` values — offline fetch →
  `cachedData`; refresh failure → `refreshError`; settings change → `none`; fresh success →
  `none`.
- **`test/features/weather_forecast/presentation/screens/weather_screen_test.dart`**
  (modify): update `loadCachedWeather` stubs; replace the test *"shows cached-data
  snackbar again when refresh fails on cached data"* (line ~886) with an assertion that the
  refresh-error message appears; add a city-switch-offline case showing the cached-data
  message; keep the settings-change no-re-trigger and French localization cases green.
- **`test/features/settings/presentation/screens/settings_screen_test.dart`** and
  **`test/core/config/app_routes_test.dart`** (modify): update `loadCachedWeather` stubs.

Existing green tests must stay green except where the new behavior supersedes them.

---

## 8. Commands

| Step | Command |
|---|---|
| ObjectBox codegen | `dart run build_runner build` |
| Localization codegen | `flutter gen-l10n` |
| Static analysis | `flutter analyze` |
| Full test suite | `flutter test` |
| Weather screen tests | `flutter test test/features/weather_forecast/presentation/screens/weather_screen_test.dart` |
| Manual smoke check | `flutter run` (toggle airplane mode with cached data) |

---

## 9. Non-Goals / Out of Scope

- No persistent "stale data" indicator in the header or cards.
- No retry action on either SnackBar (pull-to-refresh already exists).
- No change to the empty-state onboarding sheet or fallback-search SnackBar flow.
- No change to `WeatherEmpty`, `WeatherError`, `WeatherInitial`, the `WeatherStateX`
  extension, or the `fetchWeather` domain contract signature.
- No change to `_onRefreshWeather`'s handling of the no-data case (`WeatherEmpty`).
