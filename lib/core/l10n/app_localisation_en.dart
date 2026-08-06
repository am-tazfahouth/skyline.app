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

  @override
  String get appTitle => 'SkyLine';

  @override
  String get weatherRefreshing => 'Refreshing...';

  @override
  String get weatherRetry => 'Retry';

  @override
  String get weatherSearchForLocation => 'Search for a location';

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
  String get weatherConditionClear => 'Clear';

  @override
  String get weatherConditionPartlyCloudy => 'Partly cloudy';

  @override
  String get weatherConditionFoggy => 'Foggy';

  @override
  String get weatherConditionDrizzle => 'Drizzle';

  @override
  String get weatherConditionRain => 'Rain';

  @override
  String get weatherConditionSnow => 'Snow';

  @override
  String get weatherConditionRainShowers => 'Rain showers';

  @override
  String get weatherConditionThunderstorm => 'Thunderstorm';

  @override
  String get weatherStatsWind => 'Wind';

  @override
  String get weatherStatsChanceOfRain => 'Chance of rain';

  @override
  String get weatherStatsHumidity => 'Humidity';

  @override
  String get weatherHourlyTitle => 'Hourly Forecast';

  @override
  String get weatherDailyTitle => 'Next 7 Days';

  @override
  String get weatherDayToday => 'Today';

  @override
  String get weatherDayTomorrow => 'Tomorrow';

  @override
  String get weatherSunSunrise => 'Sunrise';

  @override
  String get weatherSunSunset => 'Sunset';

  @override
  String get weatherSunZenith => 'Zenith';

  @override
  String get weatherSunMidnight => 'Midnight';

  @override
  String get weatherSunTitle => 'Sun Time';

  @override
  String get weatherNightTitle => 'Night Time';

  @override
  String get locationTitle => 'Location';

  @override
  String get locationCurrentLocationTooltip => 'Current location';

  @override
  String get locationEnable => 'Enable';

  @override
  String get locationNoFavorites => 'No favorites yet';

  @override
  String get locationSearchTitle => 'Search City';

  @override
  String get locationSearchHint => 'Search city...';

  @override
  String get locationSearchNoResults => 'No results found';

  @override
  String get locationSearchPrompt => 'Type to search for a city';

  @override
  String get errorNetwork =>
      'No internet connection. Please check your network.';

  @override
  String get errorFetch => 'Could not load weather data. Please try again.';

  @override
  String get errorCache => 'Could not save weather data locally.';

  @override
  String get errorLoadCache => 'Could not load cached weather data.';

  @override
  String get errorUnexpected => 'Something went wrong. Please try again.';

  @override
  String get errorLoadSetting => 'Could not load your preferences.';

  @override
  String get errorUpdateSetting => 'Could not save your preferences.';

  @override
  String get errorLocation =>
      'Could not get your location. Please check permissions.';

  @override
  String get errorSearch => 'Could not search cities. Please try again.';

  @override
  String get errorGpsDisabled => 'Location services are turned off.';

  @override
  String get errorGpsPermissionDenied =>
      'Location permission is required to get your current location.';

  @override
  String get errorGpsPermissionPermanentlyDenied =>
      'Location permission is permanently denied. Please enable it in Settings.';
}
