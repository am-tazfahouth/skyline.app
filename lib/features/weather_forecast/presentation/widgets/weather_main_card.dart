import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/constants/app_spacing.dart';
import 'package:sky_line/core/constants/app_text_styles.dart';
import 'package:sky_line/core/enums/setting_heat_unit.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/core/utils/weather_format.dart';
import 'package:sky_line/core/utils/weather_icon_mapper.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_state.dart';

class WeatherMainCard extends StatelessWidget {
  const WeatherMainCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeatherForecastBloc, WeatherForecastState>(
      builder: (context, state) {
        final surface = AppTheme.surfaceFor(Theme.of(context).brightness);
        final styles = Theme.of(context).extension<TextStyleCatalog>()!;
        final l10n = AppLocalisation.of(context)!;
        final primaryText = surface.onColor;
        final secondaryText = surface.onColorContainer;

        final weather = state.weatherOrNull;
        final settings = state.settingsOrNull;
        final date = weather != null
            ? l10n.weatherDateLong(DateTime.now())
            : '--';
        final condition = weather != null
            ? WeatherFormat.condition(weather.current.weatherCode, l10n)
            : '--';
        final temperature = weather != null
            ? WeatherFormat.temperature(weather.current.temperature, unit: settings?.heatUnit ?? SettingHeatUnit.celsius)
            : '--°C';
        final iconData = weather != null
            ? WeatherIconMapper.fromWeatherCode(
                weather.current.weatherCode,
                isDay: weather.current.isDay,
              )
            : Icons.cloud_rounded;
        final iconSize = 72.0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(iconData, color: primaryText, size: iconSize),
            SizedBox(height: AppSpacing.md),
            Text(
              temperature,
              style: styles.displayLarge.copyWith(color: primaryText),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              condition,
              style: styles.titleSmall.copyWith(color: primaryText),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(date,
                style: styles.bodyMedium.copyWith(color: secondaryText)),
          ],
        ),
        );
      },
    );
  }
}
