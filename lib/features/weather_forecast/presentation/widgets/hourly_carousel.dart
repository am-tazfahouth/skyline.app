import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/hourly_weather_entity.dart';

class HourlyCarousel extends StatelessWidget {
  final List<HourlyWeatherEntity> hourly;

  const HourlyCarousel({super.key, required this.hourly});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: hourly.length,
        itemBuilder: (context, index) {
          final hour = hourly[index];
          final timeStr = DateFormat('HH:mm').format(hour.time);
          return Container(
            width: 72,
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(36),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  timeStr,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Icon(
                  _weatherIcon(hour.weatherCode),
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 4),
                Text(
                  '${hour.temperature.toStringAsFixed(0)}°',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static IconData _weatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code <= 3) return Icons.cloud;
    if (code <= 48) return Icons.foggy;
    if (code <= 55) return Icons.grain;
    if (code <= 65) return Icons.umbrella;
    if (code <= 82) return Icons.water_drop;
    return Icons.flash_on;
  }
}
