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
