import 'package:equatable/equatable.dart';
import 'package:sky_line/core/errors/failure.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/weather_result.dart';

abstract class WeatherForecastState extends Equatable {
  const WeatherForecastState();

  bool get isFetching => false;

  @override
  List<Object?> get props => [];
}

class WeatherInitial extends WeatherForecastState {
  const WeatherInitial();
}

class WeatherLoaded extends WeatherForecastState {
  final WeatherResult result;
  @override
  final bool isFetching;

  const WeatherLoaded(this.result, {this.isFetching = false});

  WeatherLoaded copyWith({WeatherResult? result, bool? isFetching}) {
    return WeatherLoaded(
      result ?? this.result,
      isFetching: isFetching ?? this.isFetching,
    );
  }

  @override
  List<Object?> get props => [result, isFetching];
}

class WeatherEmpty extends WeatherForecastState {
  @override
  final bool isFetching;

  const WeatherEmpty({this.isFetching = false});

  @override
  List<Object?> get props => [isFetching];
}

class WeatherError extends WeatherForecastState {
  final Failure failure;

  const WeatherError(this.failure);

  @override
  List<Object?> get props => [failure];
}

extension WeatherStateX on WeatherForecastState {
  bool get hasData => this is WeatherLoaded || this is WeatherEmpty;
  bool get hasWeather => this is WeatherLoaded;
  WeatherEntity? get weatherOrNull => switch (this) {
    WeatherLoaded(result: final r) => r.weather,
    _ => null,
  };
}
