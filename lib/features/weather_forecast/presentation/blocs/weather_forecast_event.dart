import 'package:equatable/equatable.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';

abstract class WeatherForecastEvent extends Equatable {
  const WeatherForecastEvent();

  @override
  List<Object?> get props => [];
}

class FetchWeatherEvent extends WeatherForecastEvent {
  final double? latitude;
  final double? longitude;

  const FetchWeatherEvent({this.latitude, this.longitude});

  @override
  List<Object?> get props => [latitude, longitude];
}

class RefreshWeatherEvent extends WeatherForecastEvent {
  const RefreshWeatherEvent();
}

class ApplySettingsEvent extends WeatherForecastEvent {
  final SettingEntity settings;

  const ApplySettingsEvent({required this.settings});

  @override
  List<Object?> get props => [settings];
}

class ResetWeatherEvent extends WeatherForecastEvent {
  const ResetWeatherEvent();
}
