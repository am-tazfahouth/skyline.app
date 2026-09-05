import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/core/enums/setting_lang.dart';
import 'package:sky_line/core/utils/platform_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns fr when device locale is fr', () {
    TestWidgetsFlutterBinding.instance.platformDispatcher.localeTestValue =
        const Locale('fr', 'FR');
    expect(PlatformUtils.getSystemLang(), SettingLang.fr);
  });

  test('returns ar when device locale is ar', () {
    TestWidgetsFlutterBinding.instance.platformDispatcher.localeTestValue =
        const Locale('ar', 'SA');
    expect(PlatformUtils.getSystemLang(), SettingLang.ar);
  });

  test('returns es when device locale is es', () {
    TestWidgetsFlutterBinding.instance.platformDispatcher.localeTestValue =
        const Locale('es', 'ES');
    expect(PlatformUtils.getSystemLang(), SettingLang.es);
  });

  test('returns en when device locale is en', () {
    TestWidgetsFlutterBinding.instance.platformDispatcher.localeTestValue =
        const Locale('en', 'US');
    expect(PlatformUtils.getSystemLang(), SettingLang.en);
  });

  test('returns en (fallback) for unsupported locale', () {
    TestWidgetsFlutterBinding.instance.platformDispatcher.localeTestValue =
        const Locale('de', 'DE');
    expect(PlatformUtils.getSystemLang(), SettingLang.en);
  });

  test('returns en (fallback) for unsupported zh locale', () {
    TestWidgetsFlutterBinding.instance.platformDispatcher.localeTestValue =
        const Locale('zh', 'CN');
    expect(PlatformUtils.getSystemLang(), SettingLang.en);
  });
}
