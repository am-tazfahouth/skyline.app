// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localisation.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalisationEn extends AppLocalisation {
  AppLocalisationEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsWindUnit => 'Wind Unit';

  @override
  String get settingsTemperatureUnit => 'Temperature Unit';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsLangEn => 'English';

  @override
  String get settingsLangFr => 'Français';

  @override
  String get settingsLangEs => 'Español';

  @override
  String get settingsLangAr => 'العربية';

  @override
  String get settingsWindUnitMs => 'm/s';

  @override
  String get settingsWindUnitKmh => 'km/h';

  @override
  String get settingsTempUnitCelsius => 'Celsius';

  @override
  String get settingsTempUnitFahrenheit => 'Fahrenheit';
}
