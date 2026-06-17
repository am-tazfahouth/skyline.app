import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sky_line/core/enums/setting_theme.dart';

class PlatformUtils {
  static const smallScreenThreshold = 350;

  // Check internet connectivity
  static Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Get time format of the devices
  static bool is24HourFormat() {
    return WidgetsBinding.instance.platformDispatcher.alwaysUse24HourFormat;
  }  

  // Get screen orientation
  static Orientation getAppOrientation(){
    FlutterView view = PlatformDispatcher.instance.views.first;
    final w = view.physicalSize.width / view.devicePixelRatio;
    final h = view.physicalSize.height / view.devicePixelRatio;
    return w > h ?
      Orientation.landscape :
      Orientation.portrait
    ;
  }

  // Get status bar height
  double getStatusBarHeight() {
    final FlutterView view = PlatformDispatcher.instance.views.first;
    return view.viewPadding.top / view.devicePixelRatio;
  }

  // Get screen height
  static double getScreenHeight(){
    FlutterView view = PlatformDispatcher.instance.views.first;
    return view.physicalSize.height / view.devicePixelRatio;
  }

  // Get keyboard heigth
  static double getKeyboardHeight(){
    final FlutterView view = PlatformDispatcher.instance.views.first;
    return view.viewInsets.bottom / view.devicePixelRatio;
  }

  // Get a systeme ui overlay
  static SystemUiOverlayStyle getSystemUiStyle( SettingTheme theme, BuildContext context) {
    final brightness = theme == SettingTheme.system
      ? Theme.brightnessOf(context)
      : theme == SettingTheme.light
          ? Brightness.light
          : Brightness.dark
      ;

    return SystemUiOverlayStyle(
      // Status bar
      statusBarColor: Colors.transparent,
      systemStatusBarContrastEnforced: false,
      statusBarIconBrightness: brightness == Brightness.light 
        ? Brightness.dark 
        : Brightness.light
      ,
      // Navigation bar
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: brightness == Brightness.light 
        ? Brightness.dark 
        : Brightness.light
      ,
    );
  }

  // Get android navigation bar height
  double getNavigationBarHeight() {
    final FlutterView view = PlatformDispatcher.instance.views.first;
    return view.viewPadding.bottom / view.devicePixelRatio;
  }
}
