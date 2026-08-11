import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class LocationPermissionSource {
  static const MethodChannel _settingsChannel = MethodChannel('sky_line/platform');

  @visibleForTesting
  static bool Function() isAndroidPlatform = () => Platform.isAndroid;

  Future<ph.PermissionStatus> requestLocationPermission() {
    return ph.Permission.locationWhenInUse.request();
  }

  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  Future<Position> getCurrentPosition() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );
  }

  Future<bool> openLocationSettings() async {
    if (isAndroidPlatform()) {
      try {
        return await _settingsChannel.invokeMethod<bool>('openLocationSettings') ?? false;
      } on MissingPluginException {
        // Fall through to the plugin fallback below.
      }
    }
    return Geolocator.openLocationSettings();
  }

  Future<bool> openAppSettings() async {
    if (isAndroidPlatform()) {
      try {
        return await _settingsChannel.invokeMethod<bool>('openAppSettings') ?? false;
      } on MissingPluginException {
        // Fall through to the plugin fallback below.
      }
    }
    return ph.openAppSettings();
  }
}
