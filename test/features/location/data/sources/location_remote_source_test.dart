import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/features/location/data/models/reverse_geocode_model.dart';
import 'package:sky_line/features/location/data/sources/location_remote_source.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late LocationRemoteSource source;

  setUp(() {
    mockDio = MockDio();
    source = LocationRemoteSource(mockDio);
  });

  group('search', () {
    test('calls Dio with correct URL and returns JSON', () async {
      final responseData = {
        'results': [
          {'name': 'Paris', 'latitude': 48.85, 'longitude': 2.35},
        ],
      };

      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => Response(
        data: responseData,
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ));

      final result = await source.search('Paris', language: 'fr');

      expect(result, equals(responseData));
      verify(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).called(1);
    });

    test('passes language parameter to the API', () async {
      final responseData = {
        'results': [
          {'name': 'Paris', 'latitude': 48.85, 'longitude': 2.35},
        ],
      };

      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => Response(
        data: responseData,
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ));

      await source.search('Paris', language: 'en');

      verify(() => mockDio.get(
        any(),
        queryParameters: {
          'name': 'Paris',
          'count': 10,
          'language': 'en',
          'format': 'json',
        },
      )).called(1);
    });

    test('throws on DioException', () async {
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionTimeout,
      ));

      expect(() => source.search('Paris', language: 'fr'), throwsA(isA<DioException>()));
    });
  });

  group('reverseGeocode', () {
    final responseData = {
      'city': 'Moroni',
      'principalSubdivision': 'Grande Comore',
      'countryName': 'Comoros',
      'countryCode': 'KM',
    };

    void stubSuccess() {
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => Response(
        data: responseData,
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ));
    }

    test('calls Dio with the BigDataCloud URL and parses the response', () async {
      stubSuccess();

      final result = await source.reverseGeocode(latitude: -11.70, longitude: 43.25, language: 'fr');

      expect(result, isA<ReverseGeocodeModel>());
      expect(result.city, 'Moroni');
      verify(() => mockDio.get(
        'https://api.bigdatacloud.net/data/reverse-geocode-client',
        queryParameters: any(named: 'queryParameters'),
      )).called(1);
    });

    test('passes latitude, longitude and localityLanguage from parameter', () async {
      stubSuccess();

      await source.reverseGeocode(latitude: -11.70, longitude: 43.25, language: 'en');

      verify(() => mockDio.get(
        any(),
        queryParameters: {
          'latitude': -11.70,
          'longitude': 43.25,
          'localityLanguage': 'en',
        },
      )).called(1);
    });

    test('throws on DioException', () async {
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionTimeout,
      ));

      expect(
        () => source.reverseGeocode(latitude: -11.70, longitude: 43.25, language: 'fr'),
        throwsA(isA<DioException>()),
      );
    });
  });
}
