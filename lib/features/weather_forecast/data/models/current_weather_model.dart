import 'package:equatable/equatable.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/current_weather_entity.dart';

class CurrentWeatherModel extends Equatable {
  final double temperature;
  final int humidity;
  final bool isDay;
  final double windSpeed;
  final double precipitation;
  final int weatherCode;

  const CurrentWeatherModel({
    required this.temperature,
    required this.humidity,
    required this.isDay,
    required this.windSpeed,
    required this.precipitation,
    required this.weatherCode,
  });

  factory CurrentWeatherModel.fromJson(Map<String, dynamic> json) {
    return CurrentWeatherModel(
      temperature: (json['temperature_2m'] as num).toDouble(),
      humidity: (json['relative_humidity_2m'] as num).toInt(),
      isDay: (json['is_day'] as num).toInt() == 1,
      windSpeed: (json['wind_speed_10m'] as num).toDouble(),
      precipitation: (json['precipitation'] as num).toDouble(),
      weatherCode: (json['weather_code'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'temperature_2m': temperature,
    'relative_humidity_2m': humidity,
    'is_day': isDay ? 1 : 0,
    'wind_speed_10m': windSpeed,
    'precipitation': precipitation,
    'weather_code': weatherCode,
  };

  CurrentWeatherEntity toEntity() => CurrentWeatherEntity(
    temperature: temperature,
    humidity: humidity,
    isDay: isDay,
    windSpeed: windSpeed,
    precipitation: precipitation,
    weatherCode: weatherCode,
  );

  CurrentWeatherModel copyWith({
    double? temperature,
    int? humidity,
    bool? isDay,
    double? windSpeed,
    double? precipitation,
    int? weatherCode,
  }) {
    return CurrentWeatherModel(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      isDay: isDay ?? this.isDay,
      windSpeed: windSpeed ?? this.windSpeed,
      precipitation: precipitation ?? this.precipitation,
      weatherCode: weatherCode ?? this.weatherCode,
    );
  }

  @override
  List<Object?> get props => [
    temperature,
    humidity,
    isDay,
    windSpeed,
    precipitation,
    weatherCode,
  ];
}
