import 'package:flutter/material.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';

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
