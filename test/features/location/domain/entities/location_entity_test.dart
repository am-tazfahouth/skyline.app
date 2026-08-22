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

  group('isAtSamePointAs', () {
    test('returns true for identical coordinates', () {
      const a = LocationEntity(latitude: 48.8566, longitude: 2.3522, cityName: 'Paris');
      const b = LocationEntity(latitude: 48.8566, longitude: 2.3522, cityName: 'Paris');
      expect(a.isAtSamePointAs(b), isTrue);
    });

    test('returns true when coordinates differ only below the 4th decimal', () {
      const searched = LocationEntity(
        latitude: 48.8566,
        longitude: 2.3522,
        cityName: 'Paris',
      );
      const gpsFix = LocationEntity(
        latitude: 48.8566149,
        longitude: 2.3522087,
        cityName: 'Paris',
        isGpsLocation: true,
      );
      expect(searched.isAtSamePointAs(gpsFix), isTrue);
    });

    test('returns true even when city names differ', () {
      const a = LocationEntity(latitude: 48.8566, longitude: 2.3522, cityName: 'Paris');
      const b = LocationEntity(latitude: 48.8566, longitude: 2.3522, cityName: 'Random');
      expect(a.isAtSamePointAs(b), isTrue);
    });

    test('returns false when latitude differs by more than ~11 meters', () {
      const a = LocationEntity(latitude: 48.8566, longitude: 2.3522, cityName: 'Paris');
      const b = LocationEntity(latitude: 48.8571, longitude: 2.3522, cityName: 'Paris');
      expect(a.isAtSamePointAs(b), isFalse);
    });

    test('returns false when longitude differs by more than ~11 meters', () {
      const a = LocationEntity(latitude: 48.8566, longitude: 2.3522, cityName: 'Paris');
      const b = LocationEntity(latitude: 48.8566, longitude: 2.3533, cityName: 'Paris');
      expect(a.isAtSamePointAs(b), isFalse);
    });

    test('handles negative coordinates consistently', () {
      const a = LocationEntity(latitude: 40.7128, longitude: -74.00601, cityName: 'New York');
      const b = LocationEntity(latitude: 40.7128, longitude: -74.006049, cityName: 'New York');
      expect(a.isAtSamePointAs(b), isTrue);
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
