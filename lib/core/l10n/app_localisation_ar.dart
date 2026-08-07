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

  @override
  String get appTitle => 'SkyLine';

  @override
  String get weatherRefreshing => 'جارٍ التحديث...';

  @override
  String get weatherRetry => 'إعادة المحاولة';

  @override
  String get weatherSearchForLocation => 'ابحث عن مكان';

  @override
  String weatherDateLong(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat(
      'dMMMMy',
      localeName,
    );
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String weatherDayLabel(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat(
      'E dMMM',
      localeName,
    );
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String weatherSunTime(DateTime time) {
    final intl.DateFormat timeDateFormat = intl.DateFormat.jm(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$timeString';
  }

  @override
  String get weatherConditionClear => 'صافٍ';

  @override
  String get weatherConditionPartlyCloudy => 'غائم جزئياً';

  @override
  String get weatherConditionFoggy => 'ضبابي';

  @override
  String get weatherConditionDrizzle => 'رذاذ';

  @override
  String get weatherConditionRain => 'مطر';

  @override
  String get weatherConditionSnow => 'ثلج';

  @override
  String get weatherConditionRainShowers => 'زخات مطر';

  @override
  String get weatherConditionThunderstorm => 'عاصفة رعدية';

  @override
  String get weatherStatsWind => 'الرياح';

  @override
  String get weatherStatsChanceOfRain => 'احتمال هطول المطر';

  @override
  String get weatherStatsHumidity => 'الرطوبة';

  @override
  String get weatherHourlyTitle => 'توقعات كل ساعة';

  @override
  String get weatherDailyTitle => 'الأيام السبعة القادمة';

  @override
  String get weatherDayToday => 'اليوم';

  @override
  String get weatherDayTomorrow => 'غداً';

  @override
  String get weatherSunSunrise => 'شروق الشمس';

  @override
  String get weatherSunSunset => 'غروب الشمس';

  @override
  String get weatherSunZenith => 'الذروة';

  @override
  String get weatherSunMidnight => 'منتصف الليل';

  @override
  String get weatherSunTitle => 'وقت الشمس';

  @override
  String get weatherNightTitle => 'وقت الليل';

  @override
  String get locationTitle => 'المواقع';

  @override
  String get locationCurrentLocationTooltip => 'الموقع الحالي';

  @override
  String get locationEnable => 'تفعيل';

  @override
  String get locationNoFavorites => 'لا توجد أماكن مفضلة بعد';

  @override
  String get locationSearchHint => 'ابحث عن مدينة...';

  @override
  String get locationSearchNoResults => 'لا توجد نتائج';

  @override
  String get locationSearchPrompt => 'اكتب للبحث عن مدينة';

  @override
  String get errorNetwork => 'لا يوجد اتصال بالإنترنت. يرجى التحقق من شبكتك.';

  @override
  String get errorFetch => 'تعذّر تحميل بيانات الطقس. يرجى المحاولة مرة أخرى.';

  @override
  String get errorCache => 'تعذّر حفظ بيانات الطقس محلياً.';

  @override
  String get errorLoadCache => 'تعذّر تحميل بيانات الطقس المحفوظة.';

  @override
  String get errorUnexpected => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get errorLoadSetting => 'تعذّر تحميل تفضيلاتك.';

  @override
  String get errorUpdateSetting => 'تعذّر حفظ تفضيلاتك.';

  @override
  String get errorLocation =>
      'تعذّر الحصول على موقعك. يرجى التحقق من الأذونات.';

  @override
  String get errorSearch => 'تعذّر البحث عن المدن. يرجى المحاولة مرة أخرى.';

  @override
  String get errorGpsDisabled => 'خدمات الموقع معطّلة.';

  @override
  String get errorGpsPermissionDenied =>
      'يجب منح إذن الموقع للحصول على موقعك الحالي.';

  @override
  String get errorGpsPermissionPermanentlyDenied =>
      'تم رفض إذن الموقع نهائياً. يرجى تفعيله في الإعدادات.';
}
