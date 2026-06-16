import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/features/weather_forecast/data/models/daily_weather_model.dart';

void main() {
  final json = {
    'time': '2026-05-16',
    'temperature_2m_max': 27.3,
    'temperature_2m_min': 23.3,
    'weather_code': 80,
    'sunrise': '2026-05-16T03:16',
    'sunset': '2026-05-16T14:50',
  };

  group('DailyWeatherModel', () {
    test('fromJson creates model correctly', () {
      final model = DailyWeatherModel.fromJson(json);
      expect(model.tempMax, 27.3);
      expect(model.tempMin, 23.3);
      expect(model.weatherCode, 80);
    });

    test('toEntity creates equivalent entity', () {
      final model = DailyWeatherModel.fromJson(json);
      final entity = model.toEntity();
      expect(entity.tempMax, model.tempMax);
      expect(entity.tempMin, model.tempMin);
    });

    test('props are correct', () {
      final model = DailyWeatherModel.fromJson(json);
      expect(model.props.length, 6);
    });
  });
}
