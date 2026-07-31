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

  setUpAll(() {
    registerFallbackValue(const LocationEntity(
      latitude: 0,
      longitude: 0,
      cityName: '',
    ));
  });

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

  group('ReorderFavoritesEvent', () {
    const locationA = LocationEntity(latitude: 1.0, longitude: 1.0, cityName: 'A');
    const locationB = LocationEntity(latitude: 2.0, longitude: 2.0, cityName: 'B');
    const locationC = LocationEntity(latitude: 3.0, longitude: 3.0, cityName: 'C');

    blocTest<LocationBloc, LocationState>(
      'reorders favorites within bounds',
      build: () {
        when(() => mockRepo.loadFavorites()).thenReturn([locationA, locationB, locationC]);
        when(() => mockRepo.saveAllFavorites(any())).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(const ReorderFavoritesEvent(oldIndex: 0, newIndex: 2)),
      expect: () => [isA<LocationFavoritesLoaded>()],
      verify: (_) {
        final captured = verify(() => mockRepo.saveAllFavorites(captureAny())).captured.single as List;
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
      act: (bloc) => bloc.add(const ReorderFavoritesEvent(oldIndex: 5, newIndex: 0)),
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
      act: (bloc) => bloc.add(const ReorderFavoritesEvent(oldIndex: 0, newIndex: 5)),
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
