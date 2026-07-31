# Location Screen Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `LocationScreen` that lists favorite locations (with GPS detection and add-to-favorites search flow) and wire it into the weather UI: grid icon navigation, dynamic header title, and location→weather bridging.

**Architecture:** Presentation-layer wiring. No changes to `LocationBloc`, repositories, data sources, or ObjectBox. Reuse existing events (`AddFavoriteEvent`, `SelectLocationEvent`, `DetectCurrentLocationEvent`) as-is. A `BlocListener<LocationBloc>` in `WeatherScreen` bridges `LocationSelected` → `FetchWeatherEvent(latitude:, longitude:)`. The header title is read from `LocationBloc` state via `BlocBuilder`.

**Tech Stack:** Flutter >=3.35.0 (Dart ^3.9.2), flutter_bloc 9.x, equatable 2.x, mocktail, bloc_test, flutter_test

**Spec:** `docs/superpowers/specs/2026-07-31-location-screen-integration-design.md`

## Global Constraints

- All code in English (variables, classes, comments).
- Equatable on entities/models/events/states with explicit `props` (existing classes unchanged).
- Manual `copyWith` only (no freezed).
- Zero `flutter analyze` warnings.
- TDD: write the failing test first, verify it fails, then implement.
- Commit after each task with the exact message provided.
- Do NOT modify `LocationBloc`, `LocationRepository`, data sources, ObjectBox entities, or `DbHelper`.

---

### Task 1: `LocationEntity.title` Getter

**Files:**
- Modify: `lib/features/location/domain/entities/location_entity.dart` (add getter at end of class, after `props`)
- Test: `test/features/location/domain/entities/location_entity_test.dart`

**Interfaces:**
- Consumes: existing `LocationEntity` fields `cityName` (String), `country` (String?)
- Produces: `String get title` — `cityName` + non-empty `country` joined with `', '`; e.g. `'Moroni, Comoros'`, `'Paris'`, `'Current Location'`

- [ ] **Step 1: Write the failing tests**

Add a `group('title', ...)` block inside `main()` in `test/features/location/domain/entities/location_entity_test.dart`:

```dart
    group('title', () {
      test('joins city and country with a comma', () {
        const loc = LocationEntity(
          latitude: 0,
          longitude: 0,
          cityName: 'Moroni',
          country: 'Comoros',
        );
        expect(loc.title, 'Moroni, Comoros');
      });

      test('falls back to city when country is null', () {
        const loc = LocationEntity(latitude: 0, longitude: 0, cityName: 'Paris');
        expect(loc.title, 'Paris');
      });

      test('falls back to city when country is empty', () {
        const loc = LocationEntity(
          latitude: 0,
          longitude: 0,
          cityName: 'Paris',
          country: '',
        );
        expect(loc.title, 'Paris');
      });
    });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/location/domain/entities/location_entity_test.dart`
Expected: FAIL — `noSuchMethod: The getter 'title' was called on null` (getter does not exist yet)

- [ ] **Step 3: Implement the getter**

In `lib/features/location/domain/entities/location_entity.dart`, after the `props` override (end of class):

```dart
  String get title => [cityName, country]
      .where((e) => e != null && e.isNotEmpty)
      .join(', ');
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/location/domain/entities/location_entity_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/location/domain/entities/location_entity.dart test/features/location/domain/entities/location_entity_test.dart
git commit -m "feat(location): add title getter to LocationEntity"
```

---

### Task 2: Add-to-Favorites on Search Result Selection

**Files:**
- Modify: `lib/features/location/presentation/screens/location_search_screen.dart` (result tap handler only)
- Create: `test/features/location/presentation/screens/location_search_screen_test.dart`

