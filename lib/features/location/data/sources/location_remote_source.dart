import 'package:dio/dio.dart';
import 'package:sky_line/core/constants/api_constants.dart';

class LocationRemoteSource {
  final Dio _dio;

  LocationRemoteSource(this._dio);

  Future<Map<String, dynamic>> search(String query) async {
    final response = await _dio.get(
      ApiConstants.openMeteoGeocodingUrl,
      queryParameters: {
        'name': query,
        'count': 10,
        'language': 'fr',
        'format': 'json',
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
