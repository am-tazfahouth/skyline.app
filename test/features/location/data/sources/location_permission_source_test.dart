import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });

  tearDown(() {
    LocationPermissionSource.isAndroidPlatform = () => Platform.isAndroid;
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

  test('openLocationSettings falls back to the geolocator plugin when the channel is missing',
      () async {
    expect(
      () => LocationPermissionSource().openLocationSettings(),
      throwsA(isA<MissingPluginException>()),
    );
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

  test('openAppSettings falls back to the permission_handler plugin when the channel is missing',
      () async {
    expect(
      () => LocationPermissionSource().openAppSettings(),
      throwsA(isA<MissingPluginException>()),
    );
  });

  test('openLocationSettings skips the channel on non-Android platforms', () async {
    LocationPermissionSource.isAndroidPlatform = () => false;
    final calls = <String>[];
    mockChannel((call) async {
      calls.add(call.method);
      return true;
    });

    expect(
      () => LocationPermissionSource().openLocationSettings(),
      throwsA(isA<MissingPluginException>()),
    );
    expect(calls, isEmpty);
  });
}
