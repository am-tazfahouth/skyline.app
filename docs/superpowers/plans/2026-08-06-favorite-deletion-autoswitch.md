# Favorite Deletion Auto-Switch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When the favorite currently displayed by the weather content is deleted and other favorites remain, automatically promote the first remaining favorite and fetch its weather instead of resetting the weather screen to the empty fallback.

**Architecture:** The `LocationBloc._onRemoveFavorite` handler computes the replacement current location (the first favorite after reload) and persists it via `saveLastLocation`. The `WeatherScreen` listener gains one new trigger: when `LocationFavoritesLoaded.currentLocation` changes to a different non-null location, it dispatches `FetchWeatherEvent` for the new coordinates. No new events, states, or UI changes.

**Tech Stack:** Flutter, `flutter_bloc`, `equatable`, `mocktail`, `bloc_test`.

## Global Constraints

- **English code only:** identifiers, comments, and commit messages in English.
- **Zero warnings:** `flutter analyze` must report 0 warnings and 0 infos after every task.
- **TDD:** write/extend the failing test first, run it to see it fail, then implement.
- **Immutability:** no mutable private fields in BLoCs; state emitted via `emit(...)`.
- Spec: `docs/superpowers/specs/2026-08-06-favorite-deletion-autoswitch-design.md`

## File Structure

| Action | File | Responsibility |
|---|---|---|
| Modify | `lib/features/location/presentation/blocs/location_bloc.dart` | `_onRemoveFavorite` promotes first remaining favorite |
| Modify | `lib/features/weather_forecast/presentation/screens/weather_screen.dart` | React to `currentLocation` change in `LocationFavoritesLoaded` |
| Modify | `test/features/location/presentation/blocs/location_bloc_test.dart` | Update removal test to the new promotion behavior |
| Modify | `test/features/weather_forecast/presentation/screens/weather_screen_test.dart` | New widget test for auto-switch on delete |

---

### Task 1: Promote the first remaining favorite on removal

**Files:**
- Modify: `lib/features/location/presentation/blocs/location_bloc.dart:140-176`
- Test: `test/features/location/presentation/blocs/location_bloc_test.dart`

**Interfaces:**
- Produces: after `RemoveFavoriteEvent`, when the removed location was the current location and favorites remain, `LocationFavoritesLoaded(favorites: f, currentLocation: f.first)` is emitted and `repository.saveLastLocation(f.first)` is called. `clearLastLocation()` is only called when `favorites.isEmpty` or no promotion occurred.
- Consumes: `LocationRepository.saveLastLocation(LocationEntity)` (already exists), `LocationRepository.loadFavorites()`, `LocationRepository.clearLastLocation()`.

- [ ] **Step 1: Update the failing test**

In `test/features/location/presentation/blocs/location_bloc_test.dart`, replace the bloc test `'removing the current favorite clears it even when other favorites remain'` (currently around lines 212-230) with:

```dart
blocTest<LocationBloc, LocationState>(
  'removing the current favorite promotes the first remaining favorite',
  seed: () => LocationFavoritesLoaded(
    favorites: [testLocation, otherLocation],
    currentLocation: testLocation,
  ),
  build: () {
    when(() => mockRepo.removeFavorite(any())).thenAnswer((_) async {});
    when(() => mockRepo.loadFavorites()).thenReturn([otherLocation]);
    when(() => mockRepo.saveLastLocation(any())).thenAnswer((_) async {});
    return bloc;
  },
  act: (bloc) => bloc.add(const RemoveFavoriteEvent(location: testLocation)),
  expect: () => [
    isA<LocationFavoritesLoaded>()
      .having((s) => s.favorites, 'favorites', [otherLocation])
      .having((s) => s.currentLocation?.cityName, 'currentLocation', 'New York'),
  ],
  verify: (_) {
    verify(() => mockRepo.saveLastLocation(otherLocation)).called(1);
    verifyNever(() => mockRepo.clearLastLocation());
  },
);
```

