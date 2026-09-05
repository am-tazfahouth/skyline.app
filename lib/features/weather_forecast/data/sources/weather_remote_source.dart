import 'package:dio/dio.dart';
import 'package:sky_line/core/constants/api_constants.dart';

class WeatherRemoteSource {
  final Dio _dio;

  WeatherRemoteSource(this._dio);

  Future<Map<String, dynamic>> fetchWeather(
    double latitude,
    double longitude,
  ) async {
    final url = ApiConstants.buildForecastUrl(latitude, longitude);
    final response = await _dio.get(url);
    return response.data as Map<String, dynamic>;
  }
}
