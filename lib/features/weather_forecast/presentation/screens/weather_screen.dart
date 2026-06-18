import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_state.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/views/weather_content_view.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/views/weather_error_view.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/views/weather_initial_view.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeatherForecastBloc, WeatherForecastState>(
      builder: (context, state) {
        final content = _contentFor(state);
        if (state.hasData && state.isFetching) {
          final theme = Theme.of(context);
          final primary = theme.colorScheme.primary;
          return Stack(
            children: [
              content,
              Positioned.fill(
                child: Container(
                  color: theme.colorScheme.surface.withValues(alpha: 0.7),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LoadingAnimationWidget.staggeredDotsWave(
                          size: 25,
                          color: primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Refreshing...',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return content;
      },
    );
  }

  Widget _contentFor(WeatherForecastState state) {
    return switch (state) {
      WeatherInitial() => const WeatherInitialView(),
      WeatherEmpty() => const WeatherContentView(),
      WeatherLoaded() => const WeatherContentView(),
      WeatherError(failure: final f) => WeatherErrorView(message: f.message),
      _ => const WeatherInitialView(),
    };
  }
}
