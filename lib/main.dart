import 'package:flutter/material.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/enums/setting_theme.dart';
import 'package:sky_line/core/utils/platform_utils.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appTheme = AppTheme(Theme.of(context).textTheme);

    return AnnotatedRegion(
      value: PlatformUtils.getSystemUiStyle(SettingTheme.system, context),
      child: MaterialApp(
        title: 'SkiLine',
        home: Scaffold(),
        theme: appTheme.light(),
        darkTheme: appTheme.dark(),
        debugShowCheckedModeBanner: false,
        themeMode: SettingTheme.getThemeMode(SettingTheme.system),
      ), 
    );
  }
}