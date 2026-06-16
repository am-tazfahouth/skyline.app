import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/errors/failure.dart';
import 'package:sky_line/features/weather_forecast/data/repositories/weather_repository_impl.dart';
import 'package:sky_line/features/weather_forecast/data/sources/weather_remote_source.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/weather_entity.dart';

class MockWeatherRemoteSource extends Mock implements WeatherRemoteSource {}

void main() {
  late WeatherRemoteSource mockRemoteSource;
  late WeatherRepositoryImpl repository;

  setUp(() {
    mockRemoteSource = MockWeatherRemoteSource();
    repository = WeatherRepositoryImpl(mockRemoteSource);
  });

  group('fetchWeather', () {
    final validJson = {
      'current': {
        'temperature_2m': 26.5,
        'relative_humidity_2m': 80,
        'is_day': 1,
        'wind_speed_10m': 12.0,
        'precipitation': 0.0,
        'weather_code': 0,
      },
      'hourly': {
        'time': ['2026-05-16T12:00'],
        'temperature_2m': [26.5],
        'precipitation_probability': [10],
        'weather_code': [0],
      },
      'daily': {
        'time': ['2026-05-16'],
        'temperature_2m_max': [28.0],
        'temperature_2m_min': [22.0],
        'weather_code': [0],
        'sunrise': ['2026-05-16T03:16'],
        'sunset': ['2026-05-16T14:50'],
      },
    };

    test('returns WeatherEntity on success', () async {
      when(() => mockRemoteSource.fetchWeather()).thenAnswer(
        (_) async => validJson,
      );

      final result = await repository.fetchWeather();
      expect(result, isA<WeatherEntity>());
      expect(result.current.temperature, 26.5);
      expect(result.hourly.length, 1);
      expect(result.daily.length, 1);
    });

    test('throws NetworkFailure on network error', () async {
      when(() => mockRemoteSource.fetchWeather()).thenThrow(
        const NetworkFailure('No internet'),
      );

      expect(
        () => repository.fetchWeather(),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('throws ParsingFailure on unexpected error', () async {
      when(() => mockRemoteSource.fetchWeather()).thenThrow(
        FormatException('Bad JSON'),
      );

      expect(
        () => repository.fetchWeather(),
        throwsA(isA<ParsingFailure>()),
      );
    });
  });
}
