import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/config/db_helper/db_helper.dart';
import 'package:sky_line/core/errors/failure.dart';
import 'package:sky_line/features/weather_forecast/data/models/current_weather_model.dart';
import 'package:sky_line/features/weather_forecast/data/models/weather_model.dart';
import 'package:sky_line/features/weather_forecast/data/repositories/weather_repository_impl.dart';
import 'package:sky_line/features/weather_forecast/data/sources/weather_remote_source.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/weather_result.dart';

class MockWeatherRemoteSource extends Mock implements WeatherRemoteSource {}
class MockDbHelper extends Mock implements DbHelper {}

void main() {
  late MockWeatherRemoteSource mockRemoteSource;
  late MockDbHelper mockDbHelper;
  late WeatherRepositoryImpl repository;

  setUp(() {
    mockRemoteSource = MockWeatherRemoteSource();
    mockDbHelper = MockDbHelper();
    repository = WeatherRepositoryImpl(mockRemoteSource, mockDbHelper);
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

    test('returns WeatherResult on success', () async {
      when(() => mockRemoteSource.fetchWeather()).thenAnswer(
        (_) async => validJson,
      );

      final result = await repository.fetchWeather();
      expect(result, isA<WeatherResult>());
      expect(result.isCached, false);
      expect(result.weather.current.temperature, 26.5);
      expect(result.weather.hourly.length, 1);
      expect(result.weather.daily.length, 1);
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

  group('loadCachedWeather', () {
    test('returns WeatherResult when cache is fresh', () async {
      when(() => mockDbHelper.loadWeather(
        maxAgeMillis: any(named: 'maxAgeMillis'),
      )).thenReturn(
        WeatherModel(
          current: CurrentWeatherModel(
            temperature: 26.5, humidity: 80, isDay: true,
            windSpeed: 12.0, precipitation: 0.0, weatherCode: 0,
          ),
          hourly: [],
          daily: [],
        ),
      );

      final result = await repository.loadCachedWeather();

      expect(result, isA<WeatherResult>());
      expect(result!.isCached, true);
      expect(result.weather.current.temperature, 26.5);
    });

    test('returns null when cache is empty', () async {
      when(() => mockDbHelper.loadWeather(
        maxAgeMillis: any(named: 'maxAgeMillis'),
      )).thenReturn(null);

      final result = await repository.loadCachedWeather();
      expect(result, isNull);
    });
  });
}
