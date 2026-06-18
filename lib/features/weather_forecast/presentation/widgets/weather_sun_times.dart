import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_state.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/sun_time/sun_times_ui_model.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/sun_time/time_row.dart';

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
        final weather = state.weatherOrNull;
        final daily = weather?.daily ?? [];
        if (daily.isEmpty) {
          return _buildPlaceholder(
            cardColor: cardColor,
            primaryText: primaryText,
            secondaryText: secondaryText,
          );
        }

        final today = daily.first;
        final now = DateTime.now();
        final nextSunrise = daily.length > 1
            ? daily[1].sunrise
            : today.sunrise.add(const Duration(hours: 24));

        final config = PeriodConfig.compute(
          today: today,
          nextSunrise: nextSunrise,
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

  Widget _buildPlaceholder({
    required Color cardColor,
    required Color primaryText,
    required Color secondaryText,
  }) {
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
                  icon: Icons.wb_sunny_rounded,
                  iconColor: secondaryText,
                  label: 'Sunrise',
                  time: '--:--',
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                ),
                const SizedBox(height: 16),
                TimeRow(
                  icon: Icons.nightlight_round,
                  iconColor: secondaryText,
                  label: 'Sunset',
                  time: '--:--',
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(height: 100),
          ),
        ],
      ),
    );
  }
}

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

  final currentY = sin(progress * pi);
  if (past.isNotEmpty && past.last.x != progress) {
    past.add(FlSpot(progress, currentY));
  }
  if (future.isNotEmpty && future.first.x != progress) {
    future.insert(0, FlSpot(progress, currentY));
  }

  return (past: past, future: future);
}
