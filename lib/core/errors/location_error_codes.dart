import 'package:sky_line/core/enums/app_error_source.dart';
import 'package:sky_line/core/errors/app_error_code.dart';

class LocationErrorCodes {
  LocationErrorCodes._();

  static const gpsDisabled = AppErrorCode(AppErrorSource.location, 'gpsDisabled');
  static const gpsPermissionDenied = AppErrorCode(AppErrorSource.location, 'gpsPermissionDenied');
  static const gpsFailed = AppErrorCode(AppErrorSource.location, 'gpsFailed');
  static const searchFailed = AppErrorCode(AppErrorSource.location, 'searchFailed');
  static const saveFavoriteFailed = AppErrorCode(AppErrorSource.location, 'saveFavoriteFailed');
  static const loadFavoritesFailed = AppErrorCode(AppErrorSource.location, 'loadFavoritesFailed');
  static const unexpected = AppErrorCode(AppErrorSource.location, 'unexpected');
}
