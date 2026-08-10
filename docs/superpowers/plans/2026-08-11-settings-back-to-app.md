# Settings Back-to-App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Android system back button return to the app after opening location / app settings from the GPS-error SnackBar, by launching the settings activities as the root of a fresh task.

**Architecture:** A native `MethodChannel` (`sky_line/platform`) registered in `MainActivity.configureFlutterEngine` starts the settings intents with `FLAG_ACTIVITY_NEW_TASK | FLAG_ACTIVITY_CLEAR_TASK | FLAG_ACTIVITY_RESET_TASK_IF_NEEDED`. The Dart `LocationPermissionSource` delegates the two settings-open methods to that channel on Android only, falling back to geolocator / permission_handler when the channel is missing or on non-Android platforms. The existing `LocationWaitingForSettings` + resume-retry BLoC logic is untouched.

**Tech Stack:** Flutter 3.x, Kotlin (Android embedding), geolocator 14.x, permission_handler (android 12.1.0/14.0.0), flutter_test.

## Global Constraints

- All code, comments and commits in English.
- `flutter analyze` must report zero warnings/infos; `flutter test` must be green after every task.
- Channel name is exactly `sky_line/platform`; method names exactly `openLocationSettings` and `openAppSettings` (sync with both native and Dart sides).
- Android-only redirect: iOS keeps `Geolocator.openLocationSettings()` / `permission_handler.openAppSettings()` unchanged.
- No changes to `LocationBloc`, `LocationState` (`LocationWaitingForSettings`), repositories, domain, or presentation.
- Reference spec: `docs/superpowers/specs/2026-08-11-settings-back-to-app-design.md`.

---

### Task 1: Dart side — channel-backed `LocationPermissionSource` (TDD)

**Files:**
- Modify: `lib/features/location/data/sources/location_permission_source.dart`
- Create: `test/features/location/data/sources/location_permission_source_test.dart`

**Interfaces:**
- Consumes: existing `LocationPermissionSource` public API (unchanged call sites).
- Produces:
  - `LocationPermissionSource.openLocationSettings()` → `Future<bool>` — Android: invokes channel method `openLocationSettings`; on `MissingPluginException` falls back to `Geolocator.openLocationSettings()`.
  - `LocationPermissionSource.openAppSettings()` → `Future<bool>` — Android: invokes channel method `openAppSettings`; on `MissingPluginException` falls back to `ph.openAppSettings()`.
  - `static bool Function() isAndroidPlatform` (test seam, default `() => Platform.isAndroid`), annotated `@visibleForTesting`.
- Test: `test/features/location/data/sources/location_permission_source_test.dart` (new file).

- [ ] **Step 1: Write the failing test**

Create `test/features/location/data/sources/location_permission_source_test.dart`:

```dart
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/features/location/data/sources/location_permission_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('sky_line/platform');

  void mockChannel(MethodCall? Function(MethodCall call)? handler) {
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
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/location/data/sources/location_permission_source_test.dart`
Expected: FAIL — the channel is never invoked (current `openLocationSettings` calls `Geolocator.openLocationSettings()`, which throws `MissingPluginException` in tests, so the `expect(result, isTrue)` assertions fail).

- [ ] **Step 3: Implement the channel-backed source**

Replace the body of `lib/features/location/data/sources/location_permission_source.dart` with:

```dart
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
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/location/data/sources/location_permission_source_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: Static analysis + full regression + commit**

Run: `flutter analyze`
Expected: No issues found.

Run: `flutter test`
Expected: All tests pass (existing suite + the 6 new ones).

```bash
git add lib/features/location/data/sources/location_permission_source.dart test/features/location/data/sources/location_permission_source_test.dart
git commit -m "feat(location): open system settings via native channel on Android"
```

---

### Task 2: Native side — `MainActivity` MethodChannel + build verification

**Files:**
- Modify: `android/app/src/main/kotlin/com/example/sky_line/MainActivity.kt`

**Interfaces:**
- Consumes: channel methods produced in Task 1 — `openLocationSettings` and `openAppSettings` on channel `sky_line/platform`, both returning `success(true)`; any other method answers `result.notImplemented()`.
- Produces: native handling that starts `Settings.ACTION_LOCATION_SOURCE_SETTINGS` (no data) and `Settings.ACTION_APPLICATION_DETAILS_SETTINGS` (data `package:$packageName`), both with flags `NEW_TASK | CLEAR_TASK | RESET_TASK_IF_NEEDED`.

- [ ] **Step 1: Register the channel in `MainActivity`**

Replace the whole content of `android/app/src/main/kotlin/com/example/sky_line/MainActivity.kt` with:

```kotlin
package com.example.sky_line

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sky_line/platform")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openLocationSettings" -> {
                        openSettings(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
                        result.success(true)
                    }
                    "openAppSettings" -> {
                        openSettings(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.parse("package:$packageName"),
                        )
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun openSettings(action: String, data: Uri? = null) {
        val intent = if (data != null) Intent(action, data) else Intent(action)
        intent.addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TASK or
                Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED,
        )
        startActivity(intent)
    }
}
```

- [ ] **Step 2: Compile the Android build to verify the Kotlin**

Run: `flutter build apk --debug`
Expected: Build succeeds (Kotlin compiles). Note: requires the Android SDK; if unavailable on the machine, this step blocks and the manual verification in Step 4 cannot run.

- [ ] **Step 3: Full regression**

Run: `flutter test`
Expected: All tests pass.

Run: `flutter analyze`
Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add android/app/src/main/kotlin/com/example/sky_line/MainActivity.kt
git commit -m "feat(location): open settings in fresh task on Android"
```

---

### Task 3: Manual device verification

**Files:** none.

- [ ] **Step 1: Verify the disabled-location-service flow**

Run: `flutter run` on an Android device/emulator with the Settings app **already open** beforehand.
1. Trigger the "location service disabled" GPS error so the SnackBar "Enable" action appears.
2. Tap "Enable" → the location settings page opens.
3. Press the system back button → the app must be foregrounded (not a stale Settings page).
4. The app resumes and re-runs location detection (existing `LocationWaitingForSettings` logic).

- [ ] **Step 2: Verify the permanently-denied flow**

On a device/emulator, deny location permission permanently so the "Settings" SnackBar action appears.
1. Tap "Settings" → the app details settings page opens.
2. Press the system back button → the app must be foregrounded.
3. Re-enable the permission and confirm detection succeeds.
