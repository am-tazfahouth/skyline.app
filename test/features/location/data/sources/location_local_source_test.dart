import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/config/db_helper/db_helper.dart';
import 'package:sky_line/core/config/db_helper/location_cache_entity.dart';
import 'package:sky_line/core/config/db_helper/last_location_entity.dart';
import 'package:sky_line/features/location/data/sources/location_local_source.dart';

class MockDbHelper extends Mock implements DbHelper {}

void main() {
  late MockDbHelper mockDbHelper;
  late LocationLocalSource source;

  setUp(() {
    mockDbHelper = MockDbHelper();
    source = LocationLocalSource(mockDbHelper);
  });

  group('loadFavorites', () {
    test('returns list from DbHelper', () {
      when(() => mockDbHelper.loadFavorites()).thenReturn([
        LocationCacheEntity(latitude: 48.85, longitude: 2.35, cityName: 'Paris'),
      ]);

      final result = source.loadFavorites();
      expect(result, hasLength(1));
      expect(result.first.cityName, 'Paris');
    });
  });

  group('loadLastLocation', () {
    test('returns null when no last location', () {
      when(() => mockDbHelper.loadLastLocation()).thenReturn(null);
      expect(source.loadLastLocation(), isNull);
    });

    test('returns LastLocationEntity when exists', () {
      final entity = LastLocationEntity(
        latitude: 48.85,
        longitude: 2.35,
        cityName: 'Paris',
      );
      when(() => mockDbHelper.loadLastLocation()).thenReturn(entity);

      final result = source.loadLastLocation();
      expect(result, isNotNull);
      expect(result!.cityName, 'Paris');
    });
  });
}
