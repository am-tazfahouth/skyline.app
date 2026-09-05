# Settings Back-to-App — Design Spec

**Date:** 2026-08-11
**Feature:** Make the system back button return to the app after opening location / app settings from the GPS-error SnackBar
**Status:** Approved

---

## 1. Overview

When a GPS error occurs (service disabled or permission permanently denied), the app shows a
SnackBar whose action opens the relevant system settings page. On Android, both libraries used
for that redirection launch the settings intent with `FLAG_ACTIVITY_NEW_TASK` combined with
`FLAG_ACTIVITY_NO_HISTORY` and `FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS` (no back-stack-clearing
flags):

- `geolocator_android` `openLocationSettings` → `Utils.java:14-16, 31-33`
- `permission_handler_android` `openAppSettings` → `AppSettingsManager.java:28-30`

If the Settings app is **already running** in its own task (e.g. the user has a separate Settings
window open), `FLAG_ACTIVITY_NEW_TASK` alone reuses that existing task and pushes the target
settings page onto its back stack. `NO_HISTORY`/`EXCLUDE_FROM_RECENTS` only affect the launched
page's presence in recents — they do not evict the stale page already beneath it in the task.
Pressing the system back button therefore returns to the previously-open settings page instead of
the app.

This defect affects both GPS-error flows:

1. **Location service disabled** → SnackBar "Enable" → `Geolocator.openLocationSettings()`.
2. **Permission permanently denied** → SnackBar "Settings" → `permission_handler.openAppSettings()`.

The fix launches the settings activities with
`FLAG_ACTIVITY_NEW_TASK | FLAG_ACTIVITY_CLEAR_TASK | FLAG_ACTIVITY_RESET_TASK_IF_NEEDED`, making
the settings page the root of its own task so the back button closes it and returns to the app.
Neither geolocator nor permission_handler exposes intent flags, so a small native `MethodChannel`
is added in `MainActivity.kt`. iOS behavior is unchanged (no back stack in Settings).

---

## 2. Problem Details

`lib/features/location/presentation/blocs/location_bloc.dart` redirects to system settings from
the SnackBar actions defined in
`lib/features/location/presentation/utils/gps_error_feedback.dart`:

- `gpsDisabled` → `OpenLocationSettingsEvent` → `repository.openLocationSettings()`
  → `LocationPermissionSource.openLocationSettings()` → `Geolocator.openLocationSettings()`.
- `gpsPermissionPermanentlyDenied` → `OpenAppSettingsEvent` → `repository.openAppSettings()`
  → `LocationPermissionSource.openAppSettings()` → `ph.openAppSettings()`.

`lib/features/location/data/sources/location_permission_source.dart` is a thin adapter over the
two packages; neither package lets the caller set intent flags.

Android task semantics: with `FLAG_ACTIVITY_NEW_TASK` and no task-clearing flag, the system looks
for an existing task whose affinity matches the Settings app. When one exists (Settings already
open), the new activity is added to that task's existing back stack; `NO_HISTORY`/
`EXCLUDE_FROM_RECENTS` do not remove the page already beneath it. Back then pops the stack within
Settings instead of returning to the app.

---

## 3. Approach

Add a single native `MethodChannel` (name `sky_line/platform`) registered from
`MainActivity.configureFlutterEngine`. The channel exposes:

- `openLocationSettings` → `Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)`.
- `openAppSettings` → `Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, data: package Uri)`.

Both intents get the combined flags and are started from the activity; unknown methods answer
`result.notImplemented()`.

On the Dart side, `LocationPermissionSource` keeps its current API but, **on Android only**,
delegates the two settings-open methods to the channel and falls back to geolocator /
permission_handler when the channel is unavailable (`MissingPluginException`) or on non-Android
platforms.

The BLoC state machine (`LocationWaitingForSettings` + resume re-detection) is untouched and
keeps working: back now returns to the app, the app resumes, and detection is retried.

---

## 4. Architecture & Component Changes

