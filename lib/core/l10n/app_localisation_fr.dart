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
  String get settingsSectionGeneral => 'Général';

  @override
  String get settingsSectionPreference => 'Préférences';

  @override
  String get settingsSectionAbout => 'À propos';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsWindUnit => 'Unité du vent';

  @override
  String get settingsTemperatureUnit => 'Unité de température';

  @override
  String get settingsThemeDescription =>
      'Choisissez le thème de l\'application';

  @override
  String get settingsLanguageDescription =>
      'Choisissez la langue de l\'application';

  @override
  String get settingsWindUnitDescription =>
      'Choisissez l\'unité de mesure du vent';

  @override
  String get settingsTemperatureUnitDescription =>
      'Choisissez l\'unité de mesure de la température';

  @override
  String get settingsShare => 'Partager';

  @override
  String get settingsShareDescription => 'Partagez avec vos amis';

  @override
  String get settingsLicenses => 'Licences';

  @override
  String settingsAppVersion(String version) {
    return 'Version de l\'application : $version';
  }

  @override
  String get settingsCopyright => '© 2026 TzfLab';

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

  @override
  String get appTitle => 'SkyLine';

  @override
  String get weatherRefreshing => 'Actualisation...';

  @override
  String get weatherRetry => 'Réessayer';

  @override
  String get weatherSearchForLocation => 'Recherchez un lieu';

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
  String get weatherConditionClear => 'Ciel dégagé';

  @override
  String get weatherConditionPartlyCloudy => 'Partiellement nuageux';

  @override
  String get weatherConditionFoggy => 'Brouillard';

  @override
  String get weatherConditionDrizzle => 'Bruine';

  @override
  String get weatherConditionRain => 'Pluie';

  @override
  String get weatherConditionSnow => 'Neige';

  @override
  String get weatherConditionRainShowers => 'Averses';

  @override
  String get weatherConditionThunderstorm => 'Orage';

  @override
  String get weatherStatsWind => 'Vent';

  @override
  String get weatherStatsChanceOfRain => 'Risque de pluie';

  @override
  String get weatherStatsHumidity => 'Humidité';

  @override
  String get weatherHourlyTitle => 'Prévisions horaires';

  @override
  String get weatherDailyTitle => '7 prochains jours';

  @override
  String get weatherDayToday => 'Aujourd\'hui';

  @override
  String get weatherDayTomorrow => 'Demain';

  @override
  String get weatherSunSunrise => 'Lever du soleil';

  @override
  String get weatherSunSunset => 'Coucher du soleil';

  @override
  String get weatherSunZenith => 'Zénith';

  @override
  String get weatherSunMidnight => 'Minuit';

  @override
  String get weatherSunTitle => 'Heures du soleil';

  @override
  String get weatherNightTitle => 'Heures de nuit';

  @override
  String get locationTitle => 'Lieux';

  @override
  String get locationCurrentLocationTooltip => 'Position actuelle';

  @override
  String get locationEnable => 'Activer';

  @override
  String get locationNoFavorites => 'Aucun favori pour l\'instant';

  @override
  String get locationSearchHint => 'Rechercher une ville...';

  @override
  String get locationSearchNoResults => 'Aucun résultat trouvé';

  @override
  String get locationSearchPrompt =>
      'Saisissez un nom de ville pour rechercher';

  @override
  String get locationOnboardingTitle => 'Définir votre position';

  @override
  String get locationOnboardingBody =>
      'Autorisez la localisation pour voir la météo à votre position actuelle.';

  @override
  String get locationOnboardingEnable => 'Activer la localisation';

  @override
  String get locationOnboardingLater => 'Plus tard';

  @override
  String get weatherEmptySearchMessage =>
      'Recherchez une ville pour voir la météo.';

  @override
  String get weatherEmptySearchAction => 'Rechercher';

  @override
  String get errorNetwork =>
      'Pas de connexion internet. Vérifiez votre réseau.';

  @override
  String get errorFetch =>
      'Impossible de charger les données météo. Veuillez réessayer.';

  @override
  String get errorCache =>
      'Impossible d\'enregistrer les données météo localement.';

  @override
  String get errorLoadCache =>
      'Impossible de charger les données météo en cache.';

  @override
  String get errorUnexpected => 'Une erreur est survenue. Veuillez réessayer.';

  @override
  String get errorLoadSetting => 'Impossible de charger vos préférences.';

  @override
  String get errorUpdateSetting => 'Impossible d\'enregistrer vos préférences.';

  @override
  String get errorLocation =>
      'Impossible d\'obtenir votre position. Vérifiez les autorisations.';

  @override
  String get errorSearch =>
      'Impossible de rechercher des villes. Veuillez réessayer.';

  @override
  String get errorGpsDisabled =>
      'Les services de localisation sont désactivés.';

  @override
  String get errorGpsPermissionDenied =>
      'L\'autorisation de localisation est requise pour obtenir votre position actuelle.';

  @override
  String get errorGpsPermissionPermanentlyDenied =>
      'L\'autorisation de localisation est refusée définitivement. Activez-la dans les Réglages.';
}
