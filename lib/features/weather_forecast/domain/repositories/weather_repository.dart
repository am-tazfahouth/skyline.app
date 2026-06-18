import 'package:sky_line/features/weather_forecast/domain/entities/weather_result.dart';

abstract class WeatherRepository {
  Future<WeatherResult> fetchWeather();
  Future<WeatherResult?> loadCachedWeather();
}
