import 'package:sky_line/features/weather_forecast/domain/entities/weather_entity.dart';

abstract class WeatherRepository {
  Future<WeatherEntity> fetchWeather();
}
