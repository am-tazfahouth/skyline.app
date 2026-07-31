import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/features/location/data/mappers/location_mapper.dart';
import 'package:sky_line/features/location/data/models/location_model.dart';

void main() {
  group('LocationMapper', () {
    test('fromJsonList parses array of geocoding results', () {
      final json = {
        'results': [
          {
            'name': 'Paris',
            'latitude': 48.85341,
            'longitude': 2.3488,
            'country': 'France',
            'admin1': 'Île-de-France',
          },
          {
            'name': 'Lyon',
            'latitude': 45.76404,
            'longitude': 4.83566,
            'country': 'France',
            'admin1': 'Auvergne-Rhône-Alpes',
          },
        ],
      };

      final results = LocationMapper.fromJsonList(json);
      expect(results, hasLength(2));
      expect(results[0], isA<LocationModel>());
      expect(results[0].cityName, 'Paris');
      expect(results[1].cityName, 'Lyon');
    });

    test('fromJsonList returns empty list when no results key', () {
      final json = <String, dynamic>{};
      final results = LocationMapper.fromJsonList(json);
      expect(results, isEmpty);
    });

    test('fromJsonList returns empty list when results is empty', () {
      final json = {'results': <dynamic>[]};
      final results = LocationMapper.fromJsonList(json);
      expect(results, isEmpty);
    });
  });
}
