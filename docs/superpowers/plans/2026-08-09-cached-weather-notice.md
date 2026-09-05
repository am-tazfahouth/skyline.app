# Cached Weather Notice — Implementation Plan

**Date:** 2026-08-09
**Feature:** weather_forecast
**Status:** Implemented

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show a localized SnackBar every time the app displays weather data from the cache (connection unavailable), detected purely in the presentation layer.

**Architecture:** `WeatherResult.isCached` already flows through `WeatherLoaded.result.isCached`, so no domain/data/bloc changes are needed. A small stateless feedback helper (`showCachedWeatherSnackBar`) mirrors the existing `gps_error_feedback.dart` pattern. `_WeatherScreenState` gains a `_showsCachedData` predicate and two detection points: an `initState` post-frame check (state already settled before the screen subscribes) and a dedicated `BlocListener<WeatherForecastBloc>` `listenWhen` (transitions into a final cached state).

**Tech Stack:** Flutter, `flutter_bloc`, `equatable`, `flutter_test`/`mocktail`.

## Global Constraints

- All code, identifiers, comments and commits in English only.
- `flutter analyze` must produce zero warnings/infos.
- `flutter test` must pass.
- No freezed / no codegen; `copyWith` manual.
- Presentation layer consumes bloc states via `BlocListener`; user-facing strings must be localized (en/fr/es/ar), never debug strings.
- Do not modify domain/data layers or `WeatherForecastBloc`.

---

## File Structure

- `lib/core/l10n/app_localisation.dart` — add abstract getter `weatherCachedDataMessage` (after `weatherEmptySearchAction`).
- `lib/core/l10n/app_localisation_en.dart` / `_fr.dart` / `_es.dart` / `_ar.dart` — override the getter.
- `lib/features/weather_forecast/presentation/utils/cached_weather_feedback.dart` (new) — `showCachedWeatherSnackBar(BuildContext)`.
- `test/features/weather_forecast/presentation/utils/cached_weather_feedback_test.dart` (new).
- `lib/features/weather_forecast/presentation/screens/weather_screen.dart` — predicate + initState check + dedicated BlocListener.
- `test/features/weather_forecast/presentation/screens/weather_screen_test.dart` — five new widget tests.

---

### Task 1: Localized cached-data message

**Files:**
- Modify: `lib/core/l10n/app_localisation.dart` (after line 517, `weatherEmptySearchAction`)
- Modify: `lib/core/l10n/app_localisation_en.dart` (after line 244)
- Modify: `lib/core/l10n/app_localisation_fr.dart` (after line 246)
- Modify: `lib/core/l10n/app_localisation_es.dart` (after line 242)
- Modify: `lib/core/l10n/app_localisation_ar.dart` (after line 241)

**Interfaces:**
- Produces: `String get weatherCachedDataMessage` on `AppLocalisation` (implemented in all 4 locales). Later tasks read this getter.

- [ ] **Step 1: Add the abstract getter**

In `lib/core/l10n/app_localisation.dart`, insert after the `weatherEmptySearchAction` getter (line 517):

```dart
  /// Informs the user that the displayed weather data comes from the cache
  /// because the connection could not be established.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Showing cached data.'**
  String get weatherCachedDataMessage;
```

- [ ] **Step 2: Implement the getter in all 4 locales**

`en` (after `weatherEmptySearchAction`, line 244):

```dart
  @override
  String get weatherCachedDataMessage =>
      'No internet connection. Showing cached data.';
```

`fr` (after `weatherEmptySearchAction`, line 246):

```dart
  @override
  String get weatherCachedDataMessage =>
      'Connexion impossible. Données affichées depuis le cache.';
```

`es` (after `weatherEmptySearchAction`, line 242):

```dart
  @override
  String get weatherCachedDataMessage =>
      'Sin conexión. Mostrando datos guardados.';
```

`ar` (after `weatherEmptySearchAction`, line 241):

