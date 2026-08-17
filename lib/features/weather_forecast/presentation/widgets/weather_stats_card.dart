import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/constants/app_radius.dart';
import 'package:sky_line/core/constants/app_spacing.dart';
import 'package:sky_line/core/constants/app_text_styles.dart';
import 'package:sky_line/core/enums/setting_wind_unit.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/core/utils/weather_format.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/hourly_weather_entity.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_state.dart';

class WeatherStatsCard extends StatelessWidget {
  const WeatherStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeatherForecastBloc, WeatherForecastState>(
      builder: (context, state) {
        final surface = AppTheme.surfaceFor(Theme.of(context).brightness);
        final styles = Theme.of(context).extension<TextStyleCatalog>()!;
        final l10n = AppLocalisation.of(context)!;
        final cardColor = surface.colorContainer;
        final primaryText = surface.onColor;
        final secondaryText = surface.onColorContainer;

        final weather = state.weatherOrNull;
        final settings = state.settingsOrNull;
        final wind = weather != null
            ? WeatherFormat.wind(weather.current.windSpeed, unit: settings?.windUnit ?? SettingWindUnit.ms)
            : '-- m/s';
        final rain = weather != null
            ? WeatherFormat.percentInt(_findCurrentHourPrecipitationProbability(weather.hourly))
            : '--%';
        final humidity = weather != null
            ? WeatherFormat.percentInt(weather.current.humidity)
            : '--%';

        return Row(
          children: [
            Expanded(child: _buildStatCard(
              styles: styles,
              icon: Icons.air_rounded,
              value: wind,
              label: l10n.weatherStatsWind,
              cardColor: cardColor,
              primaryText: primaryText,
              secondaryText: secondaryText,
            )),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: _buildStatCard(
              styles: styles,
              icon: Icons.umbrella_rounded,
              value: rain,
              label: l10n.weatherStatsChanceOfRain,
              cardColor: cardColor,
              primaryText: primaryText,
              secondaryText: secondaryText,
            )),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: _buildStatCard(
              styles: styles,
              icon: Icons.water_drop_outlined,
              value: humidity,
              label: l10n.weatherStatsHumidity,
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
    required TextStyleCatalog styles,
    required IconData icon,
    required String value,
    required String label,
    required Color cardColor,
    required Color primaryText,
    required Color secondaryText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: secondaryText, size: 20),
          SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: styles.titleMedium.copyWith(color: primaryText),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(label, style: styles.labelSmall.copyWith(color: secondaryText)),
        ],
      ),
    );
  }

  int _findCurrentHourPrecipitationProbability(List<HourlyWeatherEntity> hourly) {
    if (hourly.isEmpty) return 0;
    final now = DateTime.now();
    final closest = hourly.reduce((a, b) =>
        a.time.difference(now).abs() < b.time.difference(now).abs() ? a : b);
    return closest.precipitationProbability;
  }
}
