import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' hide LocationServiceDisabledException;
import 'package:mocktail/mocktail.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:sky_line/core/errors/location_exceptions.dart';
import 'package:sky_line/features/location/data/sources/location_remote_source.dart';
import 'package:sky_line/features/location/data/sources/location_local_source.dart';
import 'package:sky_line/features/location/data/sources/location_permission_source.dart';
import 'package:sky_line/features/location/data/repositories/location_repository_impl.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';
import 'package:sky_line/core/config/db_helper/location_cache_entity.dart';
import 'package:sky_line/core/config/db_helper/last_location_entity.dart';

class MockRemoteSource extends Mock implements LocationRemoteSource {}
class MockLocalSource extends Mock implements LocationLocalSource {}
class MockPermissionSource extends Mock implements LocationPermissionSource {}

void main() {
  late MockRemoteSource mockRemote;
  late MockLocalSource mockLocal;
  late MockPermissionSource mockPermission;
  late LocationRepositoryImpl repo;

  setUp(() {
    mockRemote = MockRemoteSource();
    mockLocal = MockLocalSource();
    mockPermission = MockPermissionSource();
    repo = LocationRepositoryImpl(mockRemote, mockLocal, mockPermission);
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

  group('removeFavorite', () {
    test('removes favorite matching cityName and country', () async {
      final favorites = [
        LocationCacheEntity(
          id: 1, latitude: 48.85, longitude: 2.35,
          cityName: 'Paris', country: 'France',
        ),
        LocationCacheEntity(
          id: 2, latitude: 48.85, longitude: 2.35,
          cityName: 'Paris', country: 'USA',
        ),
      ];
      when(() => mockLocal.loadFavorites()).thenReturn(favorites);
      when(() => mockLocal.removeFavorite(any())).thenReturn(null);

      const location = LocationEntity(
        latitude: 48.85, longitude: 2.35,
        cityName: 'Paris', country: 'USA',
      );
      await repo.removeFavorite(location);

      verify(() => mockLocal.removeFavorite(2)).called(1);
      verifyNever(() => mockLocal.removeFavorite(1));
    });

    test('does nothing when no matching favorite found', () async {
      when(() => mockLocal.loadFavorites()).thenReturn([
        LocationCacheEntity(
          id: 1, latitude: 48.85, longitude: 2.35,
          cityName: 'Paris', country: 'France',
        ),
      ]);
      when(() => mockLocal.removeFavorite(any())).thenReturn(null);

      const location = LocationEntity(
        latitude: 48.85, longitude: 2.35,
        cityName: 'Paris', country: 'USA',
      );
      await repo.removeFavorite(location);

      verifyNever(() => mockLocal.removeFavorite(any()));
    });
  });

  group('saveAllFavorites', () {
    test('saves all favorites with list index as sortOrder', () async {
      when(() => mockLocal.saveAllFavorites(any())).thenReturn(null);

      final favorites = [
        const LocationEntity(
          latitude: 48.85, longitude: 2.35,
          cityName: 'Paris', country: 'France', sortOrder: 5,
        ),
        const LocationEntity(
          latitude: 40.71, longitude: -74.00,
          cityName: 'New York', country: 'USA', sortOrder: 3,
        ),
      ];
      await repo.saveAllFavorites(favorites);

      final captured = verify(() => mockLocal.saveAllFavorites(captureAny())).captured;
      final saved = captured.first as List<LocationCacheEntity>;
      expect(saved, hasLength(2));
      expect(saved[0].sortOrder, 0);
      expect(saved[0].cityName, 'Paris');
      expect(saved[1].sortOrder, 1);
      expect(saved[1].cityName, 'New York');
    });

    test('saves empty list', () async {
      when(() => mockLocal.saveAllFavorites(any())).thenReturn(null);

      await repo.saveAllFavorites([]);

      final captured = verify(() => mockLocal.saveAllFavorites(captureAny())).captured;
      final saved = captured.first as List<LocationCacheEntity>;
      expect(saved, isEmpty);
    });
  });

  group('loadLastLocation', () {
    test('returns LocationEntity when last location exists', () {
      when(() => mockLocal.loadLastLocation()).thenReturn(
        LastLocationEntity(
          latitude: 48.85, longitude: 2.35,
          cityName: 'Paris', country: 'France', admin1: 'Ile-de-France',
        ),
      );

      final result = repo.loadLastLocation();
      expect(result, isNotNull);
      expect(result!.cityName, 'Paris');
      expect(result.country, 'France');
      expect(result.admin1, 'Ile-de-France');
    });

    test('returns null when no last location saved', () {
      when(() => mockLocal.loadLastLocation()).thenReturn(null);

      final result = repo.loadLastLocation();
      expect(result, isNull);
    });
  });

  group('saveLastLocation', () {
    test('saves to local source', () async {
      when(() => mockLocal.saveLastLocation(any())).thenReturn(null);

      const entity = LocationEntity(
        latitude: 48.85, longitude: 2.35,
        cityName: 'Paris', country: 'France',
      );
      await repo.saveLastLocation(entity);

      verify(() => mockLocal.saveLastLocation(any())).called(1);
    });
  });

  group('detectCurrentLocation', () {
    final position = Position(
      latitude: -11.70,
      longitude: 43.25,
      timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

    test('requests permission, checks service, returns GPS location', () async {
      when(() => mockPermission.requestLocationPermission())
          .thenAnswer((_) async => ph.PermissionStatus.granted);
      when(() => mockPermission.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(() => mockPermission.getCurrentPosition())
          .thenAnswer((_) async => position);

      final result = await repo.detectCurrentLocation();

      expect(result.latitude, -11.70);
      expect(result.longitude, 43.25);
      expect(result.isGpsLocation, isTrue);
      verify(() => mockPermission.requestLocationPermission()).called(1);
      verify(() => mockPermission.isLocationServiceEnabled()).called(1);
      verify(() => mockPermission.getCurrentPosition()).called(1);
    });

    test('throws LocationPermissionDeniedException when denied', () async {
      when(() => mockPermission.requestLocationPermission())
          .thenAnswer((_) async => ph.PermissionStatus.denied);

      expect(
        () => repo.detectCurrentLocation(),
        throwsA(isA<LocationPermissionDeniedException>()),
      );
    });

    test('throws LocationPermissionDeniedException when restricted', () async {
      when(() => mockPermission.requestLocationPermission())
          .thenAnswer((_) async => ph.PermissionStatus.restricted);

      expect(
        () => repo.detectCurrentLocation(),
        throwsA(isA<LocationPermissionDeniedException>()),
      );
    });

    test('throws LocationPermissionPermanentlyDeniedException when denied forever',
        () async {
      when(() => mockPermission.requestLocationPermission())
          .thenAnswer((_) async => ph.PermissionStatus.permanentlyDenied);

      expect(
        () => repo.detectCurrentLocation(),
        throwsA(isA<LocationPermissionPermanentlyDeniedException>()),
      );
    });

    test('throws LocationServiceDisabledException when service is off', () async {
      when(() => mockPermission.requestLocationPermission())
          .thenAnswer((_) async => ph.PermissionStatus.granted);
      when(() => mockPermission.isLocationServiceEnabled())
          .thenAnswer((_) async => false);

      expect(
        () => repo.detectCurrentLocation(),
        throwsA(isA<LocationServiceDisabledException>()),
      );
      verifyNever(() => mockPermission.getCurrentPosition());
    });
  });

  group('openLocationSettings', () {
    test('delegates to permission source', () async {
      when(() => mockPermission.openLocationSettings())
          .thenAnswer((_) async => true);

      await repo.openLocationSettings();

      verify(() => mockPermission.openLocationSettings()).called(1);
    });
  });

  group('openAppSettings', () {
    test('delegates to permission source', () async {
      when(() => mockPermission.openAppSettings())
          .thenAnswer((_) async => true);

      await repo.openAppSettings();

      verify(() => mockPermission.openAppSettings()).called(1);
    });
  });
}
