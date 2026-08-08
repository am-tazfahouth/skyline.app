# Boot Hydration Design Spec

**Date:** 2026-08-09
**Feature:** Hydrate favorites, onboarding and settings before `runApp` to eliminate the startup empty-state flash on `LocationScreen`
**Status:** Approved

---

## 1. Overview

On cold start, `LocationScreen` briefly renders its empty-favorites view before the real data arrives. The root cause is a timing race:

- `LocationBloc` starts in `LocationInitial`, and `_onLoadFavorites` emits **no intermediate loading state** — it goes straight to `LocationFavoritesLoaded` (or `LocationError`).
- Until that emission lands, `LocationScreen`'s `BlocBuilder` (location_screen.dart:80) hits the default switch branch and resolves `favorites = []`, rendering `FavoritesListWidget` with no items (the "no favorites" placeholder).
- When the async load completes, the bloc emits `LocationFavoritesLoaded` and the screen rebuilds with the real list — producing a visible empty→loaded flash.

The same cold-start race affects two sibling reads:

- `SettingsBloc` starts in `SettingsLoadSuccess(isLoaded: false)`; the persisted settings arrive only after `LoadSettingsEvent` completes, so the first `MaterialApp` frame can render with default settings before snapping to the user's theme and locale.
- `LocationOnboardingBloc` starts in `LocationOnboardingLoading`; `WeatherScreen` compensates by dispatching `LoadOnboardingStatusEvent` from `initState`, which makes the onboarding sheet's appearance timing-dependent on an async read and forces a duplicate read during boot.

This spec moves the three local reads **before `runApp`**, while the native splash is still visible, so every screen's first frame already sees hydrated state.

---

## 2. Approach

The chosen approach is **pre-`runApp` hydration via a new `AppBootstrap.hydrate()` helper**, awaited in `main()` between `InjectionContainer.init()` and `FlutterNativeSplash.remove()`. The native splash is preserved for the whole hydration window, so the user never sees an empty or half-configured frame.

Why hydration instead of more loading states:

- It fixes the root cause (state not ready when first built) instead of masking it.
- It keeps `LocationScreen`'s existing switch-based rendering — no new state, no spinner UI, no duplicated fetch.
- It makes onboarding deterministic: `LocationOnboardingLoaded` is guaranteed to precede the first build of `WeatherScreen`, so the sheet can be driven synchronously from the first frame without re-reading `hasSeenLocationOnboarding()`.
- Hydrated settings give the first `MaterialApp` frame the correct theme and locale immediately.
- No bloc logic changes: the events (`LoadFavoritesEvent`, `LoadSettingsEvent`, `LoadOnboardingStatusEvent`) are exactly the ones dispatched today — only their trigger point moves.

---

## 3. Rejected Alternatives

Two alternatives were considered and rejected:

- **A. Explicit `LocationFavoritesLoading` state + spinner on `LocationScreen`** — `_onLoadFavorites` would emit a loading state before reading, and `LocationScreen` would show a spinner while it is current. Rejected because it only *masks* the flash (a spinner still occupies the frame) instead of eliminating it; it does not coordinate the other blocs (settings and onboarding stay timing-dependent); and it risks a duplicated weather fetch, since `WeatherScreen` reacts to location transitions. It also adds a new state that every switch over `LocationState` must handle.
- **B. Hybrid: loading state + pre-`runApp` hydration** — redundant: hydration alone already removes the empty frame, so the loading state becomes dead UI that can never be observed. Rejected as unnecessary surface area.

---

## 4. Architecture & Component Changes

### 4.1 `lib/core/config/app_bootstrap.dart` — new file

`AppBootstrap` is an `abstract final class` (static-only helper, not instantiable) living in `core/config`, matching the `InjectionContainer` style:

```dart
abstract final class AppBootstrap {
  static Future<void> hydrate({
    SettingsBloc? settingsBloc,
    LocationBloc? locationBloc,
    LocationOnboardingBloc? onboardingBloc,
    Duration timeout = const Duration(seconds: 5),
  }) async {
```

- The three bloc parameters default to the `InjectionContainer` singletons, so `main()` calls `AppBootstrap.hydrate()` with no arguments, while tests inject blocs built on mocktail-mocked repositories.
- `timeout` defaults to 5 seconds; the tests pass a short timeout to exercise the never-completing-read path.

`hydrate()` proceeds in three ordered steps:

