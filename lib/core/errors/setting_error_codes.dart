import 'package:sky_line/core/errors/app_error_code.dart';
import 'package:sky_line/core/enums/app_error_source.dart';

class SettingErrorCodes {
  static const load = AppErrorCode(AppErrorSource.settings, 'load');
  static const update = AppErrorCode(AppErrorSource.settings, 'update');
}