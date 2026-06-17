import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/utils/weather_format.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_state.dart';

class WeatherStatsCard extends StatelessWidget {
  const WeatherStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeatherForecastBloc, WeatherForecastState>(
      builder: (context, state) {
        if (state is! WeatherLoaded) {
          return const SizedBox.shrink();
        }

        final surface = AppTheme.surfaceFor(Theme.of(context).brightness);
        final cardColor = surface.colorContainer;
        final primaryText = surface.onColor;
        final secondaryText = surface.onColorContainer;

        final current = state.weather.current;
        final wind = WeatherFormat.wind(current.windSpeed);
        final rain = WeatherFormat.percent(current.precipitation);
        final humidity = WeatherFormat.percentInt(current.humidity);

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(icon: Icons.air_rounded, value: wind, label: 'Wind', primaryText: primaryText, secondaryText: secondaryText),
                  _buildVerticalDivider(secondaryText: secondaryText),
                  _buildStatItem(icon: Icons.umbrella_rounded, value: rain, label: 'Chance of rain', primaryText: primaryText, secondaryText: secondaryText),
                  _buildVerticalDivider(secondaryText: secondaryText),
                  _buildStatItem(icon: Icons.water_drop_outlined, value: humidity, label: 'Humidity', primaryText: primaryText, secondaryText: secondaryText),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color primaryText,
    required Color secondaryText,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: secondaryText, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: primaryText,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(color: secondaryText, fontSize: 11)),
      ],
    );
  }

  Widget _buildVerticalDivider({required Color secondaryText}) {
    return Container(height: 36, width: 1, color: secondaryText.withValues(alpha: 0.3));
  }
}
