import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/errors/failure.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/current_weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/daily_weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/hourly_weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/usecases/fetch_weather_usecase.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_event.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_state.dart';

class MockFetchWeatherUseCase extends Mock implements FetchWeatherUseCase {}

void main() {
  late MockFetchWeatherUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockFetchWeatherUseCase();
  });

  group('WeatherForecastBloc', () {
    final testWeather = WeatherEntity(
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

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'emits [Loading, Loaded] on success',
      build: () {
        when(() => mockUseCase()).thenAnswer((_) async => testWeather);
        return WeatherForecastBloc(mockUseCase);
      },
      act: (bloc) => bloc.add(const FetchWeatherEvent()),
      expect: () => [
        isA<WeatherLoading>(),
        isA<WeatherLoaded>().having(
          (s) => s.weather.current.temperature,
          'temperature',
          28.0,
        ),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(() => mockUseCase()).thenThrow(const ServerFailure('API down'));
        return WeatherForecastBloc(mockUseCase);
      },
      act: (bloc) => bloc.add(const FetchWeatherEvent()),
      expect: () => [
        isA<WeatherLoading>(),
        isA<WeatherError>(),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'emits [Loading, Error] on unexpected error',
      build: () {
        when(() => mockUseCase()).thenThrow(Exception('unknown'));
        return WeatherForecastBloc(mockUseCase);
      },
      act: (bloc) => bloc.add(const FetchWeatherEvent()),
      expect: () => [
        isA<WeatherLoading>(),
        isA<WeatherError>(),
      ],
    );
  });
}
