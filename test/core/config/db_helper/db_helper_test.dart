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

  group('DbHelper', () {
    test('saveWeather and loadWeather roundtrip', () {
      final model = WeatherModel(
        current: CurrentWeatherModel(
          temperature: 22.5,
          humidity: 65,
          isDay: true,
          windSpeed: 12.0,
          precipitation: 0.0,
          weatherCode: 0,
        ),
        hourly: [
          HourlyWeatherModel(
            time: DateTime(2026, 6, 17, 10),
            temperature: 22.5,
            precipitationProbability: 10,
            weatherCode: 0,
          ),
        ],
        daily: [
          DailyWeatherModel(
            date: DateTime(2026, 6, 17),
            tempMax: 25.0,
            tempMin: 18.0,
            weatherCode: 0,
            sunrise: DateTime(2026, 6, 17, 6),
            sunset: DateTime(2026, 6, 17, 20),
          ),
        ],
      );

      dbHelper.saveWeather(model);
      final loaded = dbHelper.loadWeather();

      expect(loaded, isNotNull);
      expect(loaded!.current.temperature, 22.5);
      expect(loaded.hourly.length, 1);
      expect(loaded.daily.length, 1);
    });

    test('loadWeather returns null when empty', () {
      final loaded = dbHelper.loadWeather();
      expect(loaded, isNull);
    });

    test('loadWeather respects maxAgeMillis', () {
      final model = WeatherModel(
        current: CurrentWeatherModel(
          temperature: 22.5, humidity: 65, isDay: true,
          windSpeed: 12.0, precipitation: 0.0, weatherCode: 0,
        ),
        hourly: [],
        daily: [],
      );

      dbHelper.saveWeather(model);
      // 0ms TTL should expire immediately
      final expired = dbHelper.loadWeather(maxAgeMillis: 0);
      expect(expired, isNull);

      // no TTL should return data
      final fresh = dbHelper.loadWeather();
      expect(fresh, isNotNull);
    });
  });
}