1. **Subscribe first, then dispatch.** For each bloc, `_waitFor(...)` starts `bloc.stream.firstWhere(done)` *before* the corresponding load event is added. Because `bloc.stream` is a broadcast stream that does not replay past states, subscribing before dispatching guarantees the load emission is observed. This is the same race the flash originates from (the screen subscribes before the data is loaded) — here it happens deliberately, *before `runApp`*.
2. **Dispatch the three load events**: `LoadSettingsEvent`, `LoadFavoritesEvent`, `LoadOnboardingStatusEvent`.
3. **Await all three futures** with `Future.wait([settingsFuture, locationFuture, onboardingFuture])`.

**Done predicates** (exact values):

| Bloc | Done predicate |
|---|---|
| `SettingsBloc` | `(state is SettingsLoadSuccess && state.isLoaded) \|\| state is SettingsError` |
| `LocationBloc` | `state is LocationFavoritesLoaded \|\| state is LocationError` |
| `LocationOnboardingBloc` | `state is LocationOnboardingLoaded \|\| state is LocationOnboardingError` |

The settings predicate deliberately checks `isLoaded`: `SettingsBloc` **starts** in `SettingsLoadSuccess(isLoaded: false)`, so without the flag the very first state would trivially satisfy the predicate and hydration would return before the read. The error states are included in every predicate so a failed local read still completes hydration (the app degrades gracefully instead of blocking).

**`_waitFor` helper:**

```dart
static Future<void> _waitFor<Event, State>(
  Bloc<Event, State> bloc,
  bool Function(State) done,
  Duration timeout,
) async {
  try {
    await bloc.stream.firstWhere(done).timeout(timeout);
  } catch (_) {
    // A local hydration failure or timeout must never block app launch.
  }
}
```

The `<Event, State>` generic keeps the helper reusable across the three bloc types without casting.

### 4.2 `lib/main.dart` — wiring

Today `main()` dispatches `LoadSettingsEvent` and `LoadFavoritesEvent` through cascades on the `MultiBlocProvider` providers. New flow:

```dart
FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
await InjectionContainer.init();
await AppBootstrap.hydrate();
FlutterNativeSplash.remove();

runApp(
  MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => InjectionContainer.weatherBloc..add(FetchWeatherEvent()),
      ),
      BlocProvider(create: (_) => InjectionContainer.settingsBloc),
      BlocProvider(create: (_) => InjectionContainer.locationBloc),
      BlocProvider(create: (_) => InjectionContainer.locationOnboardingBloc),
    ],
    child: MyApp(),
  ),
);
```

- The `..add(LoadSettingsEvent())` and `..add(LoadFavoritesEvent())` cascades are **removed** from the providers — their events now fire inside hydration.
- `..add(FetchWeatherEvent())` stays **fire-and-forget after hydration**: network must never block the splash, and the weather bloc's existing cached-data / offline handling is untouched.
- `FlutterNativeSplash.remove()` runs only after hydration completes (or the per-bloc timeout elapses), so the native splash covers the entire hydration window.
- `MyApp` therefore receives `SettingsLoadSuccess(isLoaded: true)` from the first frame and builds the correct theme/locale immediately.

### 4.3 `WeatherScreen` — deterministic onboarding via post-frame check

Because onboarding is hydrated before `runApp`, the `LocationOnboardingLoaded` emission precedes `WeatherScreen`'s subscription. Consequences:

- The `initState` dispatch of `LoadOnboardingStatusEvent` becomes redundant — it would re-read `hasSeenLocationOnboarding()` and emit a duplicate loaded state during boot.
- The onboarding `BlocListener` can no longer drive the first-frame sheet: no onboarding transition happens after subscription, so the listener never fires at boot.

