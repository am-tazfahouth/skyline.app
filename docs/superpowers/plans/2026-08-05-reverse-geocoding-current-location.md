# Reverse Geocoding for Current Location — Implementation Plan

**Date:** 2026-08-05
**Feature:** location
**Status:** Implemented

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enrich the GPS-detected location with the real city name/country/admin1 via BigDataCloud reverse geocoding, falling back to `Current Location` on failure.

**Architecture:** On `detectCurrentLocation()`, the repository enriches the raw GPS `Position` with a `ReverseGeocodeModel` fetched from BigDataCloud's free endpoint. All changes stay in the `location` feature's data layer plus one core constant. No new dependency (reuses `Dio`), no domain/presentation changes — the existing UI already renders `cityName`, `admin1`, `country`.

**Tech Stack:** Flutter/Dart, Dio 5.x, Equatable, mocktail, flutter_test.

## Global Constraints

- All code, comments, and commit messages in **English**.
- Every data model extends `Equatable` with explicit `props`; manual `copyWith` (no freezed).
- `flutter analyze` must pass with **0 warnings, 0 infos**.
- Follow existing patterns: `fromJson`, manual mappers, TDD (failing test → implement → passing test).
- No BuildContext in data/domain layers; `localityLanguage: 'fr'` (consistent with the hardcoded search language).
- GPS coordinates of the detected position are **always preserved**; the nearest city's coordinates are never used.

---

### Task 1: `ReverseGeocodeModel` (DTO)

**Files:**
- Create: `lib/features/location/data/models/reverse_geocode_model.dart`
- Test: `test/features/location/data/models/reverse_geocode_model_test.dart`

**Interfaces:**
- Produces: `ReverseGeocodeModel` with fields `String? city`, `String? locality`, `String? principalSubdivision`, `String? countryName` (cleaned), `String? countryCode`; static `fromJson(Map<String, dynamic>)`; `copyWith`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/features/location/data/models/reverse_geocode_model.dart';

