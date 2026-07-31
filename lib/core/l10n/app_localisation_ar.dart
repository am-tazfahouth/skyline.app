// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localisation.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalisationAr extends AppLocalisation {
  AppLocalisationAr([String locale = 'ar']) : super(locale);

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsTheme => 'المظهر';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsWindUnit => 'وحدة الرياح';

  @override
  String get settingsTemperatureUnit => 'وحدة درجة الحرارة';

  @override
  String get settingsThemeLight => 'فاتح';

  @override
  String get settingsThemeDark => 'داكن';

  @override
  String get settingsThemeSystem => 'النظام';

  @override
  String get settingsLangEn => 'English';

  @override
  String get settingsLangFr => 'Français';

  @override
  String get settingsLangEs => 'Español';

  @override
  String get settingsLangAr => 'العربية';

  @override
  String get settingsWindUnitMs => 'م/ث';

  @override
  String get settingsWindUnitKmh => 'كم/س';

  @override
  String get settingsTempUnitCelsius => 'مئوية';

  @override
  String get settingsTempUnitFahrenheit => 'فهرنهايت';
}
