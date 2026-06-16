import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/errors/failure.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/current_weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/repositories/weather_repository.dart';
import 'package:sky_line/features/weather_forecast/domain/usecases/fetch_weather_usecase.dart';

class MockWeatherRepository extends Mock implements WeatherRepository {}

void main() {
  late MockWeatherRepository mockRepository;
  late FetchWeatherUseCase useCase;

  setUp(() {
    mockRepository = MockWeatherRepository();
    useCase = FetchWeatherUseCase(mockRepository);
  });

  test('returns WeatherEntity on success', () async {
    final weather = WeatherEntity(
      current: const CurrentWeatherEntity(
        temperature: 26.5,
        humidity: 80,
        isDay: true,
        windSpeed: 12.0,
        precipitation: 0.0,
        weatherCode: 0,
      ),
      hourly: [],
      daily: [],
    );

    when(() => mockRepository.fetchWeather()).thenAnswer(
      (_) async => weather,
    );

    final result = await useCase();
    expect(result, isA<WeatherEntity>());
    expect(result.current.temperature, 26.5);
  });

  test('throws Failure on error', () async {
    when(() => mockRepository.fetchWeather()).thenThrow(
      const NetworkFailure('No internet'),
    );

    expect(() => useCase(), throwsA(isA<NetworkFailure>()));
  });
}
