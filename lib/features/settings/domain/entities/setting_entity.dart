import 'package:equatable/equatable.dart';
import 'package:sky_line/core/enums/setting_heat_unit.dart';
import 'package:sky_line/core/enums/setting_lang.dart';
import 'package:sky_line/core/enums/setting_theme.dart';
import 'package:sky_line/core/enums/setting_wind_unit.dart';

class SettingEntity extends Equatable {
  final SettingTheme theme;
  final SettingLang lang;
  final SettingWindUnit windUnit;
  final SettingHeatUnit heatUnit;

  const SettingEntity({
    this.theme = SettingTheme.system,
    this.lang = SettingLang.en,
    this.windUnit = SettingWindUnit.ms,
    this.heatUnit = SettingHeatUnit.celsius,
  });

  static const defaults = SettingEntity();

  SettingEntity copyWith({
    SettingTheme? theme,
    SettingLang? lang,
    SettingWindUnit? windUnit,
    SettingHeatUnit? heatUnit,
  }) {
    return SettingEntity(
      theme: theme ?? this.theme,
      lang: lang ?? this.lang,
      windUnit: windUnit ?? this.windUnit,
      heatUnit: heatUnit ?? this.heatUnit,
    );
  }

  @override
  List<Object?> get props => [theme, lang, windUnit, heatUnit];
}
