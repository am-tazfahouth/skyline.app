# System Language First-Launch — Design Spec

**Date:** 2026-09-04
**Feature:** settings / language
**Status:** Approved

## Problem

On first launch of the application, the default language is `en` (`SettingEntity.defaults`), regardless of the system/device language. The user therefore has to manually change the language in the settings, even when the device language is already supported by the application.

Languages supported by the application: `en`, `fr`, `es`, `ar`.

## Goal

On **first launch only** (no persisted setting in the database), the application must automatically set its language to that of the system when supported. If the system language does not match any supported language, the application falls back to `en`.

The language chosen this way becomes a default manual setting, modifiable afterwards in the settings (it must not re-apply the system setting on every launch).

## Chosen Approach

Approach **A (Data layer) + testable injection**. No change in the presentation layer, the BLoC, `main.dart` nor the injection container.

The existing flow stays unchanged:
- `main.dart` reads `setting.lang` via `SettingsBloc` / `SettingsLoadSuccess`.
- `SettingRepositoryImpl.loadSettings()` is the entry point of the first launch: it returns `SettingEntity.defaults` when nothing exists in the database.

## Design

### 1. `lib/core/utils/platform_utils.dart` — system language detection

Add a static method that resolves the supported system language with an `en` fallback:

```dart
// Resolve supported system language, fallback to en
static SettingLang getSystemLang() {
  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  return getLangFromString(locale.languageCode);
}
```

- Reuses `getLangFromString(String)` from `lib/core/enums/setting_lang.dart`, which already maps `en/fr/es/ar` with an `en` fallback.
- Importing `setting_lang.dart`: no cycle (this file does not import `platform_utils`).
- Consistent with the existing `is24HourFormat()` pattern which reads `platformDispatcher`.

### 2. `lib/features/settings/data/repositories/setting_repository_impl.dart` — injection + first launch

Add an injectable `systemLangProvider`, with a dedicated named constructor for tests so the existing injection container stays untouched:

```dart
class SettingRepositoryImpl implements SettingRepository {
  final DbHelper _dbHelper;
  final SettingLang Function() systemLangProvider;

  SettingRepositoryImpl(this._dbHelper)
      : systemLangProvider = PlatformUtils.getSystemLang;

  @visibleForTesting
  SettingRepositoryImpl.withSystemLang(
    this._dbHelper,
    this.systemLangProvider,
  );

  @override
  Future<SettingEntity> loadSettings() async {
    final cached = _dbHelper.loadSettings();
    if (cached == null) {
      final lang = systemLangProvider();
      final setting = SettingEntity.defaults.copyWith(lang: lang);
      saveSettings(setting);
      return setting;
    }
    return SettingMapper.toEntity(SettingMapper.fromCacheEntity(cached));
  }

  // saveSettings unchanged
}
```

Behavior:
- If `cached == null` (first launch): system language resolved, setting persisted (`saveSettings`), value returned.
- If a setting exists: language kept as-is (no overwrite by the system).

## Data

- The auto-detected language is persisted immediately via `saveSettings(setting)`. It thus becomes the default manual setting.
- No new entity, no new ObjectBox field, no migration required.

## Error Handling

- `loadSettings()` does not throw for detection: the `en` fallback always guarantees a valid language.
- `saveSettings` keeps its existing synchronous behavior (`DbHelper`).
- The BLoC and the UI stay unchanged: no new error state.

## Tests

### `test/core/utils/platform_utils_test.dart` (to create)

Verify detection and mapping via `tester.platformDispatcher.locale`:
- locale `fr` → `SettingLang.fr`
- locale `ar` → `SettingLang.ar`
- unsupported locale (`de`, `zh`) → `SettingLang.en` (fallback)

### `test/features/settings/data/repositories/setting_repository_impl_test.dart` (additions)

Use `SettingRepositoryImpl.withSystemLang` with a mocktail `DbHelper`:
- `loadSettings()` returns `null`, provider `fr` → `SettingEntity.lang == SettingLang.fr` and `saveSettings` called.
- `loadSettings()` returns `null`, provider `ar` → `SettingLang.ar`.
- `loadSettings()` returns `null`, unsupported provider (`de`) → `SettingLang.en` (fallback).
- `loadSettings()` returns an existing setting (lang `es`) → language kept `es`, `saveSettings` not called.

## Factory Verification

- `flutter analyze` : 0 warning, 0 info.
- `flutter test` : entire suite green.
- `flutter test test/core/utils/platform_utils_test.dart test/features/settings/data/repositories/setting_repository_impl_test.dart`

## Out of Scope (YAGNI)

- Do not re-apply the system language on every launch.
- No dedicated first-launch language selection screen.
- No change to the injection container (the default constructor remains `SettingRepositoryImpl(this._dbHelper)`).