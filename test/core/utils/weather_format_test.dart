import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/core/enums/setting_heat_unit.dart';
import 'package:sky_line/core/enums/setting_wind_unit.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/core/l10n/app_localisation_en.dart';
import 'package:sky_line/core/l10n/app_localisation_fr.dart';
import 'package:sky_line/core/utils/weather_format.dart';

void main() {
  group('WeatherFormat.temperature', () {
    test('defaults to Celsius', () {
      expect(WeatherFormat.temperature(23), '23°C');
    });

    test('returns Fahrenheit when specified', () {
      expect(
        WeatherFormat.temperature(23, unit: SettingHeatUnit.fahrenheit),
        '73°F',
      );
    });

    test('returns Celsius when explicitly set', () {
      expect(
        WeatherFormat.temperature(0, unit: SettingHeatUnit.celsius),
        '0°C',
      );
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
    test('condition returns correct English labels', () {
      final AppLocalisation l10n = AppLocalisationEn();
      expect(WeatherFormat.condition(0, l10n), 'Clear');
      expect(WeatherFormat.condition(3, l10n), 'Partly cloudy');
      expect(WeatherFormat.condition(95, l10n), 'Thunderstorm');
    });

    test('condition returns localized French labels', () {
      final AppLocalisation l10n = AppLocalisationFr();
      expect(WeatherFormat.condition(0, l10n), 'Ciel dégagé');
      expect(WeatherFormat.condition(95, l10n), 'Orage');
    });
  });
}
