import 'package:equatable/equatable.dart';
import 'package:sky_line/core/errors/app_error_code.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';
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

enum WeatherNotice { none, cachedData, refreshError }

class WeatherLoaded extends WeatherForecastState {
  final WeatherResult result;
  final SettingEntity settings;
  @override
  final bool isFetching;
  final WeatherNotice notice;

  const WeatherLoaded(
    this.result, {
    this.isFetching = false,
    required this.settings,
    this.notice = WeatherNotice.none,
  });

  WeatherLoaded copyWith({
    WeatherResult? result,
    SettingEntity? settings,
    bool? isFetching,
    WeatherNotice? notice,
  }) {
    return WeatherLoaded(
      result ?? this.result,
      isFetching: isFetching ?? this.isFetching,
      settings: settings ?? this.settings,
      notice: notice ?? this.notice,
    );
  }

  @override
  List<Object?> get props => [result, settings, isFetching, notice];
}

class WeatherEmpty extends WeatherForecastState {
  @override
  final bool isFetching;
  final SettingEntity settings;

  const WeatherEmpty({this.isFetching = false, required this.settings});

  @override
  List<Object?> get props => [isFetching, settings];
}

class WeatherError extends WeatherForecastState {
  final AppErrorCode errorCode;

  const WeatherError({required this.errorCode});

  @override
  List<Object?> get props => [errorCode];
}

extension WeatherStateX on WeatherForecastState {
  bool get hasData => this is WeatherLoaded || this is WeatherEmpty;
  bool get hasWeather => this is WeatherLoaded;
  WeatherEntity? get weatherOrNull => switch (this) {
    WeatherLoaded(result: final r) => r.weather,
    _ => null,
  };
  SettingEntity? get settingsOrNull => switch (this) {
    WeatherLoaded(settings: final s) => s,
    WeatherEmpty(settings: final s) => s,
    _ => null,
  };
}
