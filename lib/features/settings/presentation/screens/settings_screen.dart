import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/errors/app_error.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_state.dart';
import 'package:sky_line/features/settings/presentation/widgets/select_heat_unit_dialog.dart';
import 'package:sky_line/features/settings/presentation/widgets/select_lang_dialog.dart';
import 'package:sky_line/features/settings/presentation/widgets/select_theme_dialog.dart';
import 'package:sky_line/features/settings/presentation/widgets/select_wind_unit_dialog.dart';
import 'package:sky_line/features/settings/presentation/widgets/setting_card.dart';
import 'package:sky_line/features/settings/presentation/widgets/setting_item.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';

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
        listener: (context, state) {
          if (state is SettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppError.getUserErrorMessage(state.errorCode)),
              ),
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
                  const SizedBox(height: 20),
                  SettingCard(
                    title: "General", 
                    options: [
                      SettingItem(
                        title: 'Theme',
                        description: 'Choose the theme of the application',
                        icon: Icons.light_mode_outlined,
                        onClick: () => selectThemeDialog(context, setting)
                      ),
                      SizedBox(height: 5),
                      SettingItem(
                        title: 'Language',
                        description: 'Choose the language of the application',
                        icon: Icons.language_outlined,
                        onClick: () => selectLangDialog(context, setting)
                      ),
                    ]
                  ),
                  const SizedBox(height: 20),
                  SettingCard(
                    title: "Preference", 
                    options: [
                      SettingItem(
                        title: 'Wind',
                        description: 'Choose the unit of measurement for wind',
                        icon: Icons.air_outlined,
                        onClick: () => selectWindUnitDialog(context, setting)
                      ),
                      SizedBox(height: 5),
                      SettingItem(
                        title: 'Temperature',
                        description: 'Choose the unit of measurement of the temperature',
                        icon: Icons.thermostat_outlined,
                        onClick: () => selectHeatUnitDialog(context, setting)
                      ),
                    ]
                  ),
                  const SizedBox(height: 20),
                  SettingCard(
                    title: "About", 
                    options: [
                      SettingItem(
                        title: 'Share',
                        description: 'Share with your friend',
                        icon: Icons.share, 
                        onClick: () {}
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      SettingItem(
                        title: 'Licenses',
                        icon: Icons.info_outline_rounded,
                        onClick: () => _showLicence(context, "0.6.4")
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      SettingItem(
                        title: "App version: 0.6.4",
                        icon: Icons.android,
                        onClick: null
                      ),
                    ]
                  ),
                  const SizedBox(height: 100),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showLicence(BuildContext context, String version) {
    showLicensePage(
      context: context,
      applicationName: 'Notly',
      applicationVersion: version,
      applicationIcon: Image.asset(
        'assets/images/logo/ic_launcher.png',
        height: 70,
        width: 70,
      ),
      applicationLegalese: "© 2026 TzfLab"
    );
  }
}
