# Location Onboarding & Manual Search Fallback — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a first-launch location onboarding bottom sheet and a manual-search fallback SnackBar on `WeatherScreen`. When `WeatherEmpty` is reached, if the persistent flag `hasSeenLocationOnboarding` is false, show a bottom sheet after a 500 ms delay offering "Enable location" / "Later". Independently, whenever `WeatherEmpty` is reached (regardless of the flag), show a SnackBar inviting a manual city search — except while the bottom sheet is showing, and never on `WeatherError`.

**Architecture:** Persistent flag stored in a new ObjectBox entity (`OnboardingCacheEntity`), exposed through `LocationRepository` (`hasSeenLocationOnboarding()` / `markLocationOnboardingSeen()`). A dedicated `LocationOnboardingBloc` (mirror of `SettingsBloc`) holds the flag; `WeatherScreen` becomes a `StatefulWidget` orchestrating the sheet, the fallback SnackBar and GPS error feedback (factorized into a shared helper reused by `LocationScreen`).

**Tech Stack:** Flutter, `flutter_bloc`, `equatable`, `objectbox`, `mocktail`, `bloc_test`.

## Global Constraints

- **English code only:** identifiers, comments, and commit messages in English.
- **Zero warnings:** `flutter analyze` must report 0 warnings and 0 infos after every task.
- **TDD:** write/extend the failing test first, run it to see it fail, then implement.
- **Immutability:** no mutable private fields in BLoCs; state emitted via `emit(...)`.
- **No hardcoded user strings:** all user-visible text goes through the ARB files (`lib/core/l10n/arb/`) regenerated with `flutter gen-l10n`.
- **Do NOT modify:** the boot coordination of the 3 events in `main.dart:30-37`, `WeatherErrorView`, or the `WeatherError` state behavior.
- **No commits delivered:** implementer subagents may use temporary local commits for clean review diffs; the controller soft-resets the branch to the original HEAD at the end (working tree keeps all changes, uncommitted).

## File Structure

| Action | File | Responsibility |
|---|---|---|
| Create | `lib/core/config/db_helper/onboarding_cache_entity.dart` | `@Entity()` with `id` + `hasSeenLocationOnboarding` |
| Modify | `lib/core/config/db_helper/db_helper.dart` | `loadOnboardingFlag()` / `saveOnboardingFlag(bool)` |
| Regenerate | `lib/core/config/db_helper/generated/objectbox.g.dart` | `dart run build_runner build` |
| Modify | `lib/features/location/data/sources/location_local_source.dart` | flag load/save passthrough |
| Modify | `lib/features/location/domain/repositories/location_repository.dart` | `hasSeenLocationOnboarding()` / `markLocationOnboardingSeen()` |
| Modify | `lib/features/location/data/repositories/location_repository_impl.dart` | implement via `_localSource` |
| Create | `lib/features/location/presentation/blocs/location_onboarding_event.dart` | `LoadOnboardingStatusEvent`, `CompleteOnboardingEvent` |
| Create | `lib/features/location/presentation/blocs/location_onboarding_state.dart` | `Loading`, `Loaded(hasSeenLocationOnboarding)`, `Error` |
| Create | `lib/features/location/presentation/blocs/location_onboarding_bloc.dart` | `LocationOnboardingBloc(logger, repository)` |
| Create | `lib/features/location/presentation/utils/gps_error_feedback.dart` | `isGpsError(AppErrorCode)`, `showGpsErrorSnackBar(BuildContext, AppErrorCode)` |
| Create | `lib/features/location/presentation/widgets/location_onboarding_sheet.dart` | `LocationOnboardingSheet` |
| Modify | `lib/features/location/presentation/screens/location_screen.dart` | use shared GPS helper (remove private `_isGpsError`/`_gpsErrorAction`) |
| Modify | `lib/features/weather_forecast/presentation/screens/weather_screen.dart` | `StatefulWidget` orchestration |
| Modify | `lib/injection_container.dart` | wire `locationOnboardingBloc` |
| Modify | `lib/main.dart` | one `BlocProvider` line (3 boot events untouched) |
| Modify | `lib/core/l10n/arb/intl_{en,fr,es,ar}.arb` | new keys |
| Regenerate | `lib/core/l10n/app_localisation*.dart` | `flutter gen-l10n` |

