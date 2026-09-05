# System Language First-Launch — Implementation Plan

**Date:** 2026-09-04
**Feature:** settings
**Status:** Implemented

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** At first launch (no persisted settings), automatically set the app language to the device's system language when supported, falling back to `en`.

**Architecture:** Detection lives in `core` (`PlatformUtils.getSystemLang()`), and first-launch resolution + persistence happens in the Data layer (`SettingRepositoryImpl.loadSettings()` via an injected `systemLangProvider`). No presentation/BLoC/injection-container changes.

**Tech Stack:** Flutter/Dart, mocktail for tests, `WidgetsBinding.instance.platformDispatcher.locale` for system language.

## Global Constraints

- Code, variables, comments, and commits must be in English.
- All domain entities / models / events / states extend `Equatable` (no change needed here — `SettingEntity` already does).
- `flutter analyze` must report 0 warnings and 0 infos.
- `flutter test` must pass.
- Do NOT modify `main.dart`, `SettingsBloc`, `injection_container.dart`, or the `SettingEntity` defaults.
- Supported `SettingLang` values: `en`, `fr`, `es`, `ar` (fallback is `en`).
- The default constructor `SettingRepositoryImpl(this._dbHelper)` must remain working unchanged.

---

### Task 1: System language detection in PlatformUtils

**Files:**
- Modify: `lib/core/utils/platform_utils.dart`
- Test: `test/core/utils/platform_utils_test.dart` (create)

**Interfaces:**
- Produces: `static SettingLang PlatformUtils.getSystemLang()` — returns the device system language mapped to `SettingLang`, with fallback to `SettingLang.en` for any unsupported language. Reuses `getLangFromString(String)` from `lib/core/enums/setting_lang.dart`.

- [ ] **Step 1: Write the failing test**

Create `test/core/utils/platform_utils_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/core/enums/setting_lang.dart';
import 'package:sky_line/core/utils/platform_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns fr when device locale is fr', () {
    tester.binding.platformDispatcher.localeTestValue =
        const Locale('fr', 'FR');
    expect(PlatformUtils.getSystemLang(), SettingLang.fr);
  });

  test('returns ar when device locale is ar', () {
    tester.binding.platformDispatcher.localeTestValue =
        const Locale('ar', 'SA');
    expect(PlatformUtils.getSystemLang(), SettingLang.ar);
  });

  test('returns es when device locale is es', () {
    tester.binding.platformDispatcher.localeTestValue =
        const Locale('es', 'ES');
    expect(PlatformUtils.getSystemLang(), SettingLang.es);
  });

  test('returns en when device locale is en', () {
    tester.binding.platformDispatcher.localeTestValue =
        const Locale('en', 'US');
    expect(PlatformUtils.getSystemLang(), SettingLang.en);
  });

  test('returns en (fallback) for unsupported locale', () {
    tester.binding.platformDispatcher.localeTestValue =
        const Locale('de', 'DE');
    expect(PlatformUtils.getSystemLang(), SettingLang.en);
  });

  test('returns en (fallback) for unsupported zh locale', () {
    tester.binding.platformDispatcher.localeTestValue =
        const Locale('zh', 'CN');
    expect(PlatformUtils.getSystemLang(), SettingLang.en);
  });
}
```

Note: `localeTestValue` is available on `TestPlatformDispatcher` (Flutter test binding); `platformDispatcher` accesses the root `WidgetsBinding`'s platform dispatcher.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/utils/platform_utils_test.dart`
Expected: FAIL — `getSystemLang` is not defined on `PlatformUtils`.

- [ ] **Step 3: Write minimal implementation**

In `lib/core/utils/platform_utils.dart`, add an import and the new static method:

```dart
import 'package:sky_line/core/enums/setting_lang.dart';
```

Add after the `is24HourFormat()` method (line ~24):

