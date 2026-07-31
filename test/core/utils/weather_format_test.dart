import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/core/enums/setting_heat_unit.dart';
import 'package:sky_line/core/enums/setting_wind_unit.dart';
import 'package:sky_line/core/utils/weather_format.dart';

void main() {
  group('WeatherFormat.temperature', () {
    test('defaults to Celsius', () {
      expect(WeatherFormat.temperature(23), '23°C');
    });

    test('returns Fahrenheit when specified', () {
      expect(WeatherFormat.temperature(23, unit: SettingHeatUnit.fahrenheit),
          '73°F');
    });

    test('returns Celsius when explicitly set', () {
      expect(WeatherFormat.temperature(0, unit: SettingHeatUnit.celsius),
          '0°C');
    });
  });

  group('WeatherFormat.wind', () {
    test('defaults to m/s', () {
      expect(WeatherFormat.wind(5), '5 m/s');
    });

    test('returns km/h when specified', () {
      expect(WeatherFormat.wind(10, unit: SettingWindUnit.kmh), '36 km/h');
    });

    test('returns m/s when explicitly set', () {
      expect(WeatherFormat.wind(3.5, unit: SettingWindUnit.ms), '4 m/s');
    });
  });

  group('WeatherFormat other methods', () {
    test('date formats correctly', () {
      final dt = DateTime(2026, 6, 26);
      expect(WeatherFormat.date(dt), '26 June 2026');
    });

    test('condition returns correct string', () {
      expect(WeatherFormat.condition(0), 'Clear');
      expect(WeatherFormat.condition(3), 'Partly cloudy');
      expect(WeatherFormat.condition(95), 'Thunderstorm');
    });
  });
}