Tests:

| Action | File |
|---|---|
| Create | `test/features/location/presentation/blocs/location_onboarding_bloc_test.dart` |
| Create | `test/features/location/presentation/widgets/location_onboarding_sheet_test.dart` |
| Modify | `test/features/weather_forecast/presentation/screens/weather_screen_test.dart` |
| Modify | `test/features/location/data/repositories/location_repository_impl_test.dart` |
| Modify | `test/features/location/data/sources/location_local_source_test.dart` |
| Modify | `test/core/config/db_helper/db_helper_test.dart` |

## l10n keys

`locationOnboardingTitle`, `locationOnboardingBody`, `locationOnboardingEnable`, `locationOnboardingLater`, `weatherEmptySearchMessage`, `weatherEmptySearchAction`.

EN:
- `locationOnboardingTitle`: "Set your location"
- `locationOnboardingBody`: "Enable location access to see the weather for your current position."
- `locationOnboardingEnable`: "Enable location"
- `locationOnboardingLater`: "Later"
- `weatherEmptySearchMessage`: "Search for a city to see the weather."
- `weatherEmptySearchAction`: "Search"

FR:
- "Définir votre position"
- "Autorisez la localisation pour voir la météo à votre position actuelle."
- "Activer la localisation"
- "Plus tard"
- "Recherchez une ville pour voir la météo."
- "Rechercher"

ES:
- "Configura tu ubicación"
- "Permite el acceso a tu ubicación para ver el clima en tu posición actual."
- "Activar ubicación"
- "Más tarde"
- "Busca una ciudad para ver el clima."
- "Buscar"

AR:
- "تعيين موقعك"
- "فعّل الوصول إلى موقعك لعرض الطقس في موقعك الحالي."
- "تفعيل الموقع"
- "لاحقًا"
- "ابحث عن مدينة لعرض الطقس."
- "بحث"

---

### Task 1: l10n keys (ARB + regenerate)

**Files:** modify `lib/core/l10n/arb/intl_{en,fr,es,ar}.arb`; regenerate with `flutter gen-l10n` (updates `lib/core/l10n/app_localisation.dart` and the 4 `app_localisation_*.dart` files).

**Interfaces produced:** 6 new getters on `AppLocalisation`: `locationOnboardingTitle`, `locationOnboardingBody`, `locationOnboardingEnable`, `locationOnboardingLater`, `weatherEmptySearchMessage`, `weatherEmptySearchAction`.

- [ ] **Step 1:** Add the 6 keys to `intl_en.arb` (template; with `@` descriptions for at least `locationOnboardingTitle` and `weatherEmptySearchMessage`).
- [ ] **Step 2:** Add the same 6 keys to `intl_fr.arb`, `intl_es.arb`, `intl_ar.arb` with the translations above.
- [ ] **Step 3:** Run `flutter gen-l10n`. Verify the generated `lib/core/l10n/app_localisation.dart` exposes the 6 getters and each `app_localisation_*.dart` overrides them.
- [ ] **Step 4:** Run `flutter analyze` (0 warnings) and `flutter test` to confirm nothing regressed.

### Task 2: Persistence layer (entity + DbHelper + repository)

**Files:** create `onboarding_cache_entity.dart`; modify `db_helper.dart`, `location_local_source.dart`, `location_repository.dart`, `location_repository_impl.dart`; regenerate `objectbox.g.dart`; update `db_helper_test.dart`, `location_local_source_test.dart`, `location_repository_impl_test.dart`.

**Interfaces:**
- Produces:
  - `OnboardingCacheEntity { int id; bool hasSeenLocationOnboarding; }`
  - `bool DbHelper.loadOnboardingFlag()` (default `false` when empty), `void DbHelper.saveOnboardingFlag(bool seen)`
  - `bool LocationLocalSource.loadOnboardingFlag()`, `void LocationLocalSource.saveOnboardingFlag(bool seen)`
  - `Future<bool> LocationRepository.hasSeenLocationOnboarding()`, `Future<void> LocationRepository.markLocationOnboardingSeen()`
- Consumes: existing `DbHelper` box pattern (removeAll + put id 0).

