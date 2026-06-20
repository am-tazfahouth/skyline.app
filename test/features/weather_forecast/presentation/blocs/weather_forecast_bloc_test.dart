import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/errors/failure.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/current_weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/daily_weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/hourly_weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/weather_result.dart';
import 'package:sky_line/features/weather_forecast/domain/repositories/weather_repository.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_event.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_state.dart';

class MockWeatherRepository extends Mock implements WeatherRepository {}

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

void main() {
  late MockWeatherRepository mockRepository;

  setUp(() {
    mockRepository = MockWeatherRepository();
  });

  group('FetchWeatherEvent', () {
    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'emits [Loaded(fetching), Loaded(done)] when cache valid + offline',
      setUp: () {
        when(() => mockRepository.loadCachedWeather())
            .thenAnswer((_) async => _result(cached: true));
      },
      build: () => WeatherForecastBloc(
        mockRepository,
        isConnected: () async => false,
      ),
      act: (bloc) => bloc.add(const FetchWeatherEvent()),
      expect: () => [
        isA<WeatherLoaded>()
            .having((s) => s.result.isCached, 'cached', true)
            .having((s) => s.isFetching, 'fetching', true),
        isA<WeatherLoaded>()
            .having((s) => s.isFetching, 'done', false),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'emits [Loaded(cached,fetching), Loaded(fresh)] when cache + online + succeeds',
      setUp: () {
        when(() => mockRepository.loadCachedWeather())
            .thenAnswer((_) async => _result(cached: true));
        when(() => mockRepository.fetchWeather())
            .thenAnswer((_) async => _result(cached: false));
      },
      build: () => WeatherForecastBloc(
        mockRepository,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(const FetchWeatherEvent()),
      expect: () => [
        isA<WeatherLoaded>()
            .having((s) => s.result.isCached, 'cached', true)
            .having((s) => s.isFetching, 'fetching', true),
        isA<WeatherLoaded>()
            .having((s) => s.isFetching, 'done', false)
            .having((s) => s.result.isCached, 'fresh', false),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'cache valid + fetch fails → stays Loaded(cached)',
      setUp: () {
        when(() => mockRepository.loadCachedWeather())
            .thenAnswer((_) async => _result(cached: true));
        when(() => mockRepository.fetchWeather())
            .thenThrow(const ServerFailure('API down'));
      },
      build: () => WeatherForecastBloc(
        mockRepository,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(const FetchWeatherEvent()),
      expect: () => [
        isA<WeatherLoaded>()
            .having((s) => s.result.isCached, 'cached', true)
            .having((s) => s.isFetching, 'fetching', true),
        isA<WeatherLoaded>()
            .having((s) => s.isFetching, 'done', false),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'emits [Empty(fetching), Loaded] when no cache + online + succeeds',
      setUp: () {
        when(() => mockRepository.loadCachedWeather())
            .thenAnswer((_) async => null);
        when(() => mockRepository.fetchWeather())
            .thenAnswer((_) async => _result());
      },
      build: () => WeatherForecastBloc(
        mockRepository,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(const FetchWeatherEvent()),
      expect: () => [
        const WeatherEmpty(isFetching: true),
        isA<WeatherLoaded>(),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'emits [Empty(fetching), Empty()] when no cache + offline',
      setUp: () {
        when(() => mockRepository.loadCachedWeather())
            .thenAnswer((_) async => null);
      },
      build: () => WeatherForecastBloc(
        mockRepository,
        isConnected: () async => false,
      ),
      act: (bloc) => bloc.add(const FetchWeatherEvent()),
      expect: () => [
        const WeatherEmpty(isFetching: true),
        const WeatherEmpty(isFetching: false),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'emits [Empty(fetching), Error] when no cache + online + fails',
      setUp: () {
        when(() => mockRepository.loadCachedWeather())
            .thenAnswer((_) async => null);
        when(() => mockRepository.fetchWeather())
            .thenThrow(const ServerFailure('API down'));
      },
      build: () => WeatherForecastBloc(
        mockRepository,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(const FetchWeatherEvent()),
      expect: () => [
        const WeatherEmpty(isFetching: true),
        isA<WeatherError>(),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'no cache + online + unexpected error → Error',
      setUp: () {
        when(() => mockRepository.loadCachedWeather())
            .thenAnswer((_) async => null);
        when(() => mockRepository.fetchWeather())
            .thenThrow(Exception('unknown'));
      },
      build: () => WeatherForecastBloc(
        mockRepository,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(const FetchWeatherEvent()),
      expect: () => [
        const WeatherEmpty(isFetching: true),
        isA<WeatherError>(),
      ],
    );
  });

  group('RefreshWeatherEvent', () {
    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'from Loaded → fetch succeeds → Loaded(fresh)',
      seed: () => WeatherLoaded(_result(cached: true)),
      setUp: () {
        when(() => mockRepository.fetchWeather())
            .thenAnswer((_) async => _result(cached: false));
      },
      build: () => WeatherForecastBloc(
        mockRepository,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(const RefreshWeatherEvent()),
      expect: () => [
        isA<WeatherLoaded>()
            .having((s) => s.isFetching, 'fetching', true),
        isA<WeatherLoaded>()
            .having((s) => s.isFetching, 'done', false)
            .having((s) => s.result.isCached, 'fresh', false),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'from Loaded → fetch fails → stays Loaded(original)',
      seed: () => WeatherLoaded(_result(cached: true)),
      setUp: () {
        when(() => mockRepository.fetchWeather())
            .thenThrow(const NetworkFailure('no net'));
      },
      build: () => WeatherForecastBloc(
        mockRepository,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(const RefreshWeatherEvent()),
      expect: () => [
        isA<WeatherLoaded>()
            .having((s) => s.isFetching, 'fetching', true),
        isA<WeatherLoaded>()
            .having((s) => s.isFetching, 'done', false)
            .having((s) => s.result.isCached, 'still cached', true),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'from Empty → fetch succeeds → Loaded',
      seed: () => const WeatherEmpty(),
      setUp: () {
        when(() => mockRepository.fetchWeather())
            .thenAnswer((_) async => _result());
      },
      build: () => WeatherForecastBloc(
        mockRepository,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(const RefreshWeatherEvent()),
      expect: () => [
        const WeatherEmpty(isFetching: true),
        isA<WeatherLoaded>(),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'from Empty → fetch fails → stays Empty',
      seed: () => const WeatherEmpty(),
      setUp: () {
        when(() => mockRepository.fetchWeather())
            .thenThrow(const ServerFailure('fail'));
      },
      build: () => WeatherForecastBloc(
        mockRepository,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(const RefreshWeatherEvent()),
      expect: () => [
        const WeatherEmpty(isFetching: true),
        const WeatherEmpty(isFetching: false),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'from Empty → unexpected error → Error',
      seed: () => const WeatherEmpty(),
      setUp: () {
        when(() => mockRepository.fetchWeather())
            .thenThrow(Exception('unknown'));
      },
      build: () => WeatherForecastBloc(
        mockRepository,
        isConnected: () async => true,
      ),
      act: (bloc) => bloc.add(const RefreshWeatherEvent()),
      expect: () => [
        const WeatherEmpty(isFetching: true),
        isA<WeatherError>(),
      ],
    );
  });
}