`initState` is replaced by a post-frame callback:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) _maybeHandleEmptyState(context);
  });
}
```

- The post-frame callback runs after the first frame; `_maybeHandleEmptyState` reads the already-hydrated onboarding state and either schedules the onboarding sheet (not seen) or shows the fallback search snackbar (seen). This covers the **already-empty-at-first-build** case.
- It is guarded by `mounted` because the callback may fire after the widget is disposed.
- The existing weather `BlocListener` (`listenWhen`: transition into `WeatherEmpty && !isFetching`) still covers the **transition-to-empty-after-fetch** case, so a late empty fetch still triggers the sheet or snackbar. No listener logic is removed.

---

## 5. Data Flow

```
main()
  → WidgetsFlutterBinding.ensureInitialized()
  → SystemChrome.setEnabledSystemUIMode(edgeToEdge)
  → FlutterNativeSplash.preserve()
  → await InjectionContainer.init()                       // singletons built
  → await AppBootstrap.hydrate()
      → _waitFor(settings)   subscribe firstWhere(done)   // subscribe first
      → _waitFor(location)   subscribe firstWhere(done)
      → _waitFor(onboarding) subscribe firstWhere(done)
      → settingsBloc.add(LoadSettingsEvent)
      → locationBloc.add(LoadFavoritesEvent)
      → onboardingBloc.add(LoadOnboardingStatusEvent)
      → await Future.wait([settings, location, onboarding])
  → FlutterNativeSplash.remove()
  → runApp(MultiBlocProvider(...))
      → WeatherScreen first frame: correct theme/locale; onboarding
        already LocationOnboardingLoaded
      → post-frame callback → _maybeHandleEmptyState → sheet or snackbar
        on empty weather
      → LocationScreen first build: LocationBloc already
        LocationFavoritesLoaded → FavoritesListWidget renders the real
        favorites (or a correct empty list) → no empty-state flash
```

---

## 6. Error Handling

- **Local read failures:** if `loadFavorites`, `loadSettings` or `hasSeenLocationOnboarding` throws, the bloc catches it and emits its error state (`LocationError`, `SettingsError`, `LocationOnboardingError`), which **satisfies the done predicate** — hydration completes normally. Error states are part of the predicates by design, not an afterthought.
- **Never-completing reads / 5s timeout:** `_waitFor` wraps `firstWhere(done).timeout(timeout)` in a try/catch that swallows everything. After 5 seconds the `TimeoutException` is caught and hydration proceeds to `runApp`. The load event has already been dispatched, so the bloc finishes in the background and emits whenever ready.
- **Best-available-state launch:** on any local failure or timeout, the app still starts with the best available state — empty favorites on `LocationScreen`, default settings (`isLoaded: false`), and onboarding in an error state, where `_maybeHandleEmptyState` returns early → **no sheet**. The existing per-screen error UIs (`LocationError`, `SettingsError`) are unchanged.
- **Network:** `FetchWeatherEvent` is fire-and-forget after hydration, so a slow or hung network can never extend the splash.

---

## 7. Testing Strategy

TDD; `flutter analyze` (zero warnings) and `flutter test` must pass.

- **`test/core/config/app_bootstrap_test.dart`** (new) — blocs built with mocktail-mocked repositories (`MockLocationRepository`, `MockSettingRepository`, `MockAppLogger`):
  1. *hydrate leaves location, onboarding and settings blocs loaded* — asserts `LocationFavoritesLoaded`, `LocationOnboardingLoaded`, and `SettingsLoadSuccess` with `isLoaded == true`.
  2. *hydrate completes without throwing when a repository read fails* — all three repositories throw; `expectLater(..., completes)`.
  3. *hydrate never blocks launch when a read never completes* — the onboarding read returns a `Completer<bool>().future` that never resolves; `timeout: 50ms`; `expectLater(..., completes)`.

- **`test/features/weather_forecast/presentation/screens/weather_screen_test.dart`** (modify):
  - A new helper pre-hydrates the onboarding bloc before building the screen (mirror of production hydration).
  - The existing onboarding tests use the pre-hydrated bloc.
  - A new determinism test asserts `hasSeenLocationOnboarding()` is called **exactly once** and the `LocationOnboardingSheet` appears at the **first empty frame**.

- Existing tests (startup, GPS failure, delete/reset paths) must stay green unchanged.

---

## 8. Commands

| Step | Command |
|---|---|
| Static analysis | `flutter analyze` |
| Bootstrap tests | `flutter test test/core/config/app_bootstrap_test.dart` |
| Weather screen tests | `flutter test test/features/weather_forecast/presentation/screens/weather_screen_test.dart` |
| Full test suite | `flutter test` |
| Manual smoke check | `flutter run` |

---

## 9. Non-Goals / Out of Scope

- No change to the logic of `_onLoadFavorites`, `_onLoadSettings` or `_onLoadOnboardingStatus` — only their trigger point moves.
- No new bloc states, events, or repositories.
- No change to the weather fetch pipeline (`FetchWeatherEvent` fire-and-forget, offline caching, error views).
- No change to `LocationScreen`'s rendering logic.
- No changes to `lib/features/location/presentation/screens/location_screen.dart` (edited separately; outside this plan).
