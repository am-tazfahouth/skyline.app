import 'package:objectbox/objectbox.dart';

@Entity()
class SettingCacheEntity {
  @Id()
  int id;
  String themeValue;
  String langValue;
  String windUnitValue;
  String heatUnitValue;

  SettingCacheEntity({
    required this.id,
    required this.themeValue,
    required this.langValue,
    required this.windUnitValue,
    required this.heatUnitValue,
  });
}