```dart
  @override
  String get weatherCachedDataMessage =>
      'تعذّر الاتصال. عرض البيانات المخزّنة.';
```

- [ ] **Step 3: Verify no analyzer errors**

Run: `flutter analyze`
Expected: 0 issues (the abstract getter is now implemented everywhere).

- [ ] **Step 4: Commit**

```bash
git add lib/core/l10n/
git commit -m "feat(l10n): add cached weather data message"
```

---

### Task 2: Cached-data SnackBar feedback helper

**Files:**
- Test: `test/features/weather_forecast/presentation/utils/cached_weather_feedback_test.dart` (new)
- Create: `lib/features/weather_forecast/presentation/utils/cached_weather_feedback.dart` (new)

**Interfaces:**
- Consumes: `AppLocalisation.weatherCachedDataMessage` (Task 1).
- Produces: `void showCachedWeatherSnackBar(BuildContext context)` — hides the current SnackBar then shows the localized cached-data message with no action.

- [ ] **Step 1: Write the failing test**

Create `test/features/weather_forecast/presentation/utils/cached_weather_feedback_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/features/weather_forecast/presentation/utils/cached_weather_feedback.dart';

void main() {
  Future<void> pumpFeedback(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: AppLocalisation.supportedLocales,
        localizationsDelegates: AppLocalisation.localizationsDelegates,
        home: Builder(
          builder: (context) => Scaffold(
            body: Builder(
              builder: (innerContext) => ElevatedButton(
                onPressed: () => showCachedWeatherSnackBar(innerContext),
                child: const Text('trigger'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the localized cached-data message with no action',
      (tester) async {
    await pumpFeedback(tester);

    expect(
      find.text('No internet connection. Showing cached data.'),
      findsOneWidget,
    );
    expect(find.byType(SnackBarAction), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/weather_forecast/presentation/utils/cached_weather_feedback_test.dart`
Expected: FAIL — compile error: `showCachedWeatherSnackBar` is undefined.

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/weather_forecast/presentation/utils/cached_weather_feedback.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';