**Interfaces:**
- Consumes: `LocationBloc.repository` (public field, type `LocationRepository`), `LocationRepository.loadFavorites() → List<LocationEntity>`, `AddFavoriteEvent(location:)`, `SelectLocationEvent(location:)`, `LocationSearchLoaded.results`
- Produces: result-tap behavior — dispatch `AddFavoriteEvent` (only when the location is not already a favorite, matched by exact `latitude`/`longitude`) followed by `SelectLocationEvent`, then pop the route.

> Design note (refinement of spec §5): the tap handler reads favorites from `bloc.repository.loadFavorites()` instead of `bloc.state`. At tap time the state is `LocationSearchLoaded`, which does not carry the favorites list; reading the repository is the reliable source.

- [ ] **Step 1: Write the failing widget tests**

Create `test/features/location/presentation/screens/location_search_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/services/logger_sevices.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';
import 'package:sky_line/features/location/domain/repositories/location_repository.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_event.dart';
import 'package:sky_line/features/location/presentation/screens/location_search_screen.dart';

class MockRepository extends Mock implements LocationRepository {}

class MockLogger extends Mock implements AppLogger {}

const paris = LocationEntity(
  latitude: 48.85,
  longitude: 2.35,
  cityName: 'Paris',
  country: 'France',
);

void main() {
  late MockRepository repo;
  late LocationBloc bloc;

  setUpAll(() {
    registerFallbackValue(const LocationEntity(latitude: 0, longitude: 0, cityName: ''));
  });

  setUp(() {
    repo = MockRepository();
    bloc = LocationBloc(logger: MockLogger(), repository: repo);
  });

  tearDown(() => bloc.close());

  Future<void> pumpSearchResults(WidgetTester tester) async {
    when(() => repo.searchLocations(any())).thenAnswer((_) async => [paris]);
    await tester.pumpWidget(
      BlocProvider<LocationBloc>.value(
        value: bloc,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LocationSearchScreen(),
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
    bloc.add(const SearchLocationsEvent('par'));
    await tester.pumpAndSettle();
  }

  testWidgets('tapping a result adds it to favorites then selects it',
      (tester) async {
    when(() => repo.loadFavorites()).thenReturn([]);
    when(() => repo.saveFavorite(any())).thenAnswer((_) async {});
    when(() => repo.saveLastLocation(any())).thenAnswer((_) async {});

    await pumpSearchResults(tester);
    await tester.tap(find.text('Paris'));
    await tester.pumpAndSettle();

    verify(() => repo.saveFavorite(paris)).called(1);
    verify(() => repo.saveLastLocation(paris)).called(1);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('tapping a result skips add when already a favorite',
      (tester) async {
    when(() => repo.loadFavorites()).thenReturn([paris]);
    when(() => repo.saveFavorite(any())).thenAnswer((_) async {});
    when(() => repo.saveLastLocation(any())).thenAnswer((_) async {});

    await pumpSearchResults(tester);
    await tester.tap(find.text('Paris'));
    await tester.pumpAndSettle();

    verifyNever(() => repo.saveFavorite(any()));
    verify(() => repo.saveLastLocation(paris)).called(1);
    expect(find.text('open'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/location/presentation/screens/location_search_screen_test.dart`
Expected: FAIL — currently the handler never calls `saveFavorite`, so `verify(() => repo.saveFavorite(paris)).called(1)` fails

- [ ] **Step 3: Implement add-then-select**

Replace the `SearchResultTile` `onTap` body in `lib/features/location/presentation/screens/location_search_screen.dart` (currently dispatches only `SelectLocationEvent`) with:

```dart
                        return SearchResultTile(
                          location: location,
                          onTap: () {
                            final bloc = context.read<LocationBloc>();
                            final favorites = bloc.repository.loadFavorites();
                            final isAlreadyFavorite = favorites.any(
                              (f) => f.latitude == location.latitude &&
                                  f.longitude == location.longitude,
                            );
                            if (!isAlreadyFavorite) {
                              bloc.add(AddFavoriteEvent(location: location));
                            }
                            bloc.add(SelectLocationEvent(location: location));
                            Navigator.pop(context);
                          },
                        );
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/location/presentation/screens/location_search_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Run analysis and full location tests**

Run: `flutter analyze`
Expected: 0 issues

Run: `flutter test test/features/location/`
Expected: ALL PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/location/presentation/screens/location_search_screen.dart test/features/location/presentation/screens/location_search_screen_test.dart
git commit -m "feat(location): add search result to favorites before selection"
```

