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
  String get settingsSectionGeneral => 'General';

  @override
  String get settingsSectionPreference => 'Preferencias';

  @override
  String get settingsSectionAbout => 'Acerca de';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsWindUnit => 'Unidad del viento';

  @override
  String get settingsTemperatureUnit => 'Unidad de temperatura';

  @override
  String get settingsThemeDescription => 'Elige el tema de la aplicación';

  @override
  String get settingsLanguageDescription => 'Elige el idioma de la aplicación';

  @override
  String get settingsWindUnitDescription =>
      'Elige la unidad de medida del viento';

  @override
  String get settingsTemperatureUnitDescription =>
      'Elige la unidad de medida de la temperatura';

  @override
  String get settingsShare => 'Compartir';

  @override
  String get settingsShareDescription => 'Comparte con tus amigos';

  @override
  String get settingsLicenses => 'Licencias';

  @override
  String settingsAppVersion(String version) {
    return 'Versión de la aplicación: $version';
  }

  @override
  String get settingsCopyright => '© 2026 TzfLab';

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

  @override
  String get appTitle => 'SkyLine';

  @override
  String get weatherRefreshing => 'Actualizando...';

  @override
  String get weatherRetry => 'Reintentar';

  @override
  String get weatherSearchForLocation => 'Buscar un lugar';

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
  String get weatherConditionClear => 'Despejado';

  @override
  String get weatherConditionPartlyCloudy => 'Parcialmente nublado';

  @override
  String get weatherConditionFoggy => 'Niebla';

  @override
  String get weatherConditionDrizzle => 'Llovizna';

  @override
  String get weatherConditionRain => 'Lluvia';

  @override
  String get weatherConditionSnow => 'Nieve';

  @override
  String get weatherConditionRainShowers => 'Chubascos';

  @override
  String get weatherConditionThunderstorm => 'Tormenta';

  @override
  String get weatherStatsWind => 'Viento';

  @override
  String get weatherStatsChanceOfRain => 'Probabilidad de lluvia';

  @override
  String get weatherStatsHumidity => 'Humedad';

  @override
  String get weatherHourlyTitle => 'Pronóstico por horas';

  @override
  String get weatherDailyTitle => 'Próximos 7 días';

  @override
  String get weatherDayToday => 'Hoy';

  @override
  String get weatherDayTomorrow => 'Mañana';

  @override
  String get weatherSunSunrise => 'Amanecer';

  @override
  String get weatherSunSunset => 'Atardecer';

  @override
  String get weatherSunZenith => 'Cenit';

  @override
  String get weatherSunMidnight => 'Medianoche';

  @override
  String get weatherSunTitle => 'Hora solar';

  @override
  String get weatherNightTitle => 'Hora nocturna';

  @override
  String get locationTitle => 'Ubicaciones';

  @override
  String get locationCurrentLocationTooltip => 'Ubicación actual';

  @override
  String get locationEnable => 'Activar';

  @override
  String get locationNoFavorites => 'Aún no hay favoritos';

  @override
  String get locationSearchHint => 'Buscar ciudad...';

  @override
  String get locationSearchNoResults => 'No se encontraron resultados';

  @override
  String get locationSearchPrompt => 'Escribe para buscar una ciudad';

  @override
  String get locationOnboardingTitle => 'Configura tu ubicación';

  @override
  String get locationOnboardingBody =>
      'Permite el acceso a tu ubicación para ver el clima en tu posición actual.';

  @override
  String get locationOnboardingEnable => 'Activar ubicación';

  @override
  String get locationOnboardingLater => 'Más tarde';

  @override
  String get weatherEmptySearchMessage => 'Busca una ciudad para ver el clima.';

  @override
  String get weatherEmptySearchAction => 'Buscar';

  @override
  String get weatherCachedDataMessage =>
      'Sin conexión. Mostrando datos guardados.';

  @override
  String get weatherRefreshErrorMessage =>
      'Error de red. Inténtelo de nuevo más tarde.';

  @override
  String get errorNetwork => 'Sin conexión a internet. Compruebe su red.';

  @override
  String get errorFetch =>
      'No se pudieron cargar los datos meteorológicos. Inténtelo de nuevo.';

  @override
  String get errorCache =>
      'No se pudieron guardar los datos meteorológicos localmente.';

  @override
  String get errorLoadCache =>
      'No se pudieron cargar los datos meteorológicos guardados.';

  @override
  String get errorUnexpected => 'Algo salió mal. Inténtelo de nuevo.';

  @override
  String get errorLoadSetting => 'No se pudieron cargar sus preferencias.';

  @override
  String get errorUpdateSetting => 'No se pudieron guardar sus preferencias.';

  @override
  String get errorLocation =>
      'No se pudo obtener su ubicación. Compruebe los permisos.';

  @override
  String get errorSearch =>
      'No se pudieron buscar ciudades. Inténtelo de nuevo.';

  @override
  String get errorGpsDisabled =>
      'Los servicios de ubicación están desactivados.';

  @override
  String get errorGpsPermissionDenied =>
      'Se requiere el permiso de ubicación para obtener su ubicación actual.';

  @override
  String get errorGpsPermissionPermanentlyDenied =>
      'El permiso de ubicación está denegado permanentemente. Actívelo en los Ajustes.';
}
