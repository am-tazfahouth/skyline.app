import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/enums/setting_heat_unit.dart';
import 'package:sky_line/core/utils/weather_format.dart';
import 'package:sky_line/core/utils/weather_icon_mapper.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_state.dart';

class WeatherDailyTileList extends StatelessWidget {
  const WeatherDailyTileList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeatherForecastBloc, WeatherForecastState>(
      builder: (context, state) {
        final surface = AppTheme.surfaceFor(Theme.of(context).brightness);
        final primaryText = surface.onColor;
        final secondaryText = surface.onColorContainer;
        final colorScheme = Theme.of(context).colorScheme;
        final gradientCold = colorScheme.primary;
        final gradientHot = colorScheme.tertiary;

        final weather = state.weatherOrNull;
        final settings = state.settingsOrNull;
        if (weather == null) {
          return _buildPlaceholder(primaryText, secondaryText, gradientCold, gradientHot);
        }

        final items = weather.daily.take(7).toList();
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            Row(
              children: [
                Icon(
                  size: 18,
                  color: primaryText,
                  Icons.calendar_month_outlined,
                ),
                const SizedBox(width: 4),
                Text(
                  'Next 7 Days',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ...items.map((item) {
              final dayLabel = _formatDayLabel(item.date);
              final condition = WeatherFormat.condition(item.weatherCode);
              final tempMin = WeatherFormat.temperature(item.tempMin, unit: settings?.heatUnit ?? SettingHeatUnit.celsius);
              final tempMax = WeatherFormat.temperature(item.tempMax, unit: settings?.heatUnit ?? SettingHeatUnit.celsius);
              return _buildRowTile(
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

  String _formatDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return DateFormat('E, d MMM').format(date);
  }

  Widget _buildPlaceholder(Color primaryText, Color secondaryText, Color gradientCold, Color gradientHot) {
    return Column(
      children: List.generate(
        5,
        (_) => _buildRowTile(
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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Row(
        children: [
          Icon(icon, color: secondaryText, size: 22),
          const SizedBox(width: 30),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dayLabel,
                style: TextStyle(
                  color: primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                condition,
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 130,
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      tempMin,
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      tempMax,
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
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
