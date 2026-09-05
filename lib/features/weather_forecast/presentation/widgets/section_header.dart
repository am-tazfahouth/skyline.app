import 'package:flutter/material.dart';
import 'package:sky_line/core/constants/app_spacing.dart';
import 'package:sky_line/core/constants/app_text_styles.dart';

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
    final styles = Theme.of(context).extension<TextStyleCatalog>()!;
    return Row(
      children: [
        Icon(size: 18, color: color, icon),
        const SizedBox(width: AppSpacing.xs),
        Text(
          title,
          style: styles.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
