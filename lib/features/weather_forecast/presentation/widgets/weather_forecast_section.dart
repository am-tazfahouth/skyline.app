import 'package:flutter/material.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/weather_daily_tile_list.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/weather_hourly_tile_list.dart';

class WeatherForecastSection extends StatelessWidget {
  const WeatherForecastSection({super.key});

  @override
  Widget build(BuildContext context) {
    final surface = AppTheme.surfaceFor(Theme.of(context).brightness);
    final cardColor = surface.colorContainer;
/*     final primaryText = surface.onColor;
 */
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const WeatherHourlyTileList(),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const WeatherDailyTileList(),
        ),
      ],
    );
  }
}
