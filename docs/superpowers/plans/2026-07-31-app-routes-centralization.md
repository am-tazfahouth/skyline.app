# App Routes Centralization — Implementation Plan

**Date:** 2026-07-31
**Feature:** core
**Status:** Implemented

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Centralize all app navigation in a named-route generator (`AppRoutes` + `RouteGenerator`) with a slide transition, and switch all existing `Navigator.push(MaterialPageRoute(...))` calls to named routes.

**Architecture:** A single `lib/core/config/app_routes.dart` file holds route name constants and a `RouteGenerator.generateRoute` that maps route names to screens via a `PageRouteBuilder` slide transition (right-to-left, `Curves.ease`). `main.dart` wires it through `initialRoute` + `onGenerateRoute`. `weather_header.dart` and `location_screen.dart` switch their direct pushes to `Navigator.pushNamed`.

**Tech Stack:** Flutter, Dart 3, Material navigation (`RouteSettings`, `PageRouteBuilder`, `SlideTransition`).

## Global Constraints

- Flutter >=3.35.0, Dart ^3.9.2 (per `pubspec.yaml`).
- `flutter analyze` must report 0 warnings and 0 infos before each commit.
- `flutter test` (full suite) must pass before each commit.
- All code, comments, and commit messages in English.
- TDD: write the failing test before implementation code (Tasks 1). For refactor tasks (3, 4), update the existing navigation tests first, then change the implementation, and verify green.
- No `build_runner` / code generation needed for this feature.
- Do not add code comments unless the existing file already has them nearby (match local style).
- `RouteGenerator` must gracefully fall back to the weather home screen on unknown or null route names (spec §6).

---

### Task 1: Create `AppRoutes` + `RouteGenerator`

**Files:**
- Test: `test/core/config/app_routes_test.dart` (create)
- Create: `lib/core/config/app_routes.dart`

**Interfaces:**
- Produces:
  - `class AppRoutes` with constants `weather = '/'`, `location = '/location'`, `locationSearch = '/location/search'`, `settings = '/settings'`.
  - `class RouteGenerator` with `static Route<dynamic> generateRoute(RouteSettings settings)`.
- Consumes: the four existing screens, all with const constructors: `WeatherScreen()`, `LocationScreen()`, `LocationSearchScreen()`, `SettingsScreen()`.

- [ ] **Step 1: Write the failing test**

Create `test/core/config/app_routes_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/config/app_routes.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/core/services/logger_sevices.dart';
import 'package:sky_line/features/location/domain/repositories/location_repository.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';
import 'package:sky_line/features/location/presentation/screens/location_screen.dart';
import 'package:sky_line/features/location/presentation/screens/location_search_screen.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';
import 'package:sky_line/features/settings/domain/repositories/setting_repository.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:sky_line/features/settings/presentation/screens/settings_screen.dart';
import 'package:sky_line/features/weather_forecast/domain/repositories/weather_repository.dart';
import 'package:sky_line/features/weather_forecast/domain/usecases/get_settings_use_case.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/screens/weather_screen.dart';

class MockLocationRepository extends Mock implements LocationRepository {}

class MockWeatherRepository extends Mock implements WeatherRepository {}

class MockSettingRepository extends Mock implements SettingRepository {}

class MockAppLogger extends Mock implements AppLogger {}

class MockGetSettingsUseCase extends Mock implements GetSettingsUseCase {}

void main() {
  late MockLocationRepository locationRepo;
  late MockWeatherRepository weatherRepo;
  late MockSettingRepository settingRepo;
  late MockAppLogger logger;
  late MockGetSettingsUseCase getSettings;

  setUp(() {
    locationRepo = MockLocationRepository();
    weatherRepo = MockWeatherRepository();
    settingRepo = MockSettingRepository();
    logger = MockAppLogger();
    getSettings = MockGetSettingsUseCase();

    when(() => locationRepo.loadFavorites()).thenReturn([]);
    when(() => weatherRepo.loadCachedWeather()).thenAnswer((_) async => null);
    when(() => getSettings()).thenAnswer((_) async => SettingEntity.defaults);
    when(() => settingRepo.loadSettings())
        .thenAnswer((_) async => SettingEntity.defaults);
  });

  Widget wrap(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LocationBloc>(
          create: (_) =>
              LocationBloc(logger: logger, repository: locationRepo),
        ),
        BlocProvider<WeatherForecastBloc>(
          create: (_) => WeatherForecastBloc(
            logger: logger,
            weatherRepository: weatherRepo,
            getSettings: getSettings,
            isConnected: () async => true,
          ),
        ),
        BlocProvider<SettingsBloc>(
          create: (_) => SettingsBloc(logger: logger, repository: settingRepo),
        ),
      ],
      child: child,
    );
  }

  Future<void> pumpRoute(WidgetTester tester, String routeName) async {
    await tester.pumpWidget(
      wrap(
        MaterialApp(
          localizationsDelegates: AppLocalisation.localizationsDelegates,
          supportedLocales: AppLocalisation.supportedLocales,
          initialRoute: routeName,
          onGenerateRoute: RouteGenerator.generateRoute,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('weather route builds WeatherScreen', (tester) async {
    await pumpRoute(tester, AppRoutes.weather);

    expect(find.byType(WeatherScreen), findsOneWidget);
  });

  testWidgets('location route builds LocationScreen', (tester) async {
    await pumpRoute(tester, AppRoutes.location);

    expect(find.byType(LocationScreen), findsOneWidget);
  });

  testWidgets('locationSearch route builds LocationSearchScreen',
      (tester) async {
    await pumpRoute(tester, AppRoutes.locationSearch);

    expect(find.byType(LocationSearchScreen), findsOneWidget);
  });

  testWidgets('settings route builds SettingsScreen', (tester) async {
    await pumpRoute(tester, AppRoutes.settings);

    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('unknown route falls back to WeatherScreen', (tester) async {
    await pumpRoute(tester, '/unknown');

    expect(find.byType(WeatherScreen), findsOneWidget);
  });

  testWidgets('null route name falls back to WeatherScreen', (tester) async {
    await tester.pumpWidget(
      wrap(
        MaterialApp(
          localizationsDelegates: AppLocalisation.localizationsDelegates,
          supportedLocales: AppLocalisation.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    RouteGenerator.generateRoute(
                      const RouteSettings(name: null),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(WeatherScreen), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/config/app_routes_test.dart`
