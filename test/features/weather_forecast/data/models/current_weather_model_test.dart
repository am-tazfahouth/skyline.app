import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/features/weather_forecast/data/models/current_weather_model.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/current_weather_entity.dart';

void main() {
  final json = {
    'temperature_2m': 26.5,
    'relative_humidity_2m': 95,
    'is_day': 1,
    'wind_speed_10m': 6.4,
    'precipitation': 0.30,
    'weather_code': 55,
  };

  group('CurrentWeatherModel', () {
    test('fromJson creates model correctly', () {
      final model = CurrentWeatherModel.fromJson(json);
      expect(model.temperature, 26.5);
      expect(model.humidity, 95);
      expect(model.isDay, true);
      expect(model.windSpeed, 6.4);
      expect(model.precipitation, 0.30);
      expect(model.weatherCode, 55);
    });

    test('fromJson parses is_day 0 as false', () {
      final nightJson = {...json, 'is_day': 0};
      final model = CurrentWeatherModel.fromJson(nightJson);
      expect(model.isDay, false);
    });

    test('toJson produces correct map', () {
      final model = CurrentWeatherModel.fromJson(json);
      final output = model.toJson();
      expect(output['temperature_2m'], 26.5);
      expect(output['is_day'], 1);
    });

    test('toEntity creates equivalent entity', () {
      final model = CurrentWeatherModel.fromJson(json);
      final entity = model.toEntity();
      expect(entity, isA<CurrentWeatherEntity>());
      expect(entity.temperature, model.temperature);
      expect(entity.humidity, model.humidity);
    });

    test('props are correct', () {
      final model = CurrentWeatherModel.fromJson(json);
      expect(model.props.length, 6);
    });
  });
}
