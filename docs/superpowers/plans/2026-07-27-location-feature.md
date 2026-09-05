# Location Feature — Implementation Plan

**Date:** 2026-07-27
**Feature:** location
**Status:** Implemented

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `location` feature to SkyLine that manages GPS detection, city search via Open-Meteo Geocoding API, and favorites with horizontal swipe navigation on the weather screen.

**Architecture:** Standalone feature `features/location/` following Clean Architecture (data/domain/presentation). `LocationBloc` manages state. Inter-bloc communication via `BlocListener` in `WeatherScreen`. Weather API parameterized with lat/lon.

**Tech Stack:** Flutter, flutter_bloc 9.x, equatable 2.x, dio 5.x, geolocator 14.x, objectbox 5.x

## Global Constraints

- Dart SDK ^3.9.2, Flutter >=3.35.0
- All code in English (variables, classes, comments)
- Equatable on all entities, models, events, states with explicit `props`
- Manual `copyWith` only (no freezed)
- Dedicated static mapper classes for layer conversion
- Zero `flutter analyze` warnings
- TDD: write failing test first, then implement

---

### Task 1: Core Error Codes & Enum Updates

**Files:**
- Create: `lib/core/errors/location_error_codes.dart`
- Modify: `lib/core/enums/app_error_source.dart`
- Modify: `lib/core/enums/user_error_type.dart`
- Modify: `lib/core/errors/app_error.dart`

**Interfaces:**
- Consumes: `AppErrorCode`, `AppErrorSource`, `UserErrorType` (existing)
- Produces: `LocationErrorCodes` class with 7 static const instances

- [ ] **Step 1: Add `location` to `AppErrorSource` enum**

```dart
// lib/core/enums/app_error_source.dart
enum AppErrorSource {
  weatherForecast,
  settings,
  location,
}
```

- [ ] **Step 2: Add location error types to `UserErrorType`**

```dart
// lib/core/enums/user_error_type.dart
enum UserErrorType {
  network,
  fetch,
  cache,
  loadCache,
  unexpected,
  loadSetting,
  updateSetting,
  location,
  search,
}
```

- [ ] **Step 3: Create `LocationErrorCodes`**

```dart
// lib/core/errors/location_error_codes.dart
import 'package:sky_line/core/enums/app_error_source.dart';
import 'package:sky_line/core/errors/app_error_code.dart';

class LocationErrorCodes {
  LocationErrorCodes._();

  static const gpsDisabled = AppErrorCode(AppErrorSource.location, 'gpsDisabled');
  static const gpsPermissionDenied = AppErrorCode(AppErrorSource.location, 'gpsPermissionDenied');
  static const gpsFailed = AppErrorCode(AppErrorSource.location, 'gpsFailed');
  static const searchFailed = AppErrorCode(AppErrorSource.location, 'searchFailed');
  static const saveFavoriteFailed = AppErrorCode(AppErrorSource.location, 'saveFavoriteFailed');
  static const loadFavoritesFailed = AppErrorCode(AppErrorSource.location, 'loadFavoritesFailed');
  static const unexpected = AppErrorCode(AppErrorSource.location, 'unexpected');
}
```

- [ ] **Step 4: Update `AppError` maps**

Add to `_debugErrorMessages`:
```dart
LocationErrorCodes.gpsDisabled: "GPS is disabled on the device.",
LocationErrorCodes.gpsPermissionDenied: "GPS permission was denied by the user.",
LocationErrorCodes.gpsFailed: "Failed to detect GPS location.",
LocationErrorCodes.searchFailed: "Failed to search for cities.",
LocationErrorCodes.saveFavoriteFailed: "Failed to save favorite location.",
LocationErrorCodes.loadFavoritesFailed: "Failed to load favorite locations.",
LocationErrorCodes.unexpected: "An unexpected location error occurred.",
```

Add to `_userErrorTypeMap`:
```dart
LocationErrorCodes.gpsDisabled: UserErrorType.location,
LocationErrorCodes.gpsPermissionDenied: UserErrorType.location,
LocationErrorCodes.gpsFailed: UserErrorType.location,
LocationErrorCodes.searchFailed: UserErrorType.search,
LocationErrorCodes.saveFavoriteFailed: UserErrorType.location,
LocationErrorCodes.loadFavoritesFailed: UserErrorType.location,
LocationErrorCodes.unexpected: UserErrorType.unexpected,
```

Add cases in `getUserErrorMessage`:
```dart
case UserErrorType.location:
  return "Could not get your location. Please check permissions.";
case UserErrorType.search:
  return "Could not search cities. Please try again.";
```

- [ ] **Step 5: Run `flutter analyze`**

Run: `flutter analyze`
Expected: 0 issues

- [ ] **Step 6: Commit**

```bash
git add lib/core/errors/location_error_codes.dart lib/core/enums/app_error_source.dart lib/core/enums/user_error_type.dart lib/core/errors/app_error.dart
git commit -m "feat(location): add error codes and enum values for location feature"
```

---

### Task 2: Location Entity & Model

**Files:**
- Create: `lib/features/location/domain/entities/location_entity.dart`
- Create: `lib/features/location/data/models/location_model.dart`
- Create: `lib/features/location/data/mappers/location_mapper.dart`

**Interfaces:**
- Consumes: `Equatable` (existing)
- Produces: `LocationEntity`, `LocationModel`, `LocationMapper`

- [ ] **Step 1: Write `LocationEntity` test**

Create `test/features/location/domain/entities/location_entity_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';

void main() {
  group('LocationEntity', () {
    test('supports value equality', () {
      const a = LocationEntity(latitude: 48.85, longitude: 2.35, cityName: 'Paris');
      const b = LocationEntity(latitude: 48.85, longitude: 2.35, cityName: 'Paris');
      expect(a, equals(b));
    });

    test('copyWith creates new instance with updated fields', () {
      const original = LocationEntity(latitude: 48.85, longitude: 2.35, cityName: 'Paris');
      final updated = original.copyWith(cityName: 'Lyon');
      expect(updated.cityName, 'Lyon');
      expect(updated.latitude, 48.85);
      expect(original.cityName, 'Paris');
    });

    test('isGpsLocation defaults to false', () {
      const loc = LocationEntity(latitude: 0, longitude: 0, cityName: 'Test');
      expect(loc.isGpsLocation, false);
    });

    test('sortOrder defaults to 0', () {
      const loc = LocationEntity(latitude: 0, longitude: 0, cityName: 'Test');
      expect(loc.sortOrder, 0);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/location/domain/entities/location_entity_test.dart`
Expected: FAIL (file not found)

- [ ] **Step 3: Implement `LocationEntity`**