---

### Task 3: `LocationScreen`

**Files:**
- Create: `lib/features/location/presentation/screens/location_screen.dart`
- Create: `test/features/location/presentation/screens/location_screen_test.dart`

**Interfaces:**
- Consumes: `LocationBloc`, `LocationState` subtypes (`LocationFavoritesLoaded`, `LocationSelected`, `LocationDetecting`, `LocationError`), `FavoritesListWidget(favorites:, onLocationTap:)`, `LocationErrorCodes` (const `AppErrorCode`), `AppError.getUserErrorMessage(AppErrorCode)`, `LocationSearchScreen`
- Produces: `LocationScreen` — AppBar titled `'Location'` with a GPS `IconButton` (`Icons.my_location_rounded`, spinner while `LocationDetecting`), body with `FavoritesListWidget`, FAB (`Icons.add`) pushing `LocationSearchScreen`, and a `BlocListener` that (a) on `LocationSelected` adds the GPS location to favorites when not already present, then pops; (b) shows a SnackBar on GPS `LocationError` codes.

- [ ] **Step 1: Write the failing widget tests**

Create `test/features/location/presentation/screens/location_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/services/logger_sevices.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';
import 'package:sky_line/features/location/domain/repositories/location_repository.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_event.dart';
import 'package:sky_line/features/location/presentation/screens/location_screen.dart';

class MockRepository extends Mock implements LocationRepository {}

class MockLogger extends Mock implements AppLogger {}

const paris = LocationEntity(
  latitude: 48.85,
  longitude: 2.35,
  cityName: 'Paris',
  country: 'France',
);

const gps = LocationEntity(
  latitude: -11.7,
  longitude: 43.25,
  cityName: 'Current Location',
  isGpsLocation: true,
);

void main() {
  late MockRepository repo;
  late LocationBloc bloc;

  setUpAll(() {
    registerFallbackValue(const LocationEntity(latitude: 0, longitude: 0, cityName: ''));
  });

  setUp(() {
    repo = MockRepository();
    bloc = LocationBloc(logger: MockLogger(), repository: repo);
  });

  tearDown(() => bloc.close());

  Future<void> pumpLocationScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider<LocationBloc>.value(
        value: bloc,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LocationScreen()),
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
  }

  testWidgets('renders title and empty favorites state', (tester) async {
    await pumpLocationScreen(tester);

    expect(find.text('Location'), findsOneWidget);
    expect(find.text('No favorites yet'), findsOneWidget);
  });

  testWidgets('renders favorite locations', (tester) async {
    when(() => repo.loadFavorites()).thenReturn([paris]);
    when(() => repo.loadLastLocation()).thenReturn(null);
    bloc.add(const LoadFavoritesEvent());

    await pumpLocationScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('Paris'), findsOneWidget);
  });

  testWidgets('FAB navigates to LocationSearchScreen', (tester) async {
    await pumpLocationScreen(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Search City'), findsOneWidget);
  });

  testWidgets('GPS action dispatches DetectCurrentLocationEvent', (tester) async {
    when(() => repo.loadFavorites()).thenReturn([]);
    when(() => repo.detectCurrentLocation()).thenAnswer((_) async => gps);
    when(() => repo.saveLastLocation(any())).thenAnswer((_) async {});
    when(() => repo.saveFavorite(any())).thenAnswer((_) async {});

    await pumpLocationScreen(tester);
    await tester.tap(find.byIcon(Icons.my_location_rounded));
    await tester.pumpAndSettle();

    verify(() => repo.detectCurrentLocation()).called(1);
  });

  testWidgets('GPS selection adds favorite and pops', (tester) async {
    when(() => repo.loadFavorites()).thenReturn([]);
    when(() => repo.detectCurrentLocation()).thenAnswer((_) async => gps);
    when(() => repo.saveLastLocation(any())).thenAnswer((_) async {});
    when(() => repo.saveFavorite(any())).thenAnswer((_) async {});

    await pumpLocationScreen(tester);
    await tester.tap(find.byIcon(Icons.my_location_rounded));
    await tester.pumpAndSettle();

    verify(() => repo.saveFavorite(gps)).called(1);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('non-GPS selection pops without adding favorite', (tester) async {
    when(() => repo.loadFavorites()).thenReturn([]);
    when(() => repo.saveLastLocation(any())).thenAnswer((_) async {});

    await pumpLocationScreen(tester);
    bloc.add(const SelectLocationEvent(location: paris));
    await tester.pumpAndSettle();

    verifyNever(() => repo.saveFavorite(any()));
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('favorite tap dispatches SelectLocationEvent', (tester) async {
    when(() => repo.loadFavorites()).thenReturn([paris]);
    when(() => repo.loadLastLocation()).thenReturn(null);
    when(() => repo.saveLastLocation(any())).thenAnswer((_) async {});
    bloc.add(const LoadFavoritesEvent());

    await pumpLocationScreen(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paris'));
    await tester.pumpAndSettle();

    verify(() => repo.saveLastLocation(paris)).called(1);
  });

  testWidgets('GPS error shows a SnackBar', (tester) async {
    when(() => repo.loadFavorites()).thenReturn([]);
    when(() => repo.detectCurrentLocation()).thenThrow(Exception('gps failed'));

    await pumpLocationScreen(tester);
    await tester.tap(find.byIcon(Icons.my_location_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/location/presentation/screens/location_screen_test.dart`
