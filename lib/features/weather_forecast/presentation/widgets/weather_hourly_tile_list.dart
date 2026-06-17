import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/utils/weather_icon_mapper.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_state.dart';

class WeatherHourlyTileList extends StatelessWidget {
  const WeatherHourlyTileList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeatherForecastBloc, WeatherForecastState>(
      builder: (context, state) {
        if (state is! WeatherLoaded) return const SizedBox.shrink();

        final surface = AppTheme.surfaceFor(Theme.of(context).brightness);
        final cardColor = surface.colorContainer;
        final primaryText = surface.onColor;
        final secondaryText = surface.onColorContainer;

        final now = DateTime.now();
        final filtered = state.weather.hourly.where((h) =>
          h.time.isAfter(now) && h.time.isBefore(now.add(const Duration(hours: 12)))
        ).toList();

        if (filtered.isEmpty) return const SizedBox.shrink();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: filtered.map((item) {
              final time = DateFormat('HH:mm').format(item.time);
              final temp = '${item.temperature.toStringAsFixed(0)}°';
              final isDay = item.time.hour >= 6 && item.time.hour < 18;
              return Container(
                margin: const EdgeInsets.only(right: 14),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Text(time, style: TextStyle(color: secondaryText, fontSize: 12)),
                    const SizedBox(height: 10),
                    Icon(WeatherIconMapper.fromWeatherCode(item.weatherCode, isDay: isDay), color: secondaryText, size: 22),
                    const SizedBox(height: 10),
                    Text(
                      temp,
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
