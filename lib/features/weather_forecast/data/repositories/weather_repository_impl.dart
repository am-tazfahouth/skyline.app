import 'package:sky_line/core/errors/failure.dart';
import 'package:sky_line/features/weather_forecast/data/sources/weather_remote_source.dart';
import 'package:sky_line/features/weather_forecast/data/weather_mapper.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/repositories/weather_repository.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherRemoteSource _remoteSource;

  WeatherRepositoryImpl(this._remoteSource);

  @override
  Future<WeatherEntity> fetchWeather() async {
    try {
      final json = await _remoteSource.fetchWeather();
      return WeatherMapper.fromJson(json);
    } on Failure {
      rethrow;
    } catch (e, s) {
      throw ParsingFailure('Failed to parse weather data: $e', s);
    }
  }
}
