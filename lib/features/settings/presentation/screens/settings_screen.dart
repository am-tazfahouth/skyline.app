import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/constants/app_spacing.dart';
import 'package:sky_line/core/errors/app_error.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_state.dart';
import 'package:sky_line/features/settings/presentation/widgets/select_heat_unit_dialog.dart';
import 'package:sky_line/features/settings/presentation/widgets/select_lang_dialog.dart';
import 'package:sky_line/features/settings/presentation/widgets/select_theme_dialog.dart';
import 'package:sky_line/features/settings/presentation/widgets/select_wind_unit_dialog.dart';
import 'package:sky_line/features/settings/presentation/widgets/setting_card.dart';
import 'package:sky_line/features/settings/presentation/widgets/setting_item.dart';
import 'package:sky_line/features/settings/presentation/widgets/creator_card.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_event.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalisation.of(context)!;
    final bgColor = AppTheme.surfaceFor(Theme.of(context).brightness).color;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        notificationPredicate: (_) => false,
        backgroundColor: bgColor,
      ),
      backgroundColor: bgColor,
      body: BlocListener<SettingsBloc, SettingsState>(
        listenWhen: (previous, current) {
          if (current is SettingsError) return true;
          if (current is! SettingsLoadSuccess) return false;
          if (previous is! SettingsLoadSuccess) return true;
          return previous.setting != current.setting;
        },
        listener: (context, state) {
          if (state is SettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppError.getUserErrorMessage(state.errorCode, l10n)),
              ),
            );
          } else if (state is SettingsLoadSuccess) {
            context.read<WeatherForecastBloc>().add(
              ApplySettingsEvent(settings: state.setting),
            );
          }
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              if (state is! SettingsLoadSuccess) return const SizedBox.shrink();
              // ignore: unused_local_variable
              final setting = state.setting;
              return Column(
                children: [
                  SizedBox(height: AppSpacing.xl),
                  SettingCard(
                    title: l10n.settingsSectionGeneral, 
                    options: [
                      SettingItem(
                        title: l10n.settingsTheme,
                        description: l10n.settingsThemeDescription,
                        icon: Icons.light_mode_outlined,
                        onClick: () => selectThemeDialog(context, setting)
                      ),
                      SizedBox(height: AppSpacing.xs),
                      SettingItem(
                        title: l10n.settingsLanguage,
                        description: l10n.settingsLanguageDescription,
                        icon: Icons.language_outlined,
                        onClick: () => selectLangDialog(context, setting)
                      ),
                    ]
                  ),
                  SizedBox(height: AppSpacing.xl),
                  SettingCard(
                    title: l10n.settingsSectionPreference, 
                    options: [
                      SettingItem(
                        title: l10n.settingsWindUnit,
                        description: l10n.settingsWindUnitDescription,
                        icon: Icons.air_outlined,
                        onClick: () => selectWindUnitDialog(context, setting)
                      ),
                      SizedBox(height: AppSpacing.xs),
                      SettingItem(
                        title: l10n.settingsTemperatureUnit,
                        description: l10n.settingsTemperatureUnitDescription,
                        icon: Icons.thermostat_outlined,
                        onClick: () => selectHeatUnitDialog(context, setting)
                      ),
                    ]
                  ),
                  SizedBox(height: AppSpacing.xl),
                  SettingCard(
                    title: l10n.settingsSectionAbout, 
                    options: [
                      SettingItem(
                        title: l10n.settingsShare,
                        description: l10n.settingsShareDescription,
                        icon: Icons.share, 
                        onClick: () {}
                      ),
                      SizedBox(height: AppSpacing.xs),
                      SettingItem(
                        title: l10n.settingsLicenses,
                        icon: Icons.info_outline_rounded,
                        onClick: () => _showLicence(context, state.appVersion)
                      ),
                      SizedBox(height: AppSpacing.xs),
                      SettingItem(
                        title: l10n.settingsAppVersion(state.appVersion.isEmpty ? '—' : state.appVersion),
                        icon: Icons.android,
                        onClick: null
                      ),
                    ]
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const CreatorCard(),
                  SizedBox(height: AppSpacing.xxl),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showLicence(BuildContext context, String version) {
    final l10n = AppLocalisation.of(context)!;
    showLicensePage(
      context: context,
      applicationName: l10n.appTitle,
      applicationVersion: version,
      applicationIcon: Image.asset(
        'assets/images/logo/ic_launcher.png',
        height: 70,
        width: 70,
      ),
      applicationLegalese: l10n.settingsCopyright
    );
  }
}