`testLocation` (`Paris`) and `otherLocation` (`New York`) are already defined in the file's `main()`.

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/location/presentation/blocs/location_bloc_test.dart`

Expected: FAIL — `currentLocation` is null (old code), not `otherLocation`, and `saveLastLocation` was never called.

- [ ] **Step 3: Implement the promotion in `_onRemoveFavorite`**

Add the import at the top of `lib/features/location/presentation/blocs/location_bloc.dart`, in alphabetical position (before the `domain/repositories` import):

```dart
import 'package:sky_line/features/location/domain/entities/location_entity.dart';
```

Replace the block in `_onRemoveFavorite` from `final currentLocation = isStillFavorite ? previousLocation : null;` through the `clearLastLocation()` `if` (lines 159-163) with:

```dart
      final LocationEntity? currentLocation;
      if (isStillFavorite) {
        currentLocation = previousLocation;
      } else if (previousLocation != null && favorites.isNotEmpty) {
        currentLocation = favorites.first;
        await repository.saveLastLocation(currentLocation);
      } else {
        currentLocation = null;
      }
      if (favorites.isEmpty ||
          (previousLocation != null && currentLocation == null)) {
        await repository.clearLastLocation();
      }
```

The rest of the handler (reload, emit, catch) is unchanged.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/location/presentation/blocs/location_bloc_test.dart`

Expected: PASS — all removal tests including the updated one.

- [ ] **Step 5: Analyze and commit**

Run: `flutter analyze`

Expected: 0 issues.

```bash
git add lib/features/location/presentation/blocs/location_bloc.dart test/features/location/presentation/blocs/location_bloc_test.dart
git commit -m "feat(location): promote first favorite on removal of current"
```

---

### Task 2: Switch weather to the promoted favorite

**Files:**
- Modify: `lib/features/weather_forecast/presentation/screens/weather_screen.dart:20-43`
- Test: `test/features/weather_forecast/presentation/screens/weather_screen_test.dart`

**Interfaces:**
- Consumes: `LocationSelected.location`, `LocationFavoritesLoaded.currentLocation` (from `lib/features/location/presentation/blocs/location_state.dart`); `FetchWeatherEvent({double? latitude, double? longitude})` and `ResetWeatherEvent()` from `weather_forecast_event.dart`.
- Produces: `WeatherScreen` dispatches `FetchWeatherEvent(latitude: l.latitude, longitude: l.longitude)` when `LocationFavoritesLoaded` transitions to a different non-null `currentLocation`.

- [ ] **Step 1: Write the failing widget test**

Append to `test/features/weather_forecast/presentation/screens/weather_screen_test.dart` (inside `main()`, after the `'clearing the current location resets weather to the empty fallback'` test):

```dart
  testWidgets('removing the displayed favorite switches to the first remaining favorite',
      (tester) async {
    when(() => mockRepository.fetchWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    )).thenAnswer((_) async => buildWeatherResult());
    when(() => mockRepository.clearCachedWeather()).thenAnswer((_) async {});

    const ny = LocationEntity(
      latitude: 40.71,
      longitude: -74.00,
      cityName: 'New York',
      country: 'USA',
    );

    final locationRepo = MockLocationRepository();
    var favorites = [paris, ny];
    when(() => locationRepo.loadFavorites()).thenAnswer((_) => favorites);
    when(() => locationRepo.loadLastLocation()).thenReturn(paris);
    when(() => locationRepo.removeFavorite(any())).thenAnswer((_) async {
      favorites = [ny];
    });
    when(() => locationRepo.saveLastLocation(any())).thenAnswer((_) async {});
    when(() => locationRepo.clearLastLocation()).thenAnswer((_) async {});
    final locationBloc = LocationBloc(
      logger: MockAppLogger(),
      repository: locationRepo,
    );
    locationBloc.add(const LoadFavoritesEvent());

    final bloc = WeatherForecastBloc(
      logger: MockAppLogger(),
      weatherRepository: mockRepository,
      getSettings: mockGetSettings,
      isConnected: () async => true,
    );
    bloc.add(const FetchWeatherEvent());
    await tester.pumpWidget(createTestScreen(bloc, locationBloc: locationBloc));
    await tester.pumpAndSettle();
    expect(bloc.state, isA<WeatherLoaded>());

    locationBloc.add(const RemoveFavoriteEvent(location: paris));
    await tester.pumpAndSettle();

    verify(
      () => mockRepository.fetchWeather(latitude: 40.71, longitude: -74.00),
    ).called(1);
    expect(bloc.state, isA<WeatherLoaded>());
    expect(bloc.state, isNot(isA<WeatherEmpty>()));
    expect(find.text('New York, USA'), findsOneWidget);
  });
```