Expected: FAIL — the analyzer cannot resolve `package:sky_line/core/config/app_routes.dart` (file does not exist yet).

- [ ] **Step 3: Write minimal implementation**

Create `lib/core/config/app_routes.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:sky_line/features/location/presentation/screens/location_screen.dart';
import 'package:sky_line/features/location/presentation/screens/location_search_screen.dart';
import 'package:sky_line/features/settings/presentation/screens/settings_screen.dart';
import 'package:sky_line/features/weather_forecast/presentation/screens/weather_screen.dart';

class AppRoutes {
  static const String weather = '/';
  static const String location = '/location';
  static const String locationSearch = '/location/search';
  static const String settings = '/settings';
}

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.weather:
        return _slideRoute(const WeatherScreen());
      case AppRoutes.location:
        return _slideRoute(const LocationScreen());
      case AppRoutes.locationSearch:
        return _slideRoute(const LocationSearchScreen());
      case AppRoutes.settings:
        return _slideRoute(const SettingsScreen());
      default:
        return _slideRoute(const WeatherScreen());
    }
  }

  static Route<dynamic> _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;
        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/config/app_routes_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: Run full analysis and suite**

Run: `flutter analyze` and `flutter test`
Expected: 0 issues; all tests pass.

- [ ] **Step 6: Commit**

```bash
git add test/core/config/app_routes_test.dart lib/core/config/app_routes.dart
git commit -m "feat: centralize app routing with RouteGenerator"
```

---

### Task 2: Wire named routes into `main.dart`

**Files:**
- Modify: `lib/main.dart:13` (remove now-unused `WeatherScreen` import), `lib/main.dart:57-59` (MaterialApp home/onGenerateRoute/initialRoute)

**Interfaces:**
- Consumes: `AppRoutes.weather` and `RouteGenerator.generateRoute` from Task 1.
- Produces: `MaterialApp` configured with `initialRoute: AppRoutes.weather` and `onGenerateRoute: RouteGenerator.generateRoute`.

- [ ] **Step 1: Update imports**

In `lib/main.dart`, add `import 'package:sky_line/core/config/app_routes.dart';` after the `app_theme.dart` import (line 4), and remove the now-unused `import 'package:sky_line/features/weather_forecast/presentation/screens/weather_screen.dart';` (line 13).

- [ ] **Step 2: Replace `home:` with `initialRoute` + `onGenerateRoute`**

In `lib/main.dart`, replace:

```dart
            home: WeatherScreen(),
```

with:

```dart
            initialRoute: AppRoutes.weather,
            onGenerateRoute: RouteGenerator.generateRoute,
```

- [ ] **Step 3: Verify with analysis**

Run: `flutter analyze`
Expected: 0 issues (confirms the `WeatherScreen` import removal was correct — it would otherwise be an unused-import warning).

Run: `flutter test`
Expected: all tests still pass.

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart
git commit -m "feat: wire named routes into app entry point"
```

---

### Task 3: Use named routes in `WeatherHeader`

**Files:**
- Modify: `lib/features/weather_forecast/presentation/widgets/weather_header.dart:1-6` (imports), `:17-25` (grid icon), `:44-52` (settings icon)
- Modify: `test/features/weather_forecast/presentation/screens/weather_screen_test.dart:58` (test harness `MaterialApp`)

**Interfaces:**
- Consumes: `AppRoutes.location`, `AppRoutes.settings`, `RouteGenerator.generateRoute` from Task 1.
- Produces: grid icon → `Navigator.pushNamed(context, AppRoutes.location)`; settings icon → `Navigator.pushNamed(context, AppRoutes.settings)`.

