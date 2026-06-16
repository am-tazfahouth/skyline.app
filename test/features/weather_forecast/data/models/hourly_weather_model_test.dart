import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/features/weather_forecast/data/models/hourly_weather_model.dart';

void main() {
  final json = {
    'time': '2026-05-16T12:00',
    'temperature_2m': 26.7,
    'precipitation_probability': 59,
    'weather_code': 61,
  };

  group('HourlyWeatherModel', () {
    test('fromJson creates model correctly', () {
      final model = HourlyWeatherModel.fromJson(json);
      expect(model.temperature, 26.7);
      expect(model.precipitationProbability, 59);
      expect(model.weatherCode, 61);
    });

    test('toEntity creates equivalent entity', () {
      final model = HourlyWeatherModel.fromJson(json);
      final entity = model.toEntity();
      expect(entity.temperature, model.temperature);
      expect(entity.time, model.time);
    });

    test('props are correct', () {
      final model = HourlyWeatherModel.fromJson(json);
      expect(model.props.length, 4);
    });
  });
}
