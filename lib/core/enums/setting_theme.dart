import 'package:flutter/material.dart';

enum SettingTheme{
  light,
  dark,
  system;

  // Convert String to theme
  static SettingTheme getThemeFromString(String theme) {
    switch (theme) {
      case 'light':
        return SettingTheme.light;
      case 'dark':
        return SettingTheme.dark;
      default:
        return SettingTheme.system;
    }
  }

  // Convert a theme to String
  static String getStringFromTheme(SettingTheme theme) {
    switch (theme) {
      case SettingTheme.light:
        return 'light';
      case SettingTheme.dark:
        return 'dark';
      default:
        return 'system';
    }
  }

  // Convert SettingTheme in ThemeMode
  static ThemeMode getThemeMode(SettingTheme theme) {
    switch (theme) {
      case SettingTheme.light:
        return ThemeMode.light;
      case SettingTheme.dark:
        return ThemeMode.dark;
      case SettingTheme.system:
        return ThemeMode.system;
    }
  }

  // Convert a theme to String for the ui
  /* static String getStringFromThemeByLanguage(BuildContext context, SettingTheme theme) {
    switch (theme) {
      case SettingTheme.light:
        return AppLocalizations.of(context)!.settingThemeLight;
      case SettingTheme.dark:
        return AppLocalizations.of(context)!.settingThemeDark;
      default:
        return AppLocalizations.of(context)!.settingThemeSystem;
    }
  } */
}

