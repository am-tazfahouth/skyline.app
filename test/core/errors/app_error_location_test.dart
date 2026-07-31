import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/core/errors/app_error.dart';
import 'package:sky_line/core/errors/location_error_codes.dart';

void main() {
  group('AppError - Location error codes', () {
    test('getDebugErrorMessage returns correct message for gpsDisabled', () {
      final message = AppError.getDebugErrorMessage(
        LocationErrorCodes.gpsDisabled,
      );
      expect(message, 'GPS is disabled on the device.');
    });

    test('getDebugErrorMessage returns correct message for gpsPermissionDenied', () {
      final message = AppError.getDebugErrorMessage(
        LocationErrorCodes.gpsPermissionDenied,
      );
      expect(message, 'GPS permission was denied by the user.');
    });

    test('getDebugErrorMessage returns correct message for gpsFailed', () {
      final message = AppError.getDebugErrorMessage(
        LocationErrorCodes.gpsFailed,
      );
      expect(message, 'Failed to detect GPS location.');
    });

    test('getDebugErrorMessage returns correct message for searchFailed', () {
      final message = AppError.getDebugErrorMessage(
        LocationErrorCodes.searchFailed,
      );
      expect(message, 'Failed to search for cities.');
    });

    test('getDebugErrorMessage returns correct message for saveFavoriteFailed', () {
      final message = AppError.getDebugErrorMessage(
        LocationErrorCodes.saveFavoriteFailed,
      );
      expect(message, 'Failed to save favorite location.');
    });

    test('getDebugErrorMessage returns correct message for loadFavoritesFailed', () {
      final message = AppError.getDebugErrorMessage(
        LocationErrorCodes.loadFavoritesFailed,
      );
      expect(message, 'Failed to load favorite locations.');
    });

    test('getDebugErrorMessage returns correct message for unexpected', () {
      final message = AppError.getDebugErrorMessage(
        LocationErrorCodes.unexpected,
      );
      expect(message, 'An unexpected location error occurred.');
    });

    test('getUserErrorMessage returns correct message for location type', () {
      final message = AppError.getUserErrorMessage(
        LocationErrorCodes.gpsDisabled,
      );
      expect(message, 'Could not get your location. Please check permissions.');
    });

    test('getUserErrorMessage returns correct message for search type', () {
      final message = AppError.getUserErrorMessage(
        LocationErrorCodes.searchFailed,
      );
      expect(message, 'Could not search cities. Please try again.');
    });
  });
}