- [ ] **Step 1:** Add failing tests first: `DbHelper` round-trip (default false, save true/false), `LocationLocalSource` passthrough, `LocationRepositoryImpl` returns `_localSource` values and `markLocationOnboardingSeen()` calls `saveOnboardingFlag(true)`.
- [ ] **Step 2:** Create the entity, add `DbHelper` methods + box, add `LocationLocalSource` + `LocationRepository` + `LocationRepositoryImpl` methods.
- [ ] **Step 3:** Run `dart run build_runner build` to regenerate `objectbox.g.dart`; verify the new entity is registered.
- [ ] **Step 4:** Run the 3 updated test files, then `flutter analyze` and the full `flutter test`.

### Task 3: GPS error feedback factorization

**Files:** create `lib/features/location/presentation/utils/gps_error_feedback.dart`; modify `location_screen.dart`.

**Interfaces produced:**
- `bool isGpsError(AppErrorCode code)` — true for `LocationErrorCodes.gpsDisabled`, `gpsPermissionDenied`, `gpsPermissionPermanentlyDenied`, `gpsFailed`.
- `void showGpsErrorSnackBar(BuildContext context, AppErrorCode code)` — shows a SnackBar via `ScaffoldMessenger.of(context)` with `AppError.getUserErrorMessage(code, l10n)` and the same actions as `location_screen.dart:24-46`: `gpsDisabled` → `SnackBarAction(locationEnable)` → `OpenLocationSettingsEvent`; `gpsPermissionDenied` → `SnackBarAction(weatherRetry)` → `DetectCurrentLocationEvent`; `gpsPermissionPermanentlyDenied` → `SnackBarAction(settingsTitle)` → `OpenAppSettingsEvent`; otherwise no action.

**Behavior:** `location_screen.dart` must delegate to the helper, removing its private `_isGpsError`/`_gpsErrorAction` methods, with zero change to the produced SnackBars. Existing `location_screen_test.dart` must stay green untouched.

- [ ] **Step 1:** Extract the helper functions with the exact messages/actions above.
- [ ] **Step 2:** Refactor `location_screen.dart` to use them (its `BlocListener` calls `showGpsErrorSnackBar` when `isGpsError(state.errorCode)`).
- [ ] **Step 3:** Run `flutter analyze` + `flutter test test/features/location/presentation/screens/location_screen_test.dart` + full suite.

### Task 4: LocationOnboardingBloc + wiring

**Files:** create `location_onboarding_event.dart`, `location_onboarding_state.dart`, `location_onboarding_bloc.dart`; modify `injection_container.dart`, `main.dart`; create `test/features/location/presentation/blocs/location_onboarding_bloc_test.dart`.

**Interfaces produced:**
- `abstract class LocationOnboardingEvent extends Equatable` with `LoadOnboardingStatusEvent` and `CompleteOnboardingEvent`.
- `abstract class LocationOnboardingState extends Equatable` with `LocationOnboardingLoading`, `LocationOnboardingLoaded { final bool hasSeenLocationOnboarding; }`, `LocationOnboardingError`.
- `class LocationOnboardingBloc extends Bloc<LocationOnboardingEvent, LocationOnboardingState>` with ctor `({required AppLogger logger, required LocationRepository repository})`, initial state `LocationOnboardingLoading`.
  - `LoadOnboardingStatusEvent` → `repository.hasSeenLocationOnboarding()` → `LocationOnboardingLoaded(hasSeenLocationOnboarding: value)`; on error log + `LocationOnboardingError`.
  - `CompleteOnboardingEvent` → `repository.markLocationOnboardingSeen()`; always emit `LocationOnboardingLoaded(hasSeenLocationOnboarding: true)` (even if the write throws — log it), guaranteeing the "set flag before close without exception" behavior.

**Wiring:** `InjectionContainer.locationOnboardingBloc` (`static late final`), created in `init()` with `logger` + `locationRepository`. `main.dart`: add `BlocProvider(create: (_) => InjectionContainer.locationOnboardingBloc)` to the `MultiBlocProvider` — the 3 existing boot events are NOT modified and no boot event is added for onboarding (the screen triggers `LoadOnboardingStatusEvent` itself).