void main() {
  group('fromJson', () {
    test('parses a full response and strips the country article', () {
      final model = ReverseGeocodeModel.fromJson(const {
        'city': 'Paris',
        'locality': 'Saint-Merri',
        'principalSubdivision': 'Île-de-France',
        'countryName': 'France (la)',
        'countryCode': 'FR',
      });

      expect(model.city, 'Paris');
      expect(model.locality, 'Saint-Merri');
      expect(model.principalSubdivision, 'Île-de-France');
      expect(model.countryName, 'France');
      expect(model.countryCode, 'FR');
    });

    test('strips the trailing article from countryName', () {
      final model = ReverseGeocodeModel.fromJson(const {
        'countryName': 'États-Unis d\'Amérique (les)',
      });
      expect(model.countryName, 'États-Unis d\'Amérique');
    });

    test('keeps countryName unchanged when it has no article', () {
      final model = ReverseGeocodeModel.fromJson(const {'countryName': 'Comoros'});
      expect(model.countryName, 'Comoros');
    });

    test('handles missing fields', () {
      final model = ReverseGeocodeModel.fromJson(const {});
      expect(model.city, isNull);
      expect(model.locality, isNull);
      expect(model.principalSubdivision, isNull);
      expect(model.countryName, isNull);
      expect(model.countryCode, isNull);
    });
  });

  group('copyWith', () {
    test('returns a new instance with updated fields', () {
      const original = ReverseGeocodeModel(city: 'Paris', countryName: 'France');
      final updated = original.copyWith(city: 'Lyon');
      expect(updated.city, 'Lyon');
      expect(original.city, 'Paris');
    });
  });

  group('equality', () {
    test('is value-based', () {
      const a = ReverseGeocodeModel(city: 'Paris');
      const b = ReverseGeocodeModel(city: 'Paris');
      expect(a, b);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/location/data/models/reverse_geocode_model_test.dart`
Expected: FAIL — "ReverseGeocodeModel not defined" (import error).

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:equatable/equatable.dart';

class ReverseGeocodeModel extends Equatable {
  final String? city;
  final String? locality;
  final String? principalSubdivision;
  final String? countryName;
  final String? countryCode;

  const ReverseGeocodeModel({
    this.city,
    this.locality,
    this.principalSubdivision,
    this.countryName,
    this.countryCode,
  });

  factory ReverseGeocodeModel.fromJson(Map<String, dynamic> json) {
    return ReverseGeocodeModel(
      city: json['city'] as String?,
      locality: json['locality'] as String?,
      principalSubdivision: json['principalSubdivision'] as String?,
      countryName: _cleanCountryName(json['countryName'] as String?),
      countryCode: json['countryCode'] as String?,
    );
  }

  static String? _cleanCountryName(String? raw) {
    if (raw == null || raw.isEmpty) return raw;
    return raw.replaceAll(RegExp(r'\s*\(.*\)\s*$'), '').trim();
  }

  ReverseGeocodeModel copyWith({
    String? city,
    String? locality,
    String? principalSubdivision,
    String? countryName,
    String? countryCode,
  }) {
    return ReverseGeocodeModel(
      city: city ?? this.city,
      locality: locality ?? this.locality,
      principalSubdivision: principalSubdivision ?? this.principalSubdivision,
      countryName: countryName ?? this.countryName,
      countryCode: countryCode ?? this.countryCode,
    );
  }

  @override
  List<Object?> get props => [
        city,
        locality,
        principalSubdivision,
        countryName,
        countryCode,
      ];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/location/data/models/reverse_geocode_model_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/location/data/models/reverse_geocode_model.dart test/features/location/data/models/reverse_geocode_model_test.dart
git commit -m "feat: add reverse geocoding model"
```

---

### Task 2: `reverseGeocode` remote source method

**Files:**
- Modify: `lib/core/constants/api_constants.dart` (add constant)
- Modify: `lib/features/location/data/sources/location_remote_source.dart:1-21`
- Test: `test/features/location/data/sources/location_remote_source_test.dart`

**Interfaces:**
- Consumes: `ReverseGeocodeModel.fromJson` (from Task 1).
- Produces: `Future<ReverseGeocodeModel> reverseGeocode({required double latitude, required double longitude})` on `LocationRemoteSource`.

- [ ] **Step 1: Write the failing tests** (append to `location_remote_source_test.dart`, adding import `package:sky_line/features/location/data/models/reverse_geocode_model.dart`)

```dart
  group('reverseGeocode', () {
    final responseData = {
      'city': 'Moroni',
      'principalSubdivision': 'Grande Comore',
      'countryName': 'Comoros',
      'countryCode': 'KM',
    };

    void stubSuccess() {
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => Response(
        data: responseData,
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ));
    }

    test('calls Dio with the BigDataCloud URL and parses the response', () async {
      stubSuccess();

      final result = await source.reverseGeocode(latitude: -11.70, longitude: 43.25);

      expect(result, isA<ReverseGeocodeModel>());
      expect(result.city, 'Moroni');
      verify(() => mockDio.get(
        'https://api.bigdatacloud.net/data/reverse-geocode-client',
        queryParameters: any(named: 'queryParameters'),
      )).called(1);
    });

    test('passes latitude, longitude and localityLanguage=fr', () async {
      stubSuccess();

      await source.reverseGeocode(latitude: -11.70, longitude: 43.25);

      verify(() => mockDio.get(
        any(),
        queryParameters: {
          'latitude': -11.70,
          'longitude': 43.25,
          'localityLanguage': 'fr',
        },
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

      expect(
        () => source.reverseGeocode(latitude: -11.70, longitude: 43.25),
        throwsA(isA<DioException>()),
      );
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/location/data/sources/location_remote_source_test.dart`
Expected: FAIL — "reverseGeocode not defined".

- [ ] **Step 3: Write minimal implementation**

In `lib/core/constants/api_constants.dart`, add inside `ApiConstants`:

```dart
  static const String bigDataCloudReverseGeocodeUrl =
      'https://api.bigdatacloud.net/data/reverse-geocode-client';
```

In `lib/features/location/data/sources/location_remote_source.dart`, add import
`package:sky_line/features/location/data/models/reverse_geocode_model.dart` and:

```dart
  Future<ReverseGeocodeModel> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.get(
      ApiConstants.bigDataCloudReverseGeocodeUrl,
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'localityLanguage': 'fr',
      },
    );
    return ReverseGeocodeModel.fromJson(response.data as Map<String, dynamic>);
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/location/data/sources/location_remote_source_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/constants/api_constants.dart lib/features/location/data/sources/location_remote_source.dart test/features/location/data/sources/location_remote_source_test.dart
git commit -m "feat: add reverse geocoding remote source"
```

---

### Task 3: Enrich `detectCurrentLocation` in the repository

**Files:**
- Modify: `lib/features/location/data/repositories/location_repository_impl.dart:112-135`
- Test: `test/features/location/data/repositories/location_repository_impl_test.dart`

**Interfaces:**
- Consumes: `_remoteSource.reverseGeocode({required double latitude, required double longitude})` (Task 2).
- Produces: `detectCurrentLocation()` now returns a `LocationEntity` with real `cityName`/`country`/`admin1` when reverse geocoding succeeds, otherwise `cityName: 'Current Location'`. Coordinates and `isGpsLocation: true` are always preserved.

- [ ] **Step 1: Write the failing tests** — add import `package:sky_line/features/location/data/models/reverse_geocode_model.dart`; in the `detectCurrentLocation` group, replace the existing `'requests permission, checks service, returns GPS location'` test and add:

```dart
    void stubPermissions() {
      when(() => mockPermission.requestLocationPermission())
          .thenAnswer((_) async => ph.PermissionStatus.granted);
      when(() => mockPermission.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(() => mockPermission.getCurrentPosition())
          .thenAnswer((_) async => position);
    }

    test('requests permission, checks service, returns GPS location', () async {
      stubPermissions();
      when(() => mockRemote.reverseGeocode(latitude: -11.70, longitude: 43.25))
          .thenAnswer((_) async => const ReverseGeocodeModel(city: 'Moroni'));

      final result = await repo.detectCurrentLocation();

      expect(result.latitude, -11.70);
      expect(result.longitude, 43.25);
      expect(result.isGpsLocation, isTrue);
      verify(() => mockPermission.requestLocationPermission()).called(1);
      verify(() => mockPermission.isLocationServiceEnabled()).called(1);
      verify(() => mockPermission.getCurrentPosition()).called(1);
      verify(() => mockRemote.reverseGeocode(latitude: -11.70, longitude: 43.25)).called(1);
    });

    test('returns enriched location when reverse geocoding succeeds', () async {
      stubPermissions();
      when(() => mockRemote.reverseGeocode(latitude: -11.70, longitude: 43.25))
          .thenAnswer((_) async => const ReverseGeocodeModel(
                city: 'Moroni',
                principalSubdivision: 'Grande Comore',
                countryName: 'Comoros',
              ));

      final result = await repo.detectCurrentLocation();

      expect(result.cityName, 'Moroni');
      expect(result.country, 'Comoros');
      expect(result.admin1, 'Grande Comore');
      expect(result.isGpsLocation, isTrue);
      expect(result.latitude, -11.70);
      expect(result.longitude, 43.25);
    });

    test('uses locality when city is empty', () async {
      stubPermissions();
      when(() => mockRemote.reverseGeocode(latitude: -11.70, longitude: 43.25))
          .thenAnswer((_) async => const ReverseGeocodeModel(locality: 'Saint-Merri'));

      final result = await repo.detectCurrentLocation();

      expect(result.cityName, 'Saint-Merri');
    });

    test('falls back to Current Location when reverse geocoding throws', () async {
      stubPermissions();
      when(() => mockRemote.reverseGeocode(latitude: -11.70, longitude: 43.25))
          .thenThrow(Exception('network error'));

      final result = await repo.detectCurrentLocation();

      expect(result.cityName, 'Current Location');
      expect(result.latitude, -11.70);
      expect(result.longitude, 43.25);
      expect(result.isGpsLocation, isTrue);
    });

    test('falls back to Current Location when no city or locality is returned', () async {
      stubPermissions();
      when(() => mockRemote.reverseGeocode(latitude: -11.70, longitude: 43.25))
          .thenAnswer((_) async => const ReverseGeocodeModel());

      final result = await repo.detectCurrentLocation();

      expect(result.cityName, 'Current Location');
      expect(result.latitude, -11.70);
      expect(result.longitude, 43.25);
    });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/location/data/repositories/location_repository_impl_test.dart`
Expected: FAIL — `'Current Location'` returned instead of `'Moroni'` (enrichment not implemented).

- [ ] **Step 3: Write minimal implementation** — replace the tail of `detectCurrentLocation()` in `location_repository_impl.dart`:

```dart
    final position = await _permissionSource.getCurrentPosition();
    return _resolveDetectedLocation(position.latitude, position.longitude);
  }

  Future<LocationEntity> _resolveDetectedLocation(
    double latitude,
    double longitude,
  ) async {
    try {
      final place =
          await _remoteSource.reverseGeocode(latitude: latitude, longitude: longitude);
      final city = _firstNonEmpty([place.city, place.locality]);
      if (city == null) return _gpsFallback(latitude, longitude);
      return LocationEntity(
        latitude: latitude,
        longitude: longitude,
        cityName: city,
        country: place.countryName,
        admin1: place.principalSubdivision,
        isGpsLocation: true,
      );
    } catch (_) {
      return _gpsFallback(latitude, longitude);
    }
  }

  LocationEntity _gpsFallback(double latitude, double longitude) {
    return LocationEntity(
      latitude: latitude,
      longitude: longitude,
      cityName: 'Current Location',
      isGpsLocation: true,
    );
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value;
    }
    return null;
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/location/data/repositories/location_repository_impl_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/location/data/repositories/location_repository_impl.dart test/features/location/data/repositories/location_repository_impl_test.dart
git commit -m "feat: enrich GPS location with reverse geocoding"
```

---

### Final verification (after Task 3)

- [ ] Run: `flutter analyze` — Expected: no issues.
- [ ] Run: `flutter test` — Expected: all tests pass.

---

**Notes / deliberate decisions**
- `localityLanguage: 'fr'` is hardcoded (same pattern as the existing search source). Language from settings is out of scope.
- Reverse-geocode failure is a **silent fallback** (no logger injected into the repo — constructor, DI, and existing mocks stay unchanged).
- Bloc/DI/UI need **no changes**: enrichment happens inside the repository; `location_screen.dart` already auto-adds GPS locations as favorites and the weather header already renders `title`.
- `_resolveDetectedLocation`'s `catch (_)` also guards against a `null` body edge case, so the previously-existing "returns GPS location" test would degrade gracefully even without stubbing.
