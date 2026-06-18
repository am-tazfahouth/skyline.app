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
        final cardColor = surface.colorContainer;
        final primaryText = surface.onColor;
        final secondaryText = surface.onColorContainer;

        final weather = state.weatherOrNull;
        if (weather == null) {
          return _buildPlaceholder(cardColor, primaryText, secondaryText);
        }

        final items = weather.daily.take(7).toList();
        if (items.isEmpty) return const SizedBox.shrink();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: items.map((item) {
              final day = DateFormat('E').format(item.date);
              final temp =
                  '${item.tempMax.toStringAsFixed(0)}° / ${item.tempMin.toStringAsFixed(0)}°';
              return _buildTile(
                day: day,
                icon: WeatherIconMapper.fromWeatherCode(item.weatherCode),
                temp: temp,
                cardColor: cardColor,
                primaryText: primaryText,
                secondaryText: secondaryText,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(
      Color cardColor, Color primaryText, Color secondaryText) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: List.generate(
          5,
          (_) => _buildTile(
            day: '--',
            icon: Icons.cloud_rounded,
            temp: '--° / --°',
            cardColor: cardColor,
            primaryText: primaryText,
            secondaryText: secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildTile({
    required String day,
    required IconData icon,
    required String temp,
    required Color cardColor,
    required Color primaryText,
    required Color secondaryText,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(day, style: TextStyle(color: secondaryText, fontSize: 12)),
          const SizedBox(height: 10),
          Icon(icon, color: secondaryText, size: 22),
          const SizedBox(height: 10),
          Text(
            temp,
            style: TextStyle(
              color: primaryText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
