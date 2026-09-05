# GitHub Releases APK Delivery — Design Spec

**Date:** 2026-09-05
**Feature:** delivery / CI-CD
**Status:** Approved

## Problem

The application has no delivery system: there is no installable APK available outside of the local development environment, and the Android release build is currently signed with the debug keys (`build.gradle.kts` line 37). Anyone who wants to install and test SkyLine on an Android device must build it themselves.

## Goal

Deliver signed APKs directly from GitHub, downloadable from the **Releases** page, via the existing CI. A dedicated keystore (never committed) signs the release builds, stored as GitHub secrets.

## Chosen Approach

- **Delivery channel:** GitHub Releases (an APK is a release asset).
- **Trigger:** pushing a versioned tag (`v*`) triggers a fully gated pipeline (analyze + test, then build + publish). No release on every push.
- **APK format:** split per ABI (`--split-per-abi`) — three APKs (`arm64-v8a`, `armeabi-v7a`, `x86_64`).
- **Signing:** dedicated keystore. Local dev reads `android/key.properties`; CI decodes the `ANDROID_KEYSTORE_BASE64` secret into the same file.
- **Identity:** `namespace` and `applicationId` move from the Flutter placeholder `com.example.sky_line` to `app.skyline.dev`. `MainActivity.kt` is relocated to the `app.skyline.dev` package so the manifest's `.MainActivity` still resolves. The iOS bundle identifiers (`com.example.skyLine`) and the Linux `APPLICATION_ID` (`com.example.sky_line`) are aligned to `app.skyline.dev` too — the placeholder identity is removed on every platform in the same change.

## Design

### 1. Version & identity

- `pubspec.yaml`: `version: 0.3.1` → `1.0.0+1` so `flutter.versionCode`/`flutter.versionName` match the first release tag `v1.0.0` (versionName `1.0.0`, versionCode `1`). Note: with `--split-per-abi`, Flutter encodes the ABI into `versionCode` (base 1000 per ABI → arm64 `2001`, armv7 `1001`, x64 `4001`); this is expected Flutter behavior, not a bug.
- `android/app/build.gradle.kts`: `namespace = "app.skyline.dev"`, `applicationId = "app.skyline.dev"`, TODO comment removed.

### 2. Release signing — `android/app/build.gradle.kts`

```kotlin
import java.util.Properties

// ...
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    // namespace / applicationId ...
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }
    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}
```

- Local / manual build with no keys keeps the debug fallback so `flutter run --release` keeps working.
- CI always provides the keys, so the release build is always signed with the real keystore.

### 3. Keystore lifecycle

- **Generation (local, one-time):**
  ```
  keytool -genkey -v -keystore android/app/sky_line_upload.jks -alias skyline -keyalg RSA -keysize 2048 -validity 10000
  ```
- **Local configuration:** `android/key.properties` (gitignored):
  ```
  storePassword=<pwd>
  keyPassword=<pwd>
  keyAlias=skyline
  storeFile=sky_line_upload.jks   # relative to android/app
  ```
- **GitHub secrets (4):** `ANDROID_KEYSTORE_BASE64` (`base64 -w0 android/app/sky_line_upload.jks`), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.
- Rules: the keystore must never be committed; it must be backed up externally (losing it makes upgrades impossible); `key.properties` output never logged.

### 4. Workflow `.github/workflows/ci.yml`

```yaml
on:
  push:
    branches: [main]
    tags: ['v*']
  pull_request:
    branches: [main]
```

Jobs:

- **`analyze-and-test`** (existing, unchanged): runs on push to `main`, on tags and on PRs → `flutter analyze --fatal-infos` + `flutter test`. The tag commit is therefore verified before delivery.
- **`build-release`** — `needs: analyze-and-test`, `if: startsWith(github.ref, 'refs/tags/v')`:
  1. Checkout, `subosito/flutter-action` (3.35.0, cache), `flutter pub get`.
  2. Guard: fail with a clear message if `ANDROID_KEYSTORE_BASE64` is missing.
  3. Decode the secret into `android/app/sky_line_upload.jks` and write `android/key.properties` from the 4 secrets in a masked `run` step.
  4. `flutter build apk --release --split-per-abi` → three APKs in `build/app/outputs/flutter-apk/`.
  5. `softprops/action-gh-release@v2` → release titled/tagged `v<ref_name>` with the three APKs as assets.

## Data

- No data change: pure delivery/build infrastructure.
- Version metadata lives in `pubspec.yaml` only (Gradle consumes it via the Flutter plugin).

## Error Handling

- Missing secrets → the build-release job fails early with an explicit message (never ships unsigned APKs).
- Analyze/test failure on the tag → the release job never runs (`needs`).
- Local build without keys → debug-signing fallback keeps development flows working.

## Tests

This is build infrastructure (`pubspec`, Gradle signing config, workflow YAML, docs). There is no Dart logic.

### Factory Verification

- `flutter analyze` : 0 warning, 0 info.
- `flutter test` : suite green.
- `flutter build apk --release --split-per-abi` locally (debug fallback) to validate the new Gradle configuration compiles.
- YAML validity of `.github/workflows/ci.yml`.
- Real end-to-end: user pushes `v1.0.0` once secrets are configured → a Release with three signed APKs is published.

## Out of Scope (YAGNI)

- No App Bundle / Play Store publishing.
- No universal "fat" APK (user chose split per ABI).
- No automatic release on every commit.
- No Play Store `applicationId`/signing concerns.