# Boot Hydration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Eliminate the empty-state flash on `LocationScreen` at startup by hydrating favorites, onboarding and settings *before* `runApp`.

**Architecture:** `AppBootstrap.hydrate()` is awaited in `main()` before `runApp` (native splash preserved). `WeatherScreen` makes onboarding deterministic via a post-frame check instead of the `initState` dispatch. Blocs do not change — only their triggers move.

**Tech Stack:** Flutter/Dart, flutter_bloc 9.x, mocktail (tests), AGENTS.md conventions.

## Global Constraints

- **English only** : code, names, comments, commits.
- **Immutability** : `Equatable`, manual `copyWith` (no freezed).
- **`flutter analyze`** : 0 warnings, 0 infos.
- **`flutter test`** : full suite green.
- **Commit style** : conventional commits in English (`feat:`, `feat(location):`, `docs:`).
- **Per-task commits** : stage only the task's own files. The pre-existing uncommitted section-header refactor and the manual `location_screen.dart` edit must remain untouched and unmixed.
- **Do not touch** : `location_screen.dart` (manually edited by the user).

---

## File Structure

| File | Responsibility |
|---|---|
| `docs/superpowers/specs/2026-08-09-boot-hydration-design.md` | Design spec (create) |
| `lib/core/config/app_bootstrap.dart` | Pre-runApp hydration helper (create) |
| `test/core/config/app_bootstrap_test.dart` | `AppBootstrap` tests (create) |
| `lib/main.dart` | Wire `hydrate()` before `runApp`, move events (modify) |
| `lib/features/weather_forecast/presentation/screens/weather_screen.dart` | Deterministic post-frame onboarding (modify) |
| `test/features/weather_forecast/presentation/screens/weather_screen_test.dart` | Onboarding pre-hydration + new test (modify) |

---

### Task 1: Boot hydration design spec

**Files:**
- Create: `docs/superpowers/specs/2026-08-09-boot-hydration-design.md`

- [x] **Step 1: Write the design doc**

Content: objective (flash `LocationFavoritesLoaded`→`[]` on `LocationScreen`), chosen approach (pre-runApp hydration, native splash preserved), rejected alternatives (`LocationFavoritesLoading` state, hybrid), `AppBootstrap.hydrate()` architecture (3 predicates: `LocationFavoritesLoaded || LocationError`, `LocationOnboardingLoaded || LocationOnboardingError`, `SettingsLoadSuccess(isLoaded: true) || SettingsError`), `WeatherScreen` change (post-frame), error handling (never blocking, 5s timeout), tests.

- [x] **Step 2: Commit**

```bash
git add docs/superpowers/specs/2026-08-09-boot-hydration-design.md
git commit -m "docs: add boot hydration design spec"
```

---

### Task 2: `AppBootstrap.hydrate()` helper

**Files:**
- Create: `lib/core/config/app_bootstrap.dart`
- Test: `test/core/config/app_bootstrap_test.dart`

**Interfaces:**
- Produces: `Future<void> AppBootstrap.hydrate({SettingsBloc? settingsBloc, LocationBloc? locationBloc, LocationOnboardingBloc? onboardingBloc, Duration timeout = const Duration(seconds: 5)})` — leaves the 3 blocs in their loaded-or-error state, never throws.

- [x] **Step 1: Write the failing test**

