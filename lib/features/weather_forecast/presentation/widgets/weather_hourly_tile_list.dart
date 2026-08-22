import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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

class WeatherHourlyTileList extends StatelessWidget {
  const WeatherHourlyTileList({super.key});

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
        if (weather == null) {
          return _buildPlaceholder(styles, cardColor, primaryText, secondaryText);
        }

        final now = DateTime.now();
        final filtered = weather.hourly.where((h) =>
          h.time.isAfter(now) &&
          h.time.isBefore(now.add(const Duration(hours: 12))),
        ).toList();

        if (filtered.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            WeatherSectionHeader(
              icon: Icons.access_time_filled_outlined,
              title: l10n.weatherHourlyTitle,
              color: primaryText,
            ),
            SizedBox(height: AppSpacing.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: filtered.map((item) {
                  final time = DateFormat('HH:mm').format(item.time);
                  final temp = WeatherFormat.temperature(item.temperature, unit: settings?.heatUnit ?? SettingHeatUnit.celsius);
                  final isDay = item.time.hour >= 6 && item.time.hour < 18;
                  return _buildTile(
                    styles: styles,
                    time: time,
                    icon: WeatherIconMapper.fromWeatherCode(
                    item.weatherCode, isDay: isDay),
                    temp: temp,
                    cardColor: cardColor,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaceholder(TextStyleCatalog styles, Color cardColor, Color primaryText, Color secondaryText) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: List.generate(
          6,
          (_) => _buildTile(
            styles: styles,
            time: '--:--',
            icon: Icons.cloud_rounded,
            temp: '--°',
            cardColor: cardColor,
            primaryText: primaryText,
            secondaryText: secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildTile({
    required TextStyleCatalog styles,
    required String time,
    required IconData icon,
    required String temp,
    required Color cardColor,
    required Color primaryText,
    required Color secondaryText,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.md),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        children: [
          Text(time, style: styles.bodyMedium.copyWith(color: secondaryText)),
          SizedBox(height: AppSpacing.sm),
          Icon(icon, color: secondaryText, size: 22),
          SizedBox(height: AppSpacing.sm),
          Text(
            temp,
            style: styles.titleMedium.copyWith(color: primaryText),
          ),
        ],
      ),
    );
  }
}
