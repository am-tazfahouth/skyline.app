import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/current_weather_entity.dart';

class CurrentWeatherCard extends StatelessWidget {
  final CurrentWeatherEntity current;

  const CurrentWeatherCard({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('d MMMM yyyy').format(DateTime.now());
    final condition = _weatherDescription(current.weatherCode);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateStr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                condition,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${current.temperature.toStringAsFixed(0)}°C',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          Icon(
            _weatherIcon(current.weatherCode, current.isDay),
            size: 64,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ],
      ),
    );
  }

  static String _weatherDescription(int code) {
    if (code == 0) return 'Clear sky';
    if (code <= 3) return 'Partly cloudy';
    if (code <= 48) return 'Foggy';
    if (code <= 55) return 'Drizzle';
    if (code <= 65) return 'Rain';
    if (code <= 82) return 'Rain showers';
    return 'Thunderstorm';
  }

  static IconData _weatherIcon(int code, bool isDay) {
    if (code == 0) return isDay ? Icons.wb_sunny : Icons.nightlight_round;
    if (code <= 3) return Icons.cloud;
    if (code <= 48) return Icons.foggy;
    if (code <= 55) return Icons.grain;
    if (code <= 65) return Icons.umbrella;
    if (code <= 82) return Icons.water_drop;
    return Icons.flash_on;
  }
}
