import 'package:sky_line/core/errors/weather_exceptions.dart';
import 'package:sky_line/features/weather_forecast/data/models/current_weather_model.dart';
import 'package:sky_line/features/weather_forecast/data/models/daily_weather_model.dart';
import 'package:sky_line/features/weather_forecast/data/models/hourly_weather_model.dart';
import 'package:sky_line/features/weather_forecast/data/models/weather_model.dart';

class WeatherMapper {
  WeatherMapper._();

  static WeatherModel fromJson(Map<String, dynamic> json) {
    try {
      final currentJson = json['current'] as Map<String, dynamic>;
      final hourlyJson = json['hourly'] as Map<String, dynamic>;
      final dailyJson = json['daily'] as Map<String, dynamic>;

      final current = CurrentWeatherModel.fromJson(currentJson);

      final hourlyTimes = hourlyJson['time'] as List<dynamic>;
      final hourlyTemps = hourlyJson['temperature_2m'] as List<dynamic>;
      final hourlyPrecip =
          hourlyJson['precipitation_probability'] as List<dynamic>;
      final hourlyCodes = hourlyJson['weather_code'] as List<dynamic>;

      final hourlyList = <HourlyWeatherModel>[];
      for (var i = 0; i < hourlyTimes.length; i++) {
        hourlyList.add(
          HourlyWeatherModel(
            time: DateTime.parse(hourlyTimes[i] as String),
            temperature: (hourlyTemps[i] as num).toDouble(),
            precipitationProbability: (hourlyPrecip[i] as num).toInt(),
            weatherCode: (hourlyCodes[i] as num).toInt(),
          ),
        );
      }

      final dailyTimes = dailyJson['time'] as List<dynamic>;
      final dailyMax = dailyJson['temperature_2m_max'] as List<dynamic>;
      final dailyMin = dailyJson['temperature_2m_min'] as List<dynamic>;
      final dailyCodes = dailyJson['weather_code'] as List<dynamic>;
      final dailySunrise = dailyJson['sunrise'] as List<dynamic>;
      final dailySunset = dailyJson['sunset'] as List<dynamic>;

      final dailyList = <DailyWeatherModel>[];
      for (var i = 0; i < dailyTimes.length; i++) {
        dailyList.add(
          DailyWeatherModel(
            date: DateTime.parse(dailyTimes[i] as String),
            tempMax: (dailyMax[i] as num).toDouble(),
            tempMin: (dailyMin[i] as num).toDouble(),
            weatherCode: (dailyCodes[i] as num).toInt(),
            sunrise: DateTime.parse(dailySunrise[i] as String),
            sunset: DateTime.parse(dailySunset[i] as String),
          ),
        );
      }

      return WeatherModel(
        current: current,
        hourly: hourlyList,
        daily: dailyList,
      );
    } on TypeError catch (e) {
      throw WeatherParseException('Invalid weather data format: $e');
    } on FormatException catch (e) {
      throw WeatherParseException('Invalid weather data format: $e');
    }
  }
}
