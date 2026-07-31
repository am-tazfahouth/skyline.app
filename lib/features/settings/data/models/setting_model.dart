import 'package:equatable/equatable.dart';
import 'package:sky_line/core/enums/setting_heat_unit.dart';
import 'package:sky_line/core/enums/setting_lang.dart';
import 'package:sky_line/core/enums/setting_theme.dart';
import 'package:sky_line/core/enums/setting_wind_unit.dart';

class SettingModel extends Equatable {
  final SettingTheme theme;
  final SettingLang lang;
  final SettingWindUnit windUnit;
  final SettingHeatUnit heatUnit;

  const SettingModel({
    this.theme = SettingTheme.system,
    this.lang = SettingLang.en,
    this.windUnit = SettingWindUnit.ms,
    this.heatUnit = SettingHeatUnit.celsius,
  });

  @override
  List<Object?> get props => [theme, lang, windUnit, heatUnit];
}
