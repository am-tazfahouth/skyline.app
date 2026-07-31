# Location Feature Design Spec

**Date:** 2026-07-27
**Feature:** Location management for SkyLine weather app
**Status:** Approved

---

## 1. Overview

Add a third feature `location` to SkyLine that manages geographic locations for weather lookup. The feature enables:

1. **GPS auto-detection** — On app launch, detect device position and load local weather
2. **City search** — Search cities via Open-Meteo Geocoding API with instant results
3. **Instant weather preview** — Tap a search result to immediately see its weather
4. **Favorites management** — Save cities as favorites, reorder, remove, swipe between them

### User Flow

1. **App launch**: GPS detection → if available, show local weather. If GPS disabled, show weather for last saved city.
2. **Search**: User types city name → debounced API call → results list → tap result → weather loads immediately.
3. **Favorite**: On the weather screen, a star/heart button saves the current city to favorites.
4. **Navigation**: Swipe horizontally on the weather screen to switch between favorite cities.

---

## 2. Architecture

### File Structure

```
lib/features/location/
├── data/
│   ├── mappers/
│   │   └── location_mapper.dart
│   ├── models/
│   │   └── location_model.dart
│   ├── repositories/
│   │   └── location_repository_impl.dart
│   └── sources/
│       ├── location_remote_source.dart
│       └── location_local_source.dart
├── domain/
│   ├── entities/
│   │   └── location_entity.dart
│   ├── repositories/
│   │   └── location_repository.dart
│   └── usecases/
│       └── (none initially)
├── presentation/
│   ├── blocs/
│   │   ├── location_event.dart
│   │   ├── location_state.dart
│   │   └── location_bloc.dart
│   ├── screens/
│   │   └── location_search_screen.dart
│   └── widgets/
│       ├── search_bar_widget.dart
│       ├── search_result_tile.dart
│       └── favorites_list_widget.dart
```

**Approach:** Standalone feature with its own `LocationBloc`, following the same Clean Architecture pattern as `weather_forecast` and `settings`.

---

## 3. Data Model

### `LocationEntity` (domain layer)

```dart
class LocationEntity extends Equatable {
  final double latitude;
  final double longitude;
  final String cityName;
  final String? country;
  final String? admin1;
  final bool isGpsLocation;
  final int sortOrder;

  const LocationEntity({
    required this.latitude,
    required this.longitude,
    required this.cityName,
    this.country,
    this.admin1,
    this.isGpsLocation = false,
    this.sortOrder = 0,
  });

  LocationEntity copyWith({...});

  @override
  List<Object?> get props => [latitude, longitude, cityName, country, admin1, isGpsLocation, sortOrder];
}
```

### `LocationModel` (data layer)

Mirrors `LocationEntity` with JSON serialization for Open-Meteo Geocoding API response mapping:

```dart
factory LocationModel.fromJson(Map<String, dynamic> json) {
  return LocationModel(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    cityName: json['name'] as String,
    country: json['country'] as String?,
    admin1: json['admin1'] as String?,
  );
}
```

### Open-Meteo Geocoding API

**Endpoint:** `https://geocoding-api.open-meteo.com/v1/search`

**Parameters:**
- `name` — search query (e.g., "Paris", "Dakar")
- `count` — number of results (10)
- `language` — response language ("fr")
- `format` — "json"

**Response structure:**
```json
{
  "results": [
    {
      "id": 2988507,
      "name": "Paris",
      "latitude": 48.85341,
      "longitude": 2.3488,
      "country": "France",
      "admin1": "Île-de-France",
      "timezone": "Europe/Paris",
      "population": 2138551
    }
  ]
}
```

---

## 4. LocationBloc

### Events

```dart
abstract class LocationEvent extends Equatable { ... }

class DetectCurrentLocationEvent extends LocationEvent {}
class SearchLocationsEvent extends LocationEvent {
  final String query;
  const SearchLocationsEvent(this.query);
}
class SelectLocationEvent extends LocationEvent {
  final LocationEntity location;
  const SelectLocationEvent(this.location);
}
class AddFavoriteEvent extends LocationEvent {
  final LocationEntity location;
  const AddFavoriteEvent(this.location);
}
class RemoveFavoriteEvent extends LocationEvent {
  final LocationEntity location;
  const RemoveFavoriteEvent(this.location);
}
class ReorderFavoritesEvent extends LocationEvent {
  final int oldIndex;
  final int newIndex;
  const ReorderFavoritesEvent(this.oldIndex, this.newIndex);
}
class LoadFavoritesEvent extends LocationEvent {}
```