```dart
// test/core/config/app_bootstrap_test.dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/config/app_bootstrap.dart';
import 'package:sky_line/core/services/logger_sevices.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';
import 'package:sky_line/features/location/domain/repositories/location_repository.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_onboarding_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_onboarding_state.dart';
import 'package:sky_line/features/location/presentation/blocs/location_state.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';
import 'package:sky_line/features/settings/domain/repositories/setting_repository.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_state.dart';

class MockLocationRepository extends Mock implements LocationRepository {}

class MockSettingRepository extends Mock implements SettingRepository {}

class MockAppLogger extends Mock implements AppLogger {}

void main() {
  test('hydrate leaves location, onboarding and settings blocs loaded', () async {
    final locationRepo = MockLocationRepository();
    when(() => locationRepo.loadFavorites())
        .thenReturn(const <LocationEntity>[]);
    when(() => locationRepo.loadLastLocation()).thenReturn(null);

    final onboardingRepo = MockLocationRepository();
    when(() => onboardingRepo.hasSeenLocationOnboarding())
        .thenAnswer((_) async => false);

    final settingRepo = MockSettingRepository();
    when(() => settingRepo.loadSettings())
        .thenAnswer((_) async => const SettingEntity());

    final locationBloc =
        LocationBloc(logger: MockAppLogger(), repository: locationRepo);
    final onboardingBloc = LocationOnboardingBloc(
      logger: MockAppLogger(),
      repository: onboardingRepo,
    );
    final settingsBloc =
        SettingsBloc(logger: MockAppLogger(), repository: settingRepo);

    await AppBootstrap.hydrate(
      locationBloc: locationBloc,
      onboardingBloc: onboardingBloc,
      settingsBloc: settingsBloc,
    );

    expect(locationBloc.state, isA<LocationFavoritesLoaded>());
    expect(onboardingBloc.state, isA<LocationOnboardingLoaded>());
    expect(settingsBloc.state, isA<SettingsLoadSuccess>());
    expect((settingsBloc.state as SettingsLoadSuccess).isLoaded, isTrue);
  });

  test('hydrate completes without throwing when a repository read fails', () async {
    final locationRepo = MockLocationRepository();
    when(() => locationRepo.loadFavorites()).thenThrow(Exception('boom'));

    final onboardingRepo = MockLocationRepository();
    when(() => onboardingRepo.hasSeenLocationOnboarding())
        .thenThrow(Exception('boom'));

    final settingRepo = MockSettingRepository();
    when(() => settingRepo.loadSettings()).thenThrow(Exception('boom'));

    await expectLater(
      AppBootstrap.hydrate(
        locationBloc:
            LocationBloc(logger: MockAppLogger(), repository: locationRepo),
        onboardingBloc: LocationOnboardingBloc(
          logger: MockAppLogger(),
          repository: onboardingRepo,
        ),
        settingsBloc:
            SettingsBloc(logger: MockAppLogger(), repository: settingRepo),
      ),
      completes,
    );
  });

  test('hydrate never blocks launch when a read never completes', () async {
    final locationRepo = MockLocationRepository();
    when(() => locationRepo.loadFavorites())
        .thenReturn(const <LocationEntity>[]);
    when(() => locationRepo.loadLastLocation()).thenReturn(null);

    final onboardingRepo = MockLocationRepository();
    when(() => onboardingRepo.hasSeenLocationOnboarding())
        .thenAnswer((_) => Completer<bool>().future);

    final settingRepo = MockSettingRepository();
    when(() => settingRepo.loadSettings())
        .thenAnswer((_) async => const SettingEntity());

    await expectLater(
      AppBootstrap.hydrate(
        locationBloc:
            LocationBloc(logger: MockAppLogger(), repository: locationRepo),
        onboardingBloc: LocationOnboardingBloc(
          logger: MockAppLogger(),
          repository: onboardingRepo,
        ),
        settingsBloc:
            SettingsBloc(logger: MockAppLogger(), repository: settingRepo),
        timeout: const Duration(milliseconds: 50),
      ),
      completes,
    );
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/config/app_bootstrap_test.dart`
Expected: FAIL — compilation error, `AppBootstrap` not defined.

- [x] **Step 3: Write the minimal implementation**

