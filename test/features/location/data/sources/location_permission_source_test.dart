import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:sky_line/features/location/data/sources/location_permission_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('sky_line/platform');

  void mockChannel(Future<Object?>? Function(MethodCall call)? handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }

  setUp(() {
    LocationPermissionSource.isAndroidPlatform = () => true;
    LocationPermissionSource.geolocatorOpenLocationSettings = () async => true;
    LocationPermissionSource.permissionHandlerOpenAppSettings = () async => true;
  });

  tearDown(() {
    LocationPermissionSource.isAndroidPlatform = () => Platform.isAndroid;
    LocationPermissionSource.geolocatorOpenLocationSettings = Geolocator.openLocationSettings;
    LocationPermissionSource.permissionHandlerOpenAppSettings = ph.openAppSettings;
    mockChannel(null);
  });

  test('openLocationSettings invokes the native channel on Android and returns true',
      () async {
    final calls = <String>[];
    mockChannel((call) async {
      calls.add(call.method);
      return true;
    });

    final result = await LocationPermissionSource().openLocationSettings();

    expect(result, isTrue);
    expect(calls, ['openLocationSettings']);
  });

  test('openLocationSettings returns false when the channel reports false', () async {
    mockChannel((call) async => false);

    final result = await LocationPermissionSource().openLocationSettings();

    expect(result, isFalse);
  });

  test('openLocationSettings falls back to the geolocator plugin when the channel throws',
      () async {
    mockChannel((call) async => throw MissingPluginException());
    var fallbackCalled = false;
    LocationPermissionSource.geolocatorOpenLocationSettings = () async {
      fallbackCalled = true;
      return true;
    };

    final result = await LocationPermissionSource().openLocationSettings();

    expect(result, isTrue);
    expect(fallbackCalled, isTrue);
  });

  test('openAppSettings invokes the native channel on Android and returns true', () async {
    final calls = <String>[];
    mockChannel((call) async {
      calls.add(call.method);
      return true;
    });

    final result = await LocationPermissionSource().openAppSettings();

    expect(result, isTrue);
    expect(calls, ['openAppSettings']);
  });

  test('openAppSettings returns false when the channel reports false', () async {
    mockChannel((call) async => false);

    final result = await LocationPermissionSource().openAppSettings();

    expect(result, isFalse);
  });

  test('openAppSettings falls back to the permission_handler plugin when the channel throws',
      () async {
    mockChannel((call) async => throw MissingPluginException());
    var fallbackCalled = false;
    LocationPermissionSource.permissionHandlerOpenAppSettings = () async {
      fallbackCalled = true;
      return true;
    };

    final result = await LocationPermissionSource().openAppSettings();

    expect(result, isTrue);
    expect(fallbackCalled, isTrue);
  });

  test('openLocationSettings skips the channel on non-Android platforms', () async {
    LocationPermissionSource.isAndroidPlatform = () => false;
    var fallbackCalled = false;
    LocationPermissionSource.geolocatorOpenLocationSettings = () async {
      fallbackCalled = true;
      return true;
    };
    final calls = <String>[];
    mockChannel((call) async {
      calls.add(call.method);
      return true;
    });

    final result = await LocationPermissionSource().openLocationSettings();

    expect(result, isTrue);
    expect(calls, isEmpty);
    expect(fallbackCalled, isTrue);
  });

  test('openAppSettings skips the channel on non-Android platforms', () async {
    LocationPermissionSource.isAndroidPlatform = () => false;
    var fallbackCalled = false;
    LocationPermissionSource.permissionHandlerOpenAppSettings = () async {
      fallbackCalled = true;
      return true;
    };
    final calls = <String>[];
    mockChannel((call) async {
      calls.add(call.method);
      return true;
    });

    final result = await LocationPermissionSource().openAppSettings();

    expect(result, isTrue);
    expect(calls, isEmpty);
    expect(fallbackCalled, isTrue);
  });
}
