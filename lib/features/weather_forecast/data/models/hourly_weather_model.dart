import 'package:equatable/equatable.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/hourly_weather_entity.dart';

class HourlyWeatherModel extends Equatable {
  final DateTime time;
  final double temperature;
  final int precipitationProbability;
  final int weatherCode;

  const HourlyWeatherModel({
    required this.time,
    required this.temperature,
    required this.precipitationProbability,
    required this.weatherCode,
  });

  factory HourlyWeatherModel.fromJson(Map<String, dynamic> json) {
    return HourlyWeatherModel(
      time: DateTime.parse(json['time'] as String),
      temperature: (json['temperature_2m'] as num).toDouble(),
      precipitationProbability:
          (json['precipitation_probability'] as num).toInt(),
      weatherCode: (json['weather_code'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'temperature_2m': temperature,
        'precipitation_probability': precipitationProbability,
        'weather_code': weatherCode,
      };

  HourlyWeatherEntity toEntity() => HourlyWeatherEntity(
        time: time,
        temperature: temperature,
        precipitationProbability: precipitationProbability,
        weatherCode: weatherCode,
      );

  HourlyWeatherModel copyWith({
    DateTime? time,
    double? temperature,
    int? precipitationProbability,
    int? weatherCode,
  }) {
    return HourlyWeatherModel(
      time: time ?? this.time,
      temperature: temperature ?? this.temperature,
      precipitationProbability:
          precipitationProbability ?? this.precipitationProbability,
      weatherCode: weatherCode ?? this.weatherCode,
    );
  }

  @override
  List<Object?> get props => [
        time,
        temperature,
        precipitationProbability,
        weatherCode,
      ];
}