### States

```dart
abstract class LocationState extends Equatable { ... }

class LocationInitial extends LocationState {}
class LocationDetecting extends LocationState {}
class LocationSearchLoading extends LocationState {}
class LocationSearchLoaded extends LocationState {
  final List<LocationEntity> results;
  const LocationSearchLoaded(this.results);
}
class LocationSelected extends LocationState {
  final LocationEntity location;
  final List<LocationEntity> favorites;
  const LocationSelected({required this.location, this.favorites = const []});
}
class LocationFavoritesLoaded extends LocationState {
  final List<LocationEntity> favorites;
  final LocationEntity? currentLocation;
  const LocationFavoritesLoaded({required this.favorites, this.currentLocation});
}
class LocationError extends LocationState {
  final AppErrorCode errorCode;
  const LocationError(this.errorCode);
}
```

### BLoC Logic

**`_onDetectCurrentLocation`:**
1. Check GPS permission via `geolocator`
2. If denied → emit `LocationError(gpsPermissionDenied)`
3. Get current position → create `LocationEntity(isGpsLocation: true, cityName: "Current Location")`
4. Emit `LocationSelected(gpsLocation)`

**`_onSearchLocations`:**
1. Call `LocationRemoteSource.search(query)` via Dio
2. Map results to `List<LocationEntity>`
3. Emit `LocationSearchLoaded(results)`

**`_onSelectLocation`:**
1. Emit `LocationSelected(location)`
2. Save as "last consulted location" in ObjectBox
3. WeatherBloc listens and refetches with new coordinates

**`_onAddFavorite` / `_onRemoveFavorite`:**
1. Persist in ObjectBox
2. Reload favorites list
3. Emit `LocationFavoritesLoaded`

**Startup sequence:**
1. `LoadFavoritesEvent` → load favorites + last location from ObjectBox
2. If GPS available → `DetectCurrentLocationEvent`
3. Otherwise → use last saved location

---

## 5. Integration with WeatherBloc & API

### `WeatherRemoteSource` — Parameterized

```dart
class WeatherRemoteSource {
  final Dio _dio;
  WeatherRemoteSource(this._dio);

  Future<Map<String, dynamic>> fetchWeather(double latitude, double longitude) async {
    final url = ApiConstants.buildForecastUrl(latitude, longitude);
    final response = await _dio.get(url);
    return response.data as Map<String, dynamic>;
  }
}
```

### `ApiConstants` — Dynamic URL builder

```dart
class ApiConstants {
  static const String openMeteoBaseUrl = 'https://api.open-meteo.com/v1/forecast';

  static String buildForecastUrl(double latitude, double longitude) {
    return '$openMeteoBaseUrl?latitude=$latitude&longitude=$longitude'
        '&daily=temperature_2m_max,temperature_2m_min,weather_code,sunset,sunrise'
        '&hourly=temperature_2m,precitation_probability,weather_code'
        '&current=temperature_2m,relative_humidity_2m,is_day,wind_speed_10m,precipitation,weather_code'
        '&timezone=auto';
  }
}
```

### Inter-Bloc Communication (Option A: Event bridging via UI)

- `LocationBloc` emits `LocationSelected(location)` on selection
- `BlocListener<LocationBloc>` in `WeatherScreen` detects the change
- Adds `FetchWeatherEvent(latitude: lat, longitude: lon)` to `WeatherBloc`
- Blocs remain decoupled — the screen is the bridge

### `WeatherForecastBloc` — Updated

```dart
class FetchWeatherEvent extends WeatherForecastEvent {
  final double? latitude;
  final double? longitude;
  const FetchWeatherEvent({this.latitude, this.longitude});
}
```

### Cache Strategy

Single cache entry (last consulted city) for simplicity. YAGNI — per-city cache can be added later if needed.

---

## 6. Storage (ObjectBox)

### New Entities

```dart
@Entity()
class LocationCacheEntity {
  @Id() int id;
  double latitude;
  double longitude;
  String cityName;
  String? country;
  String? admin1;
  bool isGpsLocation;
  int sortOrder;
}

@Entity()
class LastLocationEntity {
  @Id() int id;
  double latitude;
  double longitude;
  String cityName;
  String? country;
  String? admin1;
  bool isGpsLocation;
}
```

### `DbHelper` Additions