```dart
// lib/features/location/domain/entities/location_entity.dart
import 'package:equatable/equatable.dart';

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

  LocationEntity copyWith({
    double? latitude,
    double? longitude,
    String? cityName,
    String? country,
    String? admin1,
    bool? isGpsLocation,
    int? sortOrder,
  }) {
    return LocationEntity(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cityName: cityName ?? this.cityName,
      country: country ?? this.country,
      admin1: admin1 ?? this.admin1,
      isGpsLocation: isGpsLocation ?? this.isGpsLocation,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [latitude, longitude, cityName, country, admin1, isGpsLocation, sortOrder];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/location/domain/entities/location_entity_test.dart`
Expected: PASS

- [ ] **Step 5: Write `LocationModel` test**

Create `test/features/location/data/models/location_model_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/features/location/data/models/location_model.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';

void main() {
  group('LocationModel', () {
    test('fromJson parses Open-Meteo geocoding response correctly', () {
      final json = {
        'id': 2988507,
        'name': 'Paris',
        'latitude': 48.85341,
        'longitude': 2.3488,
        'country': 'France',
        'admin1': 'Île-de-France',
        'timezone': 'Europe/Paris',
        'population': 2138551,
      };

      final model = LocationModel.fromJson(json);
      expect(model.cityName, 'Paris');
      expect(model.latitude, 48.85341);
      expect(model.longitude, 2.3488);
      expect(model.country, 'France');
      expect(model.admin1, 'Île-de-France');
    });

    test('fromJson handles null country and admin1', () {
      final json = {
        'name': 'Unknown',
        'latitude': 0.0,
        'longitude': 0.0,
      };

      final model = LocationModel.fromJson(json);
      expect(model.country, isNull);
      expect(model.admin1, isNull);
    });

    test('toEntity converts to LocationEntity', () {
      const model = LocationModel(
        latitude: 48.85,
        longitude: 2.35,
        cityName: 'Paris',
        country: 'France',
        admin1: 'Île-de-France',
      );

      final entity = model.toEntity();
      expect(entity, isA<LocationEntity>());
      expect(entity.cityName, 'Paris');
      expect(entity.latitude, 48.85);
      expect(entity.isGpsLocation, false);
    });

    test('supports value equality', () {
      const a = LocationModel(latitude: 48.85, longitude: 2.35, cityName: 'Paris');
      const b = LocationModel(latitude: 48.85, longitude: 2.35, cityName: 'Paris');
      expect(a, equals(b));
    });
  });
}
```

- [ ] **Step 6: Run test to verify it fails**

Run: `flutter test test/features/location/data/models/location_model_test.dart`
Expected: FAIL

- [ ] **Step 7: Implement `LocationModel`**

```dart
// lib/features/location/data/models/location_model.dart
import 'package:equatable/equatable.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';

class LocationModel extends Equatable {
  final double latitude;
  final double longitude;
  final String cityName;
  final String? country;
  final String? admin1;

  const LocationModel({
    required this.latitude,
    required this.longitude,
    required this.cityName,
    this.country,
    this.admin1,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      cityName: json['name'] as String,
      country: json['country'] as String?,
      admin1: json['admin1'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'name': cityName,
    'country': country,
    'admin1': admin1,
  };

  LocationEntity toEntity() => LocationEntity(
    latitude: latitude,
    longitude: longitude,
    cityName: cityName,
    country: country,
    admin1: admin1,
  );

  LocationModel copyWith({
    double? latitude,
    double? longitude,
    String? cityName,
    String? country,
    String? admin1,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cityName: cityName ?? this.cityName,
      country: country ?? this.country,
      admin1: admin1 ?? this.admin1,
    );
  }

  @override
  List<Object?> get props => [latitude, longitude, cityName, country, admin1];
}
```

- [ ] **Step 8: Run test to verify it passes**

Run: `flutter test test/features/location/data/models/location_model_test.dart`
Expected: PASS

- [ ] **Step 9: Write `LocationMapper` test**

Create `test/features/location/data/mappers/location_mapper_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/features/location/data/mappers/location_mapper.dart';
import 'package:sky_line/features/location/data/models/location_model.dart';

void main() {
  group('LocationMapper', () {
    test('fromJsonList parses array of geocoding results', () {
      final json = {
        'results': [
          {
            'name': 'Paris',
            'latitude': 48.85341,
            'longitude': 2.3488,
            'country': 'France',
            'admin1': 'Île-de-France',
          },
          {
            'name': 'Lyon',
            'latitude': 45.76404,
            'longitude': 4.83566,
            'country': 'France',
            'admin1': 'Auvergne-Rhône-Alpes',
          },
        ],
      };

      final results = LocationMapper.fromJsonList(json);
      expect(results, hasLength(2));
      expect(results[0], isA<LocationModel>());
      expect(results[0].cityName, 'Paris');
      expect(results[1].cityName, 'Lyon');
    });

    test('fromJsonList returns empty list when no results key', () {
      final json = <String, dynamic>{};
      final results = LocationMapper.fromJsonList(json);
      expect(results, isEmpty);
    });

    test('fromJsonList returns empty list when results is empty', () {
      final json = {'results': <dynamic>[]};
      final results = LocationMapper.fromJsonList(json);
      expect(results, isEmpty);
    });
  });
}
```

- [ ] **Step 10: Run test to verify it fails**

Run: `flutter test test/features/location/data/mappers/location_mapper_test.dart`
Expected: FAIL

- [ ] **Step 11: Implement `LocationMapper`**

```dart
// lib/features/location/data/mappers/location_mapper.dart
import 'package:sky_line/features/location/data/models/location_model.dart';

class LocationMapper {
  const LocationMapper._();

  static List<LocationModel> fromJsonList(Map<String, dynamic> json) {
    final results = json['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return [];

    return results
        .map((e) => LocationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
```

- [ ] **Step 12: Run test to verify it passes**

Run: `flutter test test/features/location/data/mappers/location_mapper_test.dart`
Expected: PASS

- [ ] **Step 13: Run all location tests**

Run: `flutter test test/features/location/`
Expected: ALL PASS

- [ ] **Step 14: Commit**

```bash
git add lib/features/location/ test/features/location/
git commit -m "feat(location): add LocationEntity, LocationModel, and LocationMapper"
```

---

### Task 3: ObjectBox Storage for Locations

**Files:**
- Create: `lib/core/config/db_helper/location_cache_entity.dart`
- Create: `lib/core/config/db_helper/last_location_entity.dart`
- Modify: `lib/core/config/db_helper/db_helper.dart`

**Interfaces:**
- Consumes: `LocationModel` (Task 2), `DbHelper` (existing)
- Produces: `LocationCacheEntity`, `LastLocationEntity`, `DbHelper` methods for favorites/last location

- [ ] **Step 1: Create `LocationCacheEntity`**

```dart
// lib/core/config/db_helper/location_cache_entity.dart
import 'package:objectbox/objectbox.dart';

@Entity()
class LocationCacheEntity {
  @Id()
  int id;

  double latitude;
  double longitude;
  String cityName;
  String? country;
  String? admin1;
  bool isGpsLocation;
  int sortOrder;

  LocationCacheEntity({
    this.id = 0,
    required this.latitude,
    required this.longitude,
    required this.cityName,
    this.country,
    this.admin1,
    this.isGpsLocation = false,
    this.sortOrder = 0,
  });
}
```

