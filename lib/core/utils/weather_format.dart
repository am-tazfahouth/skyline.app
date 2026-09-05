import 'package:sky_line/core/enums/setting_heat_unit.dart';
import 'package:sky_line/core/enums/setting_wind_unit.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/core/utils/weather_unit_converter.dart';

class WeatherFormat {
  static String temperature(
    double value, {
    SettingHeatUnit unit = SettingHeatUnit.celsius,
  }) {
    final converted = unit == SettingHeatUnit.fahrenheit
        ? WeatherUnitConverter.celsiusToFahrenheit(value)
        : value;
    return '${converted.toStringAsFixed(0)}°${unit == SettingHeatUnit.celsius ? "C" : "F"}';
  }

  static String wind(
    double value, {
    SettingWindUnit unit = SettingWindUnit.ms,
  }) {
    final converted = unit == SettingWindUnit.kmh
        ? WeatherUnitConverter.msToKmh(value)
        : value;
    return '${converted.toStringAsFixed(0)} ${unit == SettingWindUnit.ms ? "m/s" : "km/h"}';
  }

  static String percent(double value) {
    return '${value.toStringAsFixed(0)}%';
  }

  static String percentInt(int value) {
    return '$value%';
  }

  static String condition(int weatherCode, AppLocalisation l10n) {
    if (weatherCode == 0) return l10n.weatherConditionClear;
    if (weatherCode <= 3) return l10n.weatherConditionPartlyCloudy;
    if (weatherCode <= 48) return l10n.weatherConditionFoggy;
    if (weatherCode <= 55) return l10n.weatherConditionDrizzle;
    if (weatherCode <= 65) return l10n.weatherConditionRain;
    if (weatherCode <= 75) return l10n.weatherConditionSnow;
    if (weatherCode <= 82) return l10n.weatherConditionRainShowers;
    return l10n.weatherConditionThunderstorm;
  }
}
