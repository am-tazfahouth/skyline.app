import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/core/errors/weather_exceptions.dart';
import 'package:sky_line/features/weather_forecast/data/mappers/weather_mapper.dart';
import 'package:sky_line/features/weather_forecast/data/models/weather_model.dart';

void main() {
  final validJson = <String, dynamic>{
    'current': {
      'temperature_2m': 22.1,
      'relative_humidity_2m': 65,
      'is_day': 1,
      'wind_speed_10m': 12.3,
      'precipitation': 0.0,
      'weather_code': 1,
    },
    'hourly': {
      'time': ['2026-05-16T12:00', '2026-05-16T13:00'],
      'temperature_2m': [22.1, 23.5],
      'precipitation_probability': [10, 20],
      'weather_code': [1, 3],
    },
    'daily': {
      'time': ['2026-05-16', '2026-05-17'],
      'temperature_2m_max': [25.0, 27.0],
      'temperature_2m_min': [18.0, 19.0],
      'weather_code': [1, 3],
      'sunrise': ['2026-05-16T03:16', '2026-05-17T03:15'],
      'sunset': ['2026-05-16T14:50', '2026-05-17T14:51'],
    },
  };

  group('WeatherMapper', () {
    test('fromJson parses valid weather data', () {
      final model = WeatherMapper.fromJson(validJson);
      expect(model, isA<WeatherModel>());
      expect(model.current.temperature, 22.1);
      expect(model.hourly, hasLength(2));
      expect(model.daily, hasLength(2));
    });

    test('fromJson parses hourly fields correctly', () {
      final model = WeatherMapper.fromJson(validJson);
      expect(model.hourly[0].temperature, 22.1);
      expect(model.hourly[0].precipitationProbability, 10);
      expect(model.hourly[0].weatherCode, 1);
      expect(model.hourly[1].temperature, 23.5);
    });

    test('fromJson parses daily fields correctly', () {
      final model = WeatherMapper.fromJson(validJson);
      expect(model.daily[0].tempMax, 25.0);
      expect(model.daily[0].tempMin, 18.0);
      expect(model.daily[0].weatherCode, 1);
      expect(model.daily[1].tempMax, 27.0);
    });

    test('fromJson handles empty hourly and daily lists', () {
      final json = {
        ...validJson,
        'hourly': {
          'time': <dynamic>[],
          'temperature_2m': <dynamic>[],
          'precipitation_probability': <dynamic>[],
          'weather_code': <dynamic>[],
        },
        'daily': {
          'time': <dynamic>[],
          'temperature_2m_max': <dynamic>[],
          'temperature_2m_min': <dynamic>[],
          'weather_code': <dynamic>[],
          'sunrise': <dynamic>[],
          'sunset': <dynamic>[],
        },
      };

      final model = WeatherMapper.fromJson(json);
      expect(model.hourly, isEmpty);
      expect(model.daily, isEmpty);
    });

    test('fromJson throws WeatherParseException on missing current key', () {
      final json = {'hourly': validJson['hourly'], 'daily': validJson['daily']};

      expect(
        () => WeatherMapper.fromJson(json),
        throwsA(isA<WeatherParseException>()),
      );
    });

    test('fromJson throws WeatherParseException on type mismatch', () {
      final json = {
        'current': 'not a map',
        'hourly': validJson['hourly'],
        'daily': validJson['daily'],
      };

      expect(
        () => WeatherMapper.fromJson(json),
        throwsA(isA<WeatherParseException>()),
      );
    });

    test('fromJson throws WeatherParseException on malformed time string', () {
      final json = {
        ...validJson,
        'hourly': {
          'time': ['not-a-date'],
          'temperature_2m': [22.0],
          'precipitation_probability': [10],
          'weather_code': [1],
        },
      };

      expect(
        () => WeatherMapper.fromJson(json),
        throwsA(isA<WeatherParseException>()),
      );
    });
  });
}
