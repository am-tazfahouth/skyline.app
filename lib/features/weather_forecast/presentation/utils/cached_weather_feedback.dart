import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/errors/app_error.dart';
import 'package:sky_line/core/errors/app_error_code.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_event.dart';

/// Shows a localized SnackBar informing the user that the displayed weather
/// data comes from the cache because the connection could not be established.
void showCachedWeatherSnackBar(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalisation.of(context)!;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(content: Text(l10n.weatherCachedDataMessage)),
  );
}

/// Shows a localized SnackBar informing the user that the weather data refresh
/// could not be completed due to a network error.
void showRefreshErrorSnackBar(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalisation.of(context)!;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(content: Text(l10n.weatherRefreshErrorMessage)),
  );
}

/// Shows a localized SnackBar with the error message and a retry action
/// when the weather fetch fails completely.
void showWeatherErrorSnackBar(BuildContext context, AppErrorCode errorCode) {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalisation.of(context)!;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(AppError.getUserErrorMessage(errorCode, l10n)),
      action: SnackBarAction(
        label: l10n.weatherRetry,
        onPressed: () {
          context.read<WeatherForecastBloc>().add(const FetchWeatherEvent());
        },
      ),
    ),
  );
}
