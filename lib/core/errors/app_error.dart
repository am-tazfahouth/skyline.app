import 'package:sky_line/core/enums/user_error_type.dart';
import 'package:sky_line/core/errors/app_error_code.dart';
import 'package:sky_line/core/errors/location_error_codes.dart';
import 'package:sky_line/core/errors/setting_error_codes.dart';
import 'package:sky_line/core/errors/weather_error_codes.dart';

class AppError {
  /// Get debug message (for logs). Falls back to a generic message.
  static String getDebugErrorMessage(AppErrorCode code) {
    return _debugErrorMessages[code] ?? 'Unknown debug error: $code';
  }
 
  /// Get user-facing message (short, english defaults).
  static String getUserErrorMessage(AppErrorCode code) {
    final type = _userErrorTypeMap[code] ?? UserErrorType.unexpected;

    switch (type) {
      case UserErrorType.network:
        return "No internet connection. Please check your network.";
      case UserErrorType.fetch:
        return "Could not load weather data. Please try again.";
      case UserErrorType.cache:
        return "Could not save weather data locally.";
      case UserErrorType.loadCache:
        return "Could not load cached weather data.";
      case UserErrorType.unexpected:
        return "Something went wrong. Please try again.";        
      case UserErrorType.loadSetting:
        return "Could not load your preferences.";
      case UserErrorType.updateSetting:
        return "Could not save your preferences.";
      case UserErrorType.location:
        return "Could not get your location. Please check permissions.";
      case UserErrorType.search:
        return "Could not search cities. Please try again.";
    }
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

    // Setting
    SettingErrorCodes.load: "An error occurred while loading settings.",
    SettingErrorCodes.update: "An error occurred while updating settings.",

    // Location
    LocationErrorCodes.gpsDisabled: "GPS is disabled on the device.",
    LocationErrorCodes.gpsPermissionDenied: "GPS permission was denied by the user.",
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
