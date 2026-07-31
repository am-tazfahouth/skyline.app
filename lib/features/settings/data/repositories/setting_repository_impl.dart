import 'package:sky_line/core/config/db_helper/db_helper.dart';
import 'package:sky_line/features/settings/data/mappers/setting_mapper.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';
import 'package:sky_line/features/settings/domain/repositories/setting_repository.dart';

class SettingRepositoryImpl implements SettingRepository {
  final DbHelper _dbHelper;

  SettingRepositoryImpl(this._dbHelper);

  @override
  Future<SettingEntity> loadSettings() async {
    final cached = _dbHelper.loadSettings();
    if (cached == null) return SettingEntity.defaults;
    return SettingMapper.toEntity(SettingMapper.fromCacheEntity(cached));
  }

  @override
  Future<void> saveSettings(SettingEntity setting) async {
    final model = SettingMapper.fromEntity(setting);
    _dbHelper.saveSettings(model);
  }
}
