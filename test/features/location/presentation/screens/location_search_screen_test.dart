import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/errors/location_exceptions.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/core/services/logger_sevices.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';
import 'package:sky_line/features/location/domain/repositories/location_repository.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_event.dart';
import 'package:sky_line/features/location/presentation/blocs/location_state.dart';
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

  void createBloc() {
    repo = MockRepository();
    bloc = LocationBloc(logger: MockLogger(), repository: repo);
    addTearDown(bloc.close);
  }

  Future<void> pushSearchScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider<LocationBloc>.value(
        value: bloc,
        child: MaterialApp(
          supportedLocales: AppLocalisation.supportedLocales,
          localizationsDelegates: AppLocalisation.localizationsDelegates,
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
    await tester.pumpAndSettle();
  }

  Future<void> pumpSearchResults(WidgetTester tester) async {
    when(() => repo.searchLocations(any())).thenAnswer((_) async => [paris]);
    await pushSearchScreen(tester);
    bloc.add(const SearchLocationsEvent('par'));
    await tester.pumpAndSettle();
  }

  testWidgets('tapping a result adds it to favorites then selects it',
      (tester) async {
    createBloc();
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
    createBloc();
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

  testWidgets('GPS error state does not leak onto the search screen',
      (tester) async {
    createBloc();
    when(() => repo.loadFavorites()).thenReturn([]);
    when(() => repo.detectCurrentLocation())
        .thenThrow(const LocationServiceDisabledException());

    bloc.add(const DetectCurrentLocationEvent());
    await tester.pumpAndSettle();
    expect(bloc.state, isA<LocationError>());

    await pushSearchScreen(tester);

    expect(find.text('Location services are turned off.'), findsNothing);
    expect(find.text('Type to search for a city'), findsOneWidget);
  });

  testWidgets('search failure renders error message centered', (tester) async {
    createBloc();
    when(() => repo.searchLocations(any())).thenThrow(Exception('fail'));

    await pushSearchScreen(tester);
    bloc.add(const SearchLocationsEvent('par'));
    await tester.pumpAndSettle();

    expect(find.text('Could not search cities. Please try again.'), findsOneWidget);
  });
}
