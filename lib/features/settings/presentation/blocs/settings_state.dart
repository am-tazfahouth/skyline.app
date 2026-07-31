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

  const SettingsLoadSuccess({
    this.setting = const SettingEntity(),
    this.isLoaded = false,
  });

  SettingsLoadSuccess copyWith({SettingEntity? setting, bool? isLoaded}) {
    return SettingsLoadSuccess(
      setting: setting ?? this.setting,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  List<Object?> get props => [setting, isLoaded];
}

class SettingsError extends SettingsState {
  final AppErrorCode errorCode;

  const SettingsError({required this.errorCode});

  @override
  List<Object?> get props => [errorCode];
}
