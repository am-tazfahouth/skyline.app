import 'package:sky_line/features/weather_forecast/domain/entities/weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/repositories/weather_repository.dart';

class FetchWeatherUseCase {
  final WeatherRepository _repository;

  FetchWeatherUseCase(this._repository);

  Future<WeatherEntity> call() {
    return _repository.fetchWeather();
  }
}
