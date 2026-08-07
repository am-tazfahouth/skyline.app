import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/errors/app_error.dart';
import 'package:sky_line/core/errors/app_error_code.dart';
import 'package:sky_line/core/errors/location_error_codes.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_event.dart';

/// Returns true when [code] corresponds to a GPS-related location error.
bool isGpsError(AppErrorCode code) =>
    code == LocationErrorCodes.gpsDisabled ||
    code == LocationErrorCodes.gpsPermissionDenied ||
    code == LocationErrorCodes.gpsPermissionPermanentlyDenied ||
    code == LocationErrorCodes.gpsFailed;

/// Shows a localized SnackBar for a GPS error with a contextual action.
void showGpsErrorSnackBar(BuildContext context, AppErrorCode code) {
  final bloc = context.read<LocationBloc>();
  final l10n = AppLocalisation.of(context)!;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(AppError.getUserErrorMessage(code, l10n)),
      action: _gpsErrorAction(bloc, code, l10n),
    ),
  );
}

SnackBarAction? _gpsErrorAction(
  LocationBloc bloc,
  AppErrorCode code,
  AppLocalisation l10n,
) {
  if (code == LocationErrorCodes.gpsDisabled) {
    return SnackBarAction(
      label: l10n.locationEnable,
      onPressed: () => bloc.add(const OpenLocationSettingsEvent()),
    );
  }
  if (code == LocationErrorCodes.gpsPermissionDenied) {
    return SnackBarAction(
      label: l10n.weatherRetry,
      onPressed: () => bloc.add(const DetectCurrentLocationEvent()),
    );
  }
  if (code == LocationErrorCodes.gpsPermissionPermanentlyDenied) {
    return SnackBarAction(
      label: l10n.settingsTitle,
      onPressed: () => bloc.add(const OpenAppSettingsEvent()),
    );
  }
  return null;
}
