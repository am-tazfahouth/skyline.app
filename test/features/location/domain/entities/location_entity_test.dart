import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';

void main() {
  group('LocationEntity', () {
    test('supports value equality', () {
      const a = LocationEntity(latitude: 48.85, longitude: 2.35, cityName: 'Paris');
      const b = LocationEntity(latitude: 48.85, longitude: 2.35, cityName: 'Paris');
      expect(a, equals(b));
    });

    test('copyWith creates new instance with updated fields', () {
      const original = LocationEntity(latitude: 48.85, longitude: 2.35, cityName: 'Paris');
      final updated = original.copyWith(cityName: 'Lyon');
      expect(updated.cityName, 'Lyon');
      expect(updated.latitude, 48.85);
      expect(original.cityName, 'Paris');
    });

    test('isGpsLocation defaults to false', () {
      const loc = LocationEntity(latitude: 0, longitude: 0, cityName: 'Test');
      expect(loc.isGpsLocation, false);
    });

    test('sortOrder defaults to 0', () {
      const loc = LocationEntity(latitude: 0, longitude: 0, cityName: 'Test');
      expect(loc.sortOrder, 0);
    });
  });

  group('title', () {
    test('joins city and country with a comma', () {
      const loc = LocationEntity(
        latitude: 0,
        longitude: 0,
        cityName: 'Moroni',
        country: 'Comoros',
      );
      expect(loc.title, 'Moroni, Comoros');
    });

    test('falls back to city when country is null', () {
      const loc = LocationEntity(latitude: 0, longitude: 0, cityName: 'Paris');
      expect(loc.title, 'Paris');
    });

    test('falls back to city when country is empty', () {
      const loc = LocationEntity(
        latitude: 0,
        longitude: 0,
        cityName: 'Paris',
        country: '',
      );
      expect(loc.title, 'Paris');
    });
  });
}
