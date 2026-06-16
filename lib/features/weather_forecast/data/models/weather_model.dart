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

  @override
  List<Object?> get props => [current, hourly, daily];
}
