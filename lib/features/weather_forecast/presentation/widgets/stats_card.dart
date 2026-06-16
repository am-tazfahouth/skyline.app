import 'package:flutter/material.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/current_weather_entity.dart';

class StatsCard extends StatelessWidget {
  final CurrentWeatherEntity current;

  const StatsCard({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.air,
              value: '${(current.windSpeed / 3.6).toStringAsFixed(0)} m/s',
              label: 'Wind',
              style: style,
              theme: theme,
            ),
          ),
          _divider(theme),
          Expanded(
            child: _StatItem(
              icon: Icons.umbrella,
              value: '${current.precipitation.toStringAsFixed(0)}%',
              label: 'Chance of rain',
              style: style,
              theme: theme,
            ),
          ),
          _divider(theme),
          Expanded(
            child: _StatItem(
              icon: Icons.water_drop,
              value: '${current.humidity}%',
              label: 'Humidity',
              style: style,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(ThemeData theme) {
    return Container(
      width: 1,
      height: 32,
      color: theme.colorScheme.outlineVariant,
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final TextStyle? style;
  final ThemeData theme;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.style,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w700,
        )),
        Text(label, style: style),
      ],
    );
  }
}
