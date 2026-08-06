import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_event.dart';

class WeatherErrorView extends StatelessWidget {
  final String message;

  const WeatherErrorView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalisation.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.read<WeatherForecastBloc>().add(
                const FetchWeatherEvent(),
              ),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.weatherRetry),
            ),
          ],
        ),
      ),
    );
  }
}
