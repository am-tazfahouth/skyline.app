import 'package:equatable/equatable.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/weather_entity.dart';

class WeatherResult extends Equatable {
  final WeatherEntity weather;
  final bool isCached;

  const WeatherResult({required this.weather, required this.isCached});

  WeatherResult copyWith({WeatherEntity? weather, bool? isCached}) {
    return WeatherResult(
      weather: weather ?? this.weather,
      isCached: isCached ?? this.isCached,
    );
  }

  @override
  List<Object?> get props => [weather, isCached];
}