- [ ] **Step 2: Create `LastLocationEntity`**

```dart
// lib/core/config/db_helper/last_location_entity.dart
import 'package:objectbox/objectbox.dart';

@Entity()
class LastLocationEntity {
  @Id()
  int id;

  double latitude;
  double longitude;
  String cityName;
  String? country;
  String? admin1;
  bool isGpsLocation;

  LastLocationEntity({
    this.id = 0,
    required this.latitude,
    required this.longitude,
    required this.cityName,
    this.country,
    this.admin1,
    this.isGpsLocation = false,
  });
}
```

- [ ] **Step 3: Run `dart run build_runner build`**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `objectbox.g.dart` regenerated with new entities

- [ ] **Step 4: Update `DbHelper` with location methods**

Add to `DbHelper` class:

```dart
// Fields
late final Box<LocationCacheEntity> _locationBox;
late final Box<LastLocationEntity> _lastLocationBox;

// In constructor, add:
_locationBox = Box<LocationCacheEntity>(_store);
_lastLocationBox = Box<LastLocationEntity>(_store);

// Favorites methods
List<LocationCacheEntity> loadFavorites() {
  final list = _locationBox.getAll();
  list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return list;
}

void saveFavorite(LocationCacheEntity favorite) {
  _locationBox.put(favorite);
}

void removeFavorite(int id) {
  _locationBox.remove(id);
}

void saveAllFavorites(List<LocationCacheEntity> favorites) {
  _locationBox.removeAll();
  for (final f in favorites) {
    _locationBox.put(f);
  }
}

// Last location methods
LastLocationEntity? loadLastLocation() {
  final list = _lastLocationBox.getAll();
  return list.isNotEmpty ? list.first : null;
}

void saveLastLocation(LastLocationEntity location) {
  _lastLocationBox.removeAll();
  _lastLocationBox.put(location);
}
```

- [ ] **Step 5: Run `flutter analyze`**

Run: `flutter analyze`
Expected: 0 issues

- [ ] **Step 6: Commit**

```bash
git add lib/core/config/db_helper/
git commit -m "feat(location): add ObjectBox entities and DbHelper methods for locations"
```

---

### Task 4: Location Repository & Data Sources

**Files:**
- Create: `lib/features/location/domain/repositories/location_repository.dart`
- Create: `lib/features/location/data/sources/location_remote_source.dart`
- Create: `lib/features/location/data/sources/location_local_source.dart`
- Create: `lib/features/location/data/repositories/location_repository_impl.dart`

**Interfaces:**
- Consumes: `LocationMapper` (Task 2), `LocationModel` (Task 2), `DbHelper` (Task 3), `Dio` (existing)
- Produces: `LocationRepository` (abstract), `LocationRemoteSource`, `LocationLocalSource`, `LocationRepositoryImpl`

- [ ] **Step 1: Write `LocationRemoteSource` test**

Create `test/features/location/data/sources/location_remote_source_test.dart`:
```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/features/location/data/sources/location_remote_source.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late LocationRemoteSource source;

  setUp(() {
    mockDio = MockDio();
    source = LocationRemoteSource(mockDio);
  });

  group('search', () {
    test('calls Dio with correct URL and returns JSON', () async {
      final responseData = {
        'results': [
          {'name': 'Paris', 'latitude': 48.85, 'longitude': 2.35},
        ],
      };

      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => Response(
        data: responseData,
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ));

      final result = await source.search('Paris');

      expect(result, equals(responseData));
      verify(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).called(1);
    });

    test('throws on DioException', () async {
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionTimeout,
      ));

      expect(() => source.search('Paris'), throwsA(isA<DioException>()));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/location/data/sources/location_remote_source_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement `LocationRemoteSource`**

```dart
// lib/features/location/data/sources/location_remote_source.dart
import 'package:dio/dio.dart';

class LocationRemoteSource {
  final Dio _dio;

  LocationRemoteSource(this._dio);

