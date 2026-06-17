import 'package:flutter/material.dart';

/// A single row displaying an icon, a label (e.g. "Sunrise"),
/// and a formatted time string.
///
/// Used twice inside the [WeatherSunTimes] card:
/// one for the first period (sunrise or sunset) and one for the second.
class TimeRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String time;
  final Color primaryText;
  final Color secondaryText;

  const TimeRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.time,
    required this.primaryText,
    required this.secondaryText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: secondaryText, fontSize: 12)),
              Text(
                time,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
