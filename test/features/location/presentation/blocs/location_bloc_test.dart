import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/enums/setting_lang.dart';
import 'package:sky_line/core/errors/location_error_codes.dart';
import 'package:sky_line/core/errors/location_exceptions.dart';
import 'package:sky_line/core/services/logger_services.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';
import 'package:sky_line/features/location/domain/repositories/location_repository.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_event.dart';
import 'package:sky_line/features/location/presentation/blocs/location_state.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';
import 'package:sky_line/features/settings/domain/repositories/setting_repository.dart';

class MockRepository extends Mock implements LocationRepository {}

class MockLogger extends Mock implements AppLogger {}

class MockSettingRepository extends Mock implements SettingRepository {}

void main() {
  late MockRepository mockRepo;
  late MockLogger mockLogger;
  late MockSettingRepository mockSettingRepo;
  late LocationBloc bloc;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(
      const LocationEntity(latitude: 0, longitude: 0, cityName: ''),
    );
    registerFallbackValue(const SettingEntity());
  });

  setUp(() {
    mockRepo = MockRepository();
    mockLogger = MockLogger();
    mockSettingRepo = MockSettingRepository();
    when(
      () => mockSettingRepo.loadSettings(),
    ).thenAnswer((_) async => const SettingEntity());
    bloc = LocationBloc(
      logger: mockLogger,
      repository: mockRepo,
      settingRepository: mockSettingRepo,
    );
  });

  tearDown(() => bloc.close());

  const testLocation = LocationEntity(
    latitude: 48.85,
    longitude: 2.35,
    cityName: 'Paris',
    country: 'France',
  );

  const otherLocation = LocationEntity(
    latitude: 40.71,
    longitude: -74.00,
    cityName: 'New York',
    country: 'USA',
  );

  group('LoadFavoritesEvent', () {
    blocTest<LocationBloc, LocationState>(
      'emits LocationFavoritesLoaded with favorites and last location',
      build: () {
        when(() => mockRepo.loadFavorites()).thenReturn([testLocation]);
        when(() => mockRepo.loadLastLocation()).thenReturn(testLocation);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadFavoritesEvent()),
      expect: () => [
        isA<LocationFavoritesLoaded>()
            .having((s) => s.favorites.length, 'favorites', 1)
            .having((s) => s.currentLocation?.cityName, 'current', 'Paris'),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'clears a stale last location and nulls current location when favorites is empty',
      build: () {
        when(() => mockRepo.loadFavorites()).thenReturn([]);
        when(() => mockRepo.loadLastLocation()).thenReturn(testLocation);
        when(() => mockRepo.clearLastLocation()).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadFavoritesEvent()),
      expect: () => [
        isA<LocationFavoritesLoaded>()
            .having((s) => s.favorites, 'favorites', isEmpty)
            .having((s) => s.currentLocation, 'currentLocation', isNull),
      ],
      verify: (_) {
        verify(() => mockRepo.clearLastLocation()).called(1);
      },
    );

    blocTest<LocationBloc, LocationState>(
      'emits LocationError when loadFavorites throws',
      build: () {
        when(() => mockRepo.loadFavorites()).thenThrow(Exception('fail'));
        when(() => mockRepo.loadLastLocation()).thenReturn(null);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadFavoritesEvent()),
      expect: () => [isA<LocationError>()],
    );
  });

  group('SearchLocationsEvent', () {
    blocTest<LocationBloc, LocationState>(
      'emits LocationSearchLoading then LocationSearchLoaded',
      build: () {
        when(
          () => mockRepo.searchLocations(any(), any()),
        ).thenAnswer((_) async => [testLocation]);
        return bloc;
      },
      act: (bloc) => bloc.add(const SearchLocationsEvent('Paris')),
      expect: () => [
        isA<LocationSearchLoading>(),
        isA<LocationSearchLoaded>().having(
          (s) => s.results.length,
          'results',
          1,
        ),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'emits LocationSearchError when search throws',
      build: () {
        when(
          () => mockRepo.searchLocations(any(), any()),
        ).thenThrow(Exception('fail'));
        return bloc;
      },
      act: (bloc) => bloc.add(const SearchLocationsEvent('Paris')),
      expect: () => [
        isA<LocationSearchLoading>(),
        isA<LocationSearchError>().having(
          (s) => s.errorCode,
          'code',
          LocationErrorCodes.searchFailed,
        ),
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
      act: (bloc) =>
          bloc.add(const SelectLocationEvent(location: testLocation)),
      expect: () => [
        isA<LocationSelected>().having(
          (s) => s.location.cityName,
          'city',
          'Paris',
        ),
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
        when(() => mockRepo.clearLastLocation()).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const RemoveFavoriteEvent(location: testLocation)),
      expect: () => [isA<LocationFavoritesLoaded>()],
    );

    blocTest<LocationBloc, LocationState>(
      'removing the last favorite clears the persisted last location and nulls the current one',
      seed: () => const LocationFavoritesLoaded(
        favorites: [testLocation],
        currentLocation: testLocation,
      ),
      build: () {
        when(() => mockRepo.removeFavorite(any())).thenAnswer((_) async {});
        when(() => mockRepo.loadFavorites()).thenReturn([]);
        when(() => mockRepo.clearLastLocation()).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const RemoveFavoriteEvent(location: testLocation)),
      expect: () => [
        isA<LocationFavoritesLoaded>()
            .having((s) => s.favorites, 'favorites', isEmpty)
            .having((s) => s.currentLocation, 'currentLocation', isNull),
      ],
      verify: (_) {
        verify(() => mockRepo.clearLastLocation()).called(1);
      },
    );

    blocTest<LocationBloc, LocationState>(
      'removing a non-current favorite keeps the current location',
      seed: () => const LocationFavoritesLoaded(
        favorites: [testLocation, otherLocation],
        currentLocation: testLocation,
      ),
      build: () {
        when(() => mockRepo.removeFavorite(any())).thenAnswer((_) async {});
        when(() => mockRepo.loadFavorites()).thenReturn([testLocation]);
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const RemoveFavoriteEvent(location: otherLocation)),
      expect: () => [
        isA<LocationFavoritesLoaded>()
            .having((s) => s.favorites, 'favorites', [testLocation])
            .having(
              (s) => s.currentLocation?.cityName,
              'currentLocation',
              'Paris',
            ),
      ],
      verify: (_) {
        verifyNever(() => mockRepo.clearLastLocation());
      },
    );

    blocTest<LocationBloc, LocationState>(
      'removing the current favorite promotes the first remaining favorite',
      seed: () => const LocationFavoritesLoaded(
        favorites: [testLocation, otherLocation],
        currentLocation: testLocation,
      ),
      build: () {
        when(() => mockRepo.removeFavorite(any())).thenAnswer((_) async {});
        when(() => mockRepo.loadFavorites()).thenReturn([otherLocation]);
        when(() => mockRepo.saveLastLocation(any())).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const RemoveFavoriteEvent(location: testLocation)),
      expect: () => [
        isA<LocationFavoritesLoaded>()
            .having((s) => s.favorites, 'favorites', [otherLocation])
            .having(
              (s) => s.currentLocation?.cityName,
              'currentLocation',
              'New York',
            ),
      ],
      verify: (_) {
        verify(() => mockRepo.saveLastLocation(otherLocation)).called(1);
        verifyNever(() => mockRepo.clearLastLocation());
      },
    );
  });

  group('ReorderFavoritesEvent', () {
    const locationA = LocationEntity(
      latitude: 1.0,
      longitude: 1.0,
      cityName: 'A',
    );
    const locationB = LocationEntity(
      latitude: 2.0,
      longitude: 2.0,
      cityName: 'B',
    );
    const locationC = LocationEntity(
      latitude: 3.0,
      longitude: 3.0,
      cityName: 'C',
    );

    blocTest<LocationBloc, LocationState>(
      'reorders favorites within bounds',
      build: () {
        when(
          () => mockRepo.loadFavorites(),
        ).thenReturn([locationA, locationB, locationC]);
        when(() => mockRepo.saveAllFavorites(any())).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const ReorderFavoritesEvent(oldIndex: 0, newIndex: 2)),
      expect: () => [isA<LocationFavoritesLoaded>()],
      verify: (_) {
        final captured =
            verify(
                  () => mockRepo.saveAllFavorites(captureAny()),
                ).captured.single
                as List;
        expect(captured[0].cityName, 'B');
        expect(captured[1].cityName, 'A');
        expect(captured[2].cityName, 'C');
      },
    );

    blocTest<LocationBloc, LocationState>(
      'does not reorder when oldIndex is out of bounds',
      build: () {
        when(() => mockRepo.loadFavorites()).thenReturn([locationA, locationB]);
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const ReorderFavoritesEvent(oldIndex: 5, newIndex: 0)),
      expect: () => [isA<LocationFavoritesLoaded>()],
      verify: (_) {
        verifyNever(() => mockRepo.saveAllFavorites(any()));
      },
    );

    blocTest<LocationBloc, LocationState>(
      'does not reorder when newIndex is out of bounds',
      build: () {
        when(() => mockRepo.loadFavorites()).thenReturn([locationA, locationB]);
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const ReorderFavoritesEvent(oldIndex: 0, newIndex: 5)),
      expect: () => [isA<LocationFavoritesLoaded>()],
      verify: (_) {
        verifyNever(() => mockRepo.saveAllFavorites(any()));
      },
    );
  });

  group('DetectCurrentLocationEvent', () {
    blocTest<LocationBloc, LocationState>(
      'emits LocationDetecting then LocationSelected with GPS location',
      build: () {
        when(() => mockRepo.detectCurrentLocation(any())).thenAnswer(
          (_) async => const LocationEntity(
            latitude: -11.70,
            longitude: 43.25,
            cityName: 'Current Location',
            isGpsLocation: true,
          ),
        );
        when(() => mockRepo.saveLastLocation(any())).thenAnswer((_) async {});
        when(() => mockRepo.loadFavorites()).thenReturn([]);
        return bloc;
      },
      act: (bloc) => bloc.add(const DetectCurrentLocationEvent()),
      expect: () => [
        isA<LocationDetecting>(),
        isA<LocationSelected>().having(
          (s) => s.location.isGpsLocation,
          'isGps',
          true,
        ),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'emits LocationError gpsPermissionDenied when permission denied',
      build: () {
        when(
          () => mockRepo.detectCurrentLocation(any()),
        ).thenThrow(const LocationPermissionDeniedException());
        return bloc;
      },
      act: (bloc) => bloc.add(const DetectCurrentLocationEvent()),
      expect: () => [
        isA<LocationDetecting>(),
        isA<LocationError>().having(
          (s) => s.errorCode,
          'code',
          LocationErrorCodes.gpsPermissionDenied,
        ),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'emits LocationError gpsPermissionPermanentlyDenied when denied forever',
      build: () {
        when(
          () => mockRepo.detectCurrentLocation(any()),
        ).thenThrow(const LocationPermissionPermanentlyDeniedException());
        return bloc;
      },
      act: (bloc) => bloc.add(const DetectCurrentLocationEvent()),
      expect: () => [
        isA<LocationDetecting>(),
        isA<LocationError>().having(
          (s) => s.errorCode,
          'code',
          LocationErrorCodes.gpsPermissionPermanentlyDenied,
        ),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'emits LocationError gpsDisabled when service is off',
      build: () {
        when(
          () => mockRepo.detectCurrentLocation(any()),
        ).thenThrow(const LocationServiceDisabledException());
        return bloc;
      },
      act: (bloc) => bloc.add(const DetectCurrentLocationEvent()),
      expect: () => [
        isA<LocationDetecting>(),
        isA<LocationError>().having(
          (s) => s.errorCode,
          'code',
          LocationErrorCodes.gpsDisabled,
        ),
      ],
    );
  });

  group('language propagation', () {
    blocTest<LocationBloc, LocationState>(
      'passes settings language to detectCurrentLocation',
      build: () {
        when(
          () => mockSettingRepo.loadSettings(),
        ).thenAnswer((_) async => const SettingEntity(lang: SettingLang.fr));
        when(() => mockRepo.detectCurrentLocation(any())).thenAnswer(
          (_) async => const LocationEntity(
            latitude: -11.70,
            longitude: 43.25,
            cityName: 'Current Location',
            isGpsLocation: true,
          ),
        );
        when(() => mockRepo.saveLastLocation(any())).thenAnswer((_) async {});
        when(() => mockRepo.loadFavorites()).thenReturn([]);
        return bloc;
      },
      act: (bloc) => bloc.add(const DetectCurrentLocationEvent()),
      expect: () => [isA<LocationDetecting>(), isA<LocationSelected>()],
      verify: (_) {
        verify(() => mockRepo.detectCurrentLocation('fr')).called(1);
      },
    );

    blocTest<LocationBloc, LocationState>(
      'passes settings language to searchLocations',
      build: () {
        when(
          () => mockSettingRepo.loadSettings(),
        ).thenAnswer((_) async => const SettingEntity(lang: SettingLang.fr));
        when(
          () => mockRepo.searchLocations(any(), any()),
        ).thenAnswer((_) async => [testLocation]);
        return bloc;
      },
      act: (bloc) => bloc.add(const SearchLocationsEvent('Paris')),
      expect: () => [isA<LocationSearchLoading>(), isA<LocationSearchLoaded>()],
      verify: (_) {
        verify(() => mockRepo.searchLocations('Paris', 'fr')).called(1);
      },
    );
  });

  group('OpenLocationSettingsEvent', () {
    blocTest<LocationBloc, LocationState>(
      'opens location settings through the repository',
      build: () {
        when(() => mockRepo.openLocationSettings()).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(const OpenLocationSettingsEvent()),
      expect: () => [isA<LocationWaitingForSettings>()],
      verify: (_) {
        verify(() => mockRepo.openLocationSettings()).called(1);
      },
    );
  });

  group('OpenAppSettingsEvent', () {
    blocTest<LocationBloc, LocationState>(
      'opens app settings through the repository',
      build: () {
        when(() => mockRepo.openAppSettings()).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(const OpenAppSettingsEvent()),
      expect: () => [isA<LocationWaitingForSettings>()],
      verify: (_) {
        verify(() => mockRepo.openAppSettings()).called(1);
      },
    );
  });

  group('App lifecycle resume retry', () {
    test(
      're-triggers detection when app resumes after opening location settings',
      () async {
        when(() => mockRepo.openLocationSettings()).thenAnswer((_) async {});
        when(() => mockRepo.detectCurrentLocation(any())).thenAnswer(
          (_) async => const LocationEntity(
            latitude: -11.70,
            longitude: 43.25,
            cityName: 'Current Location',
            isGpsLocation: true,
          ),
        );
        when(() => mockRepo.saveLastLocation(any())).thenAnswer((_) async {});
        when(() => mockRepo.loadFavorites()).thenReturn([]);

        bloc.add(const OpenLocationSettingsEvent());
        await pumpEventQueue();

        expect(bloc.state, isA<LocationWaitingForSettings>());

        bloc.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await pumpEventQueue();

        expect(bloc.state, isA<LocationSelected>());
        verify(() => mockRepo.detectCurrentLocation(any())).called(1);
      },
    );

    test(
      'does not re-trigger detection on resume when settings were not opened',
      () async {
        when(
          () => mockRepo.detectCurrentLocation(any()),
        ).thenThrow(const LocationServiceDisabledException());

        bloc.add(const DetectCurrentLocationEvent());
        await pumpEventQueue();
        expect(bloc.state, isA<LocationError>());

        bloc.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await pumpEventQueue();

        verify(() => mockRepo.detectCurrentLocation(any())).called(1);
      },
    );
  });
}