- [ ] **Step 1:** Failing bloc tests first (initial loading; load false → `Loaded(false)`; load true → `Loaded(true)`; load throws → `Error`; complete → `markLocationOnboardingSeen` called + `Loaded(true)`).
- [ ] **Step 2:** Implement event/state/bloc.
- [ ] **Step 3:** Wire in `injection_container.dart` and `main.dart`.
- [ ] **Step 4:** Run the bloc test, `flutter analyze`, full `flutter test`.

### Task 5: LocationOnboardingSheet widget

**Files:** create `lib/features/location/presentation/widgets/location_onboarding_sheet.dart`; create `test/features/location/presentation/widgets/location_onboarding_sheet_test.dart`.

**Interface produced:**
```dart
class LocationOnboardingSheet extends StatelessWidget {
  const LocationOnboardingSheet({
    super.key,
    required this.onEnableLocation,
    required this.onLater,
    required this.onClose,
  });
  final VoidCallback onEnableLocation;
  final VoidCallback onLater;
  final VoidCallback onClose;
}
```

**Behavior:**
- Wrapped in `PopScope(canPop: false, onPopInvokedWithResult: (didPop, _) { if (!didPop) onLater(); })`.
- Layout (bottom-sheet padding, `SafeArea(top: false)`, `Column(mainAxisSize: min, crossAxisAlignment: stretch)`):
  - Header `Row`: `Icon(Icons.location_on_outlined)` + `SizedBox(width: 8)` + `Expanded(Text(l10n.locationOnboardingTitle, style: titleLarge))` + `IconButton(Icons.close, onPressed: onClose)`.
  - `Text(l10n.locationOnboardingBody, style: bodyLarge)`.
  - `FilledButton.icon(Icons.my_location, label: Text(l10n.locationOnboardingEnable), onPressed: onEnableLocation)` — full width.
  - `TextButton(child: Text(l10n.locationOnboardingLater), onPressed: onLater)` — full width.
- No hardcoded strings; all labels from l10n.

- [ ] **Step 1:** Widget tests first: renders title/body/buttons (en + fr), `onClose` on X tap, `onLater` on Later tap, `onEnableLocation` on Enable tap.
- [ ] **Step 2:** Implement the widget.
- [ ] **Step 3:** Run the widget test, `flutter analyze`, full `flutter test`.

### Task 6: WeatherScreen orchestration

**Files:** modify `lib/features/weather_forecast/presentation/screens/weather_screen.dart`; modify `test/features/weather_forecast/presentation/screens/weather_screen_test.dart`.

**Interfaces consumed:** `LocationOnboardingBloc` (via `context.read`), `WeatherForecastBloc`, `LocationBloc`, `AppRoutes.locationSearch`, `isGpsError` + `showGpsErrorSnackBar`, `LocationOnboardingSheet`.

**Behavior (exact):**
1. Convert `WeatherScreen` to `StatefulWidget` with fields `_sheetShown` (bool), `_sheetShowing` (bool), `_sheetTimer` (`Timer?`), `_gpsRequestFromOnboarding` (bool).
2. `initState`: `context.read<LocationOnboardingBloc>().add(const LoadOnboardingStatusEvent())`.
3. `dispose`: cancel `_sheetTimer`.
4. Keep the existing `BlocListener<LocationBloc>` behavior for `LocationSelected` (→ `FetchWeatherEvent`) and `LocationFavoritesLoaded` (→ fetch or `ResetWeatherEvent`), but: in the `LocationSelected` branch set `_gpsRequestFromOnboarding = false`; add a branch for `LocationError` where `_gpsRequestFromOnboarding == true && isGpsError(state.errorCode)` → set `_gpsRequestFromOnboarding = false` then `showGpsErrorSnackBar(context, state.errorCode)`.
5. Add `BlocListener<LocationOnboardingBloc>`: when `LocationOnboardingLoaded`, if the current `WeatherForecastBloc` state is settled `WeatherEmpty` (`!isFetching`) and `!_sheetShown`, call `_maybeHandleEmptyState(context)`.
6. Wrap the `BlocBuilder` with `BlocListener<WeatherForecastBloc>` (`listenWhen`: `current is WeatherEmpty && !current.isFetching && !(previous is WeatherEmpty && !previous.isFetching)`): listener → `_maybeHandleEmptyState(context)`.
7. `_maybeHandleEmptyState(BuildContext context)`:
   - Read `LocationOnboardingBloc` state; extract `hasSeenLocationOnboarding` (null if not `Loaded` → return, the onboarding listener re-triggers).
   - If `!hasSeen && !_sheetShown`: `_scheduleOnboardingSheet(context)` (500 ms `Timer`; on fire, if `mounted && !_sheetShown` → `_showOnboardingSheet(context)` which re-checks the flag is still false before opening).
   - Else if `!_sheetShowing`: `_showFallbackSearchSnackBar(context)`.
