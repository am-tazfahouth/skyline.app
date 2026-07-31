import 'package:equatable/equatable.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettingsEvent extends SettingsEvent {
  const LoadSettingsEvent();
}

class UpdateSettingsEvent extends SettingsEvent {
  final SettingEntity setting;

  const UpdateSettingsEvent({required this.setting});

  @override
  List<Object?> get props => [setting];
}