```dart
class DbHelper {
  late final Box<LocationCacheEntity> _locationBox;
  late final Box<LastLocationEntity> _lastLocationBox;

  List<LocationCacheEntity> loadFavorites();
  void saveFavorites(List<LocationCacheEntity> favorites);
  void addFavorite(LocationCacheEntity favorite);
  void removeFavorite(int id);

  LastLocationEntity? loadLastLocation();
  void saveLastLocation(LastLocationEntity location);
}
```

### Migration

ObjectBox handles schema evolution automatically via codegen (`dart run build_runner build`). No manual migration needed.

---

## 7. UI

### `LocationSearchScreen`

- AppBar with `TextField` for search input
- Debounce (300ms) on text input to avoid API spam
- `ListView` of results: each tile shows `cityName`, `admin1`, `country`
- Tap result → `SelectLocationEvent` → pop back to WeatherScreen with new weather
- Loading indicator (`LoadingAnimationWidget`) during search

### `WeatherScreen` Modifications

- **PageView** (horizontal swipe) between favorite cities + GPS position
- **Pagination dots** at the bottom indicating current page
- **Star/Heart button** in AppBar to add/remove current city from favorites
- **Search button** in AppBar → navigate to `LocationSearchScreen`
- `BlocListener<LocationBloc>` bridges location selection to `WeatherBloc`

### Navigation

```
WeatherScreen (PageView with favorites)
  ├── [Search button] → LocationSearchScreen
  │     └── [Tap result] → pop + WeatherScreen shows weather for city
  ├── [Favorites button] → FavoritesScreen (bottom sheet or screen)
  │     └── [Tap city] → navigate to PageView page
  └── [Star/Heart] → Add/Remove from favorites
```

---

## 8. Error Handling

### Error Codes

```dart
class LocationErrorCodes {
  static const gpsDisabled = AppErrorCode(AppErrorSource.location, 'gpsDisabled');
  static const gpsPermissionDenied = AppErrorCode(AppErrorSource.location, 'gpsPermissionDenied');
  static const gpsFailed = AppErrorCode(AppErrorSource.location, 'gpsFailed');
  static const searchFailed = AppErrorCode(AppErrorSource.location, 'searchFailed');
  static const saveFavoriteFailed = AppErrorCode(AppErrorSource.location, 'saveFavoriteFailed');
  static const loadFavoritesFailed = AppErrorCode(AppErrorSource.location, 'loadFavoritesFailed');
  static const unexpected = AppErrorCode(AppErrorSource.location, 'unexpected');
}
```

### `AppError` Updates

- New `AppErrorSource.location` enum value
- New `UserErrorType.location` and `UserErrorType.search`
- User-facing messages:
  - `location`: "Could not get your location. Please check permissions."
  - `search`: "Could not search cities. Please try again."

---

## 9. Dependencies

| Package | Status | Action |
|---|---|---|
| `geolocator` | Already in pubspec.yaml (^14.0.2) | No change |
| `dio` | Already in pubspec.yaml (^5.9.2) | Reuse for Geocoding API |
| `objectbox` | Already in pubspec.yaml (^5.0.0) | New entities added |
| `equatable` | Already in pubspec.yaml (^2.0.8) | No change |

**No new external dependencies required.**

---

## 10. Dependency Injection

### `InjectionContainer` Additions

```dart
class InjectionContainer {
  // ... existing fields ...
  static late final LocationRemoteSource locationRemoteSource;
  static late final LocationLocalSource locationLocalSource;
  static late final LocationRepository locationRepository;
  static late final LocationBloc locationBloc;

  static Future<void> init() async {
    // ... existing init ...
    locationRemoteSource = LocationRemoteSource(dio);
    locationLocalSource = LocationLocalSource(dbHelper);
    locationRepository = LocationRepositoryImpl(locationRemoteSource, locationLocalSource);
    locationBloc = LocationBloc(logger: logger, repository: locationRepository);
  }
}
```

### `main.dart` Updates

```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => InjectionContainer.settingsBloc..add(LoadSettingsEvent())),
    BlocProvider(create: (_) => InjectionContainer.locationBloc..add(LoadFavoritesEvent())),
    BlocProvider(create: (_) => InjectionContainer.weatherBloc..add(FetchWeatherEvent())),
  ],
  child: MyApp(),
)
```

---

## 11. Testing Strategy

- **Unit tests:** `LocationRepository`, `LocationMapper`, `LocationRemoteSource` (mocked Dio)
- **BLoC tests:** `LocationBloc` with `bloc_test` + `mocktail`
- **Widget tests:** `LocationSearchScreen` (search input, result list)
- **Integration:** Verify LocationBloc → WeatherBloc communication flow
