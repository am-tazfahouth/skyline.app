import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/enums/setting_heat_unit.dart';
import 'package:sky_line/core/enums/setting_wind_unit.dart';
import 'package:sky_line/core/services/logger_services.dart';
import 'package:sky_line/core/errors/weather_error_codes.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';
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

class MockWeatherRepository extends Mock implements WeatherRepository {}

class MockAppLogger extends Mock implements AppLogger {}

class MockGetSettingsUseCase extends Mock implements GetSettingsUseCase {}

const _defaultSettings = SettingEntity(
  windUnit: SettingWindUnit.ms,
  heatUnit: SettingHeatUnit.celsius,
);

WeatherResult _result({bool cached = false}) {
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

DioException _dioException({
  DioExceptionType type = DioExceptionType.badResponse,
  int? statusCode,
}) {
  return DioException(
    requestOptions: RequestOptions(path: ''),
    type: type,
    response: statusCode != null
        ? Response(
            statusCode: statusCode,
            requestOptions: RequestOptions(path: ''),
          )
        : null,
  );
}

FutureOr<({double latitude, double longitude})?> _defaultLastLocation() =>
    (latitude: 0.0, longitude: 0.0);

void main() {
  late MockWeatherRepository mockRepository;
  late MockAppLogger mockLogger;
  late MockGetSettingsUseCase mockGetSettings;

  setUp(() {
    mockRepository = MockWeatherRepository();
    mockLogger = MockAppLogger();
    mockGetSettings = MockGetSettingsUseCase();
    when(() => mockGetSettings()).thenAnswer((_) async => _defaultSettings);
  });

  group('FetchWeatherEvent', () {
    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'emits [Loaded(fetching), Loaded(done)] when cache valid + offline',
      setUp: () {
        when(
          () => mockRepository.loadCachedWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => _result(cached: true));
      },
      build: () => WeatherForecastBloc(
        logger: mockLogger,
        weatherRepository: mockRepository,
        getSettings: mockGetSettings,
        getLastLocation: _defaultLastLocation,
        isConnected: () async => false,
      ),
      act: (bloc) => bloc.add(const FetchWeatherEvent()),
      expect: () => [
        isA<WeatherLoaded>()
            .having((s) => s.result.isCached, 'cached', true)
            .having((s) => s.isFetching, 'fetching', true),
        isA<WeatherLoaded>()
            .having((s) => s.isFetching, 'done', false)
            .having((s) => s.notice, 'notice', WeatherNotice.cachedData),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'emits [Loaded(cached,fetching), Loaded(fresh)] when cache + online + succeeds',
      setUp: () {
        when(
          () => mockRepository.loadCachedWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => _result(cached: true));
        when(
          () => mockRepository.fetchWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => _result(cached: false));
      },
      build: () => WeatherForecastBloc(
        logger: mockLogger,
        weatherRepository: mockRepository,
        getSettings: mockGetSettings,
        getLastLocation: _defaultLastLocation,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(const FetchWeatherEvent()),
      expect: () => [
        isA<WeatherLoaded>()
            .having((s) => s.result.isCached, 'cached', true)
            .having((s) => s.isFetching, 'fetching', true),
        isA<WeatherLoaded>()
            .having((s) => s.isFetching, 'done', false)
            .having((s) => s.result.isCached, 'fresh', false)
            .having((s) => s.notice, 'notice', WeatherNotice.none),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'cache valid + fetch fails with DioException → stays Loaded(cached)',
      setUp: () {
        when(
          () => mockRepository.loadCachedWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => _result(cached: true));
        when(
          () => mockRepository.fetchWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenThrow(_dioException());
      },
      build: () => WeatherForecastBloc(
        logger: mockLogger,
        weatherRepository: mockRepository,
        getSettings: mockGetSettings,
        getLastLocation: _defaultLastLocation,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(const FetchWeatherEvent()),
      expect: () => [
        isA<WeatherLoaded>()
            .having((s) => s.result.isCached, 'cached', true)
            .having((s) => s.isFetching, 'fetching', true),
        isA<WeatherLoaded>()
            .having((s) => s.isFetching, 'done', false)
            .having((s) => s.notice, 'notice', WeatherNotice.cachedData),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'emits [Empty(fetching), Loaded] when no cache + online + succeeds',
      setUp: () {
        when(
          () => mockRepository.loadCachedWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => null);
        when(
          () => mockRepository.fetchWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => _result());
      },
      build: () => WeatherForecastBloc(
        logger: mockLogger,
        weatherRepository: mockRepository,
        getSettings: mockGetSettings,
        getLastLocation: _defaultLastLocation,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(const FetchWeatherEvent()),
      expect: () => [
        const WeatherEmpty(isFetching: true, settings: _defaultSettings),
        isA<WeatherLoaded>(),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'emits [Empty(fetching), Empty()] when no cache + offline',
      setUp: () {
        when(
          () => mockRepository.loadCachedWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => null);
      },
      build: () => WeatherForecastBloc(
        logger: mockLogger,
        weatherRepository: mockRepository,
        getSettings: mockGetSettings,
        getLastLocation: _defaultLastLocation,
        isConnected: () async => false,
      ),
      act: (bloc) => bloc.add(const FetchWeatherEvent()),
      expect: () => [
        const WeatherEmpty(isFetching: true, settings: _defaultSettings),
        const WeatherEmpty(isFetching: false, settings: _defaultSettings),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'emits [Empty(fetching), Error] when no cache + online + DioException',
      setUp: () {
        when(
          () => mockRepository.loadCachedWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => null);
        when(
          () => mockRepository.fetchWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenThrow(_dioException());
      },
      build: () => WeatherForecastBloc(
        logger: mockLogger,
        weatherRepository: mockRepository,
        getSettings: mockGetSettings,
        getLastLocation: _defaultLastLocation,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(const FetchWeatherEvent()),
      expect: () => [
        const WeatherEmpty(isFetching: true, settings: _defaultSettings),
        const WeatherError(
          errorCode: WeatherErrorCodes.fetch,
          settings: _defaultSettings,
        ),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'no cache + online + unexpected error → Error',
      setUp: () {
        when(
          () => mockRepository.loadCachedWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => null);
        when(
          () => mockRepository.fetchWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenThrow(Exception('unknown'));
      },
      build: () => WeatherForecastBloc(
        logger: mockLogger,
        weatherRepository: mockRepository,
        getSettings: mockGetSettings,
        getLastLocation: _defaultLastLocation,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(const FetchWeatherEvent()),
      expect: () => [
        const WeatherEmpty(isFetching: true, settings: _defaultSettings),
        const WeatherError(
          errorCode: WeatherErrorCodes.unexpected,
          settings: _defaultSettings,
        ),
      ],
    );
    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'no last location → emits Empty fallback and clears cache without fetching',
      setUp: () {
        when(
          () => mockRepository.clearCachedWeather(),
        ).thenAnswer((_) async {});
      },
      build: () => WeatherForecastBloc(
        logger: mockLogger,
        weatherRepository: mockRepository,
        getSettings: mockGetSettings,
        getLastLocation: () async => null,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(const FetchWeatherEvent()),
      expect: () => [
        const WeatherEmpty(isFetching: false, settings: _defaultSettings),
      ],
      verify: (_) {
        verify(() => mockRepository.clearCachedWeather()).called(1);
        verifyNever(
          () => mockRepository.loadCachedWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        );
        verifyNever(
          () => mockRepository.fetchWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        );
      },
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'resolves coordinates from the last location when event has none',
      setUp: () {
        when(
          () => mockRepository.loadCachedWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => null);
        when(
          () => mockRepository.fetchWeather(latitude: 1.0, longitude: 2.0),
        ).thenAnswer((_) async => _result());
      },
      build: () => WeatherForecastBloc(
        logger: mockLogger,
        weatherRepository: mockRepository,
        getSettings: mockGetSettings,
        getLastLocation: () async => (latitude: 1.0, longitude: 2.0),
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(const FetchWeatherEvent()),
      expect: () => [
        const WeatherEmpty(isFetching: true, settings: _defaultSettings),
        isA<WeatherLoaded>(),
      ],
      verify: (_) {
        verify(
          () => mockRepository.fetchWeather(latitude: 1.0, longitude: 2.0),
        ).called(1);
      },
    );
  });

  group('RefreshWeatherEvent', () {
    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'from Loaded → fetch succeeds → Loaded(fresh)',
      seed: () =>
          WeatherLoaded(_result(cached: true), settings: _defaultSettings),
      setUp: () {
        when(
          () => mockRepository.fetchWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => _result(cached: false));
      },
      build: () => WeatherForecastBloc(
        logger: mockLogger,
        weatherRepository: mockRepository,
        getSettings: mockGetSettings,
        getLastLocation: _defaultLastLocation,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(const RefreshWeatherEvent()),
      expect: () => [
        isA<WeatherLoaded>().having((s) => s.isFetching, 'fetching', true),
        isA<WeatherLoaded>()
            .having((s) => s.isFetching, 'done', false)
            .having((s) => s.result.isCached, 'fresh', false),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'from Loaded → fetch fails with DioException → stays Loaded(original)',
      seed: () =>
          WeatherLoaded(_result(cached: true), settings: _defaultSettings),
      setUp: () {
        when(
          () => mockRepository.fetchWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenThrow(_dioException(type: DioExceptionType.connectionError));
      },
      build: () => WeatherForecastBloc(
        logger: mockLogger,
        weatherRepository: mockRepository,
        getSettings: mockGetSettings,
        getLastLocation: _defaultLastLocation,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(const RefreshWeatherEvent()),
      expect: () => [
        isA<WeatherLoaded>().having((s) => s.isFetching, 'fetching', true),
        isA<WeatherLoaded>()
            .having((s) => s.isFetching, 'done', false)
            .having((s) => s.result.isCached, 'still cached', true)
            .having((s) => s.notice, 'notice', WeatherNotice.refreshError),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'from Empty → fetch succeeds → Loaded',
      seed: () => const WeatherEmpty(settings: _defaultSettings),
      setUp: () {
        when(
          () => mockRepository.fetchWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => _result());
      },
      build: () => WeatherForecastBloc(
        logger: mockLogger,
        weatherRepository: mockRepository,
        getSettings: mockGetSettings,
        getLastLocation: _defaultLastLocation,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(const RefreshWeatherEvent()),
      expect: () => [
        const WeatherEmpty(isFetching: true, settings: _defaultSettings),
        isA<WeatherLoaded>(),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'from Empty → fetch fails with DioException → stays Empty',
      seed: () => const WeatherEmpty(settings: _defaultSettings),
      setUp: () {
        when(
          () => mockRepository.fetchWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenThrow(_dioException());
      },
      build: () => WeatherForecastBloc(
        logger: mockLogger,
        weatherRepository: mockRepository,
        getSettings: mockGetSettings,
        getLastLocation: _defaultLastLocation,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(const RefreshWeatherEvent()),
      expect: () => [
        const WeatherEmpty(isFetching: true, settings: _defaultSettings),
        const WeatherEmpty(isFetching: false, settings: _defaultSettings),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'from Empty → unexpected error → Error',
      seed: () => const WeatherEmpty(settings: _defaultSettings),
      setUp: () {
        when(
          () => mockRepository.fetchWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenThrow(Exception('unknown'));
      },
      build: () => WeatherForecastBloc(
        logger: mockLogger,
        weatherRepository: mockRepository,
        getSettings: mockGetSettings,
        getLastLocation: _defaultLastLocation,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(const RefreshWeatherEvent()),
      expect: () => [
        const WeatherEmpty(isFetching: true, settings: _defaultSettings),
        const WeatherError(
          errorCode: WeatherErrorCodes.unexpected,
          settings: _defaultSettings,
        ),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'from Empty with no last location → stays Empty without fetching',
      seed: () => const WeatherEmpty(settings: _defaultSettings),
      build: () => WeatherForecastBloc(
        logger: mockLogger,
        weatherRepository: mockRepository,
        getSettings: mockGetSettings,
        getLastLocation: () async => null,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(const RefreshWeatherEvent()),
      expect: () => [
        const WeatherEmpty(isFetching: true, settings: _defaultSettings),
        const WeatherEmpty(isFetching: false, settings: _defaultSettings),
      ],
      verify: (_) {
        verifyNever(
          () => mockRepository.fetchWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        );
      },
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'stale refresh DioException after concurrent fetch success → does not overwrite fresh result with error',
      seed: () =>
          WeatherLoaded(_result(cached: true), settings: _defaultSettings),
      setUp: () {
        when(
          () => mockRepository.loadCachedWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => _result(cached: true));
        int fetchCount = 0;
        when(
          () => mockRepository.fetchWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async {
          fetchCount++;
          if (fetchCount == 1) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            return _result(cached: false);
          }
          await Future<void>.delayed(const Duration(milliseconds: 150));
          throw _dioException(type: DioExceptionType.connectionError);
        });
      },
      build: () => WeatherForecastBloc(
        logger: mockLogger,
        weatherRepository: mockRepository,
        getSettings: mockGetSettings,
        getLastLocation: _defaultLastLocation,
        isConnected: () async => true,
      ),
      act: (bloc) async {
        bloc.add(const FetchWeatherEvent());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RefreshWeatherEvent());
        await Future<void>.delayed(const Duration(milliseconds: 250));
      },
      verify: (bloc) {
        expect(
          bloc.state,
          isA<WeatherLoaded>()
              .having((s) => s.result.isCached, 'result is fresh', false)
              .having(
                (s) => s.notice,
                'no error notice on fresh data',
                WeatherNotice.none,
              ),
        );
      },
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'stale refresh failure after ResetWeatherEvent → final state is WeatherEmpty',
      seed: () =>
          WeatherLoaded(_result(cached: true), settings: _defaultSettings),
      setUp: () {
        int fetchCount = 0;
        when(
          () => mockRepository.fetchWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async {
          fetchCount++;
          if (fetchCount == 1) {
            await Future<void>.delayed(const Duration(milliseconds: 100));
            return _result(cached: false);
          }
          throw _dioException(type: DioExceptionType.connectionError);
        });
        when(
          () => mockRepository.clearCachedWeather(),
        ).thenAnswer((_) async {});
        when(
          () => mockRepository.loadCachedWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => null);
      },
      build: () => WeatherForecastBloc(
        logger: mockLogger,
        weatherRepository: mockRepository,
        getSettings: mockGetSettings,
        getLastLocation: _defaultLastLocation,
        isConnected: () async => true,
      ),
      act: (bloc) async {
        bloc.add(const FetchWeatherEvent());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RefreshWeatherEvent());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ResetWeatherEvent());
        await Future<void>.delayed(const Duration(milliseconds: 200));
      },
      verify: (bloc) {
        final lastState = bloc.state;
        expect(lastState, isA<WeatherEmpty>());
      },
    );
  });

  group('ResetWeatherEvent', () {
    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'clears cache and emits WeatherEmpty',
      seed: () =>
          WeatherLoaded(_result(cached: true), settings: _defaultSettings),
      setUp: () {
        when(
          () => mockRepository.clearCachedWeather(),
        ).thenAnswer((_) async {});
      },
      build: () => WeatherForecastBloc(
        logger: mockLogger,
        weatherRepository: mockRepository,
        getSettings: mockGetSettings,
        getLastLocation: _defaultLastLocation,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(const ResetWeatherEvent()),
      expect: () => [
        const WeatherEmpty(isFetching: false, settings: _defaultSettings),
      ],
      verify: (_) {
        verify(() => mockRepository.clearCachedWeather()).called(1);
      },
    );
  });

  group('ApplySettingsEvent', () {
    final newSettings = const SettingEntity(
      windUnit: SettingWindUnit.kmh,
      heatUnit: SettingHeatUnit.fahrenheit,
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'from WeatherLoaded → updates settings',
      seed: () =>
          WeatherLoaded(_result(cached: true), settings: _defaultSettings),
      build: () => WeatherForecastBloc(
        logger: mockLogger,
        weatherRepository: mockRepository,
        getSettings: mockGetSettings,
        getLastLocation: _defaultLastLocation,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(ApplySettingsEvent(settings: newSettings)),
      expect: () => [
        isA<WeatherLoaded>()
            .having((s) => s.settings.windUnit, 'windUnit', SettingWindUnit.kmh)
            .having(
              (s) => s.settings.heatUnit,
              'heatUnit',
              SettingHeatUnit.fahrenheit,
            )
            .having((s) => s.notice, 'notice', WeatherNotice.none),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'from WeatherEmpty → updates settings',
      seed: () => const WeatherEmpty(settings: _defaultSettings),
      build: () => WeatherForecastBloc(
        logger: mockLogger,
        weatherRepository: mockRepository,
        getSettings: mockGetSettings,
        getLastLocation: _defaultLastLocation,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(ApplySettingsEvent(settings: newSettings)),
      expect: () => [
        isA<WeatherEmpty>().having(
          (s) => s.settings.windUnit,
          'windUnit',
          SettingWindUnit.kmh,
        ),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'from WeatherInitial → no state change',
      build: () => WeatherForecastBloc(
        logger: mockLogger,
        weatherRepository: mockRepository,
        getSettings: mockGetSettings,
        getLastLocation: _defaultLastLocation,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(ApplySettingsEvent(settings: newSettings)),
      expect: () => [],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'from WeatherError → no state change',
      seed: () => const WeatherError(errorCode: WeatherErrorCodes.fetch),
      build: () => WeatherForecastBloc(
        logger: mockLogger,
        weatherRepository: mockRepository,
        getSettings: mockGetSettings,
        getLastLocation: _defaultLastLocation,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(ApplySettingsEvent(settings: newSettings)),
      expect: () => [],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'from fetching WeatherLoaded → updates settings and preserves isFetching',
      seed: () => WeatherLoaded(
        _result(cached: true),
        isFetching: true,
        settings: _defaultSettings,
      ),
      build: () => WeatherForecastBloc(
        logger: mockLogger,
        weatherRepository: mockRepository,
        getSettings: mockGetSettings,
        getLastLocation: _defaultLastLocation,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(ApplySettingsEvent(settings: newSettings)),
      expect: () => [
        isA<WeatherLoaded>()
            .having((s) => s.isFetching, 'isFetching', true)
            .having(
              (s) => s.settings.heatUnit,
              'heatUnit',
              SettingHeatUnit.fahrenheit,
            ),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'from fetching WeatherEmpty → updates settings and preserves isFetching',
      seed: () =>
          const WeatherEmpty(isFetching: true, settings: _defaultSettings),
      build: () => WeatherForecastBloc(
        logger: mockLogger,
        weatherRepository: mockRepository,
        getSettings: mockGetSettings,
        getLastLocation: _defaultLastLocation,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(ApplySettingsEvent(settings: newSettings)),
      expect: () => [
        isA<WeatherEmpty>()
            .having((s) => s.isFetching, 'isFetching', true)
            .having(
              (s) => s.settings.heatUnit,
              'heatUnit',
              SettingHeatUnit.fahrenheit,
            ),
      ],
    );
  });
}
