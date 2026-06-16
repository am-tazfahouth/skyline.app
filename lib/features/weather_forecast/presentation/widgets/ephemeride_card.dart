import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/daily_weather_entity.dart';

class EphemerideCard extends StatelessWidget {
  final DailyWeatherEntity daily;

  const EphemerideCard({super.key, required this.daily});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sunriseStr = DateFormat('hh:mm a').format(daily.sunrise);
    final sunsetStr = DateFormat('hh:mm a').format(daily.sunset);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SunTime(
                  icon: Icons.sunny,
                  label: 'Sunrise',
                  time: sunriseStr,
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _SunTime(
                  icon: Icons.nightlight_round,
                  label: 'Sunset',
                  time: sunsetStr,
                  theme: theme,
                ),
              ],
            ),
          ),
          Expanded(
            child: CustomPaint(
              size: const Size(double.infinity, 80),
              painter: _SunPathPainter(
                sunrise: daily.sunrise,
                sunset: daily.sunset,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SunTime extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final ThemeData theme;

  const _SunTime({
    required this.icon,
    required this.label,
    required this.time,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            Text(time,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ],
    );
  }
}

class _SunPathPainter extends CustomPainter {
  final DateTime sunrise;
  final DateTime sunset;
  final Color color;

  _SunPathPainter({
    required this.sunrise,
    required this.sunset,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(
      size.width / 2,
      0,
      size.width,
      size.height,
    );
    canvas.drawPath(path, paint);

    final now = DateTime.now();
    final total = sunset.difference(sunrise).inMinutes;
    final elapsed = now.difference(sunrise).inMinutes;
    final t = total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0.5;
    final x = t * size.width;
    final y = size.height - (4 * t * (1 - t) * size.height);

    canvas.drawCircle(
      Offset(x, y),
      6,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _SunPathPainter oldDelegate) => true;
}
