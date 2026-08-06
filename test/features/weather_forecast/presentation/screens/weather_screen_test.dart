import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/config/app_routes.dart';
import 'package:sky_line/core/enums/setting_heat_unit.dart';
import 'package:sky_line/core/enums/setting_wind_unit.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/core/services/logger_sevices.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';
import 'package:sky_line/features/settings/domain/repositories/setting_repository.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_bloc.dart';
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
import 'package:sky_line/features/weather_forecast/presentation/screens/weather_screen.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';
import 'package:sky_line/features/location/domain/repositories/location_repository.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_event.dart';

class MockWeatherRepository extends Mock implements WeatherRepository {}

class MockAppLogger extends Mock implements AppLogger {}

class MockGetSettingsUseCase extends Mock implements GetSettingsUseCase {}

class MockSettingRepository extends Mock implements SettingRepository {}

class MockLocationRepository extends Mock implements LocationRepository {}

const _defaultSettings = SettingEntity(
  windUnit: SettingWindUnit.ms,
  heatUnit: SettingHeatUnit.celsius,
);

Widget createTestScreen(
  WeatherForecastBloc bloc, {
  LocationBloc? locationBloc,
  Locale locale = const Locale('en'),
}) {
  final locBloc = locationBloc ??
      LocationBloc(logger: MockAppLogger(), repository: MockLocationRepository());
  return MultiBlocProvider(
    providers: [
      BlocProvider<WeatherForecastBloc>.value(value: bloc),
      BlocProvider<SettingsBloc>(
        create: (_) => SettingsBloc(
          logger: MockAppLogger(),
          repository: MockSettingRepository(),
        ),
      ),
      BlocProvider<LocationBloc>.value(value: locBloc),
    ],
    child: MaterialApp(
      onGenerateRoute: RouteGenerator.generateRoute,
      locale: locale,
      supportedLocales: AppLocalisation.supportedLocales,
      localizationsDelegates: AppLocalisation.localizationsDelegates,
      home: const WeatherScreen(),
    ),
  );
}

