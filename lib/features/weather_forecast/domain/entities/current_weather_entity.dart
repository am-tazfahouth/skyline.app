import 'package:equatable/equatable.dart';

class CurrentWeatherEntity extends Equatable {
  final double temperature;
  final int humidity;
  final bool isDay;
  final double windSpeed;
  final double precipitation;
  final int weatherCode;

  const CurrentWeatherEntity({
    required this.temperature,
    required this.humidity,
    required this.isDay,
    required this.windSpeed,
    required this.precipitation,
    required this.weatherCode,
  });

  CurrentWeatherEntity copyWith({
    double? temperature,
    int? humidity,
    bool? isDay,
    double? windSpeed,
    double? precipitation,
    int? weatherCode,
  }) {
    return CurrentWeatherEntity(
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
