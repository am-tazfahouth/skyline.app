import 'package:sky_line/core/enums/user_error_type.dart';
import 'package:sky_line/core/errors/app_error_code.dart';
import 'package:sky_line/core/errors/location_error_codes.dart';
import 'package:sky_line/core/errors/setting_error_codes.dart';
import 'package:sky_line/core/errors/weather_error_codes.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';

class AppError {
  /// Get debug message (for logs). Falls back to a generic message.
  static String getDebugErrorMessage(AppErrorCode code) {
    return _debugErrorMessages[code] ?? 'Unknown debug error: $code';
  }
 
  /// Get user-facing message (localized).
  static String getUserErrorMessage(AppErrorCode code, AppLocalisation l10n) {
    if (code == LocationErrorCodes.gpsDisabled) return l10n.errorGpsDisabled;
    if (code == LocationErrorCodes.gpsPermissionDenied) {
      return l10n.errorGpsPermissionDenied;
    }
    if (code == LocationErrorCodes.gpsPermissionPermanentlyDenied) {
      return l10n.errorGpsPermissionPermanentlyDenied;
    }

    final type = _userErrorTypeMap[code] ?? UserErrorType.unexpected;

    return switch (type) {
      UserErrorType.network => l10n.errorNetwork,
      UserErrorType.fetch => l10n.errorFetch,
      UserErrorType.cache => l10n.errorCache,
      UserErrorType.loadCache => l10n.errorLoadCache,
      UserErrorType.unexpected => l10n.errorUnexpected,
      UserErrorType.loadSetting => l10n.errorLoadSetting,
      UserErrorType.updateSetting => l10n.errorUpdateSetting,
      UserErrorType.location => l10n.errorLocation,
      UserErrorType.search => l10n.errorSearch,
    };
  }

  /// -------------------------
  /// Debug messages (detailed)
  /// -------------------------
  static final Map<AppErrorCode, String> _debugErrorMessages = {
    // Weather_forecast
    WeatherErrorCodes.fetch: "An error occurred while fetching data.",
    WeatherErrorCodes.cache: "An error occurred while caching data.",
    WeatherErrorCodes.network: "An error occurred with the network.",
    WeatherErrorCodes.loadCache: "An error occurred while loading data from cache.",
    WeatherErrorCodes.unexpected: "An unexpected error occurred. Please try again later.",
    WeatherErrorCodes.parse: "API response format error — the data could not be parsed.",

    // Setting
    SettingErrorCodes.load: "An error occurred while loading settings.",
    SettingErrorCodes.update: "An error occurred while updating settings.",

    // Location
    LocationErrorCodes.gpsDisabled: "GPS is disabled on the device.",
    LocationErrorCodes.gpsPermissionDenied: "GPS permission was denied by the user.",
    LocationErrorCodes.gpsPermissionPermanentlyDenied: "GPS permission was permanently denied by the user.",
    LocationErrorCodes.gpsFailed: "Failed to detect GPS location.",
    LocationErrorCodes.searchFailed: "Failed to search for cities.",
    LocationErrorCodes.saveFavoriteFailed: "Failed to save favorite location.",
    LocationErrorCodes.loadFavoritesFailed: "Failed to load favorite locations.",
    LocationErrorCodes.unexpected: "An unexpected location error occurred.",
  };

  /// -------------------------
  /// Mapping to user-friendly categories
  /// -------------------------
  static final Map<AppErrorCode, UserErrorType> _userErrorTypeMap = {
    // Weather_forecast
    WeatherErrorCodes.fetch: UserErrorType.fetch,
    WeatherErrorCodes.cache: UserErrorType.cache,
    WeatherErrorCodes.network: UserErrorType.network,
    WeatherErrorCodes.loadCache: UserErrorType.loadCache,
    WeatherErrorCodes.unexpected: UserErrorType.unexpected,
    WeatherErrorCodes.parse: UserErrorType.fetch,

    // Setting
    SettingErrorCodes.load: UserErrorType.loadSetting,
    SettingErrorCodes.update: UserErrorType.updateSetting,

    // Location
    LocationErrorCodes.gpsDisabled: UserErrorType.location,
    LocationErrorCodes.gpsPermissionDenied: UserErrorType.location,
    LocationErrorCodes.gpsFailed: UserErrorType.location,
    LocationErrorCodes.searchFailed: UserErrorType.search,
    LocationErrorCodes.saveFavoriteFailed: UserErrorType.location,
    LocationErrorCodes.loadFavoritesFailed: UserErrorType.location,
    LocationErrorCodes.unexpected: UserErrorType.unexpected,
  };
}
