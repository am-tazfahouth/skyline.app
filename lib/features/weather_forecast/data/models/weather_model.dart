import 'package:equatable/equatable.dart';
import 'package:sky_line/features/weather_forecast/data/models/current_weather_model.dart';
import 'package:sky_line/features/weather_forecast/data/models/daily_weather_model.dart';
import 'package:sky_line/features/weather_forecast/data/models/hourly_weather_model.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/weather_entity.dart';

class WeatherModel extends Equatable {
  final CurrentWeatherModel current;
  final List<HourlyWeatherModel> hourly;
  final List<DailyWeatherModel> daily;

  const WeatherModel({
    required this.current,
    required this.hourly,
    required this.daily,
  });

  WeatherEntity toEntity() => WeatherEntity(
        current: current.toEntity(),
        hourly: hourly.map((h) => h.toEntity()).toList(),
        daily: daily.map((d) => d.toEntity()).toList(),
      );

  WeatherModel copyWith({
    CurrentWeatherModel? current,
    List<HourlyWeatherModel>? hourly,
    List<DailyWeatherModel>? daily,
  }) {
    return WeatherModel(
      current: current ?? this.current,
      hourly: hourly ?? this.hourly,
      daily: daily ?? this.daily,
    );
  }

  Map<String, dynamic> toJson() => {
        'current': current.toJson(),
        'hourly': hourly.map((h) => h.toJson()).toList(),
        'daily': daily.map((d) => d.toJson()).toList(),
      };

  factory WeatherModel.fromCacheJson(Map<String, dynamic> json) {
    return WeatherModel(
      current: CurrentWeatherModel.fromJson(
          json['current'] as Map<String, dynamic>),
      hourly: (json['hourly'] as List)
          .map((h) =>
              HourlyWeatherModel.fromJson(h as Map<String, dynamic>))
          .toList(),
      daily: (json['daily'] as List)
          .map((d) =>
              DailyWeatherModel.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [current, hourly, daily];
}
