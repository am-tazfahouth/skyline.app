import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/core/enums/setting_heat_unit.dart';
import 'package:sky_line/core/enums/setting_lang.dart';
import 'package:sky_line/core/enums/setting_theme.dart';
import 'package:sky_line/core/enums/setting_wind_unit.dart';
import 'package:sky_line/features/settings/data/models/setting_model.dart';

void main() {
  group('SettingModel', () {
    final tModel = const SettingModel(
      theme: SettingTheme.light,
      lang: SettingLang.fr,
      windUnit: SettingWindUnit.kmh,
      heatUnit: SettingHeatUnit.fahrenheit,
    );

    test('props returns correct list', () {
      expect(tModel.props, [SettingTheme.light, SettingLang.fr, SettingWindUnit.kmh, SettingHeatUnit.fahrenheit]);
    });

    test('defaults are correct', () {
      final model = const SettingModel();
      expect(model.theme, SettingTheme.system);
      expect(model.lang, SettingLang.en);
      expect(model.windUnit, SettingWindUnit.ms);
      expect(model.heatUnit, SettingHeatUnit.celsius);
    });
  });
}
