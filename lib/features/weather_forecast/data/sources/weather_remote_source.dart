import 'package:dio/dio.dart';
import 'package:sky_line/core/constants/api_constants.dart';
import 'package:sky_line/core/errors/failure.dart';

class WeatherRemoteSource {
  final Dio _dio;

  WeatherRemoteSource(this._dio);

  Future<Map<String, dynamic>> fetchWeather() async {
    try {
      final response = await _dio.get(ApiConstants.openMeteoUrl);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkFailure(
          'No internet connection',
          e.stackTrace,
        );
      }
      throw ServerFailure(
        'Server error: ${e.response?.statusCode ?? e.message}',
        e.stackTrace,
      );
    }
  }
}
