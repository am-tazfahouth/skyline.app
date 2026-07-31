import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/core/enums/app_error_source.dart';
import 'package:sky_line/core/errors/app_error_code.dart';
import 'package:sky_line/core/errors/location_error_codes.dart';

void main() {
  group('LocationErrorCodes', () {
    test('gpsDisabled has correct source and key', () {
      expect(
        LocationErrorCodes.gpsDisabled,
        const AppErrorCode(AppErrorSource.location, 'gpsDisabled'),
      );
    });

    test('gpsPermissionDenied has correct source and key', () {
      expect(
        LocationErrorCodes.gpsPermissionDenied,
        const AppErrorCode(AppErrorSource.location, 'gpsPermissionDenied'),
      );
    });

    test('gpsFailed has correct source and key', () {
      expect(
        LocationErrorCodes.gpsFailed,
        const AppErrorCode(AppErrorSource.location, 'gpsFailed'),
      );
    });

    test('searchFailed has correct source and key', () {
      expect(
        LocationErrorCodes.searchFailed,
        const AppErrorCode(AppErrorSource.location, 'searchFailed'),
      );
    });

    test('saveFavoriteFailed has correct source and key', () {
      expect(
        LocationErrorCodes.saveFavoriteFailed,
        const AppErrorCode(AppErrorSource.location, 'saveFavoriteFailed'),
      );
    });

    test('loadFavoritesFailed has correct source and key', () {
      expect(
        LocationErrorCodes.loadFavoritesFailed,
        const AppErrorCode(AppErrorSource.location, 'loadFavoritesFailed'),
      );
    });

    test('unexpected has correct source and key', () {
      expect(
        LocationErrorCodes.unexpected,
        const AppErrorCode(AppErrorSource.location, 'unexpected'),
      );
    });

    test('all codes use location source', () {
      final codes = [
        LocationErrorCodes.gpsDisabled,
        LocationErrorCodes.gpsPermissionDenied,
        LocationErrorCodes.gpsFailed,
        LocationErrorCodes.searchFailed,
        LocationErrorCodes.saveFavoriteFailed,
        LocationErrorCodes.loadFavoritesFailed,
        LocationErrorCodes.unexpected,
      ];
      for (final code in codes) {
        expect(code.source, AppErrorSource.location);
      }
    });
  });
}
