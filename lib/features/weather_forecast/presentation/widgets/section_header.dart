import 'package:flutter/material.dart';

/// Section title bar used across forecast cards (hourly, daily, sun times).
class WeatherSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const WeatherSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          size: 18,
          color: color,
          icon,
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
