import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/errors/app_error_code.dart';
import 'package:sky_line/core/errors/location_error_codes.dart';
import 'package:sky_line/core/errors/location_exceptions.dart';
import 'package:sky_line/core/errors/weather_error_codes.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/core/services/logger_services.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';
import 'package:sky_line/features/location/domain/repositories/location_repository.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';
import 'package:sky_line/features/location/presentation/utils/gps_error_feedback.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';
import 'package:sky_line/features/settings/domain/repositories/setting_repository.dart';

class MockRepository extends Mock implements LocationRepository {}

class MockLogger extends Mock implements AppLogger {}

class MockSettingRepository extends Mock implements SettingRepository {}

void main() {
  late MockRepository repo;
  late LocationBloc bloc;

  setUpAll(() {
    registerFallbackValue(
      const LocationEntity(latitude: 0, longitude: 0, cityName: ''),
    );
    registerFallbackValue(const SettingEntity());
  });

  setUp(() {
    repo = MockRepository();
    final mockSettingRepo = MockSettingRepository();
    when(
      () => mockSettingRepo.loadSettings(),
    ).thenAnswer((_) async => const SettingEntity());
    bloc = LocationBloc(
      logger: MockLogger(),
      repository: repo,
      settingRepository: mockSettingRepo,
    );
    addTearDown(bloc.close);
  });

  Future<void> pumpFeedback(WidgetTester tester, AppErrorCode code) async {
    await tester.pumpWidget(
      BlocProvider<LocationBloc>.value(
        value: bloc,
        child: MaterialApp(
          supportedLocales: AppLocalisation.supportedLocales,
          localizationsDelegates: AppLocalisation.localizationsDelegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: Builder(
                builder: (innerContext) => ElevatedButton(
                  onPressed: () => showGpsErrorSnackBar(innerContext, code),
                  child: const Text('trigger'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();
  }

  group('isGpsError', () {
    test('returns true for gpsDisabled', () {
      expect(isGpsError(LocationErrorCodes.gpsDisabled), isTrue);
    });

    test('returns true for gpsPermissionDenied', () {
      expect(isGpsError(LocationErrorCodes.gpsPermissionDenied), isTrue);
    });

    test('returns true for gpsPermissionPermanentlyDenied', () {
      expect(
        isGpsError(LocationErrorCodes.gpsPermissionPermanentlyDenied),
        isTrue,
      );
    });

    test('returns true for gpsFailed', () {
      expect(isGpsError(LocationErrorCodes.gpsFailed), isTrue);
    });

    test('returns false for a weather error code', () {
      expect(isGpsError(WeatherErrorCodes.network), isFalse);
    });

    test('returns false for a non-GPS location error code', () {
      expect(isGpsError(LocationErrorCodes.searchFailed), isFalse);
    });
  });

  group('showGpsErrorSnackBar', () {
    testWidgets('shows localized message and Enable action for gpsDisabled', (
      tester,
    ) async {
      when(() => repo.openLocationSettings()).thenAnswer((_) async {});

      await pumpFeedback(tester, LocationErrorCodes.gpsDisabled);

      expect(find.text('Location services are turned off.'), findsOneWidget);
      expect(find.byType(SnackBarAction), findsOneWidget);
      expect(find.text('Enable'), findsOneWidget);

      await tester.tap(find.text('Enable'));
      await tester.pumpAndSettle();

      verify(() => repo.openLocationSettings()).called(1);
    });

    testWidgets(
      'shows localized message and Retry action for gpsPermissionDenied',
      (tester) async {
        when(
          () => repo.detectCurrentLocation(any()),
        ).thenThrow(const LocationPermissionDeniedException());

        await pumpFeedback(tester, LocationErrorCodes.gpsPermissionDenied);

        expect(
          find.text(
            'Location permission is required to get your current location.',
          ),
          findsOneWidget,
        );
        expect(find.byType(SnackBarAction), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        await tester.tap(find.text('Retry'));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pumpAndSettle();

        verify(() => repo.detectCurrentLocation(any())).called(1);
      },
    );

    testWidgets(
      'shows localized message and Settings action for gpsPermissionPermanentlyDenied',
      (tester) async {
        when(() => repo.openAppSettings()).thenAnswer((_) async {});

        await pumpFeedback(
          tester,
          LocationErrorCodes.gpsPermissionPermanentlyDenied,
        );

        expect(
          find.text(
            'Location permission is permanently denied. Please enable it in Settings.',
          ),
          findsOneWidget,
        );
        expect(find.byType(SnackBarAction), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);

        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();

        verify(() => repo.openAppSettings()).called(1);
      },
    );

    testWidgets('shows localized message with no action for gpsFailed', (
      tester,
    ) async {
      await pumpFeedback(tester, LocationErrorCodes.gpsFailed);

      expect(
        find.text('Could not get your location. Please check permissions.'),
        findsOneWidget,
      );
      expect(find.byType(SnackBarAction), findsNothing);
    });
  });
}
