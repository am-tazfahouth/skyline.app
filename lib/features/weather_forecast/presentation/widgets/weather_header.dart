import 'package:flutter/material.dart';

class WeatherHeader extends StatelessWidget {
  const WeatherHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.dashboard, color: theme.colorScheme.onSurface),
          Row(
            children: [
              Icon(Icons.pin_drop,
                  size: 16, color: theme.colorScheme.onSurface),
              const SizedBox(width: 4),
              Text(
                'Moroni, Comoros',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down,
                  color: theme.colorScheme.onSurface),
            ],
          ),
          Icon(Icons.settings, color: theme.colorScheme.onSurface),
        ],
      ),
    );
  }
}
