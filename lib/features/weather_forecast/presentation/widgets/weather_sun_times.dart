import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_state.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/section_header.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/sun_time/sun_times_ui_model.dart';

class WeatherSunTimes extends StatelessWidget {
  const WeatherSunTimes({super.key});

  @override
  Widget build(BuildContext context) {
    final surface = AppTheme.surfaceFor(Theme.of(context).brightness);
    final cardColor = surface.colorContainer;
    final primaryText = surface.onColor;
    final secondaryText = surface.onColorContainer;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalisation.of(context)!;

    return BlocBuilder<WeatherForecastBloc, WeatherForecastState>(
      builder: (context, state) {
        final weather = state.weatherOrNull;
        final daily = weather?.daily ?? [];
        if (daily.isEmpty) {
          return _buildPlaceholder(
            cardColor: cardColor,
            primaryText: primaryText,
            secondaryText: secondaryText,
            l10n: l10n,
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
          l10n: l10n,
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WeatherSectionHeader(
                icon: config.titleIcon,
                title: config.title,
                color: primaryText,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _TimePoint(
                    data: config.start,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '—',
                        style: TextStyle(color: secondaryText, fontSize: 20),
                      ),
                    ),
                  ),
                  _TimePoint(
                    data: config.middle,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '—',
                        style: TextStyle(color: secondaryText, fontSize: 20),
                      ),
                    ),
                  ),
                  _TimePoint(
                    data: config.end,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                  ),
                ],
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
    required AppLocalisation l10n,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _TimePoint(
            data: TimePointData(
              icon: Icons.wb_sunny_outlined,
              iconColor: Colors.grey,
              label: l10n.weatherSunSunrise,
              time: '--:--',
            ),
            primaryText: primaryText,
            secondaryText: secondaryText,
          ),
          Expanded(
            child: Center(
              child: Text(
                '—',
                style: TextStyle(color: secondaryText, fontSize: 20),
              ),
            ),
          ),
          _TimePoint(
            data: TimePointData(
              icon: Icons.wb_sunny,
              iconColor: Colors.grey,
              label: l10n.weatherSunZenith,
              time: '--:--',
            ),
            primaryText: primaryText,
            secondaryText: secondaryText,
          ),
          Expanded(
            child: Center(
              child: Text(
                '—',
                style: TextStyle(color: secondaryText, fontSize: 20),
              ),
            ),
          ),
          _TimePoint(
            data: TimePointData(
              icon: Icons.nightlight_round_outlined,
              iconColor: Colors.grey,
              label: l10n.weatherSunSunset,
              time: '--:--',
            ),
            primaryText: primaryText,
            secondaryText: secondaryText,
          ),
        ],
      ),
    );
  }
}

class _TimePoint extends StatelessWidget {
  final TimePointData data;
  final Color primaryText;
  final Color secondaryText;

  const _TimePoint({
    required this.data,
    required this.primaryText,
    required this.secondaryText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(data.icon, color: data.iconColor, size: 20),
        const SizedBox(height: 4),
        Text(
          data.label,
          style: TextStyle(color: secondaryText, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          data.time,
          style: TextStyle(
            color: primaryText,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
