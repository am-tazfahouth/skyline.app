import 'package:intl/intl.dart';
import 'package:sky_line/core/enums/setting_heat_unit.dart';
import 'package:sky_line/core/enums/setting_wind_unit.dart';
import 'package:sky_line/core/utils/weather_unit_converter.dart';

class WeatherFormat {
  static String date(DateTime dateTime) {
    return DateFormat('dd MMMM yyyy').format(dateTime);
  }

  static String temperature(double value, {SettingHeatUnit unit = SettingHeatUnit.celsius}) {
    final converted = unit == SettingHeatUnit.fahrenheit
        ? WeatherUnitConverter.celsiusToFahrenheit(value)
        : value;
    return '${converted.toStringAsFixed(0)}°${unit == SettingHeatUnit.celsius ? "C" : "F"}';
  }

  static String wind(double value, {SettingWindUnit unit = SettingWindUnit.ms}) {
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

  static String condition(int weatherCode) {
    if (weatherCode == 0) return 'Clear';
    if (weatherCode <= 3) return 'Partly cloudy';
    if (weatherCode <= 48) return 'Foggy';
    if (weatherCode <= 55) return 'Drizzle';
    if (weatherCode <= 65) return 'Rain';
    if (weatherCode <= 75) return 'Snow';
    if (weatherCode <= 82) return 'Rain showers';
    return 'Thunderstorm';
  }
}
