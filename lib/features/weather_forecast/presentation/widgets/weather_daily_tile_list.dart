import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/constants/app_radius.dart';
import 'package:sky_line/core/constants/app_spacing.dart';
import 'package:sky_line/core/constants/app_text_styles.dart';
import 'package:sky_line/core/enums/setting_heat_unit.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/core/utils/weather_format.dart';
import 'package:sky_line/core/utils/weather_icon_mapper.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_state.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/section_header.dart';

class WeatherDailyTileList extends StatelessWidget {
  const WeatherDailyTileList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeatherForecastBloc, WeatherForecastState>(
      builder: (context, state) {
        final surface = AppTheme.surfaceFor(Theme.of(context).brightness);
        final styles = Theme.of(context).extension<TextStyleCatalog>()!;
        final primaryText = surface.onColor;
        final secondaryText = surface.onColorContainer;
        final colorScheme = Theme.of(context).colorScheme;
        final l10n = AppLocalisation.of(context)!;
        final gradientCold = colorScheme.primary;
        final gradientHot = colorScheme.tertiary;

        final weather = state.weatherOrNull;
        final settings = state.settingsOrNull;
        if (weather == null) {
          return _buildPlaceholder(
            styles,
            primaryText,
            secondaryText,
            gradientCold,
            gradientHot,
          );
        }

        final items = weather.daily.take(7).toList();
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            WeatherSectionHeader(
              icon: Icons.calendar_month_outlined,
              title: l10n.weatherDailyTitle,
              color: primaryText,
            ),
            const SizedBox(height: AppSpacing.xs),
            ...items.map((item) {
              final dayLabel = _formatDayLabel(item.date, l10n);
              final condition = WeatherFormat.condition(item.weatherCode, l10n);
              final tempMin = WeatherFormat.temperature(
                item.tempMin,
                unit: settings?.heatUnit ?? SettingHeatUnit.celsius,
              );
              final tempMax = WeatherFormat.temperature(
                item.tempMax,
                unit: settings?.heatUnit ?? SettingHeatUnit.celsius,
              );
              return _buildRowTile(
                styles: styles,
                dayLabel: dayLabel,
                condition: condition,
                icon: WeatherIconMapper.fromWeatherCode(item.weatherCode),
                tempMin: tempMin,
                tempMax: tempMax,
                primaryText: primaryText,
                secondaryText: secondaryText,
                gradientCold: gradientCold,
                gradientHot: gradientHot,
              );
            }),
          ],
        );
      },
    );
  }

  String _formatDayLabel(DateTime date, AppLocalisation l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return l10n.weatherDayToday;
    if (diff == 1) return l10n.weatherDayTomorrow;
    return l10n.weatherDayLabel(date);
  }

  Widget _buildPlaceholder(
    TextStyleCatalog styles,
    Color primaryText,
    Color secondaryText,
    Color gradientCold,
    Color gradientHot,
  ) {
    return Column(
      children: List.generate(
        5,
        (_) => _buildRowTile(
          styles: styles,
          dayLabel: '--',
          condition: '--',
          icon: Icons.cloud_rounded,
          tempMin: '--°',
          tempMax: '--°',
          primaryText: primaryText,
          secondaryText: secondaryText,
          gradientCold: gradientCold,
          gradientHot: gradientHot,
        ),
      ),
    );
  }

  Widget _buildRowTile({
    required TextStyleCatalog styles,
    required String dayLabel,
    required String condition,
    required IconData icon,
    required String tempMin,
    required String tempMax,
    required Color primaryText,
    required Color secondaryText,
    required Color gradientCold,
    required Color gradientHot,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, color: secondaryText, size: 22),
          const SizedBox(width: AppSpacing.xl),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dayLabel,
                style: styles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                condition,
                style: styles.bodyMedium.copyWith(color: secondaryText),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 110,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tempMin,
                        style: styles.labelLarge.copyWith(color: primaryText),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Text(
                      tempMax,
                      style: styles.labelLarge.copyWith(color: primaryText),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.xxs),
                    gradient: LinearGradient(
                      colors: [gradientCold, gradientHot],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
