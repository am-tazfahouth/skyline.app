import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/config/app_routes.dart';
import 'package:sky_line/core/errors/location_exceptions.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/core/services/logger_services.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';
import 'package:sky_line/features/location/domain/repositories/location_repository.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_event.dart';
import 'package:sky_line/features/location/presentation/screens/location_screen.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';
import 'package:sky_line/features/settings/domain/repositories/setting_repository.dart';

class MockRepository extends Mock implements LocationRepository {}

class MockLogger extends Mock implements AppLogger {}

class MockSettingRepository extends Mock implements SettingRepository {}

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
    registerFallbackValue(const SettingEntity());
  });

  setUp(() {
    repo = MockRepository();
  });

  LocationBloc createBloc() {
    final mockSettingRepo = MockSettingRepository();
    when(() => mockSettingRepo.loadSettings()).thenAnswer((_) async => const SettingEntity());
    final bloc = LocationBloc(logger: MockLogger(), repository: repo, settingRepository: mockSettingRepo);
    addTearDown(bloc.close);
    return bloc;
  }

  Future<void> pumpLocationScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider<LocationBloc>.value(
        value: bloc,
        child: MaterialApp(
          onGenerateRoute: RouteGenerator.generateRoute,
          supportedLocales: AppLocalisation.supportedLocales,
          localizationsDelegates: AppLocalisation.localizationsDelegates,
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
    bloc = createBloc();
    await pumpLocationScreen(tester);

    expect(find.text('Location'), findsOneWidget);
    expect(find.text('No favorites yet'), findsOneWidget);
  });

  testWidgets('renders favorite locations', (tester) async {
    bloc = createBloc();
    when(() => repo.loadFavorites()).thenReturn([paris]);
    when(() => repo.loadLastLocation()).thenReturn(null);
    bloc.add(const LoadFavoritesEvent());

    await pumpLocationScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('Paris'), findsOneWidget);
  });

  testWidgets('FAB navigates to LocationSearchScreen', (tester) async {
    bloc = createBloc();
    await pumpLocationScreen(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Search city...'), findsOneWidget);
  });

  testWidgets('GPS action dispatches DetectCurrentLocationEvent', (tester) async {
    bloc = createBloc();
    when(() => repo.loadFavorites()).thenReturn([]);
    when(() => repo.detectCurrentLocation(any())).thenAnswer((_) async => gps);
    when(() => repo.saveLastLocation(any())).thenAnswer((_) async {});
    when(() => repo.saveFavorite(any())).thenAnswer((_) async {});

    await pumpLocationScreen(tester);
    await tester.tap(find.byIcon(Icons.my_location_rounded));
    await tester.pumpAndSettle();

    verify(() => repo.detectCurrentLocation(any())).called(1);
  });

  testWidgets('GPS selection adds favorite and pops', (tester) async {
    bloc = createBloc();
    when(() => repo.loadFavorites()).thenReturn([]);
    when(() => repo.detectCurrentLocation(any())).thenAnswer((_) async => gps);
    when(() => repo.saveLastLocation(any())).thenAnswer((_) async {});
    when(() => repo.saveFavorite(any())).thenAnswer((_) async {});

    await pumpLocationScreen(tester);
    await tester.tap(find.byIcon(Icons.my_location_rounded));
    await tester.pumpAndSettle();

    verify(() => repo.saveFavorite(gps)).called(1);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('non-GPS selection pops without adding favorite', (tester) async {
    bloc = createBloc();
    when(() => repo.loadFavorites()).thenReturn([]);
    when(() => repo.saveLastLocation(any())).thenAnswer((_) async {});

    await pumpLocationScreen(tester);
    bloc.add(const SelectLocationEvent(location: paris));
    await tester.pumpAndSettle();

    verifyNever(() => repo.saveFavorite(any()));
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('favorite tap dispatches SelectLocationEvent', (tester) async {
    bloc = createBloc();
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

  testWidgets('reopening the picker allows re-selecting the same favorite',
      (tester) async {
    bloc = createBloc();
    when(() => repo.loadFavorites()).thenReturn([paris]);
    when(() => repo.loadLastLocation()).thenReturn(null);
    when(() => repo.saveLastLocation(any())).thenAnswer((_) async {});

    // First visit: select Paris and pop back to the previous screen.
    await pumpLocationScreen(tester);
    bloc.add(const LoadFavoritesEvent());
    await tester.pumpAndSettle();
    expect(find.text('Paris'), findsOneWidget);
    await tester.tap(find.text('Paris'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);

    // Second visit: the bloc still holds LocationSelected(paris), so
    // re-emitting it must not be swallowed as a duplicate state.
    await pumpLocationScreen(tester);
    await tester.pumpAndSettle();
    expect(find.text('Paris'), findsOneWidget);
    await tester.tap(find.text('Paris'));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('GPS error keeps the favorites list visible', (tester) async {
    bloc = createBloc();
    when(() => repo.loadFavorites()).thenReturn([paris]);
    when(() => repo.loadLastLocation()).thenReturn(null);
    when(() => repo.detectCurrentLocation(any())).thenThrow(Exception('gps failed'));
    bloc.add(const LoadFavoritesEvent());

    await pumpLocationScreen(tester);
    await tester.pumpAndSettle();
    expect(find.text('Paris'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.my_location_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Paris'), findsOneWidget);
    expect(find.text('No favorites yet'), findsNothing);
  });

  testWidgets('GPS error shows a SnackBar', (tester) async {
    bloc = createBloc();
    when(() => repo.loadFavorites()).thenReturn([]);
    when(() => repo.detectCurrentLocation(any())).thenThrow(Exception('gps failed'));

    await pumpLocationScreen(tester);
    await tester.tap(find.byIcon(Icons.my_location_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('service disabled SnackBar offers Enable action opening location settings',
      (tester) async {
    bloc = createBloc();
    when(() => repo.loadFavorites()).thenReturn([]);
    when(() => repo.detectCurrentLocation(any()))
        .thenThrow(const LocationServiceDisabledException());
    when(() => repo.openLocationSettings()).thenAnswer((_) async {});

    await pumpLocationScreen(tester);
    await tester.tap(find.byIcon(Icons.my_location_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Location services are turned off.'), findsOneWidget);
    await tester.tap(find.text('Enable'));
    await tester.pumpAndSettle();

    verify(() => repo.openLocationSettings()).called(1);
  });

  testWidgets('permanently denied SnackBar offers Settings action opening app settings',
      (tester) async {
    bloc = createBloc();
    when(() => repo.loadFavorites()).thenReturn([]);
    when(() => repo.detectCurrentLocation(any()))
        .thenThrow(const LocationPermissionPermanentlyDeniedException());
    when(() => repo.openAppSettings()).thenAnswer((_) async {});

    await pumpLocationScreen(tester);
    await tester.tap(find.byIcon(Icons.my_location_rounded));
    await tester.pumpAndSettle();

    expect(
      find.text('Location permission is permanently denied. Please enable it in Settings.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    verify(() => repo.openAppSettings()).called(1);
  });

  testWidgets('permission denied SnackBar offers Retry action re-detecting location',
      (tester) async {
    bloc = createBloc();
    when(() => repo.loadFavorites()).thenReturn([]);
    when(() => repo.detectCurrentLocation(any()))
        .thenThrow(const LocationPermissionDeniedException());

    await pumpLocationScreen(tester);
    await tester.tap(find.byIcon(Icons.my_location_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Location permission is required to get your current location.'),
        findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    verify(() => repo.detectCurrentLocation(any())).called(2);
  });
}
