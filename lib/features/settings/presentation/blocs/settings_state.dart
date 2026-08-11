import 'package:equatable/equatable.dart';
import 'package:sky_line/core/errors/app_error_code.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsLoadSuccess extends SettingsState {
  final SettingEntity setting;
  final bool isLoaded;
  final String appVersion;

  const SettingsLoadSuccess({
    this.setting = const SettingEntity(),
    this.isLoaded = false,
    this.appVersion = '',
  });

  SettingsLoadSuccess copyWith({
    SettingEntity? setting,
    bool? isLoaded,
    String? appVersion,
  }) {
    return SettingsLoadSuccess(
      setting: setting ?? this.setting,
      isLoaded: isLoaded ?? this.isLoaded,
      appVersion: appVersion ?? this.appVersion,
    );
  }

  @override
  List<Object?> get props => [setting, isLoaded, appVersion];
}

class SettingsError extends SettingsState {
  final AppErrorCode errorCode;

  const SettingsError({required this.errorCode});

  @override
  List<Object?> get props => [errorCode];
}
