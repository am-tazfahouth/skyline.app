import 'package:equatable/equatable.dart';

class DailyWeatherEntity extends Equatable {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final int weatherCode;
  final DateTime sunrise;
  final DateTime sunset;

  const DailyWeatherEntity({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.weatherCode,
    required this.sunrise,
    required this.sunset,
  });

  DailyWeatherEntity copyWith({
    DateTime? date,
    double? tempMax,
    double? tempMin,
    int? weatherCode,
    DateTime? sunrise,
    DateTime? sunset,
  }) {
    return DailyWeatherEntity(
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
