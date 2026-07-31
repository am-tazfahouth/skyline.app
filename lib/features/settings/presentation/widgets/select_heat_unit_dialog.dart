import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/enums/setting_heat_unit.dart';
import 'package:sky_line/core/utils/format_text.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_event.dart';

// Show dialog to select the theme
void selectHeatUnitDialog(BuildContext context, SettingEntity setting) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Temperature unit'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 300
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: RadioGroup<SettingHeatUnit>(
              groupValue: setting.heatUnit,
              onChanged: (value) {
                setting = setting.copyWith(heatUnit: value) ;
                context.read<SettingsBloc>().add(UpdateSettingsEvent(setting: setting));
                Navigator.pop(context);
              },
              child: ListBody(
                children: SettingHeatUnit.values.map((unit) {
                  return RadioListTile<SettingHeatUnit>(
                    title: Text(capitalize(unit.name)),
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