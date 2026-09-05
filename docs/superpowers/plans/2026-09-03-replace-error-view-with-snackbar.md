# Replace WeatherErrorView with SnackBar — Implementation Plan

**Date:** 2026-09-03
**Feature:** weather_forecast
**Status:** Implemented

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove `WeatherErrorView` and show errors via SnackBar while always displaying `WeatherContentView`.

**Architecture:** Single `BlocListener` detects `WeatherError` transitions and shows a localized SnackBar with retry. `_contentFor()` becomes a simple return of `WeatherContentView`.

**Tech Stack:** Flutter, flutter_bloc, Equatable

## Global Constraints

- Dart/Flutter code in English only
- Equatable for all entities/models/events/states
- Manual `copyWith` (no freezed)
- `flutter analyze` must return 0 warnings, 0 errors
- `flutter test` must pass
- Follow existing code patterns in the project

---

### Task 1: Add `showWeatherErrorSnackBar` to `cached_weather_feedback.dart`

**Files:**
- Modify: `lib/features/weather_forecast/presentation/utils/cached_weather_feedback.dart`

**Interfaces:**
- Consumes: `AppError.getUserErrorMessage(code, l10n)`, `WeatherForecastBloc` with `FetchWeatherEvent`
- Produces: `showWeatherErrorSnackBar(BuildContext context, AppErrorCode errorCode)`

- [ ] **Step 1: Add imports to `cached_weather_feedback.dart`**

Add at top of file:
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/errors/app_error.dart';
import 'package:sky_line/core/errors/app_error_code.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_event.dart';
```

- [ ] **Step 2: Add `showWeatherErrorSnackBar` function**

Add after `showRefreshErrorSnackBar`:
```dart
/// Shows a localized SnackBar with the error message and a retry action
/// when the weather fetch fails completely.
void showWeatherErrorSnackBar(BuildContext context, AppErrorCode errorCode) {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalisation.of(context)!;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(AppError.getUserErrorMessage(errorCode, l10n)),
      action: SnackBarAction(
        label: l10n.weatherRetry,
        onPressed: () {
          context.read<WeatherForecastBloc>().add(const FetchWeatherEvent());
        },
      ),
    ),
  );
}
```

- [ ] **Step 3: Run `flutter analyze`**

Run: `flutter analyze`
Expected: 0 errors, 0 warnings

---

### Task 2: Update `weather_screen.dart`

**Files:**
- Modify: `lib/features/weather_forecast/presentation/screens/weather_screen.dart`

**Interfaces:**
- Consumes: `showWeatherErrorSnackBar(context, state.errorCode)` from Task 1
- Produces: Updated `_contentFor()` always returning `WeatherContentView`, new error BlocListener

- [ ] **Step 1: Remove `weather_error_view.dart` import**

Remove line 21:
```dart
import 'package:sky_line/features/weather_forecast/presentation/widgets/views/weather_error_view.dart';
```

- [ ] **Step 2: Simplify `_contentFor()`**

Replace the entire method (lines 189-197) with:
```dart
Widget _contentFor(BuildContext context, WeatherForecastState state) {
  return const WeatherContentView();
}
```

- [ ] **Step 3: Add error BlocListener**

Add a new `BlocListener` as the innermost listener, wrapping the existing `BlocBuilder`. The new listener should be placed between the last existing `BlocListener` (the empty state listener on line 136) and the `BlocBuilder` (line 142). Insert it like this:

```dart
BlocListener<WeatherForecastBloc, WeatherForecastState>(
  listenWhen: (previous, current) =>
      current is WeatherError &&
      (previous is! WeatherError || previous.errorCode != current.errorCode),
  listener: (context, state) {
    if (state is WeatherError) {
      showWeatherErrorSnackBar(context, state.errorCode);
    }
  },
  child: BlocBuilder<WeatherForecastBloc, WeatherForecastState>(
    builder: (context, state) {
      // ... existing builder code
    },
  ),
),
```

- [ ] **Step 4: Run `flutter analyze`**

Run: `flutter analyze`
Expected: 0 errors, 0 warnings

---

### Task 3: Delete `weather_error_view.dart` and update affected test

**Files:**
- Delete: `lib/features/weather_forecast/presentation/widgets/views/weather_error_view.dart`
- Modify: `test/features/weather_forecast/presentation/screens/weather_screen_test.dart` (error test ~line 400)

- [ ] **Step 1: Delete the file**

- [ ] **Step 2: Update the error test**

Rename `'shows error view on error state'` to reflect the SnackBar behavior and assert `find.byType(SnackBar)` plus the Retry action, keeping `find.text('Retry')`.

- [ ] **Step 3: Run `flutter analyze`**

Run: `flutter analyze`
Expected: 0 errors, 0 warnings (no dangling references)

- [ ] **Step 4: Run the weather screen test**

Run: `flutter test test/features/weather_forecast/presentation/screens/weather_screen_test.dart`
Expected: all pass

---

### Task 4: Verify

- [ ] **Step 1: Run `flutter test`**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 2: Run `flutter analyze`**

Run: `flutter analyze`
Expected: 0 warnings, 0 errors