- [ ] **Step 1: Update the test harness to use `RouteGenerator`**

In `test/features/weather_forecast/presentation/screens/weather_screen_test.dart`:
1. Add `import 'package:sky_line/core/config/app_routes.dart';` before the `core/enums` imports (line 8).
2. Replace the `MaterialApp` in `createTestScreen` (line 58):

```dart
    child: MaterialApp(home: const WeatherScreen()),
```

with:

```dart
    child: MaterialApp(
      onGenerateRoute: RouteGenerator.generateRoute,
      home: const WeatherScreen(),
    ),
```

Run: `flutter test test/features/weather_forecast/presentation/screens/weather_screen_test.dart`
Expected: PASS (the harness now resolves named routes; the header still uses `MaterialPageRoute`, which keeps working).

- [ ] **Step 2: Change the header to `pushNamed`**

In `lib/features/weather_forecast/presentation/widgets/weather_header.dart`:

1. Remove imports:
   - `import 'package:sky_line/features/location/presentation/screens/location_screen.dart';`
   - `import 'package:sky_line/features/settings/presentation/screens/settings_screen.dart';`
2. Add `import 'package:sky_line/core/config/app_routes.dart';` after the `flutter_bloc` imports.
3. Replace the grid icon handler (lines 18-24):

```dart
        icon: const Icon(Icons.grid_view_rounded),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LocationScreen()),
          );
        },
```

with:

```dart
        icon: const Icon(Icons.grid_view_rounded),
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.location);
        },
```

4. Replace the settings icon handler (lines 45-51):

```dart
          icon: const Icon(Icons.settings_rounded),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
```

with:

```dart
          icon: const Icon(Icons.settings_rounded),
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.settings);
          },
```

- [ ] **Step 3: Run tests to verify**

Run: `flutter test test/features/weather_forecast/presentation/screens/weather_screen_test.dart`
Expected: PASS — the "grid icon navigates to LocationScreen" test now exercises the `RouteGenerator` path.

- [ ] **Step 4: Run full analysis and suite**

Run: `flutter analyze` and `flutter test`
Expected: 0 issues; all tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/weather_forecast/presentation/widgets/weather_header.dart test/features/weather_forecast/presentation/screens/weather_screen_test.dart
git commit -m "refactor: use named routes for header navigation"
```

---

### Task 4: Use named route for the location search screen

**Files:**
- Modify: `lib/features/location/presentation/screens/location_screen.dart:1-11` (imports), `:76-83` (FAB)
- Modify: `test/features/location/presentation/screens/location_screen_test.dart:52` (test harness `MaterialApp`)

**Interfaces:**
- Consumes: `AppRoutes.locationSearch`, `RouteGenerator.generateRoute` from Task 1.
- Produces: FAB → `Navigator.pushNamed(context, AppRoutes.locationSearch)`.

- [ ] **Step 1: Update the test harness to use `RouteGenerator`**

In `test/features/location/presentation/screens/location_screen_test.dart`:
1. Add `import 'package:sky_line/core/config/app_routes.dart';` before the `core/services` import (line 5).
2. Replace the `MaterialApp` (line 52):

```dart
        child: MaterialApp(
          home: Builder(
```

with:

```dart
        child: MaterialApp(
          onGenerateRoute: RouteGenerator.generateRoute,
          home: Builder(
```

Run: `flutter test test/features/location/presentation/screens/location_screen_test.dart`
Expected: PASS.

- [ ] **Step 2: Change the FAB to `pushNamed`**

In `lib/features/location/presentation/screens/location_screen.dart`:
1. Remove `import 'package:sky_line/features/location/presentation/screens/location_search_screen.dart';` (line 10).
2. Add `import 'package:sky_line/core/config/app_routes.dart';` after the `core/errors` imports.
3. Replace the FAB handler (lines 77-82):

```dart
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LocationSearchScreen()),
            );
          },
```

with:

```dart
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.locationSearch);
          },
```

- [ ] **Step 3: Run tests to verify**

Run: `flutter test test/features/location/presentation/screens/location_screen_test.dart`
Expected: PASS — the "FAB navigates to LocationSearchScreen" test now exercises the `RouteGenerator` path.

- [ ] **Step 4: Run full analysis and suite**

Run: `flutter analyze` and `flutter test`
Expected: 0 issues; all tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/location/presentation/screens/location_screen.dart test/features/location/presentation/screens/location_screen_test.dart
git commit -m "refactor: use named route for search screen navigation"
```

---

### Task 5: Document routing in `core/config`

**Files:**
- Modify: `AGENTS.md` (section 2, `core/config` line)

**Interfaces:**
- Consumes: nothing (documentation only).

- [ ] **Step 1: Update the `core/config` description**

In `AGENTS.md`, replace:

```
│   ├── config          # Thèmes, injection de dépendances, configuration ObjectBox
```

with:

```
│   ├── config          # Thèmes, injection de dépendances, configuration ObjectBox, routing
```

- [ ] **Step 2: Commit**

```bash
git add AGENTS.md
git commit -m "docs: document routing in core/config"
```
