import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/core/config/db_helper/db_helper.dart';
import 'package:sky_line/features/weather_forecast/data/models/weather_model.dart';
import 'package:sky_line/features/weather_forecast/data/models/current_weather_model.dart';
import 'package:sky_line/features/weather_forecast/data/models/hourly_weather_model.dart';
import 'package:sky_line/features/weather_forecast/data/models/daily_weather_model.dart';

void main() {
  late DbHelper dbHelper;
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('sky_line_test_');
    dbHelper = await DbHelper.init(directory: tempDir.path);
  });

  tearDown(() {
    dbHelper.dispose();
    tempDir.deleteSync(recursive: true);
  });

  WeatherModel buildModel({required double temperature}) {
    return WeatherModel(
      current: CurrentWeatherModel(
        temperature: temperature,
        humidity: 65,
        isDay: true,
        windSpeed: 12.0,
        precipitation: 0.0,
        weatherCode: 0,
      ),
      hourly: [
        HourlyWeatherModel(
          time: DateTime(2026, 6, 17, 10),
          temperature: temperature,
          precipitationProbability: 10,
          weatherCode: 0,
        ),
      ],
      daily: [
        DailyWeatherModel(
          date: DateTime(2026, 6, 17),
          tempMax: temperature + 2,
          tempMin: temperature - 4,
          weatherCode: 0,
          sunrise: DateTime(2026, 6, 17, 6),
          sunset: DateTime(2026, 6, 17, 20),
        ),
      ],
    );
  }

  group('DbHelper weather cache', () {
    test('saveWeather and loadWeather roundtrip for the same city', () {
      dbHelper.saveWeather(buildModel(temperature: 22.5),
          latitude: 48.85, longitude: 2.35);
      final loaded = dbHelper.loadWeather(latitude: 48.85, longitude: 2.35);

      expect(loaded, isNotNull);
      expect(loaded!.current.temperature, 22.5);
      expect(loaded.hourly.length, 1);
      expect(loaded.daily.length, 1);
    });

    test('loadWeather returns null when nothing is cached', () {
      final loaded = dbHelper.loadWeather(latitude: 48.85, longitude: 2.35);
      expect(loaded, isNull);
    });

    test('loadWeather returns null for a city that was never cached', () {
      dbHelper.saveWeather(buildModel(temperature: 22.5),
          latitude: 48.85, longitude: 2.35);
      final other = dbHelper.loadWeather(latitude: -11.7022, longitude: 43.2551);
      expect(other, isNull);
    });

    test('two cities are cached independently', () {
      dbHelper.saveWeather(buildModel(temperature: 22.5),
          latitude: 48.85, longitude: 2.35);
      dbHelper.saveWeather(buildModel(temperature: 31.0),
          latitude: -11.7022, longitude: 43.2551);

      final paris = dbHelper.loadWeather(latitude: 48.85, longitude: 2.35);
      final moroni = dbHelper.loadWeather(latitude: -11.7022, longitude: 43.2551);
      expect(paris!.current.temperature, 22.5);
      expect(moroni!.current.temperature, 31.0);
    });

    test('re-saving the same city replaces its previous entry', () {
      dbHelper.saveWeather(buildModel(temperature: 22.5),
          latitude: 48.85, longitude: 2.35);
      dbHelper.saveWeather(buildModel(temperature: 27.0),
          latitude: 48.85, longitude: 2.35);

      final paris = dbHelper.loadWeather(latitude: 48.85, longitude: 2.35);
      expect(paris!.current.temperature, 27.0);
    });

    test('loadWeather respects maxAgeMillis', () {
      dbHelper.saveWeather(buildModel(temperature: 22.5),
          latitude: 48.85, longitude: 2.35);
      final expired = dbHelper.loadWeather(
          latitude: 48.85, longitude: 2.35, maxAgeMillis: 0);
      expect(expired, isNull);

      final fresh = dbHelper.loadWeather(latitude: 48.85, longitude: 2.35);
      expect(fresh, isNotNull);
    });
  });

  group('onboarding flag', () {
    test('default flag is false when nothing saved', () {
      expect(dbHelper.loadOnboardingFlag(), isFalse);
    });

    test('loadOnboardingFlag returns true after saveOnboardingFlag(true)', () {
      dbHelper.saveOnboardingFlag(true);
      expect(dbHelper.loadOnboardingFlag(), isTrue);
    });

    test('loadOnboardingFlag returns false after saveOnboardingFlag(false)', () {
      dbHelper.saveOnboardingFlag(true);
      dbHelper.saveOnboardingFlag(false);
      expect(dbHelper.loadOnboardingFlag(), isFalse);
    });
  });
}
