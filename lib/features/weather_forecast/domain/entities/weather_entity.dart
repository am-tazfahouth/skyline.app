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

  bool isDayAt(DateTime time) {
    final dayEntry = daily.cast<DailyWeatherEntity?>().firstWhere(
      (d) =>
          d != null &&
          d.sunrise.year == time.year &&
          d.sunrise.month == time.month &&
          d.sunrise.day == time.day,
      orElse: () => null,
    );
    if (dayEntry == null) {
      return time.hour >= 6 && time.hour < 18;
    }
    return time.isAfter(dayEntry.sunrise) && time.isBefore(dayEntry.sunset);
  }

  WeatherEntity withCurrentFromHourly(DateTime now) {
    if (hourly.isEmpty) return this;
    final closest = hourly.reduce(
      (a, b) =>
          a.time.difference(now).abs() < b.time.difference(now).abs() ? a : b,
    );
    return copyWith(
      current: CurrentWeatherEntity(
        temperature: closest.temperature,
        humidity: current.humidity,
        isDay: isDayAt(closest.time),
        windSpeed: current.windSpeed,
        precipitation: current.precipitation,
        weatherCode: closest.weatherCode,
      ),
    );
  }

  @override
  List<Object?> get props => [current, hourly, daily];
}
