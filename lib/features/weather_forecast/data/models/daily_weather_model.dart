import 'package:equatable/equatable.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/daily_weather_entity.dart';

class DailyWeatherModel extends Equatable {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final int weatherCode;
  final DateTime sunrise;
  final DateTime sunset;

  const DailyWeatherModel({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.weatherCode,
    required this.sunrise,
    required this.sunset,
  });

  factory DailyWeatherModel.fromJson(Map<String, dynamic> json) {
    return DailyWeatherModel(
      date: DateTime.parse(json['time'] as String),
      tempMax: (json['temperature_2m_max'] as num).toDouble(),
      tempMin: (json['temperature_2m_min'] as num).toDouble(),
      weatherCode: (json['weather_code'] as num).toInt(),
      sunrise: DateTime.parse(json['sunrise'] as String),
      sunset: DateTime.parse(json['sunset'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'time': date.toIso8601String(),
        'temperature_2m_max': tempMax,
        'temperature_2m_min': tempMin,
        'weather_code': weatherCode,
        'sunrise': sunrise.toIso8601String(),
        'sunset': sunset.toIso8601String(),
      };

  DailyWeatherEntity toEntity() => DailyWeatherEntity(
        date: date,
        tempMax: tempMax,
        tempMin: tempMin,
        weatherCode: weatherCode,
        sunrise: sunrise,
        sunset: sunset,
      );

  DailyWeatherModel copyWith({
    DateTime? date,
    double? tempMax,
    double? tempMin,
    int? weatherCode,
    DateTime? sunrise,
    DateTime? sunset,
  }) {
    return DailyWeatherModel(
      date: date ?? this.date,
      tempMax: tempMax ?? this.tempMax,
      tempMin: tempMin ?? this.tempMin,
      weatherCode: weatherCode ?? this.weatherCode,
      sunrise: sunrise ?? this.sunrise,
      sunset: sunset ?? this.sunset,
    );
  }

  @override
  List<Object?> get props => [
        date,
        tempMax,
        tempMin,
        weatherCode,
        sunrise,
        sunset,
      ];
}
