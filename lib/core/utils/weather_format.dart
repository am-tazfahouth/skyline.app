import 'package:intl/intl.dart';

class WeatherFormat {
  static String date(DateTime dateTime) {
    return DateFormat('dd MMMM yyyy').format(dateTime);
  }

  static String temperature(double value) {
    return '${value.toStringAsFixed(0)}°C';
  }

  static String wind(double value) {
    return '${value.toStringAsFixed(0)} m/s';
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
