import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localisation_ar.dart';
import 'app_localisation_en.dart';
import 'app_localisation_es.dart';
import 'app_localisation_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalisation
/// returned by `AppLocalisation.of(context)`.
///
/// Applications need to include `AppLocalisation.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localisation.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalisation.localizationsDelegates,
///   supportedLocales: AppLocalisation.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalisation.supportedLocales
/// property.
abstract class AppLocalisation {
  AppLocalisation(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalisation? of(BuildContext context) {
    return Localizations.of<AppLocalisation>(context, AppLocalisation);
  }

  static const LocalizationsDelegate<AppLocalisation> delegate =
      _AppLocalisationDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// Title for the settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsWindUnit.
  ///
  /// In en, this message translates to:
  /// **'Wind Unit'**
  String get settingsWindUnit;

  /// No description provided for @settingsTemperatureUnit.
  ///
  /// In en, this message translates to:
  /// **'Temperature Unit'**
  String get settingsTemperatureUnit;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsLangEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLangEn;

  /// No description provided for @settingsLangFr.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get settingsLangFr;

  /// No description provided for @settingsLangEs.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get settingsLangEs;

  /// No description provided for @settingsLangAr.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get settingsLangAr;

  /// No description provided for @settingsWindUnitMs.
  ///
  /// In en, this message translates to:
  /// **'m/s'**
  String get settingsWindUnitMs;

  /// No description provided for @settingsWindUnitKmh.
  ///
  /// In en, this message translates to:
  /// **'km/h'**
  String get settingsWindUnitKmh;

  /// No description provided for @settingsTempUnitCelsius.
  ///
  /// In en, this message translates to:
  /// **'Celsius'**
  String get settingsTempUnitCelsius;

  /// No description provided for @settingsTempUnitFahrenheit.
  ///
  /// In en, this message translates to:
  /// **'Fahrenheit'**
  String get settingsTempUnitFahrenheit;

  /// App brand name used as the weather header title fallback
  ///
  /// In en, this message translates to:
  /// **'SkyLine'**
  String get appTitle;

  /// No description provided for @weatherRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing...'**
  String get weatherRefreshing;

  /// No description provided for @weatherRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get weatherRetry;

  /// No description provided for @weatherSearchForLocation.
  ///
  /// In en, this message translates to:
  /// **'Search for a location'**
  String get weatherSearchForLocation;

  /// Full localized long date
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String weatherDateLong(DateTime date);

  /// Short localized day label with abbreviated weekday
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String weatherDayLabel(DateTime date);

  /// Short localized time of day
  ///
  /// In en, this message translates to:
  /// **'{time}'**
  String weatherSunTime(DateTime time);

  /// No description provided for @weatherConditionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get weatherConditionClear;

  /// No description provided for @weatherConditionPartlyCloudy.
  ///
  /// In en, this message translates to:
  /// **'Partly cloudy'**
  String get weatherConditionPartlyCloudy;

  /// No description provided for @weatherConditionFoggy.
  ///
  /// In en, this message translates to:
  /// **'Foggy'**
  String get weatherConditionFoggy;

  /// No description provided for @weatherConditionDrizzle.
  ///
  /// In en, this message translates to:
  /// **'Drizzle'**
  String get weatherConditionDrizzle;

  /// No description provided for @weatherConditionRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherConditionRain;

  /// No description provided for @weatherConditionSnow.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get weatherConditionSnow;

  /// No description provided for @weatherConditionRainShowers.
  ///
  /// In en, this message translates to:
  /// **'Rain showers'**
  String get weatherConditionRainShowers;

  /// No description provided for @weatherConditionThunderstorm.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get weatherConditionThunderstorm;

  /// No description provided for @weatherStatsWind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get weatherStatsWind;

  /// No description provided for @weatherStatsChanceOfRain.
  ///
  /// In en, this message translates to:
  /// **'Chance of rain'**
  String get weatherStatsChanceOfRain;

  /// No description provided for @weatherStatsHumidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get weatherStatsHumidity;

  /// No description provided for @weatherHourlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Hourly Forecast'**
  String get weatherHourlyTitle;

  /// No description provided for @weatherDailyTitle.
  ///
  /// In en, this message translates to:
  /// **'Next 7 Days'**
  String get weatherDailyTitle;

  /// No description provided for @weatherDayToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get weatherDayToday;

  /// No description provided for @weatherDayTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get weatherDayTomorrow;

  /// No description provided for @weatherSunSunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get weatherSunSunrise;

  /// No description provided for @weatherSunSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get weatherSunSunset;

  /// No description provided for @weatherSunZenith.
  ///
  /// In en, this message translates to:
  /// **'Zenith'**
  String get weatherSunZenith;

  /// No description provided for @weatherSunMidnight.
  ///
  /// In en, this message translates to:
  /// **'Midnight'**
  String get weatherSunMidnight;

  /// No description provided for @weatherSunTitle.
  ///
  /// In en, this message translates to:
  /// **'Sun Time'**
  String get weatherSunTitle;

  /// No description provided for @weatherNightTitle.
  ///
  /// In en, this message translates to:
  /// **'Night Time'**
  String get weatherNightTitle;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network.'**
  String get errorNetwork;

  /// No description provided for @errorFetch.
  ///
  /// In en, this message translates to:
  /// **'Could not load weather data. Please try again.'**
  String get errorFetch;

  /// No description provided for @errorCache.
  ///
  /// In en, this message translates to:
  /// **'Could not save weather data locally.'**
  String get errorCache;

  /// No description provided for @errorLoadCache.
  ///
  /// In en, this message translates to:
  /// **'Could not load cached weather data.'**
  String get errorLoadCache;

  /// No description provided for @errorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnexpected;

  /// No description provided for @errorLoadSetting.
  ///
  /// In en, this message translates to:
  /// **'Could not load your preferences.'**
  String get errorLoadSetting;

  /// No description provided for @errorUpdateSetting.
  ///
  /// In en, this message translates to:
  /// **'Could not save your preferences.'**
  String get errorUpdateSetting;

  /// No description provided for @errorLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location. Please check permissions.'**
  String get errorLocation;

  /// No description provided for @errorSearch.
  ///
  /// In en, this message translates to:
  /// **'Could not search cities. Please try again.'**
  String get errorSearch;

  /// No description provided for @errorGpsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are turned off.'**
  String get errorGpsDisabled;

  /// No description provided for @errorGpsPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required to get your current location.'**
  String get errorGpsPermissionDenied;

  /// No description provided for @errorGpsPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission is permanently denied. Please enable it in Settings.'**
  String get errorGpsPermissionPermanentlyDenied;
}

class _AppLocalisationDelegate extends LocalizationsDelegate<AppLocalisation> {
  const _AppLocalisationDelegate();

  @override
  Future<AppLocalisation> load(Locale locale) {
    return SynchronousFuture<AppLocalisation>(lookupAppLocalisation(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalisationDelegate old) => false;
}

AppLocalisation lookupAppLocalisation(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalisationAr();
    case 'en':
      return AppLocalisationEn();
    case 'es':
      return AppLocalisationEs();
    case 'fr':
      return AppLocalisationFr();
  }

  throw FlutterError(
    'AppLocalisation.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
