import 'package:equatable/equatable.dart';

abstract class WeatherForecastEvent extends Equatable {
  const WeatherForecastEvent();

  @override
  List<Object?> get props => [];
}

class FetchWeatherEvent extends WeatherForecastEvent {
  const FetchWeatherEvent();
}

class RefreshWeatherEvent extends WeatherForecastEvent {
  const RefreshWeatherEvent();
}
