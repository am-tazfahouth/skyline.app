import 'package:flutter/material.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/constants/app_radius.dart';
import 'package:sky_line/core/constants/app_spacing.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/weather_daily_tile_list.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/weather_hourly_tile_list.dart';

class WeatherForecastSection extends StatelessWidget {
  const WeatherForecastSection({super.key});

  @override
  Widget build(BuildContext context) {
    final surface = AppTheme.surfaceFor(Theme.of(context).brightness);
    final cardColor = surface.colorContainer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const WeatherHourlyTileList(),
        ),
        SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const WeatherDailyTileList(),
        ),
      ],
    );
  }
}
