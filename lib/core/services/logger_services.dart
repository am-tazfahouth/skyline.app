abstract class AppLogger {
  void e(String message, {Object? error, StackTrace? stackTrace});
  void w(String message);
  void i(String message);
}
