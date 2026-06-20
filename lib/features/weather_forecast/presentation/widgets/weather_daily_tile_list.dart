import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sky_line/core/config/app_theme.dart';
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

        final weather = state.weatherOrNull;
        if (weather == null) {
          return _buildPlaceholder(primaryText, secondaryText);
        }

        final items = weather.daily.take(7).toList();
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          children: items.map((item) {
            final day = DateFormat('E').format(item.date);
            final temp =
                '${item.tempMax.toStringAsFixed(0)}° / ${item.tempMin.toStringAsFixed(0)}°';
            return _buildRowTile(
              day: day,
              icon: WeatherIconMapper.fromWeatherCode(item.weatherCode),
              temp: temp,
              primaryText: primaryText,
              secondaryText: secondaryText,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPlaceholder(
      Color primaryText, Color secondaryText) {
    return Column(
      children: List.generate(
        5,
        (_) => _buildRowTile(
          day: '--',
          icon: Icons.cloud_rounded,
          temp: '--° / --°',
          primaryText: primaryText,
          secondaryText: secondaryText,
        ),
      ),
    );
  }

  Widget _buildRowTile({
    required String day,
    required IconData icon,
    required String temp,
    required Color primaryText,
    required Color secondaryText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              day,
              style: TextStyle(color: secondaryText, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: secondaryText, size: 22),
          const Spacer(),
          Text(
            temp,
            style: TextStyle(
              color: primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
