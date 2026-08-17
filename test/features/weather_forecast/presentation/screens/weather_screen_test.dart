import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/config/app_routes.dart';
import 'package:sky_line/core/enums/setting_heat_unit.dart';
import 'package:sky_line/core/enums/setting_wind_unit.dart';
import 'package:sky_line/core/errors/location_exceptions.dart';
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
import 'package:sky_line/features/location/presentation/blocs/location_onboarding_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_onboarding_event.dart';
import 'package:sky_line/features/location/presentation/widgets/location_onboarding_sheet.dart';

class MockWeatherRepository extends Mock implements WeatherRepository {}

class MockAppLogger extends Mock implements AppLogger {}

class MockGetSettingsUseCase extends Mock implements GetSettingsUseCase {}

class MockSettingRepository extends Mock implements SettingRepository {}

class MockLocationRepository extends Mock implements LocationRepository {}

const _defaultSettings = SettingEntity(
  windUnit: SettingWindUnit.ms,
  heatUnit: SettingHeatUnit.celsius,
);

const gpsLocation = LocationEntity(
  latitude: 46.20,
  longitude: 6.14,
  cityName: 'Geneva',
  country: 'Switzerland',
);

Future<LocationOnboardingBloc> buildHydratedOnboardingBloc({
  required MockLocationRepository repo,
}) async {
  final bloc = LocationOnboardingBloc(
    logger: MockAppLogger(),
    repository: repo,
  );
  bloc.add(const LoadOnboardingStatusEvent());
  await bloc.stream.first;
  return bloc;
}

