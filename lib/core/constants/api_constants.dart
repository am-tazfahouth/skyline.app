class ApiConstants {
  ApiConstants._();

  static const String openMeteoBaseUrl =
      'https://api.open-meteo.com/v1/forecast';

  static const String openMeteoUrl =
      '$openMeteoBaseUrl?latitude=-11.7022&longitude=43.2551'
      '&daily=temperature_2m_max,temperature_2m_min,weather_code,sunset,sunrise'
      '&hourly=temperature_2m,precipitation_probability,weather_code'
      '&current=temperature_2m,relative_humidity_2m,is_day,wind_speed_10m,precipitation,weather_code'
      '&timezone=auto';
}
