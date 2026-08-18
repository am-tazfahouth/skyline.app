import 'package:equatable/equatable.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/current_weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/daily_weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/hourly_weather_entity.dart';

class WeatherEntity extends Equatable {
  final CurrentWeatherEntity current;
  final List<HourlyWeatherEntity> hourly;
  final List<DailyWeatherEntity> daily;

  const WeatherEntity({
    required this.current,
    required this.hourly,
    required this.daily,
  });

  WeatherEntity copyWith({
    CurrentWeatherEntity? current,
    List<HourlyWeatherEntity>? hourly,
    List<DailyWeatherEntity>? daily,
  }) {
    return WeatherEntity(
      current: current ?? this.current,
      hourly: hourly ?? this.hourly,
      daily: daily ?? this.daily,
    );
  }

  WeatherEntity withCurrentFromHourly(DateTime now) {
    if (hourly.isEmpty) return this;
    final closest = hourly.reduce((a, b) =>
        a.time.difference(now).abs() < b.time.difference(now).abs()
            ? a
            : b);
    return copyWith(
      current: CurrentWeatherEntity(
        temperature: closest.temperature,
        humidity: current.humidity,
        isDay: closest.time.hour >= 6 && closest.time.hour < 18,
        windSpeed: current.windSpeed,
        precipitation: current.precipitation,
        weatherCode: closest.weatherCode,
      ),
    );
  }

  @override
  List<Object?> get props => [current, hourly, daily];
}