Widget createTestScreen(
  WeatherForecastBloc bloc, {
  LocationBloc? locationBloc,
  LocationOnboardingBloc? locationOnboardingBloc,
  Locale locale = const Locale('en'),
}) {
  final locBloc = locationBloc ??
      LocationBloc(logger: MockAppLogger(), repository: MockLocationRepository());
  final onboardingRepo = MockLocationRepository();
  when(() => onboardingRepo.hasSeenLocationOnboarding())
      .thenAnswer((_) async => true);
  final onboardingBloc = locationOnboardingBloc ??
      (LocationOnboardingBloc(
        logger: MockAppLogger(),
        repository: onboardingRepo,
      )..add(const LoadOnboardingStatusEvent()));
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
      BlocProvider<LocationOnboardingBloc>.value(value: onboardingBloc),
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

  WeatherResult buildCachedWeatherResult() {
    return buildWeatherResult().copyWith(isCached: true);
  }

  setUpAll(() {
    registerFallbackValue(const LocationEntity(latitude: 0, longitude: 0, cityName: ''));
  });

  setUp(() {
    mockRepository = MockWeatherRepository();
    mockGetSettings = MockGetSettingsUseCase();
    when(() => mockGetSettings()).thenAnswer((_) async => _defaultSettings);
    when(() => mockRepository.loadCachedWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    ))
        .thenAnswer((_) async => null);
    when(() => mockRepository.clearCachedWeather()).thenAnswer((_) async {});
  });

  WeatherForecastBloc buildEmptyBloc() {
    final bloc = WeatherForecastBloc(
      logger: MockAppLogger(),
      weatherRepository: mockRepository,
      getSettings: mockGetSettings,
      isConnected: () async => true,
    );
    bloc.add(const ResetWeatherEvent());
    return bloc;
  }

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
    expect(find.text('10%'), findsOneWidget);
    expect(find.text('SkyLine'), findsOneWidget);
  });

  testWidgets('shows precipitation probability from hourly data', (tester) async {
    final now = DateTime.now();
    final weather = WeatherEntity(
      current: const CurrentWeatherEntity(
        temperature: 15.0,
        humidity: 80,
        isDay: true,
        windSpeed: 5.0,
        precipitation: 0.3,
        weatherCode: 61,
      ),
      hourly: [
        HourlyWeatherEntity(
          time: now,
          temperature: 15.0,
          precipitationProbability: 75,
          weatherCode: 61,
        ),
      ],
      daily: [
        DailyWeatherEntity(
          date: now,
          tempMax: 16.0,
          tempMin: 10.0,
          weatherCode: 61,
          sunrise: DateTime(now.year, now.month, now.day, 6, 0),
          sunset: DateTime(now.year, now.month, now.day, 20, 0),
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
    await tester.pumpWidget(createTestScreen(bloc));
    await tester.pumpAndSettle();

    expect(find.text('75%'), findsOneWidget);
    expect(find.text('Chance of rain'), findsOneWidget);
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

  testWidgets('shows localized error message in French', (tester) async {
    when(() => mockRepository.fetchWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    )).thenThrow(DioException(
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
    await tester.pumpWidget(createTestScreen(bloc, locale: const Locale('fr')));
    await tester.pumpAndSettle();

    expect(
      find.text('Pas de connexion internet. Vérifiez votre réseau.'),
      findsOneWidget,
    );
    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('initial state shows the weather content fallback', (tester) async {
    final bloc = WeatherForecastBloc(
      logger: MockAppLogger(),
      weatherRepository: mockRepository,
      getSettings: mockGetSettings,
      isConnected: () async => true,
    );

    await tester.pumpWidget(createTestScreen(bloc, locale: const Locale('fr')));

    expect(find.text('SkyLine'), findsOneWidget);
    expect(find.text('--°C'), findsOneWidget);
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

  testWidgets('removing the displayed favorite switches to the first remaining favorite',
      (tester) async {
    when(() => mockRepository.fetchWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    )).thenAnswer((_) async => buildWeatherResult());
    when(() => mockRepository.clearCachedWeather()).thenAnswer((_) async {});

    const ny = LocationEntity(
      latitude: 40.71,
      longitude: -74.00,
      cityName: 'New York',
      country: 'USA',
    );

    final locationRepo = MockLocationRepository();
    var favorites = [paris, ny];
    when(() => locationRepo.loadFavorites()).thenAnswer((_) => favorites);
    when(() => locationRepo.loadLastLocation()).thenReturn(paris);
    when(() => locationRepo.removeFavorite(any())).thenAnswer((_) async {
      favorites = [ny];
    });
    when(() => locationRepo.saveLastLocation(any())).thenAnswer((_) async {});
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

    verify(
      () => mockRepository.fetchWeather(latitude: 40.71, longitude: -74.00),
    ).called(1);
    expect(bloc.state, isA<WeatherLoaded>());
    expect(bloc.state, isNot(isA<WeatherEmpty>()));
    expect(find.text('New York, USA'), findsOneWidget);
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

  testWidgets('shows onboarding sheet when onboarding not seen and weather is empty',
      (tester) async {
    final onboardingRepo = MockLocationRepository();
    when(() => onboardingRepo.hasSeenLocationOnboarding())
        .thenAnswer((_) async => false);
    when(() => onboardingRepo.markLocationOnboardingSeen())
        .thenAnswer((_) async {});
    final onboardingBloc = await buildHydratedOnboardingBloc(repo: onboardingRepo);

    final bloc = buildEmptyBloc();
    await tester.pumpWidget(
      createTestScreen(bloc, locationOnboardingBloc: onboardingBloc),
    );
    await tester.pump();
    expect(find.text('Set your location'), findsNothing);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.byType(LocationOnboardingSheet), findsOneWidget);
    expect(find.text('Set your location'), findsOneWidget);
    expect(find.text('Search for a city to see the weather.'), findsNothing);
  });

  testWidgets('sheet Later completes onboarding and shows fallback search snackbar',
      (tester) async {
    final onboardingRepo = MockLocationRepository();
    when(() => onboardingRepo.hasSeenLocationOnboarding())
        .thenAnswer((_) async => false);
    when(() => onboardingRepo.markLocationOnboardingSeen())
        .thenAnswer((_) async {});
    final onboardingBloc = await buildHydratedOnboardingBloc(repo: onboardingRepo);

    final bloc = buildEmptyBloc();
    await tester.pumpWidget(
      createTestScreen(bloc, locationOnboardingBloc: onboardingBloc),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Set your location'), findsOneWidget);

    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();

    verify(() => onboardingRepo.markLocationOnboardingSeen()).called(1);
    expect(find.text('Set your location'), findsNothing);
    expect(find.text('Search for a city to see the weather.'), findsOneWidget);
  });

  testWidgets('sheet close icon completes onboarding and shows fallback search snackbar',
      (tester) async {
    final onboardingRepo = MockLocationRepository();
    when(() => onboardingRepo.hasSeenLocationOnboarding())
        .thenAnswer((_) async => false);
    when(() => onboardingRepo.markLocationOnboardingSeen())
        .thenAnswer((_) async {});
    final onboardingBloc = await buildHydratedOnboardingBloc(repo: onboardingRepo);

    final bloc = buildEmptyBloc();
    await tester.pumpWidget(
      createTestScreen(bloc, locationOnboardingBloc: onboardingBloc),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Set your location'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    verify(() => onboardingRepo.markLocationOnboardingSeen()).called(1);
    expect(find.text('Set your location'), findsNothing);
    expect(find.text('Search for a city to see the weather.'), findsOneWidget);
  });

  testWidgets('sheet enable location fetches weather for the GPS position',
      (tester) async {
    when(() => mockRepository.fetchWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    )).thenAnswer((_) async => buildWeatherResult());

    final onboardingRepo = MockLocationRepository();
    when(() => onboardingRepo.hasSeenLocationOnboarding())
        .thenAnswer((_) async => false);
    when(() => onboardingRepo.markLocationOnboardingSeen())
        .thenAnswer((_) async {});
    final onboardingBloc = await buildHydratedOnboardingBloc(repo: onboardingRepo);

    final locationRepo = MockLocationRepository();
    when(() => locationRepo.detectCurrentLocation())
        .thenAnswer((_) async => gpsLocation);
    when(() => locationRepo.saveLastLocation(any())).thenAnswer((_) async {});
    when(() => locationRepo.loadFavorites()).thenReturn([]);
    final locationBloc = LocationBloc(
      logger: MockAppLogger(),
      repository: locationRepo,
    );

    final bloc = buildEmptyBloc();
    await tester.pumpWidget(
      createTestScreen(
        bloc,
        locationBloc: locationBloc,
        locationOnboardingBloc: onboardingBloc,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Set your location'), findsOneWidget);

    await tester.tap(find.text('Enable location'));
    await tester.pumpAndSettle();

    verify(() => onboardingRepo.markLocationOnboardingSeen()).called(1);
    verify(() => locationRepo.detectCurrentLocation()).called(1);
    verify(
      () => mockRepository.fetchWeather(
        latitude: gpsLocation.latitude,
        longitude: gpsLocation.longitude,
      ),
    ).called(1);
    expect(find.text('Search for a city to see the weather.'), findsNothing);
  });

  testWidgets('sheet enable location with GPS failure shows GPS error snackbar',
      (tester) async {
    final onboardingRepo = MockLocationRepository();
    when(() => onboardingRepo.hasSeenLocationOnboarding())
        .thenAnswer((_) async => false);
    when(() => onboardingRepo.markLocationOnboardingSeen())
        .thenAnswer((_) async {});
    final onboardingBloc = await buildHydratedOnboardingBloc(repo: onboardingRepo);

    final locationRepo = MockLocationRepository();
    when(() => locationRepo.detectCurrentLocation())
        .thenThrow(const LocationServiceDisabledException());
    final locationBloc = LocationBloc(
      logger: MockAppLogger(),
      repository: locationRepo,
    );

    final bloc = buildEmptyBloc();
    await tester.pumpWidget(
      createTestScreen(
        bloc,
        locationBloc: locationBloc,
        locationOnboardingBloc: onboardingBloc,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Set your location'), findsOneWidget);

    await tester.tap(find.text('Enable location'));
    await tester.pumpAndSettle();

    expect(find.text('Location services are turned off.'), findsOneWidget);
    expect(find.text('Search for a city to see the weather.'), findsNothing);
  });

  testWidgets('does not re-fetch onboarding status and shows sheet after the first empty frame',
      (tester) async {
    final onboardingRepo = MockLocationRepository();
    when(() => onboardingRepo.hasSeenLocationOnboarding())
        .thenAnswer((_) async => false);
    when(() => onboardingRepo.markLocationOnboardingSeen())
        .thenAnswer((_) async {});
    final onboardingBloc = await buildHydratedOnboardingBloc(repo: onboardingRepo);

    final bloc = buildEmptyBloc();
    await tester.pumpWidget(
      createTestScreen(bloc, locationOnboardingBloc: onboardingBloc),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.byType(LocationOnboardingSheet), findsOneWidget);
    verify(() => onboardingRepo.hasSeenLocationOnboarding()).called(1);
  });

  testWidgets('shows fallback search snackbar when onboarding seen and navigates to search',
      (tester) async {
    final bloc = buildEmptyBloc();
    await tester.pumpWidget(createTestScreen(bloc));
    await tester.pumpAndSettle();

    expect(find.byType(LocationOnboardingSheet), findsNothing);
    expect(find.text('Search for a city to see the weather.'), findsOneWidget);

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    expect(find.text('Search city...'), findsOneWidget);
  });

  testWidgets('does not show onboarding sheet or snackbar on loaded weather',
      (tester) async {
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

    expect(find.byType(LocationOnboardingSheet), findsNothing);
    expect(find.text('Search for a city to see the weather.'), findsNothing);
  });

  testWidgets('does not show onboarding sheet or snackbar on weather error',
      (tester) async {
    when(() => mockRepository.fetchWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    )).thenThrow(DioException(
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

    expect(find.byType(LocationOnboardingSheet), findsNothing);
    expect(find.text('Search for a city to see the weather.'), findsNothing);
  });

  testWidgets('shows cached-data snackbar when offline with cached weather',
      (tester) async {
    when(() => mockRepository.loadCachedWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    ))
        .thenAnswer((_) async => buildCachedWeatherResult());

    final bloc = WeatherForecastBloc(
      logger: MockAppLogger(),
      weatherRepository: mockRepository,
      getSettings: mockGetSettings,
      isConnected: () async => false,
    );
    bloc.add(const FetchWeatherEvent());
    await tester.pumpWidget(createTestScreen(bloc));
    await tester.pumpAndSettle();

    expect(
      find.text('No internet connection. Showing cached data.'),
      findsOneWidget,
    );
  });

  testWidgets('shows cached-data snackbar localized in French', (tester) async {
    when(() => mockRepository.loadCachedWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    ))
        .thenAnswer((_) async => buildCachedWeatherResult());

    final bloc = WeatherForecastBloc(
      logger: MockAppLogger(),
      weatherRepository: mockRepository,
      getSettings: mockGetSettings,
      isConnected: () async => false,
    );
    bloc.add(const FetchWeatherEvent());
    await tester.pumpWidget(createTestScreen(bloc, locale: const Locale('fr')));
    await tester.pumpAndSettle();

    expect(
      find.text('Connexion impossible. Données affichées depuis le cache.'),
      findsOneWidget,
    );
  });

  testWidgets('does not show cached-data snackbar when weather is fresh',
      (tester) async {
    when(() => mockRepository.loadCachedWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    ))
        .thenAnswer((_) async => null);
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

    expect(
      find.text('No internet connection. Showing cached data.'),
      findsNothing,
    );
  });

  testWidgets('shows network-error snackbar when refresh fails on cached data',
      (tester) async {
    when(() => mockRepository.loadCachedWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    )).thenAnswer((_) async => buildCachedWeatherResult());
    when(() => mockRepository.fetchWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    )).thenThrow(DioException(
      requestOptions: RequestOptions(path: ''),
      type: DioExceptionType.connectionError,
    ));

    final bloc = WeatherForecastBloc(
      logger: MockAppLogger(),
      weatherRepository: mockRepository,
      getSettings: mockGetSettings,
      isConnected: () async => false,
    );
    bloc.add(const FetchWeatherEvent());
    await tester.pumpWidget(createTestScreen(bloc));
    await tester.pumpAndSettle();
    expect(
      find.text('No internet connection. Showing cached data.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(
      find.text('No internet connection. Showing cached data.'),
      findsNothing,
    );

    bloc.add(const RefreshWeatherEvent());
    await tester.pumpAndSettle();
    expect(
      find.text('Network error. Please try again later.'),
      findsOneWidget,
    );
    expect(
      find.text('No internet connection. Showing cached data.'),
      findsNothing,
    );
  });

  testWidgets('shows cached-data snackbar when loading another city offline',
      (tester) async {
    when(() => mockRepository.loadCachedWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    )).thenAnswer((_) async => buildCachedWeatherResult());

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
      isConnected: () async => false,
    );
    bloc.add(const FetchWeatherEvent());
    await tester.pumpWidget(createTestScreen(bloc, locationBloc: locationBloc));
    await tester.pumpAndSettle();
    expect(
      find.text('No internet connection. Showing cached data.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(
      find.text('No internet connection. Showing cached data.'),
      findsNothing,
    );

    locationBloc.add(const SelectLocationEvent(location: paris));
    await tester.pumpAndSettle();
    expect(
      find.text('No internet connection. Showing cached data.'),
      findsOneWidget,
    );
  });

  testWidgets('does not re-show cached-data snackbar on settings change',
      (tester) async {
    when(() => mockRepository.loadCachedWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    ))
        .thenAnswer((_) async => buildCachedWeatherResult());

    final bloc = WeatherForecastBloc(
      logger: MockAppLogger(),
      weatherRepository: mockRepository,
      getSettings: mockGetSettings,
      isConnected: () async => false,
    );
    bloc.add(const FetchWeatherEvent());
    await tester.pumpWidget(createTestScreen(bloc));
    await tester.pumpAndSettle();
    expect(
      find.text('No internet connection. Showing cached data.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(
      find.text('No internet connection. Showing cached data.'),
      findsNothing,
    );

    const newSettings = SettingEntity(
      windUnit: SettingWindUnit.kmh,
      heatUnit: SettingHeatUnit.fahrenheit,
    );
    bloc.add(ApplySettingsEvent(settings: newSettings));
    await tester.pumpAndSettle();

    expect(
      find.text('No internet connection. Showing cached data.'),
      findsNothing,
    );
  });
}
