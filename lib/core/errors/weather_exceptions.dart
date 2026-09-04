class WeatherParseException implements Exception {
  final String message;
  const WeatherParseException(this.message);
  @override
  String toString() => 'WeatherParseException: $message';
}
