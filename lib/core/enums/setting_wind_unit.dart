enum SettingWindUnit {
  ms,
  kmh;

  static SettingWindUnit getWindUnitFromString(String unit) {
    switch (unit) {
      case 'kmh':
      case 'km/h':
        return SettingWindUnit.kmh;
      case 'ms':
      case 'm/s':
        return SettingWindUnit.ms;
      default:
        return SettingWindUnit.ms;
    }
  }

  static String getStringFromWindUnit(SettingWindUnit unit) {
    switch (unit) {
      case SettingWindUnit.kmh:
        return 'km/h';
      case SettingWindUnit.ms:
        return 'm/s';
    }
  }
}