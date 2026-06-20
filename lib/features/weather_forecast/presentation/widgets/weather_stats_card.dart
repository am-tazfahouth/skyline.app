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
        final surface = AppTheme.surfaceFor(Theme.of(context).brightness);
        final cardColor = surface.colorContainer;
        final primaryText = surface.onColor;
        final secondaryText = surface.onColorContainer;

        final weather = state.weatherOrNull;
        final wind = weather != null
            ? WeatherFormat.wind(weather.current.windSpeed)
            : '-- m/s';
        final rain = weather != null
            ? WeatherFormat.percent(weather.current.precipitation)
            : '--%';
        final humidity = weather != null
            ? WeatherFormat.percentInt(weather.current.humidity)
            : '--%';

        return Row(
          children: [
            Expanded(child: _buildStatCard(
              icon: Icons.air_rounded,
              value: wind,
              label: 'Wind',
              cardColor: cardColor,
              primaryText: primaryText,
              secondaryText: secondaryText,
            )),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard(
              icon: Icons.umbrella_rounded,
              value: rain,
              label: 'Chance of rain',
              cardColor: cardColor,
              primaryText: primaryText,
              secondaryText: secondaryText,
            )),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard(
              icon: Icons.water_drop_outlined,
              value: humidity,
              label: 'Humidity',
              cardColor: cardColor,
              primaryText: primaryText,
              secondaryText: secondaryText,
            )),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color cardColor,
    required Color primaryText,
    required Color secondaryText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
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
      ),
    );
  }
}
