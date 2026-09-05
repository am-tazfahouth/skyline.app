import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/features/location/data/models/reverse_geocode_model.dart';

void main() {
  group('fromJson', () {
    test('parses a full response and strips the country article', () {
      final model = ReverseGeocodeModel.fromJson(const {
        'city': 'Paris',
        'locality': 'Saint-Merri',
        'principalSubdivision': 'Île-de-France',
        'countryName': 'France (la)',
        'countryCode': 'FR',
      });

      expect(model.city, 'Paris');
      expect(model.locality, 'Saint-Merri');
      expect(model.principalSubdivision, 'Île-de-France');
      expect(model.countryName, 'France');
      expect(model.countryCode, 'FR');
    });

    test('strips the trailing article from countryName', () {
      final model = ReverseGeocodeModel.fromJson(const {
        'countryName': 'États-Unis d\'Amérique (les)',
      });
      expect(model.countryName, 'États-Unis d\'Amérique');
    });

    test('keeps countryName unchanged when it has no article', () {
      final model = ReverseGeocodeModel.fromJson(const {
        'countryName': 'Comoros',
      });
      expect(model.countryName, 'Comoros');
    });

    test('handles missing fields', () {
      final model = ReverseGeocodeModel.fromJson(const {});
      expect(model.city, isNull);
      expect(model.locality, isNull);
      expect(model.principalSubdivision, isNull);
      expect(model.countryName, isNull);
      expect(model.countryCode, isNull);
    });
  });

  group('copyWith', () {
    test('returns a new instance with updated fields', () {
      const original = ReverseGeocodeModel(
        city: 'Paris',
        countryName: 'France',
      );
      final updated = original.copyWith(city: 'Lyon');
      expect(updated.city, 'Lyon');
      expect(original.city, 'Paris');
    });
  });

  group('equality', () {
    test('is value-based', () {
      const a = ReverseGeocodeModel(city: 'Paris');
      const b = ReverseGeocodeModel(city: 'Paris');
      expect(a, b);
    });
  });
}
