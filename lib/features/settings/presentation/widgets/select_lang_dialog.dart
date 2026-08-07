import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/enums/setting_lang.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_event.dart';

//Show dialog to choose app language
void selectLangDialog(BuildContext context, SettingEntity setting){
  final l10n = AppLocalisation.of(context)!;
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(l10n.settingsLanguage),
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 300
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: RadioGroup<SettingLang>(
              groupValue: setting.lang,
              onChanged: (value) {
                setting = setting.copyWith(lang: value);
                context.read<SettingsBloc>().add(UpdateSettingsEvent(setting: setting));
                Navigator.pop(context);
              },
              child: ListBody(
                children: SettingLang.values.map((lang){
                  return RadioListTile<SettingLang>(
                    title: Text(
                      switch (lang) {
                        SettingLang.en => l10n.settingsLangEn,
                        SettingLang.fr => l10n.settingsLangFr,
                        SettingLang.es => l10n.settingsLangEs,
                        SettingLang.ar => l10n.settingsLangAr,
                      },
                    ),
                    value: lang,
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
