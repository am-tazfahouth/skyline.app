import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/current_weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/daily_weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/hourly_weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/weather_entity.dart';

void main() {
  final current = const CurrentWeatherEntity(
    temperature: 20.0,
    humidity: 60,
    isDay: true,
    windSpeed: 5.0,
    precipitation: 0.0,
    weatherCode: 0,
  );

  WeatherEntity buildEntity({
    DateTime? sunrise,
    DateTime? sunset,
    bool includeDaily = true,
  }) {
    final now = DateTime(2026, 6, 17, 12);
    final daily = includeDaily
        ? [
            DailyWeatherEntity(
              date: DateTime(2026, 6, 17),
              tempMax: 25.0,
              tempMin: 10.0,
              weatherCode: 0,
              sunrise: sunrise ?? DateTime(2026, 6, 17, 6),
              sunset: sunset ?? DateTime(2026, 6, 17, 20),
            ),
          ]
        : <DailyWeatherEntity>[];
    return WeatherEntity(
      current: current,
      hourly: [
        HourlyWeatherEntity(
          time: now,
          temperature: 20.0,
          precipitationProbability: 0,
          weatherCode: 0,
        ),
      ],
      daily: daily,
    );
  }

  group('isDayAt', () {
    test('returns true for a time between sunrise and sunset', () {
      final entity = buildEntity(
        sunrise: DateTime(2026, 6, 17, 6),
        sunset: DateTime(2026, 6, 17, 20),
      );
      expect(entity.isDayAt(DateTime(2026, 6, 17, 12)), isTrue);
      expect(entity.isDayAt(DateTime(2026, 6, 17, 6, 1)), isTrue);
      expect(entity.isDayAt(DateTime(2026, 6, 17, 19, 59)), isTrue);
    });

    test('returns false outside sunrise/sunset using the daily entry', () {
      final entity = buildEntity(
        sunrise: DateTime(2026, 6, 17, 6),
        sunset: DateTime(2026, 6, 17, 20),
      );
      expect(entity.isDayAt(DateTime(2026, 6, 17, 5, 59)), isFalse);
      expect(entity.isDayAt(DateTime(2026, 6, 17, 20, 1)), isFalse);
    });

    test('respects an early sunrise (high latitude winter)', () {
      final entity = buildEntity(
        sunrise: DateTime(2026, 6, 17, 10),
        sunset: DateTime(2026, 6, 17, 15),
      );
      expect(entity.isDayAt(DateTime(2026, 6, 17, 9)), isFalse);
      expect(entity.isDayAt(DateTime(2026, 6, 17, 12)), isTrue);
      expect(entity.isDayAt(DateTime(2026, 6, 17, 16)), isFalse);
    });

    test('picks the daily entry matching the given day', () {
      final entity = buildEntity(
        sunrise: DateTime(2026, 6, 16, 4),
        sunset: DateTime(2026, 6, 16, 22),
      );
      final withTwoDays = WeatherEntity(
        current: current,
        hourly: entity.hourly,
        daily: [
          ...entity.daily,
          DailyWeatherEntity(
            date: DateTime(2026, 6, 18),
            tempMax: 30.0,
            tempMin: 12.0,
            weatherCode: 1,
            sunrise: DateTime(2026, 6, 18, 8),
            sunset: DateTime(2026, 6, 18, 18),
          ),
        ],
      );
      expect(withTwoDays.isDayAt(DateTime(2026, 6, 18, 12)), isTrue);
      expect(withTwoDays.isDayAt(DateTime(2026, 6, 18, 21)), isFalse);
    });

    test('falls back to the hour heuristic when no daily entry matches', () {
      final entity = buildEntity(includeDaily: false);
      expect(entity.isDayAt(DateTime(2026, 6, 17, 12)), isTrue);
      expect(entity.isDayAt(DateTime(2026, 6, 17, 6)), isTrue);
      expect(entity.isDayAt(DateTime(2026, 6, 17, 5, 59)), isFalse);
      expect(entity.isDayAt(DateTime(2026, 6, 17, 18)), isFalse);
    });
  });

  group('withCurrentFromHourly', () {
    test('sets isDay from the daily sunrise/sunset of the closest hour', () {
      final entity = buildEntity(
        sunrise: DateTime(2026, 6, 17, 10),
        sunset: DateTime(2026, 6, 17, 14),
      );
      final updated = entity.withCurrentFromHourly(DateTime(2026, 6, 17, 12));
      expect(updated.current.isDay, isTrue);

      final night = buildEntity(
        sunrise: DateTime(2026, 6, 17, 10),
        sunset: DateTime(2026, 6, 17, 11),
      );
      final updatedNight = night.withCurrentFromHourly(
        DateTime(2026, 6, 17, 12),
      );
      expect(updatedNight.current.isDay, isFalse);
    });
  });
}
