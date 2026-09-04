import 'package:logger/logger.dart';
import 'package:sky_line/core/services/logger_services.dart';

class LoggerServiceImpl implements AppLogger {
  final Logger _logger;

  LoggerServiceImpl(this._logger);

  @override
  void e(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  @override
  void w(String message) {
    _logger.w(message);
  }

  @override
  void i(String message) {
    _logger.i(message);
  }
}
