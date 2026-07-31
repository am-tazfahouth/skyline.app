import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/core/constants/api_constants.dart';

void main() {
  group('ApiConstants.buildForecastUrl', () {
    test('returns correct URL with given latitude and longitude', () {
      final url = ApiConstants.buildForecastUrl(-11.7022, 43.2551);
      expect(url, contains('latitude=-11.7022'));
      expect(url, contains('longitude=43.2551'));
      expect(url, contains('timezone=auto'));
      expect(url, contains('daily='));
      expect(url, contains('hourly='));
      expect(url, contains('current='));
    });

    test('returns correct URL with different coordinates', () {
      final url = ApiConstants.buildForecastUrl(48.8566, 2.3522);
      expect(url, contains('latitude=48.8566'));
      expect(url, contains('longitude=2.3522'));
    });

    test('uses openMeteoBaseUrl', () {
      final url = ApiConstants.buildForecastUrl(0, 0);
      expect(url, startsWith(ApiConstants.openMeteoBaseUrl));
    });
  });
}
