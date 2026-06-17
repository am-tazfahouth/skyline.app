import 'package:dio/dio.dart';
import 'package:sky_line/core/config/db_helper/db_helper.dart';
import 'package:sky_line/features/weather_forecast/data/repositories/weather_repository_impl.dart';
import 'package:sky_line/features/weather_forecast/data/sources/weather_remote_source.dart';
import 'package:sky_line/features/weather_forecast/domain/usecases/fetch_weather_usecase.dart';

class InjectionContainer {
  static late final Dio dio;
  static late final DbHelper dbHelper;
  static late final WeatherRemoteSource weatherRemoteSource;
  static late final WeatherRepositoryImpl weatherRepository;
  static late final FetchWeatherUseCase fetchWeatherUseCase;

  static Future<void> init() async {
    dbHelper = await DbHelper.init();
    dio = Dio();
    weatherRemoteSource = WeatherRemoteSource(dio);
    weatherRepository = WeatherRepositoryImpl(weatherRemoteSource, dbHelper);
    fetchWeatherUseCase = FetchWeatherUseCase(weatherRepository);
  }

  static void dispose() {
    dbHelper.dispose();
  }
}