`paris` and `buildWeatherResult()` are already defined in the file. No new imports are needed (`RemoveFavoriteEvent`, `LoadFavoritesEvent`, `LocationEntity` are already imported).

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/weather_forecast/presentation/screens/weather_screen_test.dart --plain-name "removing the displayed favorite switches to the first remaining favorite"`

Expected: FAIL — after removal the location bloc sets `currentLocation` to null, the screen resets to `WeatherEmpty`, and `fetchWeather(40.71, -74.00)` is never called.

- [ ] **Step 3: Update `WeatherScreen` listenWhen and listener**

In `lib/features/weather_forecast/presentation/screens/weather_screen.dart`, replace the `listenWhen` block (lines 21-30) with:

```dart
      listenWhen: (previous, current) {
        if (current is LocationSelected) return true;
        if (current is LocationFavoritesLoaded) {
          final previousLocation = switch (previous) {
            LocationSelected(location: final l) => l,
            LocationFavoritesLoaded(currentLocation: final c) => c,
            _ => null,
          };
          final currentLocation = current.currentLocation;
          if (currentLocation == null) return previousLocation != null;
          return previousLocation != null &&
              (previousLocation.latitude != currentLocation.latitude ||
                  previousLocation.longitude != currentLocation.longitude);
        }
        return false;
      },
```

Replace the `listener` body (lines 31-43) with:

```dart
      listener: (context, state) {
        if (state is LocationSelected) {
          context.read<WeatherForecastBloc>().add(
            FetchWeatherEvent(
              latitude: state.location.latitude,
              longitude: state.location.longitude,
            ),
          );
        } else if (state is LocationFavoritesLoaded) {
          final location = state.currentLocation;
          if (location == null) {
            context.read<WeatherForecastBloc>().add(const ResetWeatherEvent());
          } else {
            context.read<WeatherForecastBloc>().add(
              FetchWeatherEvent(
                latitude: location.latitude,
                longitude: location.longitude,
              ),
            );
          }
        }
      },
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/weather_forecast/presentation/screens/weather_screen_test.dart`

Expected: PASS — the new test passes and all existing tests (including `'clearing the current location resets weather to the empty fallback'` and `'LocationSelected triggers weather fetch for coordinates'`) remain green. In particular, the startup transition `LocationInitial` → `LocationFavoritesLoaded` must NOT trigger a fetch (`previousLocation == null`).

- [ ] **Step 5: Full suite, analyze, and commit**

Run: `flutter test`

Expected: PASS — the whole suite (including `location_bloc_test.dart` from Task 1).

Run: `flutter analyze`

Expected: 0 issues.

```bash
git add lib/features/weather_forecast/presentation/screens/weather_screen.dart test/features/weather_forecast/presentation/screens/weather_screen_test.dart
git commit -m "feat(weather): auto-switch weather to first favorite on delete"
```

---

## Verification

| Check | Command |
|---|---|
| Static analysis | `flutter analyze` |
| Targeted bloc tests | `flutter test test/features/location/presentation/blocs/location_bloc_test.dart` |
| Targeted widget tests | `flutter test test/features/weather_forecast/presentation/screens/weather_screen_test.dart` |
| Full suite | `flutter test` |
