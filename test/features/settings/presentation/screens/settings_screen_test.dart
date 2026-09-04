import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/enums/setting_heat_unit.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/core/services/logger_services.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';
import 'package:sky_line/features/settings/domain/repositories/setting_repository.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_event.dart';
import 'package:sky_line/features/settings/presentation/screens/settings_screen.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/current_weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/daily_weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/hourly_weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/weather_result.dart';
import 'package:sky_line/features/weather_forecast/domain/repositories/weather_repository.dart';
import 'package:sky_line/features/weather_forecast/domain/usecases/get_settings_use_case.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_event.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_state.dart';

class MockSettingRepository extends Mock implements SettingRepository {}

class MockAppLogger extends Mock implements AppLogger {}

class MockWeatherRepository extends Mock implements WeatherRepository {}

class MockGetSettingsUseCase extends Mock implements GetSettingsUseCase {}

FutureOr<({double latitude, double longitude})?> _defaultLastLocation() => (latitude: 0.0, longitude: 0.0);

Widget createTestScreen(SettingsBloc bloc, WeatherForecastBloc weatherBloc) {
  return MaterialApp(
    theme: AppTheme(ThemeData().textTheme).light(),
    localizationsDelegates: AppLocalisation.localizationsDelegates,
    supportedLocales: AppLocalisation.supportedLocales,
    home: MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>.value(value: bloc),
        BlocProvider<WeatherForecastBloc>.value(value: weatherBloc),
      ],
      child: const SettingsScreen(),
    ),
  );
}

WeatherForecastBloc _buildWeatherBloc() {
  final repository = MockWeatherRepository();
  when(() => repository.loadCachedWeather(
    latitude: any(named: 'latitude'),
    longitude: any(named: 'longitude'),
  ))
      .thenAnswer((_) async => _weatherResult(cached: true));
  final getSettings = MockGetSettingsUseCase();
  when(() => getSettings()).thenAnswer((_) async => SettingEntity.defaults);
  return WeatherForecastBloc(
    logger: MockAppLogger(),
    weatherRepository: repository,
    getSettings: getSettings,
    getLastLocation: _defaultLastLocation,
    isConnected: () async => false,
  );
}

WeatherResult _weatherResult({required bool cached}) {
  return WeatherResult(
    weather: WeatherEntity(
      current: const CurrentWeatherEntity(
        temperature: 28.0,
        humidity: 65,
        isDay: true,
        windSpeed: 12.0,
        precipitation: 0.0,
        weatherCode: 51,
      ),
      hourly: [
        HourlyWeatherEntity(
          time: DateTime(2026, 5, 16, 12, 0),
          temperature: 28.0,
          precipitationProbability: 10,
          weatherCode: 0,
        ),
      ],
      daily: [
        DailyWeatherEntity(
          date: DateTime(2026, 5, 16),
          tempMax: 29.0,
          tempMin: 23.0,
          weatherCode: 51,
          sunrise: DateTime(2026, 5, 16, 3, 16),
          sunset: DateTime(2026, 5, 16, 14, 50),
        ),
      ],
    ),
    isCached: cached,
  );
}

void main() {
  late MockSettingRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(const SettingEntity());
  });

  setUp(() {
    mockRepository = MockSettingRepository();
    when(() => mockRepository.loadSettings()).thenAnswer(
      (_) async => SettingEntity.defaults,
    );
    when(() => mockRepository.saveSettings(any())).thenAnswer((_) async {});
  });

  testWidgets('should display settings title', (tester) async {
    final bloc = SettingsBloc(logger: MockAppLogger(), repository: mockRepository);
    bloc.add(const LoadSettingsEvent());
    await tester.pumpWidget(createTestScreen(bloc, _buildWeatherBloc()));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('should display all setting tiles', (tester) async {
    final bloc = SettingsBloc(logger: MockAppLogger(), repository: mockRepository);
    bloc.add(const LoadSettingsEvent());
    await tester.pumpWidget(createTestScreen(bloc, _buildWeatherBloc()));
    await tester.pumpAndSettle();

    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Wind Unit'), findsOneWidget);
    expect(find.text('Temperature Unit'), findsOneWidget);
  });

  testWidgets('should display setting descriptions', (tester) async {
    final bloc = SettingsBloc(logger: MockAppLogger(), repository: mockRepository);
    bloc.add(const LoadSettingsEvent());
    await tester.pumpWidget(createTestScreen(bloc, _buildWeatherBloc()));
    await tester.pumpAndSettle();

    expect(find.text('Choose the theme of the application'), findsOneWidget);
    expect(find.text('Choose the language of the application'), findsOneWidget);
    expect(find.text('Choose the unit of measurement for wind'), findsOneWidget);
    expect(find.text('Choose the unit of measurement of the temperature'), findsOneWidget);
  });

  testWidgets('should display app version from the settings bloc', (tester) async {
    final bloc = SettingsBloc(
      logger: MockAppLogger(),
      repository: mockRepository,
      getAppVersion: () async => '1.2.3',
    );
    bloc.add(const LoadSettingsEvent());
    await tester.pumpWidget(createTestScreen(bloc, _buildWeatherBloc()));
    await tester.pumpAndSettle();

    expect(find.text('App version: 1.2.3'), findsOneWidget);
  });

  testWidgets('should propagate updated settings to the weather bloc', (tester) async {
    final bloc = SettingsBloc(logger: MockAppLogger(), repository: mockRepository);
    bloc.add(const LoadSettingsEvent());
    final weatherBloc = _buildWeatherBloc();
    weatherBloc.add(const FetchWeatherEvent());

    await tester.pumpWidget(createTestScreen(bloc, weatherBloc));
    await tester.pumpAndSettle();

    expect(weatherBloc.state, isA<WeatherLoaded>());

    bloc.add(const UpdateSettingsEvent(
      setting: SettingEntity(heatUnit: SettingHeatUnit.fahrenheit),
    ));
    await tester.pumpAndSettle();

    final state = weatherBloc.state;
    expect(state, isA<WeatherLoaded>());
    expect(
      (state as WeatherLoaded).settings.heatUnit,
      SettingHeatUnit.fahrenheit,
    );
  });
}