/// Shows a localized SnackBar informing the user that the displayed weather
/// data comes from the cache because the connection could not be established.
void showCachedWeatherSnackBar(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalisation.of(context)!;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(content: Text(l10n.weatherCachedDataMessage)),
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/weather_forecast/presentation/utils/cached_weather_feedback_test.dart`
Expected: PASS.

- [ ] **Step 5: Run analyzer**

Run: `flutter analyze`
Expected: 0 issues.

- [ ] **Step 6: Commit**

```bash
git add lib/features/weather_forecast/presentation/utils/cached_weather_feedback.dart test/features/weather_forecast/presentation/utils/cached_weather_feedback_test.dart
git commit -m "feat(weather): add cached data snackbar feedback helper"
```

---

### Task 3: Detect cached-data display in the weather screen

**Files:**
- Modify: `test/features/weather_forecast/presentation/screens/weather_screen_test.dart`
- Modify: `lib/features/weather_forecast/presentation/screens/weather_screen.dart`

**Interfaces:**
- Consumes: `showCachedWeatherSnackBar(BuildContext)` (Task 2), `WeatherForecastBloc` state (`WeatherLoaded`, `WeatherEmpty`), `ApplySettingsEvent`.
- Produces: `_showsCachedData(WeatherForecastState)` private predicate on `_WeatherScreenState`; SnackBar shown on (a) already-settled cached state at first build and (b) every transition into a final cached state.

**Test messages:**
- en: `'No internet connection. Showing cached data.'`
- fr: `'Connexion impossible. Données affichées depuis le cache.'`

- [ ] **Step 1: Write the failing widget tests**

In `test/features/weather_forecast/presentation/screens/weather_screen_test.dart`:

First add a cached-result helper next to the existing `buildWeatherResult()` (after line 135):

```dart
  WeatherResult buildCachedWeatherResult() {
    return buildWeatherResult().copyWith(isCached: true);
  }
```

Then add these five tests at the end of `main()` (before the closing brace). `_defaultSettings`, `MockAppLogger`, `mockRepository`, `mockGetSettings`, `createTestScreen` and `DioException` are already available in the file.

```dart
  testWidgets('shows cached-data snackbar when offline with cached weather',
      (tester) async {
    when(() => mockRepository.loadCachedWeather())
        .thenAnswer((_) async => buildCachedWeatherResult());

    final bloc = WeatherForecastBloc(
      logger: MockAppLogger(),
      weatherRepository: mockRepository,
      getSettings: mockGetSettings,
      isConnected: () async => false,
    );
    bloc.add(const FetchWeatherEvent());
    await tester.pumpWidget(createTestScreen(bloc));
    await tester.pumpAndSettle();

    expect(
      find.text('No internet connection. Showing cached data.'),
      findsOneWidget,
    );
  });

  testWidgets('shows cached-data snackbar localized in French', (tester) async {
    when(() => mockRepository.loadCachedWeather())
        .thenAnswer((_) async => buildCachedWeatherResult());

    final bloc = WeatherForecastBloc(
      logger: MockAppLogger(),
      weatherRepository: mockRepository,
      getSettings: mockGetSettings,
      isConnected: () async => false,
    );
    bloc.add(const FetchWeatherEvent());
    await tester.pumpWidget(createTestScreen(bloc, locale: const Locale('fr')));
    await tester.pumpAndSettle();

    expect(
      find.text('Connexion impossible. Données affichées depuis le cache.'),
      findsOneWidget,
    );
  });

  testWidgets('does not show cached-data snackbar when weather is fresh',
      (tester) async {
    when(() => mockRepository.loadCachedWeather())
        .thenAnswer((_) async => null);
    when(() => mockRepository.fetchWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    )).thenAnswer((_) async => buildWeatherResult());

    final bloc = WeatherForecastBloc(
      logger: MockAppLogger(),
      weatherRepository: mockRepository,
      getSettings: mockGetSettings,
      isConnected: () async => true,
    );
    bloc.add(const FetchWeatherEvent());
    await tester.pumpWidget(createTestScreen(bloc));
    await tester.pumpAndSettle();

    expect(
      find.text('No internet connection. Showing cached data.'),
      findsNothing,
    );
  });

  testWidgets('shows cached-data snackbar again when refresh fails on cached data',
      (tester) async {
    when(() => mockRepository.loadCachedWeather())
        .thenAnswer((_) async => buildCachedWeatherResult());
    when(() => mockRepository.fetchWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    )).thenThrow(DioException(
      requestOptions: RequestOptions(path: ''),
      type: DioExceptionType.connectionError,
    ));

    final bloc = WeatherForecastBloc(
      logger: MockAppLogger(),
      weatherRepository: mockRepository,
      getSettings: mockGetSettings,
      isConnected: () async => false,
    );
    bloc.add(const FetchWeatherEvent());
    await tester.pumpWidget(createTestScreen(bloc));
    await tester.pumpAndSettle();
    expect(
      find.text('No internet connection. Showing cached data.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(
      find.text('No internet connection. Showing cached data.'),
      findsNothing,
    );

    bloc.add(const RefreshWeatherEvent());
    await tester.pumpAndSettle();
    expect(
      find.text('No internet connection. Showing cached data.'),
      findsOneWidget,
    );
  });

  testWidgets('does not re-show cached-data snackbar on settings change',
      (tester) async {
    when(() => mockRepository.loadCachedWeather())
        .thenAnswer((_) async => buildCachedWeatherResult());

    final bloc = WeatherForecastBloc(
      logger: MockAppLogger(),
      weatherRepository: mockRepository,
      getSettings: mockGetSettings,
      isConnected: () async => false,
    );
    bloc.add(const FetchWeatherEvent());
    await tester.pumpWidget(createTestScreen(bloc));
    await tester.pumpAndSettle();
    expect(
      find.text('No internet connection. Showing cached data.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(
      find.text('No internet connection. Showing cached data.'),
      findsNothing,
    );

    const newSettings = SettingEntity(
      windUnit: SettingWindUnit.kmh,
      heatUnit: SettingHeatUnit.fahrenheit,
    );
    bloc.add(ApplySettingsEvent(settings: newSettings));
    await tester.pumpAndSettle();

    expect(
      find.text('No internet connection. Showing cached data.'),
      findsNothing,
    );
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/weather_forecast/presentation/screens/weather_screen_test.dart`
Expected: FAIL — the five new tests fail (message never shown because the screen is not wired).

- [ ] **Step 3: Wire the detection into the weather screen**

In `lib/features/weather_forecast/presentation/screens/weather_screen.dart`:

(a) Add the import (after the `weather_forecast_state.dart` import):

```dart
import 'package:sky_line/features/weather_forecast/presentation/utils/cached_weather_feedback.dart';
```

(b) In `_WeatherScreenState`, add a private predicate after `_gpsRequestFromOnboarding` (line 33):

```dart
  bool _showsCachedData(WeatherForecastState state) =>
      state is WeatherLoaded && state.result.isCached && !state.isFetching;
```

(c) Extend the `initState` post-frame callback (lines 32-38) so a cached state already settled before the first frame shows the SnackBar:

```dart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final weatherState = context.read<WeatherForecastBloc>().state;
      if (weatherState is WeatherEmpty && !weatherState.isFetching) {
        _maybeHandleEmptyState(context);
      }
      if (_showsCachedData(weatherState)) {
        showCachedWeatherSnackBar(context);
      }
    });
```

(d) Add a dedicated `BlocListener<WeatherForecastBloc>` nested between the existing `LocationOnboardingBloc` listener and the existing empty-state `WeatherForecastBloc` listener. Wrap the existing empty-state listener (which currently starts at line 104) so the new listener becomes its parent:

```dart
        child: BlocListener<WeatherForecastBloc, WeatherForecastState>(
          listenWhen: (previous, current) {
            if (!_showsCachedData(current)) return false;
            if (previous is WeatherLoaded &&
                !previous.isFetching &&
                previous.result == current.result) {
              return false;
            }
            return true;
          },
          listener: (context, state) => showCachedWeatherSnackBar(context),
          child: BlocListener<WeatherForecastBloc, WeatherForecastState>(
            listenWhen: (previous, current) =>
                current is WeatherEmpty &&
                !current.isFetching &&
                !(previous is WeatherEmpty && !previous.isFetching),
            listener: (context, state) => _maybeHandleEmptyState(context),
            child: BlocBuilder<WeatherForecastBloc, WeatherForecastState>(
              // ... existing builder unchanged
            ),
          ),
        ),
```

The `previous.result == current.result` guard excludes `ApplySettingsEvent` transitions (same cached `result`, new `settings`) while letting every genuine cache fallback through (transition from `isFetching: true`, or a different `result`).

- [ ] **Step 4: Run the weather screen tests**

Run: `flutter test test/features/weather_forecast/presentation/screens/weather_screen_test.dart`
Expected: PASS — the five new tests plus all pre-existing tests.

- [ ] **Step 5: Run analyzer**

Run: `flutter analyze`
Expected: 0 issues.

- [ ] **Step 6: Commit**

```bash
git add lib/features/weather_forecast/presentation/screens/weather_screen.dart test/features/weather_forecast/presentation/screens/weather_screen_test.dart
git commit -m "feat(weather): show cached data snackbar on connection failure"
```

---

### Task 4: Full verification

**Files:** none (verification only).

- [ ] **Step 1: Run the full test suite**

Run: `flutter test`
Expected: all tests pass.

- [ ] **Step 2: Run static analysis**

Run: `flutter analyze`
Expected: 0 issues.

- [ ] **Step 3: Manual smoke check (optional)**

Run: `flutter run` — load weather with data, enable airplane mode, cold-restart the app; the SnackBar « Connexion impossible. Données affichées depuis le cache. » must appear over the cached weather.
