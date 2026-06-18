import 'package:sky_line/core/config/db_helper/db_helper.dart';
import 'package:sky_line/core/errors/failure.dart';
import 'package:sky_line/features/weather_forecast/data/sources/weather_remote_source.dart';
import 'package:sky_line/features/weather_forecast/data/weather_mapper.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/weather_result.dart';
import 'package:sky_line/features/weather_forecast/domain/repositories/weather_repository.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherRemoteSource _remoteSource;
  final DbHelper _dbHelper;
  final int _cacheMaxAgeDays;

  WeatherRepositoryImpl(this._remoteSource, this._dbHelper, [this._cacheMaxAgeDays = 6]);

  @override
  Future<WeatherResult?> loadCachedWeather() async {
    final cached = _dbHelper.loadWeather(
      maxAgeMillis: _cacheMaxAgeDays * 24 * 60 * 60 * 1000,
    );
    if (cached == null) return null;
    return WeatherResult(weather: cached.toEntity(), isCached: true);
  }

  @override
  Future<WeatherResult> fetchWeather() async {
    try {
      final json = await _remoteSource.fetchWeather();
      final model = WeatherMapper.fromJson(json);
      _dbHelper.saveWeather(model);
      return WeatherResult(weather: model.toEntity(), isCached: false);
    } on Failure {
      rethrow;
    } catch (e, s) {
      throw ParsingFailure('Failed to parse weather data: $e', s);
    }
  }
}