```dart
  // Resolve supported system language, fallback to en
  static SettingLang getSystemLang() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    return getLangFromString(locale.languageCode);
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/utils/platform_utils_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: Run analysis**

Run: `flutter analyze`
Expected: 0 issues.

- [ ] **Step 6: Commit**

```bash
git add lib/core/utils/platform_utils.dart test/core/utils/platform_utils_test.dart
git commit -m "feat: detect system language with en fallback"
```

---

### Task 2: First-launch language resolution in SettingRepositoryImpl

**Files:**
- Modify: `lib/features/settings/data/repositories/setting_repository_impl.dart`
- Modify: `test/features/settings/data/repositories/setting_repository_impl_test.dart`

**Interfaces:**
- Consumes: `SettingLang PlatformUtils.getSystemLang()` (Task 1), `SettingLang Function()` provider.
- Produces:
  - Constructor `SettingRepositoryImpl(DbHelper)` — unchanged default, defaults provider to `PlatformUtils.getSystemLang`.
  - `@visibleForTesting` constructor `SettingRepositoryImpl.withSystemLang(DbHelper, SettingLang Function() systemLangProvider)`.
  - Behavior change to `loadSettings()`: when `DbHelper.loadSettings()` returns `null`, resolve language via provider, persist via `saveSettings`, return the created `SettingEntity`; otherwise return the cached entity converted to domain (unchanged).

- [ ] **Step 1: Update the existing test for the changed null-cache behavior**

In `test/features/settings/data/repositories/setting_repository_impl_test.dart`, replace the existing `'should return defaults when cache is null'` test (lines 36-42) with a group using the injection constructor. Add new tests to the `loadSettings` group:

```dart
  group('loadSettings first launch (null cache)', () {
    setUp(() {
      when(() => mockDbHelper.loadSettings()).thenReturn(null);
      when(() => mockDbHelper.saveSettings(any())).thenReturn(null);
    });

    test('should use provider language and persist on first launch', () async {
      repository = SettingRepositoryImpl.withSystemLang(
        mockDbHelper,
        () => SettingLang.fr,
      );

      final result = await repository.loadSettings();

      expect(result.lang, SettingLang.fr);
      expect(result.theme, SettingTheme.system);
      verify(() => mockDbHelper.saveSettings(any())).called(1);
    });

    test('should fall back to en for unsupported provider language', () async {
      repository = SettingRepositoryImpl.withSystemLang(
        mockDbHelper,
        () => SettingLang.en,
      );

      final result = await repository.loadSettings();

      expect(result.lang, SettingLang.en);
      verify(() => mockDbHelper.saveSettings(any())).called(1);
    });
  });
```

The `saveSettings(any())` verification needs `registerFallbackValue(const SettingModel())` — already present in `setUpAll` (line 27). Also keep the existing `'should return cached entity converted to domain'` test unchanged in the `loadSettings` group, and add a test that a persisted cache is NOT overridden:

```dart
    test('should keep persisted language and not save when cache exists', () async {
      final entity = SettingCacheEntity(
        id: 1,
        themeValue: 'system',
        langValue: 'es',
        windUnitValue: 'ms',
        heatUnitValue: 'celsius',
      );
      when(() => mockDbHelper.loadSettings()).thenReturn(entity);
      repository = SettingRepositoryImpl.withSystemLang(
        mockDbHelper,
        () => SettingLang.fr,
      );

      final result = await repository.loadSettings();

      expect(result.lang, SettingLang.es);
      verifyNever(() => mockDbHelper.saveSettings(any()));
    });
```

Note: this test must NOT stub `saveSettings` to `thenReturn(null)` (the `saveSettings` mock returns null by default in mocktail), so `verifyNever` holds. Place it in the `loadSettings` group.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/settings/data/repositories/setting_repository_impl_test.dart`
Expected: FAIL — `SettingRepositoryImpl.withSystemLang` constructor does not exist.

- [ ] **Step 3: Write minimal implementation**

Replace the content of `lib/features/settings/data/repositories/setting_repository_impl.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:sky_line/core/config/db_helper/db_helper.dart';
import 'package:sky_line/core/enums/setting_lang.dart';
import 'package:sky_line/core/utils/platform_utils.dart';
import 'package:sky_line/features/settings/data/mappers/setting_mapper.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';
import 'package:sky_line/features/settings/domain/repositories/setting_repository.dart';

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

  @override
  Future<void> saveSettings(SettingEntity setting) async {
    final model = SettingMapper.fromEntity(setting);
    _dbHelper.saveSettings(model);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/settings/data/repositories/setting_repository_impl_test.dart`
Expected: PASS (all `loadSettings` and `saveSettings` tests).

- [ ] **Step 5: Run analysis**

Run: `flutter analyze`
Expected: 0 issues.

- [ ] **Step 6: Commit**

```bash
git add lib/features/settings/data/repositories/setting_repository_impl.dart test/features/settings/data/repositories/setting_repository_impl_test.dart
git commit -m "feat: auto-set system language on first launch"
```

---

### Task 3: Full-suite verification

**Files:** none (verification only).

- [ ] **Step 1: Run the targeted integration tests together**

Run: `flutter test test/core/utils/platform_utils_test.dart test/features/settings/data/repositories/setting_repository_impl_test.dart`
Expected: PASS.

- [ ] **Step 2: Run the full test suite**

Run: `flutter test`
Expected: PASS (all tests green).

- [ ] **Step 3: Run final analysis**

Run: `flutter analyze`
Expected: 0 warnings, 0 infos.

- [ ] **Step 4: Commit any remaining changes (if any)**

```bash
git status
# If any unintended changes exist, review and commit or discard them.
```
