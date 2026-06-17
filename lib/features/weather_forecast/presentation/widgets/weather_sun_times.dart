import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_state.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/sun_time/sun_times_ui_model.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/sun_time/time_row.dart';

/// Card widget that shows sunrise/sunset times and a trajectory chart.
///
/// Adapts automatically to the current time of day:
///   - **Day mode**: sun icon / sunrise label first, moon icon / sunset label last
///   - **Night mode**: moon icon / sunset label first, sun icon / next sunrise last
///   - The chart arc fills from the start of the period toward the end.
class WeatherSunTimes extends StatelessWidget {
  const WeatherSunTimes({super.key});

  @override
  Widget build(BuildContext context) {
    final surface = AppTheme.surfaceFor(Theme.of(context).brightness);
    final cardColor = surface.colorContainer;
    final primaryText = surface.onColor;
    final secondaryText = surface.onColorContainer;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<WeatherForecastBloc, WeatherForecastState>(
      builder: (context, state) {
        // Show nothing while weather data is loading or absent.
        if (state is! WeatherLoaded || state.weather.daily.isEmpty) {
          return const SizedBox.shrink();
        }

        final today = state.weather.daily.first;
        final now = DateTime.now();

        // Compute labels, icons and chart range for the current time of day.
        final config = PeriodConfig.compute(
          today: today,
          nextSunrise: state.weather.daily.length > 1
            ? state.weather.daily[1].sunrise
            : today.sunrise.add(const Duration(hours: 24)),
          now: now,
          colorScheme: colorScheme,
        );

        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TimeRow(
                      icon: config.firstIcon,
                      iconColor: config.firstColor,
                      label: config.firstLabel,
                      time: config.firstTime,
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                    ),
                    const SizedBox(height: 16),
                    TimeRow(
                      icon: config.secondIcon,
                      iconColor: config.secondColor,
                      label: config.secondLabel,
                      time: config.secondTime,
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 100,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return _SunPathChart(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        chartStart: config.chartStart,
                        chartEnd: config.chartEnd,
                        currentTime: now,
                        style: ChartStyle.forPeriod(config.isDay, colorScheme),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Renders a sine-wave arc representing the sun / moon trajectory.
///
/// The solid portion is the elapsed time, the dashed portion is the
/// remaining time, and the glowing dot marks the current position.
class _SunPathChart extends StatelessWidget {
  final double width;
  final double height;
  final DateTime chartStart;
  final DateTime chartEnd;
  final DateTime currentTime;
  final ChartStyle style;

  const _SunPathChart({
    required this.width,
    required this.height,
    required this.chartStart,
    required this.chartEnd,
    required this.currentTime,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    // How far through the period we are (0.0 at start, 1.0 at end).
    final total = chartEnd.difference(chartStart).inSeconds;
    final elapsed = currentTime.difference(chartStart).inSeconds;
    final progress = total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0.0;

    final spots = _buildSpots(progress);

    return Stack(
      children: [
        LineChart(
          LineChartData(
            minY: 0,
            maxY: 1.2,
            minX: 0,
            maxX: 1,
            titlesData: const FlTitlesData(show: false),
            gridData: const FlGridData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots.past,
                isCurved: true,
                curveSmoothness: 0.35,
                color: style.past,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
              LineChartBarData(
                spots: spots.future,
                isCurved: true,
                curveSmoothness: 0.35,
                color: style.future,
                barWidth: 2,
                dashArray: [5, 5],
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        ),
        // The glowing dot that represents the current sun / moon position.
        Positioned(
          left: progress * width - 3,
          top: (1.0 - sin(progress * pi)) * (height - 10) + 4.5,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: style.dot,
              boxShadow: [
                BoxShadow(
                  color: style.dotShadow,
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Generates two sets of [FlSpot]s — past and future — split at the
/// given [progress] (0.0 → 1.0) along a normalised sine curve.
///
/// The past list is a solid line, the future list a dashed line.
/// Both lists share the point at [progress] so there is no visible gap.
({List<FlSpot> past, List<FlSpot> future}) _buildSpots(double progress) {
  final fullSpots = List.generate(51, (i) {
    final x = i / 50;
    return FlSpot(x, sin(x * pi));
  });

  final past = <FlSpot>[];
  final future = <FlSpot>[];

  for (final spot in fullSpots) {
    if (spot.x <= progress) past.add(spot);
    if (spot.x >= progress) future.add(spot);
  }

  // Insert the exact progress point if not already present,
  // to avoid a gap between the solid and dashed segments.
  final currentY = sin(progress * pi);
  if (past.isNotEmpty && past.last.x != progress) {
    past.add(FlSpot(progress, currentY));
  }
  if (future.isNotEmpty && future.first.x != progress) {
    future.insert(0, FlSpot(progress, currentY));
  }

  return (past: past, future: future);
}