### 4.1 `android/app/src/main/kotlin/com/example/sky_line/MainActivity.kt`

`MainActivity` gains a channel handler:

```kotlin
override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sky_line/platform")
        .setMethodCallHandler { call, result ->
            when (call.method) {
                "openLocationSettings" -> {
                    result.success(openSettings(Settings.ACTION_LOCATION_SOURCE_SETTINGS))
                }
                "openAppSettings" -> {
                    result.success(
                        openSettings(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.parse("package:$packageName"),
                        ),
                    )
                }
                else -> result.notImplemented()
            }
        }
}

private fun openSettings(action: String, data: Uri? = null): Boolean {
    return try {
        val intent = if (data != null) Intent(action, data) else Intent(action)
        intent.addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TASK or
                Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED,
        )
        startActivity(intent)
        true
    } catch (e: Exception) {
        false
    }
}
```

`openSettings` never throws: an unresolvable intent returns `false` to the Dart side instead of
leaving the `MethodChannel` call unanswered (which would hang the BLoC in
`LocationWaitingForSettings` forever).

### 4.2 `lib/features/location/data/sources/location_permission_source.dart`

```dart
static const MethodChannel _settingsChannel = MethodChannel('sky_line/platform');

@visibleForTesting
static bool Function() isAndroidPlatform = () => Platform.isAndroid;

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
```

Imports added: `dart:io`, `package:flutter/foundation.dart` (for `@visibleForTesting`) and
`package:flutter/services.dart` (for `MethodChannel` / `MissingPluginException`). No repository,
domain, or presentation changes.

---

## 5. Data Flow

1. User taps the SnackBar action (`OpenLocationSettingsEvent` / `OpenAppSettingsEvent`).
2. `LocationBloc` emits `LocationWaitingForSettings` and calls `repository.openLocationSettings()`
   (or `openAppSettings()`).
3. `LocationPermissionSource` invokes the native channel on Android.
4. `MainActivity` starts the settings activity as the root of a fresh task; back now closes it.
5. App resumes → existing `didChangeAppLifecycleState` logic dispatches
   `DetectCurrentLocationEvent` and the GPS flow completes.
6. On iOS (or if the channel is missing) the plugin fallback is used, unchanged behavior.

---

## 6. Error Handling

- `MissingPluginException` on the channel (missing native handler, unusual host) → fall back to
  geolocator / permission_handler.
- No other exception path changes; `_onOpenLocationSettings` / `_onOpenAppSettings` already log
  failures.

---

## 7. Testing

### 7.1 Unit tests (Dart)

New file `test/features/location/data/sources/location_permission_source_test.dart`:

- Android + channel available: `openLocationSettings` invokes method `openLocationSettings` on
  `sky_line/platform` and returns the mocked result (`true`); same for `openAppSettings`.
- Android + channel missing (no mock handler): the call falls through and rethrows the plugin
  `MissingPluginException` (proving the fallback branch is reached).
- `tearDown` restores `LocationPermissionSource.isAndroidPlatform = () => Platform.isAndroid` and
  clears the mock handler so state does not leak across tests.

The native Kotlin behavior is not covered by this repo's test infrastructure (no Android
instrumentation setup); it is verified manually on an Android device/emulator and by
`flutter build apk --debug`.

### 7.2 Manual verification

1. With the Settings app open beforehand, trigger "location service disabled" → SnackBar
   "Enable" → back from the location settings page returns to the app and detection is retried.
2. Same for the permanently-denied flow → back returns to the app.

---

## 8. Verification Commands

| Command | Purpose |
|---|---|
| `flutter test` | Full Dart test suite (regression + new source tests) |
| `flutter analyze` | Zero warnings / infos |
| `flutter build apk --debug` | Compiles the modified Kotlin |

---

## 9. Out of Scope

- iOS behavior: unchanged (`Geolocator.openLocationSettings()` opens the app settings page with no
  back-stack problem).
- Changing the SnackBar action labels or the `LocationWaitingForSettings` / resume-retry logic.