```dart
// lib/core/config/app_bootstrap.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_event.dart';
import 'package:sky_line/features/location/presentation/blocs/location_onboarding_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_onboarding_event.dart';
import 'package:sky_line/features/location/presentation/blocs/location_onboarding_state.dart';
import 'package:sky_line/features/location/presentation/blocs/location_state.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_event.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_state.dart';
import 'package:sky_line/injection_container.dart';

abstract final class AppBootstrap {
  static Future<void> hydrate({
    SettingsBloc? settingsBloc,
    LocationBloc? locationBloc,
    LocationOnboardingBloc? onboardingBloc,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final settings = settingsBloc ?? InjectionContainer.settingsBloc;
    final location = locationBloc ?? InjectionContainer.locationBloc;
    final onboarding = onboardingBloc ?? InjectionContainer.locationOnboardingBloc;

    final settingsFuture = _waitFor(
      settings,
      (s) => (s is SettingsLoadSuccess && s.isLoaded) || s is SettingsError,
      timeout,
    );
    final locationFuture = _waitFor(
      location,
      (s) => s is LocationFavoritesLoaded || s is LocationError,
      timeout,
    );
    final onboardingFuture = _waitFor(
      onboarding,
      (s) => s is LocationOnboardingLoaded || s is LocationOnboardingError,
      timeout,
    );

    settings.add(const LoadSettingsEvent());
    location.add(const LoadFavoritesEvent());
    onboarding.add(const LoadOnboardingStatusEvent());

    await Future.wait([settingsFuture, locationFuture, onboardingFuture]);
  }

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
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/config/app_bootstrap_test.dart`
Expected: PASS (3 tests).

- [x] **Step 5: Commit**

```bash
git add lib/core/config/app_bootstrap.dart test/core/config/app_bootstrap_test.dart
git commit -m "feat(core): add AppBootstrap pre-runApp hydration"
```

---

### Task 3: Wire hydration in `main()`

**Files:**
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: `AppBootstrap.hydrate()` (Task 2).

- [x] **Step 1: Edit `lib/main.dart`**

Remove the `settings_event.dart` and `location_event.dart` imports; add `import 'package:sky_line/core/config/app_bootstrap.dart';` (sorted before `app_routes.dart`). Insert the hydration call and slim the providers:

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
        BlocProvider(
          create: (_) => InjectionContainer.settingsBloc,
        ),
        BlocProvider(
          create: (_) => InjectionContainer.locationBloc,
        ),
        BlocProvider(
          create: (_) => InjectionContainer.locationOnboardingBloc,
        ),
      ],
      child: MyApp(),
    ),
  );
```

- [x] **Step 2: Run static analysis**

Run: `flutter analyze`
Expected: 0 issues.

- [x] **Step 3: Run full test suite**

Run: `flutter test`
Expected: PASS (existing suite). Onboarding is hydrated before `runApp`, so `MyApp` receives `SettingsLoadSuccess(isLoaded: true)` from the first frame.

- [x] **Step 4: Commit**

```bash
git add lib/main.dart
git commit -m "feat(core): hydrate blocs before runApp"
```

---

### Task 4: Deterministic onboarding on `WeatherScreen`

**Files:**
- Modify: `test/features/weather_forecast/presentation/screens/weather_screen_test.dart`
- Modify: `lib/features/weather_forecast/presentation/screens/weather_screen.dart`

**Interfaces:**
- Consumes: `LocationOnboardingLoaded` hydrated before `runApp` (Tasks 2/3).
- Produces: behavior — the sheet/snackbar triggers on the post-frame check, without re-fetching `hasSeenLocationOnboarding()`.

- [x] **Step 1: Update the test helper (tests-first)**

Add the import and helper in `weather_screen_test.dart`:

```dart
import 'package:sky_line/features/location/presentation/blocs/location_onboarding_event.dart';
```

```dart
Future<LocationOnboardingBloc> buildHydratedOnboardingBloc({
  required MockLocationRepository repo,
}) async {
  final bloc = LocationOnboardingBloc(
    logger: MockAppLogger(),
    repository: repo,
  );
  bloc.add(const LoadOnboardingStatusEvent());
  await bloc.stream.first;
  return bloc;
}
```

In `createTestScreen`, default branch: dispatch the event (mirror of hydration). NOTE: the parentheses around the default construction are REQUIRED — `a ?? B()..add(x)` parses as `(a ?? B())..add(x)`, which would dispatch on the provided bloc too:

```dart
  final onboardingBloc = locationOnboardingBloc ??
      (LocationOnboardingBloc(
        logger: MockAppLogger(),
        repository: onboardingRepo,
      )..add(const LoadOnboardingStatusEvent()));
