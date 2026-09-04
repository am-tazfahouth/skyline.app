class ApiConstants {
  ApiConstants._();

  static const String openMeteoBaseUrl =
      'https://api.open-meteo.com/v1/forecast';

  static const String openMeteoGeocodingUrl =
      'https://geocoding-api.open-meteo.com/v1/search';

  static const String bigDataCloudReverseGeocodeUrl =
      'https://api.bigdatacloud.net/data/reverse-geocode-client';

  static const int searchResultLimit = 10;

  static const String _dailyParams =
      'temperature_2m_max,temperature_2m_min,weather_code,sunset,sunrise';
  static const String _hourlyParams =
      'temperature_2m,precipitation_probability,weather_code';
  static const String _currentParams =
      'temperature_2m,relative_humidity_2m,is_day,wind_speed_10m,precipitation,weather_code';

  static String buildForecastUrl(double latitude, double longitude) {
    return '$openMeteoBaseUrl?latitude=$latitude&longitude=$longitude'
        '&daily=$_dailyParams&hourly=$_hourlyParams&current=$_currentParams&timezone=auto';
  }
}
