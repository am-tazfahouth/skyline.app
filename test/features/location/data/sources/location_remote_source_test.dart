import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

      final result = await source.search('Paris');

      expect(result, equals(responseData));
      verify(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
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

      expect(() => source.search('Paris'), throwsA(isA<DioException>()));
    });
  });
}
