import 'package:flutter/widgets.dart';
import 'package:weather_icons/weather_icons.dart';

class WeatherIconMapper {
  static IconData fromWeatherCode(int code, {bool isDay = true}) {
    if (code == 0) {
      return isDay ? WeatherIcons.day_sunny : WeatherIcons.night_clear;
    }
    if (code <= 3) {
      return isDay ? WeatherIcons.day_cloudy : WeatherIcons.night_alt_cloudy;
    }
    if (code <= 48) return isDay ? WeatherIcons.fog : WeatherIcons.night_fog;
    if (code <= 55) {
      return isDay ? WeatherIcons.sprinkle : WeatherIcons.night_sprinkle;
    }
    if (code <= 65) return isDay ? WeatherIcons.rain : WeatherIcons.night_rain;
    if (code <= 75) return isDay ? WeatherIcons.snow : WeatherIcons.night_snow;
    if (code <= 82) {
      return isDay ? WeatherIcons.showers : WeatherIcons.night_showers;
    }
    return isDay ? WeatherIcons.thunderstorm : WeatherIcons.night_thunderstorm;
  }
}
