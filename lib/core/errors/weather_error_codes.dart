import 'package:sky_line/core/errors/app_error_code.dart';
import 'package:sky_line/core/enums/app_error_source.dart';

class WeatherErrorCodes {
  static const fetch = AppErrorCode(AppErrorSource.weatherForecast, 'fetch');
  static const cache = AppErrorCode(AppErrorSource.weatherForecast, 'cache');
  static const network = AppErrorCode(AppErrorSource.weatherForecast, 'network');
  static const loadCache = AppErrorCode(AppErrorSource.weatherForecast, 'loadCache');
  static const unexpected = AppErrorCode(AppErrorSource.weatherForecast, 'unexpected');
}