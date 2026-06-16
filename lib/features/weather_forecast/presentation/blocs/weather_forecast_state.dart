import 'package:equatable/equatable.dart';
import 'package:sky_line/core/errors/failure.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/weather_entity.dart';

abstract class WeatherForecastState extends Equatable {
  const WeatherForecastState();

  @override
  List<Object?> get props => [];
}

class WeatherInitial extends WeatherForecastState {
  const WeatherInitial();
}

class WeatherLoading extends WeatherForecastState {
  const WeatherLoading();
}

class WeatherLoaded extends WeatherForecastState {
  final WeatherEntity weather;

  const WeatherLoaded(this.weather);

  @override
  List<Object?> get props => [weather];
}

class WeatherError extends WeatherForecastState {
  final Failure failure;

  const WeatherError(this.failure);

  @override
  List<Object?> get props => [failure];
}
