import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/core/utils/weather_unit_converter.dart';

void main() {
  group('WeatherUnitConverter', () {
    test('msToKmh converts correctly', () {
      expect(WeatherUnitConverter.msToKmh(10), 36.0);
      expect(WeatherUnitConverter.msToKmh(0), 0.0);
      expect(WeatherUnitConverter.msToKmh(5.5), 19.8);
    });

    test('celsiusToFahrenheit converts correctly', () {
      expect(WeatherUnitConverter.celsiusToFahrenheit(0), 32.0);
      expect(WeatherUnitConverter.celsiusToFahrenheit(100), 212.0);
      expect(WeatherUnitConverter.celsiusToFahrenheit(-40), -40.0);
      expect(WeatherUnitConverter.celsiusToFahrenheit(23), 73.4);
    });
  });
}
