import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/config/app_routes.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/core/services/logger_sevices.dart';
import 'package:sky_line/features/location/domain/repositories/location_repository.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_onboarding_bloc.dart';
import 'package:sky_line/features/location/presentation/screens/location_screen.dart';
import 'package:sky_line/features/location/presentation/screens/location_search_screen.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';
import 'package:sky_line/features/settings/domain/repositories/setting_repository.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:sky_line/features/settings/presentation/screens/settings_screen.dart';
import 'package:sky_line/features/weather_forecast/domain/repositories/weather_repository.dart';
import 'package:sky_line/features/weather_forecast/domain/usecases/get_settings_use_case.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/screens/weather_screen.dart';

class MockLocationRepository extends Mock implements LocationRepository {}

class MockWeatherRepository extends Mock implements WeatherRepository {}

class MockSettingRepository extends Mock implements SettingRepository {}

class MockAppLogger extends Mock implements AppLogger {}

class MockGetSettingsUseCase extends Mock implements GetSettingsUseCase {}

FutureOr<({double latitude, double longitude})?> _defaultLastLocation() => (latitude: 0.0, longitude: 0.0);

void main() {
  late MockLocationRepository locationRepo;
  late MockWeatherRepository weatherRepo;
  late MockSettingRepository settingRepo;
  late MockAppLogger logger;
  late MockGetSettingsUseCase getSettings;

  setUp(() {
    locationRepo = MockLocationRepository();
    weatherRepo = MockWeatherRepository();
    settingRepo = MockSettingRepository();
    logger = MockAppLogger();
    getSettings = MockGetSettingsUseCase();

    when(() => locationRepo.loadFavorites()).thenReturn([]);
    when(() => locationRepo.hasSeenLocationOnboarding())
        .thenAnswer((_) async => true);
    when(() => weatherRepo.loadCachedWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    )).thenAnswer((_) async => null);
    when(() => getSettings()).thenAnswer((_) async => SettingEntity.defaults);
    when(() => settingRepo.loadSettings())
        .thenAnswer((_) async => SettingEntity.defaults);
  });

  Widget wrap(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LocationBloc>(
          create: (_) =>
              LocationBloc(logger: logger, repository: locationRepo, settingRepository: settingRepo),
        ),
        BlocProvider<WeatherForecastBloc>(
          create: (_) => WeatherForecastBloc(
            logger: logger,
            weatherRepository: weatherRepo,
            getSettings: getSettings,
            getLastLocation: _defaultLastLocation,
            isConnected: () async => true,
          ),
        ),
        BlocProvider<SettingsBloc>(
          create: (_) => SettingsBloc(logger: logger, repository: settingRepo),
        ),
        BlocProvider<LocationOnboardingBloc>(
          create: (_) => LocationOnboardingBloc(
            logger: logger,
            repository: locationRepo,
          ),
        ),
      ],
      child: child,
    );
  }

  Future<void> pumpRoute(WidgetTester tester, String routeName) async {
    await tester.pumpWidget(
      wrap(
        MaterialApp(
          theme: AppTheme(ThemeData().textTheme).light(),
          localizationsDelegates: AppLocalisation.localizationsDelegates,
          supportedLocales: AppLocalisation.supportedLocales,
          initialRoute: routeName,
          onGenerateRoute: RouteGenerator.generateRoute,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('weather route builds WeatherScreen', (tester) async {
    await pumpRoute(tester, AppRoutes.weather);

    expect(find.byType(WeatherScreen), findsOneWidget);
  });

  testWidgets('location route builds LocationScreen', (tester) async {
    await pumpRoute(tester, AppRoutes.location);

    expect(find.byType(LocationScreen), findsOneWidget);
  });

  testWidgets('locationSearch route builds LocationSearchScreen',
      (tester) async {
    await pumpRoute(tester, AppRoutes.locationSearch);

    expect(find.byType(LocationSearchScreen), findsOneWidget);
  });

  testWidgets('settings route builds SettingsScreen', (tester) async {
    await pumpRoute(tester, AppRoutes.settings);

    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('unknown route falls back to WeatherScreen', (tester) async {
    await pumpRoute(tester, '/unknown');

    expect(find.byType(WeatherScreen), findsOneWidget);
  });

  testWidgets('null route name falls back to WeatherScreen', (tester) async {
    await tester.pumpWidget(
      wrap(
        MaterialApp(
          theme: AppTheme(ThemeData().textTheme).light(),
          localizationsDelegates: AppLocalisation.localizationsDelegates,
          supportedLocales: AppLocalisation.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    RouteGenerator.generateRoute(
                      const RouteSettings(name: null),
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

    expect(find.byType(WeatherScreen), findsOneWidget);
  });
}
