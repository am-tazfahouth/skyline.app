import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';

abstract class SettingRepository {
  Future<SettingEntity> loadSettings();
  Future<void> saveSettings(SettingEntity setting);
}
