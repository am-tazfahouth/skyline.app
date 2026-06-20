import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/daily_weather_entity.dart';

/// Color palette for the sun path chart, switching between day and night modes.
class ChartStyle {
  final Color past;
  final Color future;
  final Color dot;
  final Color dotShadow;

  const ChartStyle({
    required this.past,
    required this.future,
    required this.dot,
    required this.dotShadow,
  });

  /// Returns colors optimised for day (amber sun dot, primary past line)
  /// or night (secondary dot, dimmer past line).
  factory ChartStyle.forPeriod(bool isDay, ColorScheme colorScheme) {
    if (isDay) {
      return ChartStyle(
        past: colorScheme.primary,
        future: colorScheme.outlineVariant,
        dot: Colors.amber,
        dotShadow: Colors.amber.withValues(alpha: 0.6),
      );
    }
    return ChartStyle(
      past: colorScheme.secondary.withValues(alpha: 0.6),
      future: colorScheme.outlineVariant,
      dot: colorScheme.secondary,
      dotShadow: colorScheme.secondary.withValues(alpha: 0.4),
    );
  }
}

/// Display data for a single time point (icon, label, formatted time).
class TimePointData extends Equatable {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String time;

  const TimePointData({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.time,
  });

  @override
  List<Object?> get props => [icon, iconColor, label, time];
}

/// Encapsulates all display values (icons, labels, times, chart range)
/// for the sun / moon times card.
///
/// The factory [compute] handles three modes:
///   - **Day**: sunrise first, sunset second
///   - **Evening night**: sunset first, next sunrise second
///   - **Dawn**: proxy sunset first, today's sunrise second
class PeriodConfig {
  final IconData firstIcon;
  final Color firstColor;
  final String firstLabel;
  final String firstTime;
  final IconData secondIcon;
  final Color secondColor;
  final String secondLabel;
  final String secondTime;
  final DateTime chartStart;
  final DateTime chartEnd;
  final bool isDay;
  final String title;
  final IconData titleIcon;

  const PeriodConfig({
    required this.firstIcon,
    required this.firstColor,
    required this.firstLabel,
    required this.firstTime,
    required this.secondIcon,
    required this.secondColor,
    required this.secondLabel,
    required this.secondTime,
    required this.chartStart,
    required this.chartEnd,
    required this.isDay,
    required this.title,
    required this.titleIcon,
  });

  TimePointData get start => TimePointData(
        icon: firstIcon,
        iconColor: firstColor,
        label: firstLabel,
        time: firstTime,
      );

  TimePointData get end => TimePointData(
        icon: secondIcon,
        iconColor: secondColor,
        label: secondLabel,
        time: secondTime,
      );

  TimePointData get middle {
    final midpoint = DateTime.fromMillisecondsSinceEpoch(
      (chartStart.millisecondsSinceEpoch + chartEnd.millisecondsSinceEpoch) ~/ 2,
    );
    final time = DateFormat('hh:mm a').format(midpoint);
    if (isDay) {
      return TimePointData(
        icon: Icons.wb_sunny,
        iconColor: firstColor,
        label: 'Zenith',
        time: time,
      );
    }
    return TimePointData(
      icon: Icons.nights_stay,
      iconColor: secondColor,
      label: 'Midnight',
      time: time,
    );
  }

  /// Determines the current period (day, evening-night, or dawn)
  /// and builds the full configuration from it.
  factory PeriodConfig.compute({
    required DailyWeatherEntity today,
    required DateTime nextSunrise,
    required DateTime now,
    required ColorScheme colorScheme,
  }) {
    final isDay = now.isAfter(today.sunrise) && now.isBefore(today.sunset);

    if (isDay) {
      // Day: sunrise → sunset
      return PeriodConfig(
        firstIcon: Icons.wb_sunny_outlined,
        firstColor: colorScheme.primary,
        firstLabel: 'Sunrise',
        firstTime: DateFormat('hh:mm a').format(today.sunrise),
        secondIcon: Icons.nightlight_round_outlined,
        secondColor: colorScheme.secondary,
        secondLabel: 'Sunset',
        secondTime: DateFormat('hh:mm a').format(today.sunset),
        chartStart: today.sunrise,
        chartEnd: today.sunset,
        isDay: true,
        title: 'Sun Time',
        titleIcon: Icons.wb_sunny_outlined,
      );
    }

    if (now.isAfter(today.sunset)) {
      // Evening: sunset → next sunrise
      return PeriodConfig(
        firstIcon: Icons.nightlight_round_outlined,
        firstColor: colorScheme.secondary,
        firstLabel: 'Sunset',
        firstTime: DateFormat('hh:mm a').format(today.sunset),
        secondIcon: Icons.wb_sunny_outlined,
        secondColor: colorScheme.primary,
        secondLabel: 'Sunrise',
        secondTime: DateFormat('hh:mm a').format(nextSunrise),
        chartStart: today.sunset,
        chartEnd: nextSunrise,
        isDay: false,
        title: 'Night Time',
        titleIcon: Icons.nightlight_round_outlined,
      );
    }

    // Dawn: proxy sunset → today's sunrise
    // Approximate yesterday's sunset as 12h before today's sunrise
    // since Open-Meteo only provides today's data.
    final proxySunset = today.sunrise.subtract(const Duration(hours: 12));
    return PeriodConfig(
      firstIcon: Icons.nightlight_round_outlined,
      firstColor: colorScheme.secondary,
      firstLabel: 'Sunset',
      firstTime: DateFormat('hh:mm a').format(proxySunset),
      secondIcon: Icons.wb_sunny_outlined,
      secondColor: colorScheme.primary,
      secondLabel: 'Sunrise',
      secondTime: DateFormat('hh:mm a').format(today.sunrise),
      chartStart: proxySunset,
      chartEnd: today.sunrise,
      isDay: false,
      title: 'Night Time',
      titleIcon: Icons.nightlight_round_outlined,
    );
  }
}
