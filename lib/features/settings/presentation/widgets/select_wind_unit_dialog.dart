import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/enums/setting_wind_unit.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_event.dart';

// Show dialog to select the theme
void selectWindUnitDialog(BuildContext context, SettingEntity setting) {
  final l10n = AppLocalisation.of(context)!;
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(l10n.settingsWindUnit),
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 300
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: RadioGroup<SettingWindUnit>(
              groupValue: setting.windUnit,
              onChanged: (value) {
                setting = setting.copyWith(windUnit: value) ;
                context.read<SettingsBloc>().add(UpdateSettingsEvent(setting: setting));
                Navigator.pop(context);
              },
              child: ListBody(
                children: SettingWindUnit.values.map((unit) {
                  return RadioListTile<SettingWindUnit>(
                    title: Text(
                      switch (unit) {
                        SettingWindUnit.ms => l10n.settingsWindUnitMs,
                        SettingWindUnit.kmh => l10n.settingsWindUnitKmh,
                      },
                    ),
                    value: unit,
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      );
    },
  );
}