Expected: FAIL — `LocationScreen` class not found

- [ ] **Step 3: Implement `LocationScreen`**

Create `lib/features/location/presentation/screens/location_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/errors/app_error.dart';
import 'package:sky_line/core/errors/app_error_code.dart';
import 'package:sky_line/core/errors/location_error_codes.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_event.dart';
import 'package:sky_line/features/location/presentation/blocs/location_state.dart';
import 'package:sky_line/features/location/presentation/screens/location_search_screen.dart';
import 'package:sky_line/features/location/presentation/widgets/favorites_list_widget.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  bool _isGpsError(AppErrorCode code) =>
      code == LocationErrorCodes.gpsDisabled ||
      code == LocationErrorCodes.gpsPermissionDenied ||
      code == LocationErrorCodes.gpsFailed;

  @override
  Widget build(BuildContext context) {
    return BlocListener<LocationBloc, LocationState>(
      listener: (context, state) {
        if (state is LocationSelected) {
          final location = state.location;
          final alreadyFavorite = state.favorites.any(
            (f) => f.latitude == location.latitude &&
                f.longitude == location.longitude,
          );
          if (location.isGpsLocation && !alreadyFavorite) {
            context
                .read<LocationBloc>()
                .add(AddFavoriteEvent(location: location));
          }
          if (context.mounted) {
            Navigator.pop(context);
          }
        } else if (state is LocationError && _isGpsError(state.errorCode)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppError.getUserErrorMessage(state.errorCode)),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Location'),
          actions: [
            BlocBuilder<LocationBloc, LocationState>(
              builder: (context, state) {
                if (state is LocationDetecting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return IconButton(
                  icon: const Icon(Icons.my_location_rounded),
                  tooltip: 'Current location',
                  onPressed: () {
                    context
                        .read<LocationBloc>()
                        .add(const DetectCurrentLocationEvent());
                  },
                );
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LocationSearchScreen()),
            );
          },
          child: const Icon(Icons.add),
        ),
        body: BlocBuilder<LocationBloc, LocationState>(
          builder: (context, state) {
            final favorites = switch (state) {
              LocationFavoritesLoaded(favorites: final f) => f,
              LocationSelected(favorites: final f) => f,
              _ => const <LocationEntity>[],
            };
            return FavoritesListWidget(
              favorites: favorites,
              onLocationTap: (location) {
                context
                    .read<LocationBloc>()
                    .add(SelectLocationEvent(location: location));
              },
            );
          },
        ),
      ),
    );
  }
}
```

