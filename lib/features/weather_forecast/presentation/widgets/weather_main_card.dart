import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/config/app_theme.dart';
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
        if (state is! WeatherLoaded) {
          return const SizedBox.shrink();
        }

        final surface = AppTheme.surfaceFor(Theme.of(context).brightness);
        final cardColor = surface.colorContainer;
        final primaryText = surface.onColor;
        final secondaryText = surface.onColorContainer;

        final current = state.weather.current;
        final date = WeatherFormat.date(DateTime.now());
        final condition = WeatherFormat.condition(current.weatherCode);
        final temperature = WeatherFormat.temperature(current.temperature);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(date, style: TextStyle(fontSize: 12, color: secondaryText)),
                    const SizedBox(height: 6),
                    Text(
                      condition,
                      style: TextStyle(
                        fontSize: 15,
                        color: primaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      temperature,
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: primaryText,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                WeatherIconMapper.fromWeatherCode(current.weatherCode, isDay: current.isDay),
                color: primaryText,
                size: 72,
              ),
            ],
          ),
        );
      },
    );
  }
}
