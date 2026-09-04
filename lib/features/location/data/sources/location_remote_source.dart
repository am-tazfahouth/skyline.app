import 'package:dio/dio.dart';
import 'package:sky_line/core/constants/api_constants.dart';
import 'package:sky_line/features/location/data/models/reverse_geocode_model.dart';

class LocationRemoteSource {
  final Dio _dio;

  LocationRemoteSource(this._dio);

  Future<Map<String, dynamic>> search(String query, {required String language}) async {
    final response = await _dio.get(
      ApiConstants.openMeteoGeocodingUrl,
      queryParameters: {
        'name': query,
        'count': 10,
        'language': language,
        'format': 'json',
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<ReverseGeocodeModel> reverseGeocode({
    required double latitude,
    required double longitude,
    required String language,
  }) async {
    final response = await _dio.get(
      ApiConstants.bigDataCloudReverseGeocodeUrl,
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'localityLanguage': language,
      },
    );
    return ReverseGeocodeModel.fromJson(response.data as Map<String, dynamic>);
  }
}