void main() {
  late MockWeatherRepository mockRepository;
  late MockGetSettingsUseCase mockGetSettings;

  const paris = LocationEntity(
    latitude: 48.85,
    longitude: 2.35,
    cityName: 'Paris',
    country: 'France',
  );

  WeatherResult buildWeatherResult() {
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
        hourly: [],
        daily: [],
      ),
      isCached: false,
    );
  }

  setUpAll(() {
    registerFallbackValue(const LocationEntity(latitude: 0, longitude: 0, cityName: ''));
  });

  setUp(() {
    mockRepository = MockWeatherRepository();
    mockGetSettings = MockGetSettingsUseCase();
    when(() => mockGetSettings()).thenAnswer((_) async => _defaultSettings);
    when(() => mockRepository.loadCachedWeather())
        .thenAnswer((_) async => null);
  });

  testWidgets('shows loading overlay when fetching', (tester) async {
    final completer = Completer<WeatherResult>();
    when(() => mockRepository.fetchWeather(latitude: any(named: 'latitude'), longitude: any(named: 'longitude')))
        .thenAnswer((_) => completer.future);

    final bloc = WeatherForecastBloc(
      logger: MockAppLogger(),
      weatherRepository: mockRepository,
      getSettings: mockGetSettings,
      isConnected: () async => true,
    );
    bloc.add(const FetchWeatherEvent());
    await tester.pumpWidget(createTestScreen(bloc));
    await tester.pump();

    expect(find.byKey(const Key('loading_indicator')), findsOneWidget);

    completer.complete(WeatherResult(
      weather: WeatherEntity(
        current: const CurrentWeatherEntity(
          temperature: 0,
          humidity: 0,
          isDay: true,
          windSpeed: 0,
          precipitation: 0,
          weatherCode: 0,
        ),
        hourly: [],
        daily: [],
      ),
      isCached: false,
    ));
    await tester.pumpAndSettle();
  });

  testWidgets('shows weather data on loaded state', (tester) async {
    final weather = WeatherEntity(
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
    );

    when(() => mockRepository.fetchWeather(latitude: any(named: 'latitude'), longitude: any(named: 'longitude')))
        .thenAnswer((_) async => WeatherResult(weather: weather, isCached: false));

    final bloc = WeatherForecastBloc(
      logger: MockAppLogger(),
      weatherRepository: mockRepository,
      getSettings: mockGetSettings,
      isConnected: () async => true,
    );
    bloc.add(const FetchWeatherEvent());
    await tester.pumpWidget(createTestScreen(bloc));
    await tester.pumpAndSettle();

    expect(find.text('28°C'), findsOneWidget);
    expect(find.text('12 m/s'), findsOneWidget);
    expect(find.text('65%'), findsOneWidget);
    expect(find.text('SkyLine'), findsOneWidget);
  });

  testWidgets('shows localized weather content in French', (tester) async {
    final now = DateTime.now();
    final weather = WeatherEntity(
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
          time: now.add(const Duration(hours: 1)),
          temperature: 28.0,
          precipitationProbability: 10,
          weatherCode: 0,
        ),
      ],
      daily: [
        DailyWeatherEntity(
          date: now,
          tempMax: 29.0,
          tempMin: 23.0,
          weatherCode: 51,
          sunrise: DateTime(now.year, now.month, now.day, 3, 16),
          sunset: DateTime(now.year, now.month, now.day, 14, 50),
        ),
      ],
    );

    when(() => mockRepository.fetchWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    )).thenAnswer((_) async => WeatherResult(weather: weather, isCached: false));

    final bloc = WeatherForecastBloc(
      logger: MockAppLogger(),
      weatherRepository: mockRepository,
      getSettings: mockGetSettings,
      isConnected: () async => true,
    );
    bloc.add(const FetchWeatherEvent());
    await tester.pumpWidget(createTestScreen(bloc, locale: const Locale('fr')));
    await tester.pumpAndSettle();

    expect(find.text('Vent'), findsOneWidget);
    expect(find.text('Risque de pluie'), findsOneWidget);
    expect(find.text('Humidité'), findsOneWidget);
    expect(find.text('Prévisions horaires'), findsOneWidget);
    expect(find.text('7 prochains jours'), findsOneWidget);
    expect(find.text('Aujourd\'hui'), findsOneWidget);
    expect(find.text('Bruine'), findsWidgets);
  });

  testWidgets('shows error view on error state', (tester) async {
    when(() => mockRepository.fetchWeather(latitude: any(named: 'latitude'), longitude: any(named: 'longitude')))
        .thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionError,
        ));

    final bloc = WeatherForecastBloc(
      logger: MockAppLogger(),
      weatherRepository: mockRepository,
      getSettings: mockGetSettings,
      isConnected: () async => true,
    );
    bloc.add(const FetchWeatherEvent());
    await tester.pumpWidget(createTestScreen(bloc));
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('header shows the selected location title', (tester) async {
    when(() => mockRepository.fetchWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    )).thenAnswer((_) async => buildWeatherResult());

    final locationRepo = MockLocationRepository();
    when(() => locationRepo.saveLastLocation(any())).thenAnswer((_) async {});
    when(() => locationRepo.loadFavorites()).thenReturn([]);
    final locationBloc = LocationBloc(
      logger: MockAppLogger(),
      repository: locationRepo,
    );

    final bloc = WeatherForecastBloc(
      logger: MockAppLogger(),
      weatherRepository: mockRepository,
      getSettings: mockGetSettings,
      isConnected: () async => true,
    );
    bloc.add(const FetchWeatherEvent());
    await tester.pumpWidget(createTestScreen(bloc, locationBloc: locationBloc));
    await tester.pumpAndSettle();

    locationBloc.add(const SelectLocationEvent(location: paris));
    await tester.pumpAndSettle();

    expect(find.text('Paris, France'), findsOneWidget);
  });

  testWidgets('grid icon navigates to LocationScreen', (tester) async {
    when(() => mockRepository.fetchWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    )).thenAnswer((_) async => buildWeatherResult());

    final bloc = WeatherForecastBloc(
      logger: MockAppLogger(),
      weatherRepository: mockRepository,
      getSettings: mockGetSettings,
      isConnected: () async => true,
    );
    bloc.add(const FetchWeatherEvent());
    await tester.pumpWidget(createTestScreen(bloc));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Location'), findsOneWidget);
  });

  testWidgets('LocationSelected triggers weather fetch for coordinates',
      (tester) async {
    when(() => mockRepository.fetchWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    )).thenAnswer((_) async => buildWeatherResult());

    final locationRepo = MockLocationRepository();
    when(() => locationRepo.saveLastLocation(any())).thenAnswer((_) async {});
    when(() => locationRepo.loadFavorites()).thenReturn([]);
    final locationBloc = LocationBloc(
      logger: MockAppLogger(),
      repository: locationRepo,
    );

    final bloc = WeatherForecastBloc(
      logger: MockAppLogger(),
      weatherRepository: mockRepository,
      getSettings: mockGetSettings,
      isConnected: () async => true,
    );
    bloc.add(const FetchWeatherEvent());
    await tester.pumpWidget(createTestScreen(bloc, locationBloc: locationBloc));
    await tester.pumpAndSettle();

    locationBloc.add(const SelectLocationEvent(location: paris));
    await tester.pumpAndSettle();

    verify(
      () => mockRepository.fetchWeather(latitude: 48.85, longitude: 2.35),
    ).called(1);
  });

  testWidgets('clearing the current location resets weather to the empty fallback',
      (tester) async {
    when(() => mockRepository.fetchWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    )).thenAnswer((_) async => buildWeatherResult());
    when(() => mockRepository.clearCachedWeather()).thenAnswer((_) async {});

    final locationRepo = MockLocationRepository();
    var favorites = [paris];
    when(() => locationRepo.loadFavorites()).thenAnswer((_) => favorites);
    when(() => locationRepo.loadLastLocation()).thenReturn(paris);
    when(() => locationRepo.removeFavorite(any())).thenAnswer((_) async {
      favorites = [];
    });
    when(() => locationRepo.clearLastLocation()).thenAnswer((_) async {});
    final locationBloc = LocationBloc(
      logger: MockAppLogger(),
      repository: locationRepo,
    );
    locationBloc.add(const LoadFavoritesEvent());

    final bloc = WeatherForecastBloc(
      logger: MockAppLogger(),
      weatherRepository: mockRepository,
      getSettings: mockGetSettings,
      isConnected: () async => true,
    );
    bloc.add(const FetchWeatherEvent());
    await tester.pumpWidget(createTestScreen(bloc, locationBloc: locationBloc));
    await tester.pumpAndSettle();
    expect(bloc.state, isA<WeatherLoaded>());

    locationBloc.add(const RemoveFavoriteEvent(location: paris));
    await tester.pumpAndSettle();

    expect(bloc.state, isA<WeatherEmpty>());
  });

  testWidgets('GPS failure does not reset the loaded weather', (tester) async {
    when(() => mockRepository.fetchWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    )).thenAnswer((_) async => buildWeatherResult());
    when(() => mockRepository.clearCachedWeather()).thenAnswer((_) async {});

    final locationRepo = MockLocationRepository();
    when(() => locationRepo.loadFavorites()).thenReturn([paris]);
    when(() => locationRepo.loadLastLocation()).thenReturn(paris);
    when(() => locationRepo.detectCurrentLocation()).thenThrow(Exception('fail'));
    final locationBloc = LocationBloc(
      logger: MockAppLogger(),
      repository: locationRepo,
    );
    locationBloc.add(const LoadFavoritesEvent());

    final bloc = WeatherForecastBloc(
      logger: MockAppLogger(),
      weatherRepository: mockRepository,
      getSettings: mockGetSettings,
      isConnected: () async => true,
    );
    bloc.add(const FetchWeatherEvent());
    await tester.pumpWidget(createTestScreen(bloc, locationBloc: locationBloc));
    await tester.pumpAndSettle();
    expect(bloc.state, isA<WeatherLoaded>());

    locationBloc.add(const DetectCurrentLocationEvent());
    await tester.pumpAndSettle();

    expect(bloc.state, isA<WeatherLoaded>());
    expect(bloc.state, isNot(isA<WeatherEmpty>()));
  });
}
