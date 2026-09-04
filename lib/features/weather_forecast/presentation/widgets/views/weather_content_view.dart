import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/constants/app_spacing.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_event.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/weather_forecast_section.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/weather_header.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/weather_main_card.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/weather_stats_card.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/weather_sun_times.dart';

class WeatherContentView extends StatelessWidget {
  const WeatherContentView({super.key});

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.surfaceFor(Theme.of(context).brightness).color;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: const WeatherHeader(),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<WeatherForecastBloc>().add(const RefreshWeatherEvent());
          await context.read<WeatherForecastBloc>().stream.firstWhere((s) => !s.isFetching);
        },
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xs),
                const WeatherMainCard(),
                // End - MainCard
                const SizedBox(height: 14),
                const WeatherStatsCard(),
                // End - States of current day
                const SizedBox(height: 20),
                const WeatherForecastSection(),
                // End - Forecast section
                const SizedBox(height: 20),
                const WeatherSunTimes(),
                // End - SunCard
              ],
            ),
          ),
        ),
      ),
    );
  }
}