Note: `AppErrorCode` is imported explicitly — `app_error.dart` imports it but does not re-export it.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/location/presentation/screens/location_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Run analysis and full location tests**

Run: `flutter analyze`
Expected: 0 issues

Run: `flutter test test/features/location/`
Expected: ALL PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/location/presentation/screens/location_screen.dart test/features/location/presentation/screens/location_screen_test.dart
git commit -m "feat(location): add LocationScreen with favorites and GPS action"
```

---

### Task 4: `WeatherHeader` — Dynamic Title and Grid Navigation

**Files:**
- Modify: `lib/features/weather_forecast/presentation/widgets/weather_header.dart`
- Test: `test/features/weather_forecast/presentation/screens/weather_screen_test.dart`

**Interfaces:**
- Consumes: `LocationBloc`, `LocationState` (`LocationSelected`, `LocationFavoritesLoaded`), `LocationEntity.title` (Task 1), `LocationScreen` (Task 3)
- Produces: `WeatherHeader` — grid icon pushes `LocationScreen`; title is `BlocBuilder<LocationBloc, LocationState>` resolving `LocationSelected(location) → location.title`, `LocationFavoritesLoaded(currentLocation) → currentLocation?.title`, else `'SkyLine'`.

- [ ] **Step 1: Update the test harness and write failing tests**

In `test/features/weather_forecast/presentation/screens/weather_screen_test.dart`:

a) Move the `LocationBloc` provider **above** `MaterialApp` (pushed routes such as `LocationScreen` need access to it), and let the helper accept an optional `LocationBloc`. Replace the existing `createTestScreen` function (lines 42-62) with:

```dart
Widget createTestScreen(WeatherForecastBloc bloc, {LocationBloc? locationBloc}) {
  final locBloc = locationBloc ??
      LocationBloc(logger: MockAppLogger(), repository: MockLocationRepository());
  return MultiBlocProvider(
    providers: [
      BlocProvider<WeatherForecastBloc>.value(value: bloc),
      BlocProvider<SettingsBloc>(
        create: (_) => SettingsBloc(
          logger: MockAppLogger(),
          repository: MockSettingRepository(),
        ),
      ),
      BlocProvider<LocationBloc>.value(value: locBloc),
    ],
    child: MaterialApp(home: const WeatherScreen()),
  );
}
```

b) Update the existing `'shows weather data on loaded state'` test: replace the assertion `expect(find.text('Moroni, Comoros'), findsOneWidget);` with `expect(find.text('SkyLine'), findsOneWidget);` (the test's `LocationBloc` is in `LocationInitial`, so the fallback applies).

c) Add new imports at the top of the test file:

```dart
import 'package:sky_line/features/location/domain/entities/location_entity.dart';
import 'package:sky_line/features/location/presentation/blocs/location_event.dart';
```

d) Add a shared weather builder helper and `const paris` at the top of `main()`:

```dart
  const paris = LocationEntity(
    latitude: 48.85,
    longitude: 2.35,
    cityName: 'Paris',
    country: 'France',
  );

  WeatherResult buildWeatherResult() {
    return WeatherResult(
      weather: WeatherEntity(
        current: const CurrentWeatherEntity(
          temperature: 28.0,
          humidity: 65,
          isDay: true,
          windSpeed: 12.0,
          precipitation: 0.0,
          weatherCode: 51,
        ),
        hourly: [],
        daily: [],
      ),
      isCached: false,
    );
  }
