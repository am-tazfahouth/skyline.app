// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localisation.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalisationEs extends AppLocalisation {
  AppLocalisationEs([String locale = 'es']) : super(locale);

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsWindUnit => 'Unidad del viento';

  @override
  String get settingsTemperatureUnit => 'Unidad de temperatura';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsThemeSystem => 'Sistema';

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
