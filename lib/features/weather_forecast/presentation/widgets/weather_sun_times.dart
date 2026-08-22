import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/constants/app_radius.dart';
import 'package:sky_line/core/constants/app_spacing.dart';
import 'package:sky_line/core/constants/app_text_styles.dart';
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
    final styles = Theme.of(context).extension<TextStyleCatalog>()!;
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
            styles: styles,
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
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WeatherSectionHeader(
                icon: config.titleIcon,
                title: config.title,
                color: primaryText,
              ),
              SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _TimePoint(
                      styles: styles,
                      data: config.start,
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '—',
                        style: styles.headlineMedium.copyWith(color: secondaryText),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _TimePoint(
                      styles: styles,
                      data: config.middle,
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '—',
                        style: styles.headlineMedium.copyWith(color: secondaryText),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _TimePoint(
                      styles: styles,
                      data: config.end,
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                    ),
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
    required TextStyleCatalog styles,
    required Color cardColor,
    required Color primaryText,
    required Color secondaryText,
    required AppLocalisation l10n,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TimePoint(
              styles: styles,
              data: TimePointData(
                icon: Icons.wb_sunny_outlined,
                iconColor: secondaryText,
                label: l10n.weatherSunSunrise,
                time: '--:--',
              ),
              primaryText: primaryText,
              secondaryText: secondaryText,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '—',
                style: styles.headlineMedium.copyWith(color: secondaryText),
              ),
            ),
          ),
          Expanded(
            child: _TimePoint(
              styles: styles,
              data: TimePointData(
                icon: Icons.wb_sunny,
                iconColor: secondaryText,
                label: l10n.weatherSunZenith,
                time: '--:--',
              ),
              primaryText: primaryText,
              secondaryText: secondaryText,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '—',
                style: styles.headlineMedium.copyWith(color: secondaryText),
              ),
            ),
          ),
          Expanded(
            child: _TimePoint(
              styles: styles,
              data: TimePointData(
                icon: Icons.nightlight_round_outlined,
                iconColor: secondaryText,
                label: l10n.weatherSunSunset,
                time: '--:--',
              ),
              primaryText: primaryText,
              secondaryText: secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimePoint extends StatelessWidget {
  final TextStyleCatalog styles;
  final TimePointData data;
  final Color primaryText;
  final Color secondaryText;

  const _TimePoint({
    required this.styles,
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
        SizedBox(height: AppSpacing.xs),
        Text(
          data.label,
          style: styles.labelSmall.copyWith(color: secondaryText),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          data.time,
          style: styles.titleMedium.copyWith(
            color: primaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