```

e) Add these tests at the end of `main()`:

```dart
  testWidgets('header shows the selected location title', (tester) async {
    when(() => mockRepository.fetchWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    )).thenAnswer((_) async => buildWeatherResult());

    final locationRepo = MockLocationRepository();
    when(() => locationRepo.saveLastLocation(any())).thenAnswer((_) async {});
    when(() => locationRepo.loadFavorites()).thenReturn([]);
    final locationBloc = LocationBloc(
      logger: MockAppLogger(),
      repository: locationRepo,
    );

    final bloc = WeatherForecastBloc(
      logger: MockAppLogger(),
      weatherRepository: mockRepository,
      getSettings: mockGetSettings,
      isConnected: () async => true,
    );
    bloc.add(const FetchWeatherEvent());
    await tester.pumpWidget(createTestScreen(bloc, locationBloc: locationBloc));
    await tester.pumpAndSettle();

    locationBloc.add(const SelectLocationEvent(location: paris));
    await tester.pumpAndSettle();

    expect(find.text('Paris, France'), findsOneWidget);
  });

  testWidgets('grid icon navigates to LocationScreen', (tester) async {
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

    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Location'), findsOneWidget);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/weather_forecast/presentation/screens/weather_screen_test.dart`
Expected: FAIL — header title is still the hard-coded `'Moroni, Comoros'`; grid icon has no navigation (the `'Location'` text is not found)

- [ ] **Step 3: Implement `WeatherHeader`**

Replace `lib/features/weather_forecast/presentation/widgets/weather_header.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_state.dart';
import 'package:sky_line/features/location/presentation/screens/location_screen.dart';
import 'package:sky_line/features/settings/presentation/screens/settings_screen.dart';

class WeatherHeader extends StatelessWidget implements PreferredSizeWidget {
  const WeatherHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      notificationPredicate: (_) => false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.grid_view_rounded),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LocationScreen()),
          );
        },
      ),
      centerTitle: true,
      title: BlocBuilder<LocationBloc, LocationState>(
        builder: (context, state) {
          final title = switch (state) {
            LocationSelected(location: final l) => l.title,
            LocationFavoritesLoaded(currentLocation: final c) => c?.title,
            _ => null,
          } ?? 'SkyLine';
          return Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/weather_forecast/presentation/screens/weather_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/weather_forecast/presentation/widgets/weather_header.dart test/features/weather_forecast/presentation/screens/weather_screen_test.dart
git commit -m "feat(weather): dynamic header title and grid navigation to LocationScreen"
```

---

### Task 5: `WeatherScreen` — Location→Weather Bridge

**Files:**
- Modify: `lib/features/weather_forecast/presentation/screens/weather_screen.dart`
- Test: `test/features/weather_forecast/presentation/screens/weather_screen_test.dart`

**Interfaces:**
- Consumes: `LocationBloc`, `LocationState.LocationSelected`, `WeatherForecastBloc`, `FetchWeatherEvent(latitude:, longitude:)`
- Produces: `WeatherScreen` wrapped in `BlocListener<LocationBloc, LocationState>` that, on `LocationSelected`, adds `FetchWeatherEvent(latitude: location.latitude, longitude: location.longitude)` to the `WeatherForecastBloc`. Only `LocationSelected` triggers a fetch.

- [ ] **Step 1: Write the failing test**

Add to `test/features/weather_forecast/presentation/screens/weather_screen_test.dart`, at the end of `main()`:

```dart
  testWidgets('LocationSelected triggers weather fetch for coordinates',
      (tester) async {
    when(() => mockRepository.fetchWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    )).thenAnswer((_) async => buildWeatherResult());

    final locationRepo = MockLocationRepository();
    when(() => locationRepo.saveLastLocation(any())).thenAnswer((_) async {});
    when(() => locationRepo.loadFavorites()).thenReturn([]);
    final locationBloc = LocationBloc(
      logger: MockAppLogger(),
      repository: locationRepo,
    );

    final bloc = WeatherForecastBloc(
      logger: MockAppLogger(),
      weatherRepository: mockRepository,
      getSettings: mockGetSettings,
      isConnected: () async => true,
    );
    bloc.add(const FetchWeatherEvent());
    await tester.pumpWidget(createTestScreen(bloc, locationBloc: locationBloc));
    await tester.pumpAndSettle();

    locationBloc.add(const SelectLocationEvent(location: paris));
    await tester.pumpAndSettle();

    verify(
      () => mockRepository.fetchWeather(latitude: 48.85, longitude: 2.35),
    ).called(1);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/weather_forecast/presentation/screens/weather_screen_test.dart`
Expected: FAIL — no `LocationSelected` → `FetchWeatherEvent` bridge exists yet, so `fetchWeather(latitude: 48.85, longitude: 2.35)` is never called

- [ ] **Step 3: Implement the bridge**

Replace the `build` method body in `lib/features/weather_forecast/presentation/screens/weather_screen.dart` so the existing logic (lines 15-53, the `BlocBuilder<WeatherForecastBloc, WeatherForecastState>` and the loading-overlay `Stack`) is wrapped inside a `BlocListener<LocationBloc, LocationState>`. Add the required imports:

```dart
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_event.dart';
import 'package:sky_line/features/location/presentation/blocs/location_state.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_event.dart';
```

New `build`:

```dart
  @override
  Widget build(BuildContext context) {
    return BlocListener<LocationBloc, LocationState>(
      listener: (context, state) {
        if (state is LocationSelected) {
          context.read<WeatherForecastBloc>().add(
            FetchWeatherEvent(
              latitude: state.location.latitude,
              longitude: state.location.longitude,
            ),
          );
        }
      },
      child: BlocBuilder<WeatherForecastBloc, WeatherForecastState>(
        builder: (context, state) {
          final content = _contentFor(state);
          if (state.hasData && state.isFetching) {
            final theme = Theme.of(context);
            final primary = theme.colorScheme.primary;
            return Stack(
              children: [
                content,
                Positioned.fill(
                  child: Container(
                    color: theme.colorScheme.surface.withValues(alpha: 0.7),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LoadingAnimationWidget.staggeredDotsWave(
                            size: 25,
                            color: primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Refreshing...',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return content;
        },
      ),
    );
  }
```

Keep `_contentFor` unchanged.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/weather_forecast/presentation/screens/weather_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Run analysis and full test suite**

Run: `flutter analyze`
Expected: 0 issues

Run: `flutter test`
Expected: ALL PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/weather_forecast/presentation/screens/weather_screen.dart test/features/weather_forecast/presentation/screens/weather_screen_test.dart
git commit -m "feat(weather): bridge LocationSelected to WeatherForecastBloc"
```

---

### Task 6: Final Verification

- [ ] **Step 1: Full analysis**

Run: `flutter analyze`
Expected: 0 issues, 0 warnings, 0 info

- [ ] **Step 2: Full test suite**

Run: `flutter test`
Expected: ALL PASS

- [ ] **Step 3: Verify all spec user flows manually**

1. `flutter run` → weather screen shows header fallback `'SkyLine'`.
2. Tap grid icon → `LocationScreen` with `'Location'` title, GPS icon, FAB, and the favorites list (or `'No favorites yet'`).
3. Tap FAB → search screen; pick a city → it appears in favorites and the weather switches to it.
4. Tap GPS icon → spinner → screen pops to weather, showing `'Current Location'` in the header and GPS weather.
5. Tap a favorite → weather switches to it; header shows its title.
6. Swipe a favorite to delete, long-press-drag to reorder → changes persist across app restarts.
