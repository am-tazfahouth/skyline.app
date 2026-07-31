import 'package:sky_line/core/config/db_helper/setting_cache_entity.dart';
import 'package:sky_line/core/enums/setting_heat_unit.dart';
import 'package:sky_line/core/enums/setting_lang.dart';
import 'package:sky_line/core/enums/setting_theme.dart';
import 'package:sky_line/core/enums/setting_wind_unit.dart';
import 'package:sky_line/features/settings/data/models/setting_model.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';

class SettingMapper {
  const SettingMapper._();

  static SettingModel fromCacheEntity(SettingCacheEntity entity) {
    return SettingModel(
      theme: SettingTheme.getThemeFromString(entity.themeValue),
      lang: getLangFromString(entity.langValue),
      windUnit: SettingWindUnit.getWindUnitFromString(entity.windUnitValue),
      heatUnit: SettingHeatUnit.getHeatUnitFromString(entity.heatUnitValue),
    );
  }

  static SettingEntity toEntity(SettingModel model) {
    return SettingEntity(
      theme: model.theme,
      lang: model.lang,
      windUnit: model.windUnit,
      heatUnit: model.heatUnit,
    );
  }

  static SettingModel fromEntity(SettingEntity entity) {
    return SettingModel(
      theme: entity.theme,
      lang: entity.lang,
      windUnit: entity.windUnit,
      heatUnit: entity.heatUnit,
    );
  }
}