8. `_showOnboardingSheet(BuildContext context)`: set `_sheetShowing = true`; `showModalBottomSheet(context: context, isDismissible: false, enableDrag: false, builder: (_) => LocationOnboardingSheet(onEnableLocation: () => _completeOnboarding(context, enableLocation: true), onLater: () => _completeOnboarding(context, enableLocation: false), onClose: () => _completeOnboarding(context, enableLocation: false)))`; on return set `_sheetShowing = false`.
9. `_completeOnboarding(BuildContext context, {required bool enableLocation})`:
   - `context.read<LocationOnboardingBloc>().add(const CompleteOnboardingEvent());`
   - `_sheetShown = true;`
   - `Navigator.of(context).pop();` (closes the sheet)
   - If `enableLocation`: `_gpsRequestFromOnboarding = true; context.read<LocationBloc>().add(const DetectCurrentLocationEvent());` — do NOT show the fallback SnackBar here (GPS success flows through the existing `LocationSelected` → `FetchWeatherEvent`; GPS failure shows the GPS SnackBar).
   - Else: post-frame callback → if `mounted` and current weather is settled `WeatherEmpty` → `_showFallbackSearchSnackBar(context)`.
10. `_showFallbackSearchSnackBar(BuildContext context)`:
    - `final messenger = ScaffoldMessenger.of(context); messenger.hideCurrentSnackBar();`
    - `messenger.showSnackBar(SnackBar(content: Text(l10n.weatherEmptySearchMessage), action: SnackBarAction(label: l10n.weatherEmptySearchAction, onPressed: () => Navigator.pushNamed(context, AppRoutes.locationSearch))))`.
    - Never fires while `_sheetShowing` is true or on `WeatherError` (listener only triggers on settled `WeatherEmpty`).

**Test setup:** `createTestScreen` in `weather_screen_test.dart` gains a `LocationOnboardingBloc` provider backed by a `MockLocationRepository`. Default to `hasSeenLocationOnboarding = true` so existing tests are unaffected (no sheet; the fallback SnackBar may appear on the existing "resets to empty fallback" test — existing assertions are bloc-state based and must stay green).

**New widget tests:**
- Flag false + settled empty → sheet appears after `pump(500ms)` + `pumpAndSettle`, with localized title.
- Sheet "Later" → `markLocationOnboardingSeen` called, sheet gone, fallback SnackBar visible.
- Sheet X → same as Later.
- Sheet "Enable location" → `markLocationOnboardingSeen` called + `detectCurrentLocation` called; on GPS success the weather repo `fetchWeather` is called with the GPS coordinates.
- Sheet "Enable" with GPS failure → GPS SnackBar shown, no fallback SnackBar.
- Flag true + settled empty → no sheet; fallback SnackBar shown; tapping "Search" navigates to `LocationSearchScreen` (`find.text('Search city...')`).
- `WeatherLoaded` / `WeatherError` → no sheet, no SnackBar.

- [ ] **Step 1:** Extend `createTestScreen` + write the failing widget tests first.
- [ ] **Step 2:** Implement the orchestration.
- [ ] **Step 3:** Run `flutter analyze`, the weather screen tests, and the full `flutter test`.

---

## Verification

- `flutter gen-l10n` (task 1)
- `dart run build_runner build` (task 2)
- `flutter analyze` — 0 warnings, 0 infos (after every task)
- `flutter test` — full suite green (after every task)

## Summary to user (no commit)

At the end, report: files created/modified, l10n keys added, and confirm `flutter analyze` + `flutter test` are green. No git commit is made.
