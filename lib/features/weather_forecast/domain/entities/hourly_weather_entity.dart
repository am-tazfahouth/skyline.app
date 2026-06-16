import 'package:equatable/equatable.dart';

class HourlyWeatherEntity extends Equatable {
  final DateTime time;
  final double temperature;
  final int precipitationProbability;
  final int weatherCode;

  const HourlyWeatherEntity({
    required this.time,
    required this.temperature,
    required this.precipitationProbability,
    required this.weatherCode,
  });

  HourlyWeatherEntity copyWith({
    DateTime? time,
    double? temperature,
    int? precipitationProbability,
    int? weatherCode,
  }) {
    return HourlyWeatherEntity(
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
