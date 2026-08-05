import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/errors/app_error.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_state.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_event.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_state.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/views/weather_content_view.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/views/weather_error_view.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/views/weather_initial_view.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LocationBloc, LocationState>(
      listenWhen: (previous, current) {
        if (current is LocationSelected) return true;
        if (current is LocationFavoritesLoaded &&
            current.currentLocation == null) {
          return previous is LocationSelected ||
              (previous is LocationFavoritesLoaded &&
                  previous.currentLocation != null);
        }
        return false;
      },
      listener: (context, state) {
        if (state is LocationSelected) {
          context.read<WeatherForecastBloc>().add(
            FetchWeatherEvent(
              latitude: state.location.latitude,
              longitude: state.location.longitude,
            ),
          );
        } else if (state is LocationFavoritesLoaded &&
            state.currentLocation == null) {
          context.read<WeatherForecastBloc>().add(const ResetWeatherEvent());
        }
      },
      child: BlocBuilder<WeatherForecastBloc, WeatherForecastState>(
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
                            key: const Key('loading_indicator'),
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
      ),
    );
  }

  Widget _contentFor(WeatherForecastState state) {
    return switch (state) {
      WeatherInitial() => const WeatherInitialView(),
      WeatherEmpty() => const WeatherContentView(),
      WeatherLoaded() => const WeatherContentView(),
      WeatherError(errorCode: final code) =>
        WeatherErrorView(message: AppError.getUserErrorMessage(code)),
      _ => const WeatherInitialView(),
    };
  }
}
