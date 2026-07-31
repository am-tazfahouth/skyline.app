import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/core/config/db_helper/setting_cache_entity.dart';
import 'package:sky_line/core/enums/setting_heat_unit.dart';
import 'package:sky_line/core/enums/setting_lang.dart';
import 'package:sky_line/core/enums/setting_theme.dart';
import 'package:sky_line/core/enums/setting_wind_unit.dart';
import 'package:sky_line/features/settings/data/mappers/setting_mapper.dart';
import 'package:sky_line/features/settings/data/models/setting_model.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';

void main() {
  group('SettingMapper', () {
    final tModel = const SettingModel(
      theme: SettingTheme.light,
      lang: SettingLang.fr,
      windUnit: SettingWindUnit.kmh,
      heatUnit: SettingHeatUnit.fahrenheit,
    );

    test('fromCacheEntity creates correct model', () {
      final entity = SettingCacheEntity(
        id: 0,
        themeValue: 'light',
        langValue: 'fr',
        windUnitValue: 'kmh',
        heatUnitValue: 'fahrenheit',
      );
      final model = SettingMapper.fromCacheEntity(entity);
      expect(model.theme, SettingTheme.light);
      expect(model.lang, SettingLang.fr);
      expect(model.windUnit, SettingWindUnit.kmh);
      expect(model.heatUnit, SettingHeatUnit.fahrenheit);
    });

    test('toEntity creates correct domain entity', () {
      final entity = SettingMapper.toEntity(tModel);
      expect(entity.theme, SettingTheme.light);
      expect(entity.lang, SettingLang.fr);
      expect(entity.windUnit, SettingWindUnit.kmh);
      expect(entity.heatUnit, SettingHeatUnit.fahrenheit);
    });

    test('fromEntity creates correct model', () {
      final setting = const SettingEntity(
        theme: SettingTheme.dark,
        lang: SettingLang.ar,
        windUnit: SettingWindUnit.ms,
        heatUnit: SettingHeatUnit.celsius,
      );
      final model = SettingMapper.fromEntity(setting);
      expect(model.theme, SettingTheme.dark);
      expect(model.lang, SettingLang.ar);
      expect(model.windUnit, SettingWindUnit.ms);
      expect(model.heatUnit, SettingHeatUnit.celsius);
    });
  });
}
