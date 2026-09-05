enum SettingHeatUnit {
  celsius,
  fahrenheit;

  static SettingHeatUnit getHeatUnitFromString(String unit) {
    switch (unit) {
      case 'fahrenheit':
        return SettingHeatUnit.fahrenheit;
      default:
        return SettingHeatUnit.celsius;
    }
  }

  static String getStringFromHeatUnit(SettingHeatUnit unit) {
    switch (unit) {
      case SettingHeatUnit.fahrenheit:
        return 'fahrenheit';
      case SettingHeatUnit.celsius:
        return 'celsius';
    }
  }
}
