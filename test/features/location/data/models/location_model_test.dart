import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/features/location/data/models/location_model.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';

void main() {
  group('LocationModel', () {
    test('fromJson parses Open-Meteo geocoding response correctly', () {
      final json = {
        'id': 2988507,
        'name': 'Paris',
        'latitude': 48.85341,
        'longitude': 2.3488,
        'country': 'France',
        'admin1': 'Île-de-France',
        'timezone': 'Europe/Paris',
        'population': 2138551,
      };

      final model = LocationModel.fromJson(json);
      expect(model.cityName, 'Paris');
      expect(model.latitude, 48.85341);
      expect(model.longitude, 2.3488);
      expect(model.country, 'France');
      expect(model.admin1, 'Île-de-France');
    });

    test('fromJson handles null country and admin1', () {
      final json = {'name': 'Unknown', 'latitude': 0.0, 'longitude': 0.0};

      final model = LocationModel.fromJson(json);
      expect(model.country, isNull);
      expect(model.admin1, isNull);
    });

    test('toEntity converts to LocationEntity', () {
      const model = LocationModel(
        latitude: 48.85,
        longitude: 2.35,
        cityName: 'Paris',
        country: 'France',
        admin1: 'Île-de-France',
      );

      final entity = model.toEntity();
      expect(entity, isA<LocationEntity>());
      expect(entity.cityName, 'Paris');
      expect(entity.latitude, 48.85);
      expect(entity.isGpsLocation, false);
    });

    test('supports value equality', () {
      const a = LocationModel(
        latitude: 48.85,
        longitude: 2.35,
        cityName: 'Paris',
      );
      const b = LocationModel(
        latitude: 48.85,
        longitude: 2.35,
        cityName: 'Paris',
      );
      expect(a, equals(b));
    });
  });
}
