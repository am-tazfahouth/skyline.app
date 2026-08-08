import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/config/app_routes.dart';
import 'package:sky_line/core/errors/app_error.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_event.dart';
import 'package:sky_line/features/location/presentation/blocs/location_onboarding_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_onboarding_event.dart';
import 'package:sky_line/features/location/presentation/blocs/location_onboarding_state.dart';
import 'package:sky_line/features/location/presentation/blocs/location_state.dart';
import 'package:sky_line/features/location/presentation/utils/gps_error_feedback.dart';
import 'package:sky_line/features/location/presentation/widgets/location_onboarding_sheet.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_event.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_state.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/views/weather_content_view.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/views/weather_error_view.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  bool _sheetShown = false;
  bool _sheetShowing = false;
  Timer? _sheetTimer;
  bool _gpsRequestFromOnboarding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final weatherState = context.read<WeatherForecastBloc>().state;
      if (weatherState is WeatherEmpty && !weatherState.isFetching) {
        _maybeHandleEmptyState(context);
      }
    });
  }

  @override
  void dispose() {
    _sheetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalisation.of(context)!;
    return BlocListener<LocationBloc, LocationState>(
      listenWhen: (previous, current) {
        if (current is LocationSelected) return true;
        if (current is LocationError) return true;
        if (current is LocationFavoritesLoaded) {
          final previousLocation = switch (previous) {
            LocationSelected(location: final l) => l,
            LocationFavoritesLoaded(currentLocation: final c) => c,
            _ => null,
          };
          final currentLocation = current.currentLocation;
          if (currentLocation == null) return previousLocation != null;
          return previousLocation != null &&
              (previousLocation.latitude != currentLocation.latitude ||
                  previousLocation.longitude != currentLocation.longitude);
        }
        return false;
      },
      listener: (context, state) {
        if (state is LocationSelected) {
          _gpsRequestFromOnboarding = false;
          context.read<WeatherForecastBloc>().add(
            FetchWeatherEvent(
              latitude: state.location.latitude,
              longitude: state.location.longitude,
            ),
          );
        } else if (state is LocationFavoritesLoaded) {
          final location = state.currentLocation;
          if (location == null) {
            context.read<WeatherForecastBloc>().add(const ResetWeatherEvent());
          } else {
            context.read<WeatherForecastBloc>().add(
              FetchWeatherEvent(
                latitude: location.latitude,
                longitude: location.longitude,
              ),
            );
          }
        } else if (state is LocationError) {
          if (_gpsRequestFromOnboarding && isGpsError(state.errorCode)) {
            _gpsRequestFromOnboarding = false;
            showGpsErrorSnackBar(context, state.errorCode);
          }
        }
      },
      child: BlocListener<LocationOnboardingBloc, LocationOnboardingState>(
        listener: (context, state) {
          if (state is LocationOnboardingLoaded) {
            final weatherState = context.read<WeatherForecastBloc>().state;
            if (weatherState is WeatherEmpty &&
                !weatherState.isFetching &&
                !_sheetShown) {
              _maybeHandleEmptyState(context);
            }
          }
        },
        child: BlocListener<WeatherForecastBloc, WeatherForecastState>(
          listenWhen: (previous, current) =>
              current is WeatherEmpty &&
              !current.isFetching &&
              !(previous is WeatherEmpty && !previous.isFetching),
          listener: (context, state) => _maybeHandleEmptyState(context),
          child: BlocBuilder<WeatherForecastBloc, WeatherForecastState>(
            builder: (context, state) {
              final content = _contentFor(context, state);
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
                                l10n.weatherRefreshing,
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
        ),
      ),
    );
  }

  Widget _contentFor(BuildContext context, WeatherForecastState state) {
    final l10n = AppLocalisation.of(context)!;
    return switch (state) {
      WeatherError(errorCode: final code) =>
        WeatherErrorView(message: AppError.getUserErrorMessage(code, l10n)),
      _ => const WeatherContentView(),
    };
  }

  void _maybeHandleEmptyState(BuildContext context) {
    final onboardingState = context.read<LocationOnboardingBloc>().state;
    if (onboardingState is! LocationOnboardingLoaded) return;
    final hasSeen = onboardingState.hasSeenLocationOnboarding;
    if (!hasSeen && !_sheetShown) {
      _scheduleOnboardingSheet(context);
    } else if (!_sheetShowing) {
      _showFallbackSearchSnackBar(context);
    }
  }

  void _scheduleOnboardingSheet(BuildContext context) {
    _sheetTimer?.cancel();
    _sheetTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && !_sheetShown) _showOnboardingSheet(context);
    });
  }

  Future<void> _showOnboardingSheet(BuildContext context) async {
    final state = context.read<LocationOnboardingBloc>().state;
    if (state is! LocationOnboardingLoaded ||
        state.hasSeenLocationOnboarding ||
        _sheetShown) {
      return;
    }
    _sheetShowing = true;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => LocationOnboardingSheet(
        onEnableLocation: () => _completeOnboarding(context, enableLocation: true),
        onLater: () => _completeOnboarding(context, enableLocation: false),
        onClose: () => _completeOnboarding(context, enableLocation: false),
      ),
    );
    if (mounted) {
      _sheetShowing = false;
    }
  }

  void _completeOnboarding(
    BuildContext context, {
    required bool enableLocation,
  }) {
    context.read<LocationOnboardingBloc>().add(const CompleteOnboardingEvent());
    _sheetShown = true;
    Navigator.of(context).pop();
    if (enableLocation) {
      _gpsRequestFromOnboarding = true;
      context.read<LocationBloc>().add(const DetectCurrentLocationEvent());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final weatherState = context.read<WeatherForecastBloc>().state;
          if (weatherState is WeatherEmpty && !weatherState.isFetching) {
            _showFallbackSearchSnackBar(context);
          }
        }
      });
    }
  }

  void _showFallbackSearchSnackBar(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalisation.of(context)!;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.weatherEmptySearchMessage),
        action: SnackBarAction(
          label: l10n.weatherEmptySearchAction,
          onPressed: () => Navigator.pushNamed(context, AppRoutes.locationSearch),
        ),
      ),
    );
  }
}
