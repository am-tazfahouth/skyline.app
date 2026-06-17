import 'package:sky_line/core/config/db_helper/db_helper.dart';
import 'package:sky_line/core/errors/failure.dart';
import 'package:sky_line/features/weather_forecast/data/sources/weather_remote_source.dart';
import 'package:sky_line/features/weather_forecast/data/weather_mapper.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/weather_result.dart';
import 'package:sky_line/features/weather_forecast/domain/repositories/weather_repository.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherRemoteSource _remoteSource;
  final DbHelper _dbHelper;

  WeatherRepositoryImpl(this._remoteSource, this._dbHelper);

  @override
  Future<WeatherResult> fetchWeather() async {
    try {
      final json = await _remoteSource.fetchWeather();
      final model = WeatherMapper.fromJson(json);
      _dbHelper.saveWeather(model);
      return WeatherResult(weather: model.toEntity(), isCached: false);
    } on NetworkFailure {
      final cached = _dbHelper.loadWeather();
      if (cached != null) {
        return WeatherResult(weather: cached.toEntity(), isCached: true);
      }
      rethrow;
    } on Failure {
      rethrow;
    } catch (e, s) {
      throw ParsingFailure('Failed to parse weather data: $e', s);
    }
  }
}
