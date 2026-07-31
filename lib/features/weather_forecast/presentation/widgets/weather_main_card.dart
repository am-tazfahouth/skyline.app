import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/enums/setting_heat_unit.dart';
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
        final primaryText = surface.onColor;
        final secondaryText = surface.onColorContainer;

        final weather = state.weatherOrNull;
        final settings = state.settingsOrNull;
        final date = weather != null
            ? WeatherFormat.date(DateTime.now())
            : '--';
        final condition = weather != null
            ? WeatherFormat.condition(weather.current.weatherCode)
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
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(iconData, color: primaryText, size: iconSize),
            const SizedBox(height: 12),
            Text(
              temperature,
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.bold,
                color: primaryText,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              condition,
              style: TextStyle(
                fontSize: 15,
                color: primaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(date,
                style: TextStyle(fontSize: 12, color: secondaryText)),
          ],
        ),
        );
      },
    );
  }
}
