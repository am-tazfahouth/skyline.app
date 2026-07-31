// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localisation.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalisationFr extends AppLocalisation {
  AppLocalisationFr([String locale = 'fr']) : super(locale);

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsWindUnit => 'Unité du vent';

  @override
  String get settingsTemperatureUnit => 'Unité de température';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsThemeSystem => 'Système';

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