  Future<Map<String, dynamic>> search(String query) async {
    final response = await _dio.get(
      'https://geocoding-api.open-meteo.com/v1/search',
      queryParameters: {
        'name': query,
        'count': 10,
        'language': 'fr',
        'format': 'json',
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/location/data/sources/location_remote_source_test.dart`
Expected: PASS

- [ ] **Step 5: Write `LocationLocalSource` test**

Create `test/features/location/data/sources/location_local_source_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/config/db_helper/db_helper.dart';
import 'package:sky_line/core/config/db_helper/location_cache_entity.dart';
import 'package:sky_line/core/config/db_helper/last_location_entity.dart';
import 'package:sky_line/features/location/data/sources/location_local_source.dart';

class MockDbHelper extends Mock implements DbHelper {}

void main() {
  late MockDbHelper mockDbHelper;
  late LocationLocalSource source;

  setUp(() {
    mockDbHelper = MockDbHelper();
    source = LocationLocalSource(mockDbHelper);
  });

  group('loadFavorites', () {
    test('returns list from DbHelper', () {
      when(() => mockDbHelper.loadFavorites()).thenReturn([
        LocationCacheEntity(latitude: 48.85, longitude: 2.35, cityName: 'Paris'),
      ]);

      final result = source.loadFavorites();
      expect(result, hasLength(1));
      expect(result.first.cityName, 'Paris');
    });
  });

  group('loadLastLocation', () {
    test('returns null when no last location', () {
      when(() => mockDbHelper.loadLastLocation()).thenReturn(null);
      expect(source.loadLastLocation(), isNull);
    });

    test('returns LastLocationEntity when exists', () {
      final entity = LastLocationEntity(
        latitude: 48.85,
        longitude: 2.35,
        cityName: 'Paris',
      );
      when(() => mockDbHelper.loadLastLocation()).thenReturn(entity);

      final result = source.loadLastLocation();
      expect(result, isNotNull);
      expect(result!.cityName, 'Paris');
    });
  });
}
```

- [ ] **Step 6: Run test to verify it fails**

Run: `flutter test test/features/location/data/sources/location_local_source_test.dart`
Expected: FAIL

- [ ] **Step 7: Implement `LocationLocalSource`**

```dart
// lib/features/location/data/sources/location_local_source.dart
import 'package:sky_line/core/config/db_helper/db_helper.dart';
import 'package:sky_line/core/config/db_helper/location_cache_entity.dart';
import 'package:sky_line/core/config/db_helper/last_location_entity.dart';

class LocationLocalSource {
  final DbHelper _dbHelper;

  LocationLocalSource(this._dbHelper);

  List<LocationCacheEntity> loadFavorites() => _dbHelper.loadFavorites();

  void saveFavorite(LocationCacheEntity favorite) => _dbHelper.saveFavorite(favorite);

  void removeFavorite(int id) => _dbHelper.removeFavorite(id);

  void saveAllFavorites(List<LocationCacheEntity> favorites) => _dbHelper.saveAllFavorites(favorites);

  LastLocationEntity? loadLastLocation() => _dbHelper.loadLastLocation();

  void saveLastLocation(LastLocationEntity location) => _dbHelper.saveLastLocation(location);
}
```

- [ ] **Step 8: Run test to verify it passes**

Run: `flutter test test/features/location/data/sources/location_local_source_test.dart`
Expected: PASS

- [ ] **Step 9: Create `LocationRepository` interface**

```dart
// lib/features/location/domain/repositories/location_repository.dart
import 'package:sky_line/features/location/domain/entities/location_entity.dart';

abstract class LocationRepository {
  Future<List<LocationEntity>> searchLocations(String query);
  List<LocationEntity> loadFavorites();
  Future<void> saveFavorite(LocationEntity location);
  Future<void> removeFavorite(LocationEntity location);
  Future<void> saveAllFavorites(List<LocationEntity> favorites);
  LocationEntity? loadLastLocation();
  Future<void> saveLastLocation(LocationEntity location);
  Future<LocationEntity> detectCurrentLocation();
}
```

- [ ] **Step 10: Write `LocationRepositoryImpl` test**

Create `test/features/location/data/repositories/location_repository_impl_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/features/location/data/sources/location_remote_source.dart';
import 'package:sky_line/features/location/data/sources/location_local_source.dart';
import 'package:sky_line/features/location/data/repositories/location_repository_impl.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';
import 'package:sky_line/core/config/db_helper/location_cache_entity.dart';
import 'package:sky_line/core/config/db_helper/last_location_entity.dart';

class MockRemoteSource extends Mock implements LocationRemoteSource {}
class MockLocalSource extends Mock implements LocationLocalSource {}

void main() {
  late MockRemoteSource mockRemote;
  late MockLocalSource mockLocal;
  late LocationRepositoryImpl repo;

  setUp(() {
    mockRemote = MockRemoteSource();
    mockLocal = MockLocalSource();
    repo = LocationRepositoryImpl(mockRemote, mockLocal);
    registerFallbackValue(LocationCacheEntity(latitude: 0, longitude: 0, cityName: ''));
    registerFallbackValue(LastLocationEntity(latitude: 0, longitude: 0, cityName: ''));
  });

  group('searchLocations', () {
    test('returns list of LocationEntity from API', () async {
      when(() => mockRemote.search('Paris')).thenAnswer((_) async => {
        'results': [
          {'name': 'Paris', 'latitude': 48.85, 'longitude': 2.35, 'country': 'France'},
        ],
      });

      final results = await repo.searchLocations('Paris');
      expect(results, hasLength(1));
      expect(results.first, isA<LocationEntity>());
      expect(results.first.cityName, 'Paris');
    });

    test('returns empty list when no results', () async {
      when(() => mockRemote.search('xyz')).thenAnswer((_) async => {
        'results': <dynamic>[],
      });

      final results = await repo.searchLocations('xyz');
      expect(results, isEmpty);
    });
  });

  group('loadFavorites', () {
    test('returns favorites from local source', () {
      when(() => mockLocal.loadFavorites()).thenReturn([
        LocationCacheEntity(latitude: 48.85, longitude: 2.35, cityName: 'Paris'),
      ]);

      final results = repo.loadFavorites();
      expect(results, hasLength(1));
      expect(results.first.cityName, 'Paris');
    });
  });

  group('saveFavorite', () {
    test('saves to local source', () async {
      when(() => mockLocal.saveFavorite(any())).thenReturn(null);

      const entity = LocationEntity(latitude: 48.85, longitude: 2.35, cityName: 'Paris');
      await repo.saveFavorite(entity);

      verify(() => mockLocal.saveFavorite(any())).called(1);
    });
  });
}
```

- [ ] **Step 11: Run test to verify it fails**

Run: `flutter test test/features/location/data/repositories/location_repository_impl_test.dart`
Expected: FAIL

- [ ] **Step 12: Implement `LocationRepositoryImpl`**

```dart
// lib/features/location/data/repositories/location_repository_impl.dart
import 'package:geolocator/geolocator.dart';
import 'package:sky_line/features/location/data/mappers/location_mapper.dart';
import 'package:sky_line/features/location/data/sources/location_remote_source.dart';
import 'package:sky_line/features/location/data/sources/location_local_source.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';
import 'package:sky_line/features/location/domain/repositories/location_repository.dart';
import 'package:sky_line/core/config/db_helper/location_cache_entity.dart';
import 'package:sky_line/core/config/db_helper/last_location_entity.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteSource _remoteSource;
  final LocationLocalSource _localSource;

  LocationRepositoryImpl(this._remoteSource, this._localSource);

  @override
  Future<List<LocationEntity>> searchLocations(String query) async {
    final json = await _remoteSource.search(query);
    final models = LocationMapper.fromJsonList(json);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  List<LocationEntity> loadFavorites() {
    return _localSource.loadFavorites().map((e) => LocationEntity(
      latitude: e.latitude,
      longitude: e.longitude,
      cityName: e.cityName,
      country: e.country,
      admin1: e.admin1,
      isGpsLocation: e.isGpsLocation,
      sortOrder: e.sortOrder,
    )).toList();
  }

  @override
  Future<void> saveFavorite(LocationEntity location) async {
    _localSource.saveFavorite(LocationCacheEntity(
      latitude: location.latitude,
      longitude: location.longitude,
      cityName: location.cityName,
      country: location.country,
      admin1: location.admin1,
      isGpsLocation: location.isGpsLocation,
      sortOrder: location.sortOrder,
    ));
  }

  @override
  Future<void> removeFavorite(LocationEntity location) async {
    final favorites = _localSource.loadFavorites();
    for (final f in favorites) {
      if (f.latitude == location.latitude && f.longitude == location.longitude) {
        _localSource.removeFavorite(f.id);
        break;
      }
    }
  }

  @override
  Future<void> saveAllFavorites(List<LocationEntity> favorites) async {
    _localSource.saveAllFavorites(favorites.asMap().entries.map((e) => LocationCacheEntity(
      latitude: e.value.latitude,
      longitude: e.value.longitude,
      cityName: e.value.cityName,
      country: e.value.country,
      admin1: e.value.admin1,
      isGpsLocation: e.value.isGpsLocation,
      sortOrder: e.key,
    )).toList());
  }

  @override
  LocationEntity? loadLastLocation() {
    final entity = _localSource.loadLastLocation();
    if (entity == null) return null;
    return LocationEntity(
      latitude: entity.latitude,
      longitude: entity.longitude,
      cityName: entity.cityName,
      country: entity.country,
      admin1: entity.admin1,
      isGpsLocation: entity.isGpsLocation,
    );
  }

  @override
  Future<void> saveLastLocation(LocationEntity location) async {
    _localSource.saveLastLocation(LastLocationEntity(
      latitude: location.latitude,
      longitude: location.longitude,
      cityName: location.cityName,
      country: location.country,
      admin1: location.admin1,
      isGpsLocation: location.isGpsLocation,
    ));
  }

  @override
  Future<LocationEntity> detectCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('gpsDisabled');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw Exception('gpsPermissionDenied');
    }
    if (permission == LocationPermission.deniedForever) throw Exception('gpsPermissionDenied');

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );

    return LocationEntity(
      latitude: position.latitude,
      longitude: position.longitude,
      cityName: 'Current Location',
      isGpsLocation: true,
    );
  }
}
```

- [ ] **Step 13: Run test to verify it passes**

Run: `flutter test test/features/location/data/repositories/location_repository_impl_test.dart`
Expected: PASS

- [ ] **Step 14: Run all location tests**

Run: `flutter test test/features/location/`
Expected: ALL PASS

- [ ] **Step 15: Run `flutter analyze`**

Run: `flutter analyze`
Expected: 0 issues

- [ ] **Step 16: Commit**

```bash
git add lib/features/location/domain/repositories/ lib/features/location/data/
git commit -m "feat(location): add LocationRepository, remote and local data sources"
```

---

### Task 5: LocationBloc

**Files:**
- Create: `lib/features/location/presentation/blocs/location_event.dart`
- Create: `lib/features/location/presentation/blocs/location_state.dart`
- Create: `lib/features/location/presentation/blocs/location_bloc.dart`

**Interfaces:**
- Consumes: `LocationRepository` (Task 4), `AppLogger` (existing), `AppError`/`LocationErrorCodes` (Task 1)
- Produces: `LocationBloc`, `LocationEvent` subclasses, `LocationState` subclasses

- [ ] **Step 1: Write `LocationBloc` test**

Create `test/features/location/presentation/blocs/location_bloc_test.dart`:
```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/services/logger_sevices.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';
import 'package:sky_line/features/location/domain/repositories/location_repository.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_event.dart';
import 'package:sky_line/features/location/presentation/blocs/location_state.dart';

class MockRepository extends Mock implements LocationRepository {}
class MockLogger extends Mock implements AppLogger {}

void main() {
  late MockRepository mockRepo;
  late MockLogger mockLogger;
  late LocationBloc bloc;

  setUp(() {
    mockRepo = MockRepository();
    mockLogger = MockLogger();
    bloc = LocationBloc(logger: mockLogger, repository: mockRepo);
  });

  tearDown(() => bloc.close());

  const testLocation = LocationEntity(
    latitude: 48.85,
    longitude: 2.35,
    cityName: 'Paris',
    country: 'France',
  );

  group('LoadFavoritesEvent', () {
    blocTest<LocationBloc, LocationState>(
      'emits LocationFavoritesLoaded with favorites and last location',
      build: () {
        when(() => mockRepo.loadFavorites()).thenReturn([testLocation]);
        when(() => mockRepo.loadLastLocation()).thenReturn(testLocation);
        return bloc;
      },
      act: (bloc) => bloc.add(LoadFavoritesEvent()),
      expect: () => [
        isA<LocationFavoritesLoaded>()
          .having((s) => s.favorites.length, 'favorites', 1)
          .having((s) => s.currentLocation?.cityName, 'current', 'Paris'),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'emits LocationError when loadFavorites throws',
      build: () {
        when(() => mockRepo.loadFavorites()).thenThrow(Exception('fail'));
        when(() => mockRepo.loadLastLocation()).thenReturn(null);
        return bloc;
      },
      act: (bloc) => bloc.add(LoadFavoritesEvent()),
      expect: () => [isA<LocationError>()],
    );
  });

  group('SearchLocationsEvent', () {
    blocTest<LocationBloc, LocationState>(
      'emits LocationSearchLoading then LocationSearchLoaded',
      build: () {
        when(() => mockRepo.searchLocations('Paris')).thenAnswer((_) async => [testLocation]);
        return bloc;
      },
      act: (bloc) => bloc.add(const SearchLocationsEvent('Paris')),
      expect: () => [
        isA<LocationSearchLoading>(),
        isA<LocationSearchLoaded>().having((s) => s.results.length, 'results', 1),
      ],
    );
  });

  group('SelectLocationEvent', () {
    blocTest<LocationBloc, LocationState>(
      'emits LocationSelected and saves last location',
      build: () {
        when(() => mockRepo.saveLastLocation(any())).thenAnswer((_) async {});
        when(() => mockRepo.loadFavorites()).thenReturn([]);
        return bloc;
      },
      act: (bloc) => bloc.add(const SelectLocationEvent(location: testLocation)),
      expect: () => [
        isA<LocationSelected>().having((s) => s.location.cityName, 'city', 'Paris'),
      ],
      verify: (_) {
        verify(() => mockRepo.saveLastLocation(any())).called(1);
      },
    );
  });

  group('AddFavoriteEvent', () {
    blocTest<LocationBloc, LocationState>(
      'saves favorite and reloads list',
      build: () {
        when(() => mockRepo.saveFavorite(any())).thenAnswer((_) async {});
        when(() => mockRepo.loadFavorites()).thenReturn([testLocation]);
        when(() => mockRepo.loadLastLocation()).thenReturn(null);
        return bloc;
      },
      act: (bloc) => bloc.add(const AddFavoriteEvent(location: testLocation)),
      expect: () => [isA<LocationFavoritesLoaded>()],
    );
  });

  group('RemoveFavoriteEvent', () {
    blocTest<LocationBloc, LocationState>(
      'removes favorite and reloads list',
      build: () {
        when(() => mockRepo.removeFavorite(any())).thenAnswer((_) async {});
        when(() => mockRepo.loadFavorites()).thenReturn([]);
        when(() => mockRepo.loadLastLocation()).thenReturn(null);
        return bloc;
      },
      act: (bloc) => bloc.add(const RemoveFavoriteEvent(location: testLocation)),
      expect: () => [isA<LocationFavoritesLoaded>()],
    );
  });

  group('DetectCurrentLocationEvent', () {
    blocTest<LocationBloc, LocationState>(
      'emits LocationDetecting then LocationSelected with GPS location',
      build: () {
        when(() => mockRepo.detectCurrentLocation()).thenAnswer((_) async => const LocationEntity(
          latitude: -11.70,
          longitude: 43.25,
          cityName: 'Current Location',
          isGpsLocation: true,
        ));
        when(() => mockRepo.saveLastLocation(any())).thenAnswer((_) async {});
        when(() => mockRepo.loadFavorites()).thenReturn([]);
        return bloc;
      },
      act: (bloc) => bloc.add(DetectCurrentLocationEvent()),
      expect: () => [
        isA<LocationDetecting>(),
        isA<LocationSelected>().having((s) => s.location.isGpsLocation, 'isGps', true),
      ],
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/location/presentation/blocs/location_bloc_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement `LocationEvent`**

```dart
// lib/features/location/presentation/blocs/location_event.dart
import 'package:equatable/equatable.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();
  @override
  List<Object?> get props => [];
}

class DetectCurrentLocationEvent extends LocationEvent {
  const DetectCurrentLocationEvent();
}

class SearchLocationsEvent extends LocationEvent {
  final String query;
  const SearchLocationsEvent(this.query);
  @override
  List<Object?> get props => [query];
}

class SelectLocationEvent extends LocationEvent {
  final LocationEntity location;
  const SelectLocationEvent({required this.location});
  @override
  List<Object?> get props => [location];
}

class AddFavoriteEvent extends LocationEvent {
  final LocationEntity location;
  const AddFavoriteEvent({required this.location});
  @override
  List<Object?> get props => [location];
}

class RemoveFavoriteEvent extends LocationEvent {
  final LocationEntity location;
  const RemoveFavoriteEvent({required this.location});
  @override
  List<Object?> get props => [location];
}

class ReorderFavoritesEvent extends LocationEvent {
  final int oldIndex;
  final int newIndex;
  const ReorderFavoritesEvent({required this.oldIndex, required this.newIndex});
  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class LoadFavoritesEvent extends LocationEvent {
  const LoadFavoritesEvent();
}
```

- [ ] **Step 4: Implement `LocationState`**

```dart
// lib/features/location/presentation/blocs/location_state.dart
import 'package:equatable/equatable.dart';
import 'package:sky_line/core/errors/app_error_code.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';

abstract class LocationState extends Equatable {
  const LocationState();
  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {
  const LocationInitial();
}

class LocationDetecting extends LocationState {
  const LocationDetecting();
}

class LocationSearchLoading extends LocationState {
  const LocationSearchLoading();
}

class LocationSearchLoaded extends LocationState {
  final List<LocationEntity> results;
  const LocationSearchLoaded(this.results);
  @override
  List<Object?> get props => [results];
}

class LocationSelected extends LocationState {
  final LocationEntity location;
  final List<LocationEntity> favorites;
  const LocationSelected({required this.location, this.favorites = const []});
  @override
  List<Object?> get props => [location, favorites];
}

class LocationFavoritesLoaded extends LocationState {
  final List<LocationEntity> favorites;
  final LocationEntity? currentLocation;
  const LocationFavoritesLoaded({required this.favorites, this.currentLocation});
  @override
  List<Object?> get props => [favorites, currentLocation];
}

class LocationError extends LocationState {
  final AppErrorCode errorCode;
  const LocationError(this.errorCode);
  @override
  List<Object?> get props => [errorCode];
}
```

- [ ] **Step 5: Implement `LocationBloc`**

```dart
// lib/features/location/presentation/blocs/location_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/errors/app_error.dart';
import 'package:sky_line/core/errors/location_error_codes.dart';
import 'package:sky_line/core/services/logger_sevices.dart';
import 'package:sky_line/features/location/domain/repositories/location_repository.dart';
import 'package:sky_line/features/location/presentation/blocs/location_event.dart';
import 'package:sky_line/features/location/presentation/blocs/location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final AppLogger logger;
  final LocationRepository repository;

  LocationBloc({required this.logger, required this.repository})
      : super(const LocationInitial()) {
    on<DetectCurrentLocationEvent>(_onDetectCurrentLocation);
    on<SearchLocationsEvent>(_onSearchLocations);
    on<SelectLocationEvent>(_onSelectLocation);
    on<AddFavoriteEvent>(_onAddFavorite);
    on<RemoveFavoriteEvent>(_onRemoveFavorite);
    on<ReorderFavoritesEvent>(_onReorderFavorites);
    on<LoadFavoritesEvent>(_onLoadFavorites);
  }

  Future<void> _onDetectCurrentLocation(
    DetectCurrentLocationEvent event,
    Emitter<LocationState> emit,
  ) async {
    emit(const LocationDetecting());
    try {
      final location = await repository.detectCurrentLocation();
      await repository.saveLastLocation(location);
      final favorites = repository.loadFavorites();
      emit(LocationSelected(location: location, favorites: favorites));
    } catch (e, stackTrace) {
      logger.e(
        AppError.getDebugErrorMessage(LocationErrorCodes.gpsFailed),
        error: e,
        stackTrace: stackTrace,
      );
      emit(const LocationError(LocationErrorCodes.gpsFailed));
    }
  }

  Future<void> _onSearchLocations(
    SearchLocationsEvent event,
    Emitter<LocationState> emit,
  ) async {
    if (event.query.trim().isEmpty) return;
    emit(const LocationSearchLoading());
    try {
      final results = await repository.searchLocations(event.query);
      emit(LocationSearchLoaded(results));
    } catch (e, stackTrace) {
      logger.e(
        AppError.getDebugErrorMessage(LocationErrorCodes.searchFailed),
        error: e,
        stackTrace: stackTrace,
      );
      emit(const LocationError(LocationErrorCodes.searchFailed));
    }
  }

  Future<void> _onSelectLocation(
    SelectLocationEvent event,
    Emitter<LocationState> emit,
  ) async {
    try {
      await repository.saveLastLocation(event.location);
      final favorites = repository.loadFavorites();
      emit(LocationSelected(location: event.location, favorites: favorites));
    } catch (e, stackTrace) {
      logger.e(
        AppError.getDebugErrorMessage(LocationErrorCodes.unexpected),
        error: e,
        stackTrace: stackTrace,
      );
      emit(const LocationError(LocationErrorCodes.unexpected));
    }
  }

  Future<void> _onAddFavorite(
    AddFavoriteEvent event,
    Emitter<LocationState> emit,
  ) async {
    try {
      await repository.saveFavorite(event.location);
      final favorites = repository.loadFavorites();
      final currentState = state;
      final currentLocation = currentState is LocationSelected ? currentState.location : null;
      emit(LocationFavoritesLoaded(favorites: favorites, currentLocation: currentLocation));
    } catch (e, stackTrace) {
      logger.e(
        AppError.getDebugErrorMessage(LocationErrorCodes.saveFavoriteFailed),
        error: e,
        stackTrace: stackTrace,
      );
      emit(const LocationError(LocationErrorCodes.saveFavoriteFailed));
    }
  }

  Future<void> _onRemoveFavorite(
    RemoveFavoriteEvent event,
    Emitter<LocationState> emit,
  ) async {
    try {
      await repository.removeFavorite(event.location);
      final favorites = repository.loadFavorites();
      final currentState = state;
      final currentLocation = currentState is LocationSelected ? currentState.location : null;
      emit(LocationFavoritesLoaded(favorites: favorites, currentLocation: currentLocation));
    } catch (e, stackTrace) {
      logger.e(
        AppError.getDebugErrorMessage(LocationErrorCodes.saveFavoriteFailed),
        error: e,
        stackTrace: stackTrace,
      );
      emit(const LocationError(LocationErrorCodes.saveFavoriteFailed));
    }
  }

  Future<void> _onReorderFavorites(
    ReorderFavoritesEvent event,
    Emitter<LocationState> emit,
  ) async {
    try {
      final favorites = repository.loadFavorites().toList();
      if (event.oldIndex < favorites.length && event.newIndex < favorites.length) {
        final item = favorites.removeAt(event.oldIndex);
        favorites.insert(event.newIndex, item);
        await repository.saveAllFavorites(favorites);
      }
      final updatedFavorites = repository.loadFavorites();
      final currentState = state;
      final currentLocation = currentState is LocationSelected ? currentState.location : null;
      emit(LocationFavoritesLoaded(favorites: updatedFavorites, currentLocation: currentLocation));
    } catch (e, stackTrace) {
      logger.e(
        AppError.getDebugErrorMessage(LocationErrorCodes.saveFavoriteFailed),
        error: e,
        stackTrace: stackTrace,
      );
      emit(const LocationError(LocationErrorCodes.saveFavoriteFailed));
    }
  }

  Future<void> _onLoadFavorites(
    LoadFavoritesEvent event,
    Emitter<LocationState> emit,
  ) async {
    try {
      final favorites = repository.loadFavorites();
      final lastLocation = repository.loadLastLocation();
      emit(LocationFavoritesLoaded(favorites: favorites, currentLocation: lastLocation));
    } catch (e, stackTrace) {
      logger.e(
        AppError.getDebugErrorMessage(LocationErrorCodes.loadFavoritesFailed),
        error: e,
        stackTrace: stackTrace,
      );
      emit(const LocationError(LocationErrorCodes.loadFavoritesFailed));
    }
  }
}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/features/location/presentation/blocs/location_bloc_test.dart`
Expected: PASS

- [ ] **Step 7: Run all location tests**

Run: `flutter test test/features/location/`
Expected: ALL PASS

- [ ] **Step 8: Run `flutter analyze`**

Run: `flutter analyze`
Expected: 0 issues

- [ ] **Step 9: Commit**

```bash
git add lib/features/location/presentation/blocs/ test/features/location/presentation/blocs/
git commit -m "feat(location): add LocationBloc with events and states"
```

---

### Task 6: WeatherBloc & API Integration

**Files:**
- Modify: `lib/core/constants/api_constants.dart`
- Modify: `lib/features/weather_forecast/data/sources/weather_remote_source.dart`
- Modify: `lib/features/weather_forecast/domain/repositories/weather_repository.dart`
- Modify: `lib/features/weather_forecast/data/repositories/weather_repository_impl.dart`
- Modify: `lib/features/weather_forecast/presentation/blocs/weather_forecast_event.dart`
- Modify: `lib/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart`

**Interfaces:**
- Consumes: `LocationEntity` (Task 2), `LocationBloc` (Task 5)
- Produces: Parameterized `fetchWeather(lat, lon)`, updated `FetchWeatherEvent`

- [ ] **Step 1: Update `ApiConstants`**

```dart
// lib/core/constants/api_constants.dart
class ApiConstants {
  ApiConstants._();

  static const String openMeteoBaseUrl = 'https://api.open-meteo.com/v1/forecast';

  static const String _dailyParams = 'temperature_2m_max,temperature_2m_min,weather_code,sunset,sunrise';
  static const String _hourlyParams = 'temperature_2m,precipitation_probability,weather_code';
  static const String _currentParams = 'temperature_2m,relative_humidity_2m,is_day,wind_speed_10m,precipitation,weather_code';

  static String buildForecastUrl(double latitude, double longitude) {
    return '$openMeteoBaseUrl?latitude=$latitude&longitude=$longitude'
        '&daily=$_dailyParams&hourly=$_hourlyParams&current=$_currentParams&timezone=auto';
  }
}
```

- [ ] **Step 2: Update `WeatherRemoteSource`**

```dart
// lib/features/weather_forecast/data/sources/weather_remote_source.dart
import 'package:dio/dio.dart';
import 'package:sky_line/core/constants/api_constants.dart';

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

- [ ] **Step 3: Update `WeatherRepository` interface**

```dart
// lib/features/weather_forecast/domain/repositories/weather_repository.dart
import 'package:sky_line/features/weather_forecast/domain/entities/weather_result.dart';

abstract class WeatherRepository {
  Future<WeatherResult> fetchWeather({required double latitude, required double longitude});
  Future<WeatherResult?> loadCachedWeather();
}
```

- [ ] **Step 4: Update `WeatherRepositoryImpl`**

```dart
// lib/features/weather_forecast/data/repositories/weather_repository_impl.dart
@override
Future<WeatherResult> fetchWeather({required double latitude, required double longitude}) async {
  final json = await _remoteSource.fetchWeather(latitude, longitude);
  final model = WeatherMapper.fromJson(json);
  _dbHelper.saveWeather(model);
  return WeatherResult(weather: model.toEntity(), isCached: false);
}
```

- [ ] **Step 5: Update `FetchWeatherEvent`**

```dart
// lib/features/weather_forecast/presentation/blocs/weather_forecast_event.dart
class FetchWeatherEvent extends WeatherForecastEvent {
  final double? latitude;
  final double? longitude;
  const FetchWeatherEvent({this.latitude, this.longitude});
  @override
  List<Object?> get props => [latitude, longitude];
}
```

- [ ] **Step 6: Update `WeatherForecastBloc._onFetchWeather`**

The `_onFetchWeather` method now uses `event.latitude` and `event.longitude` when calling `weatherRepository.fetchWeather(latitude: lat, longitude: lon)`. If null, use default coordinates (-11.7022, 43.2551).

- [ ] **Step 7: Update existing tests**

Update `test/features/weather_forecast/` tests to match new `fetchWeather(latitude:, longitude:)` signature.

- [ ] **Step 8: Run `flutter test`**

Run: `flutter test`
Expected: ALL PASS

- [ ] **Step 9: Run `flutter analyze`**

Run: `flutter analyze`
Expected: 0 issues

- [ ] **Step 10: Commit**

```bash
git add lib/core/constants/api_constants.dart lib/features/weather_forecast/
git commit -m "refactor(weather): parameterize weather API with latitude and longitude"
```

---

### Task 7: Dependency Injection & App Wiring

**Files:**
- Modify: `lib/injection_container.dart`
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: `LocationBloc` (Task 5), `LocationRepositoryImpl` (Task 4)
- Produces: Wired `InjectionContainer`, updated `main.dart` with `LocationBloc` provider

- [ ] **Step 1: Update `InjectionContainer`**

```dart
// lib/injection_container.dart
import 'package:sky_line/features/location/data/sources/location_remote_source.dart';
import 'package:sky_line/features/location/data/sources/location_local_source.dart';
import 'package:sky_line/features/location/data/repositories/location_repository_impl.dart';
import 'package:sky_line/features/location/domain/repositories/location_repository.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';

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

- [ ] **Step 2: Update `main.dart`**

Add `BlocProvider` for `LocationBloc`:
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

- [ ] **Step 3: Run `flutter analyze`**

Run: `flutter analyze`
Expected: 0 issues

- [ ] **Step 4: Commit**

```bash
git add lib/injection_container.dart lib/main.dart
git commit -m "feat(location): wire LocationBloc into DI and app providers"
```

---

### Task 8: Location Search Screen UI

**Files:**
- Create: `lib/features/location/presentation/screens/location_search_screen.dart`
- Create: `lib/features/location/presentation/widgets/search_bar_widget.dart`
- Create: `lib/features/location/presentation/widgets/search_result_tile.dart`

**Interfaces:**
- Consumes: `LocationBloc` (Task 5), `LocationEntity` (Task 2), `LoadingAnimationWidget` (existing)
- Produces: `LocationSearchScreen` widget

- [ ] **Step 1: Create `SearchResultTile` widget**

```dart
// lib/features/location/presentation/widgets/search_result_tile.dart
import 'package:flutter/material.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';

class SearchResultTile extends StatelessWidget {
  final LocationEntity location;
  final VoidCallback onTap;

  const SearchResultTile({super.key, required this.location, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final subtitle = [location.admin1, location.country]
        .where((e) => e != null && e.isNotEmpty)
        .join(', ');

    return ListTile(
      title: Text(location.cityName),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
```

- [ ] **Step 2: Create `SearchBarWidget`**

```dart
// lib/features/location/presentation/widgets/search_bar_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onSearch;

  const SearchBarWidget({super.key, required this.onSearch});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search city...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  widget.onSearch('');
                },
              )
            : null,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
```

- [ ] **Step 3: Create `LocationSearchScreen`**

```dart
// lib/features/location/presentation/screens/location_search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_event.dart';
import 'package:sky_line/features/location/presentation/blocs/location_state.dart';
import 'package:sky_line/features/location/presentation/widgets/search_bar_widget.dart';
import 'package:sky_line/features/location/presentation/widgets/search_result_tile.dart';

class LocationSearchScreen extends StatelessWidget {
  const LocationSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search City')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SearchBarWidget(
              onSearch: (query) {
                context.read<LocationBloc>().add(SearchLocationsEvent(query));
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<LocationBloc, LocationState>(
                builder: (context, state) {
                  if (state is LocationSearchLoading) {
                    return Center(
                      child: LoadingAnimationWidget.staggeredDotsWave(
                        color: Theme.of(context).primaryColor,
                        size: 40,
                      ),
                    );
                  }
                  if (state is LocationSearchLoaded) {
                    if (state.results.isEmpty) {
                      return const Center(child: Text('No results found'));
                    }
                    return ListView.builder(
                      itemCount: state.results.length,
                      itemBuilder: (context, index) {
                        final location = state.results[index];
                        return SearchResultTile(
                          location: location,
                          onTap: () {
                            context.read<LocationBloc>().add(
                              SelectLocationEvent(location: location),
                            );
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  }
                  return const Center(child: Text('Type to search for a city'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run `flutter analyze`**

Run: `flutter analyze`
Expected: 0 issues

- [ ] **Step 5: Commit**

```bash
git add lib/features/location/presentation/screens/ lib/features/location/presentation/widgets/
git commit -m "feat(location): add LocationSearchScreen with debounced search"
```

---

### Task 9: WeatherScreen Integration (PageView + Favorites)

**Files:**
- Modify: `lib/features/weather_forecast/presentation/screens/weather_screen.dart`
- Create: `lib/features/location/presentation/widgets/favorites_list_widget.dart`

**Interfaces:**
- Consumes: `LocationBloc` (Task 5), `WeatherForecastBloc` (Task 6), `LocationEntity` (Task 2)
- Produces: Updated `WeatherScreen` with PageView, favorite button, search button

- [ ] **Step 1: Create `FavoritesListWidget`**

```dart
// lib/features/location/presentation/widgets/favorites_list_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_event.dart';

class FavoritesListWidget extends StatelessWidget {
  final List<LocationEntity> favorites;
  final ValueChanged<LocationEntity> onLocationTap;

  const FavoritesListWidget({
    super.key,
    required this.favorites,
    required this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty) {
      return const Center(child: Text('No favorites yet'));
    }

    return ReorderableListView.builder(
      itemCount: favorites.length,
      onReorder: (oldIndex, newIndex) {
        context.read<LocationBloc>().add(
          ReorderFavoritesEvent(oldIndex: oldIndex, newIndex: newIndex),
        );
      },
      itemBuilder: (context, index) {
        final location = favorites[index];
        final subtitle = [location.admin1, location.country]
            .where((e) => e != null && e.isNotEmpty)
            .join(', ');

        return Dismissible(
          key: ValueKey('${location.latitude}_${location.longitude}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            context.read<LocationBloc>().add(
              RemoveFavoriteEvent(location: location),
            );
          },
          child: ListTile(
            key: ValueKey('${location.latitude}_${location.longitude}'),
            title: Text(location.cityName),
            subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
            trailing: const Icon(Icons.drag_handle),
            onTap: () => onLocationTap(location),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 2: Update `WeatherScreen` with PageView, search button, favorite button**

The `WeatherScreen` is updated to:
1. Wrap the main content in a `PageView` that shows pages for each favorite + GPS location
2. Add a search icon in AppBar → navigates to `LocationSearchScreen`
3. Add a star/heart icon in AppBar → toggles current city as favorite
4. Add pagination dots below the PageView
5. `BlocListener<LocationBloc>` bridges location selection to `WeatherBloc`

Key additions to `WeatherScreen`:
- `PageController` for swipe navigation
- `_currentPage` state for tracking current page
- Search button: `Navigator.push` to `LocationSearchScreen`
- Favorite button: `BlocBuilder<LocationBloc>` to check if current city is favorited
- `BlocListener<LocationBloc>` that adds `FetchWeatherEvent(latitude:, longitude:)` when `LocationSelected` is emitted

- [ ] **Step 3: Run `flutter analyze`**

Run: `flutter analyze`
Expected: 0 issues

- [ ] **Step 4: Commit**

```bash
git add lib/features/weather_forecast/presentation/screens/weather_screen.dart lib/features/location/presentation/widgets/favorites_list_widget.dart
git commit -m "feat(location): integrate PageView, favorites, and search into WeatherScreen"
```

---

### Task 10: Final Verification

**Files:** None (verification only)

- [ ] **Step 1: Run full test suite**

Run: `flutter test`
Expected: ALL PASS

- [ ] **Step 2: Run static analysis**

Run: `flutter analyze`
Expected: 0 issues, 0 warnings

- [ ] **Step 3: Run ObjectBox codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Success, no conflicts

- [ ] **Step 4: Verify app builds**

Run: `flutter build apk --debug`
Expected: Build succeeds

- [ ] **Step 5: Final commit if any fixes needed**

```bash
git add -A
git commit -m "chore: final verification fixes for location feature"
```
