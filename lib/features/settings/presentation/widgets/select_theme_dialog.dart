import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/enums/setting_theme.dart';
import 'package:sky_line/core/utils/format_text.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_event.dart';

// Show dialog to select the theme
void selectThemeDialog(BuildContext context, SettingEntity setting) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Theme'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 300
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: RadioGroup<SettingTheme>(
              groupValue: setting.theme,
              onChanged: (value) {
                setting = setting.copyWith(theme: value) ;
                context.read<SettingsBloc>().add(UpdateSettingsEvent(setting: setting));
                Navigator.pop(context);
              },
              child: ListBody(
                children: SettingTheme.values.map((theme) {
                  return RadioListTile<SettingTheme>(
                    title: Text(capitalize(theme.name)),
                    value: theme,
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