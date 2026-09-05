import 'package:flutter/foundation.dart';
import 'package:sky_line/core/config/db_helper/db_helper.dart';
import 'package:sky_line/core/enums/setting_lang.dart';
import 'package:sky_line/core/utils/platform_utils.dart';
import 'package:sky_line/features/settings/data/mappers/setting_mapper.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';
import 'package:sky_line/features/settings/domain/repositories/setting_repository.dart';

class SettingRepositoryImpl implements SettingRepository {
  final DbHelper _dbHelper;
  final SettingLang Function() systemLangProvider;

  SettingRepositoryImpl(this._dbHelper)
      : systemLangProvider = PlatformUtils.getSystemLang;

  @visibleForTesting
  SettingRepositoryImpl.withSystemLang(
    this._dbHelper,
    this.systemLangProvider,
  );

  @override
  Future<SettingEntity> loadSettings() async {
    final cached = _dbHelper.loadSettings();
    if (cached == null) {
      final lang = systemLangProvider();
      final setting = SettingEntity.defaults.copyWith(lang: lang);
      saveSettings(setting);
      return setting;
    }
    return SettingMapper.toEntity(SettingMapper.fromCacheEntity(cached));
  }

  @override
  Future<void> saveSettings(SettingEntity setting) async {
    final model = SettingMapper.fromEntity(setting);
    _dbHelper.saveSettings(model);
  }
}