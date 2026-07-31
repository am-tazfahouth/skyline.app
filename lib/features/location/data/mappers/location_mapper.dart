import 'package:sky_line/features/location/data/models/location_model.dart';

class LocationMapper {
  const LocationMapper._();

  static List<LocationModel> fromJsonList(Map<String, dynamic> json) {
    final results = json['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return [];

    return results
        .map((e) => LocationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
