import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/core/enums/setting_wind_unit.dart';

void main() {
  group('SettingWindUnit round-trip', () {
    test('kmh round-trips correctly with display format', () {
      const unit = SettingWindUnit.kmh;
      final str = SettingWindUnit.getStringFromWindUnit(unit);
      final parsed = SettingWindUnit.getWindUnitFromString(str);
      expect(parsed, SettingWindUnit.kmh);
    });

    test('ms round-trips correctly with display format', () {
      const unit = SettingWindUnit.ms;
      final str = SettingWindUnit.getStringFromWindUnit(unit);
      final parsed = SettingWindUnit.getWindUnitFromString(str);
      expect(parsed, SettingWindUnit.ms);
    });

    test('legacy kmh format still parses', () {
      expect(SettingWindUnit.getWindUnitFromString('kmh'), SettingWindUnit.kmh);
    });

    test('legacy ms format still parses', () {
      expect(SettingWindUnit.getWindUnitFromString('ms'), SettingWindUnit.ms);
    });
  });
}