```

- [x] **Step 2: Update the 5 onboarding tests to pre-hydrate**

In the tests `'shows onboarding sheet when onboarding not seen and weather is empty'`, `'sheet Later completes onboarding and shows fallback search snackbar'`, `'sheet close icon completes onboarding and shows fallback search snackbar'`, `'sheet enable location fetches weather for the GPS position'`, `'sheet enable location with GPS failure shows GPS error snackbar'`, replace:

```dart
final onboardingBloc = buildOnboardingBloc(repo: onboardingRepo);
```

with:

```dart
final onboardingBloc = await buildHydratedOnboardingBloc(repo: onboardingRepo);
```

(remove `buildOnboardingBloc`, now unused).

- [x] **Step 3: Add the determinism test**

```dart
testWidgets('does not re-fetch onboarding status and shows sheet at first empty frame',
    (tester) async {
  final onboardingRepo = MockLocationRepository();
  when(() => onboardingRepo.hasSeenLocationOnboarding())
      .thenAnswer((_) async => false);
  when(() => onboardingRepo.markLocationOnboardingSeen())
      .thenAnswer((_) async {});
  final onboardingBloc = await buildHydratedOnboardingBloc(repo: onboardingRepo);

  final bloc = buildEmptyBloc();
  await tester.pumpWidget(
    createTestScreen(bloc, locationOnboardingBloc: onboardingBloc),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();

  expect(find.byType(LocationOnboardingSheet), findsOneWidget);
  verify(() => onboardingRepo.hasSeenLocationOnboarding()).called(1);
});
```

- [x] **Step 4: Run tests to verify the new test fails (red)**

Run: `flutter test test/features/weather_forecast/presentation/screens/weather_screen_test.dart`
Expected: the new test FAILS — `hasSeenLocationOnboarding` called 2× (`initState` + pre-hydration).

- [x] **Step 5: Implement the post-frame check**

In `weather_screen.dart`, replace the `initState` (lines 36-40). The `location_onboarding_event.dart` import (line 11) STAYS: `CompleteOnboardingEvent` (used in `_completeOnboarding`) also lives in that file — only the `LoadOnboardingStatusEvent` dispatch is removed:

```dart
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final weatherState = context.read<WeatherForecastBloc>().state;
      if (weatherState is WeatherEmpty && !weatherState.isFetching) {
        _maybeHandleEmptyState(context);
      }
    });
  }
```

- [x] **Step 6: Run the full weather screen suite (green)**

Run: `flutter test test/features/weather_forecast/presentation/screens/weather_screen_test.dart`
Expected: PASS — the new test passes (`hasSeen` called 1×), the 5 onboarding tests pass via the post-frame check.

- [x] **Step 7: Commit**

```bash
git add test/features/weather_forecast/presentation/screens/weather_screen_test.dart lib/features/weather_forecast/presentation/screens/weather_screen.dart
git commit -m "feat(weather): hydrate onboarding before first frame"
```

---

### Task 5: Full verification

- [x] **Step 1: Static analysis**

Run: `flutter analyze`
Expected: 0 issues.

- [x] **Step 2: Full test suite**

Run: `flutter test`
Expected: PASS (full suite).

- [x] **Step 3: Manual smoke check**

Run: `flutter run`
Expected: at startup, `LocationScreen` never shows the empty view by mistake; the onboarding sheet appears on the first frame when required.

- [x] **Step 4: Save the implementation plan**

Save this document in `docs/superpowers/plans/2026-08-09-boot-hydration.md` then commit:

```bash
git add docs/superpowers/plans/2026-08-09-boot-hydration.md
git commit -m "docs: add boot hydration implementation plan"
```
