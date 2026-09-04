# System Language First-Launch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** At first launch, automatically set the app language to the device language if supported, falling back to English otherwise.

**Architecture:** Confined to the Data layer plus a `core` utility. `SettingRepositoryImpl.loadSettings()` detects when no persisted setting exists (first launch), resolves the system language via a new `PlatformUtils.getSystemLang()` (reusing the existing `getLangFromString` mapping with `en` fallback), persists the choice, and returns it. Presentation, BLoC, `main.dart`, and the injection container stay untouched.

**Tech Stack:** Flutter, Dart, mocktail (tests), `flutter_test` widget tester.

## Global Constraints

- Code, comments, variable names, and commits written exclusively in English.
- All relevant classes extend `Equatable` with explicit `props` (unchanged here).
- No `freezed` or immutable-code generators (unchanged here).
- Run `flutter analyze` with zero warnings/info before finishing.
- Run `flutter test` to validate the full suite.
- Supported languages: `en`, `fr`, `es`, `ar`. Fallback: `en`.

---

### Task 1: System language detection helper

**Files:**
- Modify: `lib/core/utils/platform_utils.dart`
- Create: `test/core/utils/platform_utils_test.dart`

**Interfaces:**
- Consumes: `getLangFromString(String)` from `lib/core/enums/setting_lang.dart`, `SettingLang` enum, `WidgetsBinding.instance.platformDispatcher.locale`.
- Produces: `static SettingLang PlatformUtils.getSystemLang()`.

- [ ] **Step 1: Write the failing tests**

Create `test/core/utils/platform_utils_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/core/enums/setting_lang.dart';
import 'package:sky_line/core/utils/platform_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SettingLang> resolve(SystemLocale locale) async {
    tester.platformDispatcher.localeTestValue = locale;
    return PlatformUtils.getSystemLang();
  }

  testWidgets('returns fr for a French system locale', (tester) async {
    expect(await resolve(const Locale('fr')), SettingLang.fr);
  });

  testWidgets('returns ar for an Arabic system locale', (tester) async {
    expect(await resolve(const Locale('ar')), SettingLang.ar);
  });

  testWidgets('returns en for a supported English locale', (tester) async {
    expect(await resolve(const Locale('en')), SettingLang.en);
  });

  testWidgets('falls back to en for an unsupported locale', (tester) async {
    expect(await resolve(const Locale('de')), SettingLang.en);
  });
}
```

Note: `Locale` here refers to `dart:ui`'s `Locale`; `tester.platformDispatcher.localeTestValue` accepts a `Locale`. Ensure `import 'dart:ui'` is not needed since `Locale` is re-exported by Flutter's `material`/`widgets`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/utils/platform_utils_test.dart`
Expected: FAIL — `getSystemLang` is not defined.

- [ ] **Step 3: Write the minimal implementation**

In `lib/core/utils/platform_utils.dart`, add the import and the method. Ensure `dart:ui` and `package:flutter/material.dart` are already imported (they are). Add import for `setting_lang.dart`:

```dart
import 'package:sky_line/core/enums/setting_lang.dart';
```

Add the method at the end of the `PlatformUtils` class:

```dart
// Resolve supported system language, fallback to en
static SettingLang getSystemLang() {
  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  return getLangFromString(locale.languageCode);
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/utils/platform_utils_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Run analyzer**

Run: `flutter analyze lib/core/utils/platform_utils.dart test/core/utils/platform_utils_test.dart`
Expected: No issues found.

- [ ] **Step 6: Commit**

```bash
git add lib/core/utils/platform_utils.dart test/core/utils/platform_utils_test.dart
git commit -m "feat: add system language detection helper"
```

---

### Task 2: First-launch language resolution in repository

**Files:**
- Modify: `lib/features/settings/data/repositories/setting_repository_impl.dart`
- Modify: `test/features/settings/data/repositories/setting_repository_impl_test.dart`

**Interfaces:**
- Consumes: `PlatformUtils.getSystemLang()`, `SettingEntity.defaults` / `copyWith`, `SettingLang`, `DbHelper.loadSettings()` / `saveSettings()`.
- Produces: `SettingRepositoryImpl.withSystemLang(DbHelper, SettingLang Function())` constructor for tests; unchanged public behavior of `SettingRepositoryImpl(DbHelper)`.

- [ ] **Step 1: Update the existing null-cache test and add first-launch tests**

Replace the `should return defaults when cache is null` test (lines 36-42) with a controlled-constructor version and add new cases. Update `test/features/settings/data/repositories/setting_repository_impl_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/config/db_helper/db_helper.dart';
import 'package:sky_line/core/config/db_helper/setting_cache_entity.dart';
import 'package:sky_line/core/enums/setting_heat_unit.dart';
import 'package:sky_line/core/enums/setting_lang.dart';
import 'package:sky_line/core/enums/setting_theme.dart';
import 'package:sky_line/core/enums/setting_wind_unit.dart';
import 'package:sky_line/features/settings/data/models/setting_model.dart';
import 'package:sky_line/features/settings/data/repositories/setting_repository_impl.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';

class MockDbHelper extends Mock implements DbHelper {}

void main() {
  late MockDbHelper mockDbHelper;

  SettingRepositoryImpl buildRepo(SettingLang Function() provider) =>
      SettingRepositoryImpl.withSystemLang(mockDbHelper, provider);

  setUpAll(() {
    registerFallbackValue(SettingCacheEntity(
      id: 1,
      themeValue: 'system',
      langValue: 'en',
      windUnitValue: 'ms',
      heatUnitValue: 'celsius',
    ));
    registerFallbackValue(const SettingModel());
  });

  setUp(() {
    mockDbHelper = MockDbHelper();
  });

  group('loadSettings', () {
    test('applies system language and persists when no cache exists', () async {
      when(() => mockDbHelper.loadSettings()).thenReturn(null);
      when(() => mockDbHelper.saveSettings(any())).thenReturn(null);
      final repo = buildRepo(() => SettingLang.fr);

      final result = await repo.loadSettings();

      expect(result.lang, SettingLang.fr);
      expect(result.theme, SettingTheme.system);
      expect(result.windUnit, SettingWindUnit.ms);
      expect(result.heatUnit, SettingHeatUnit.celsius);
      verify(() => mockDbHelper.saveSettings(any())).called(1);
    });

    test('fallback to en for unsupported system language', () async {
      when(() => mockDbHelper.loadSettings()).thenReturn(null);
      when(() => mockDbHelper.saveSettings(any())).thenReturn(null);
      final repo = buildRepo(() => SettingLang.en);

      final result = await repo.loadSettings();

      expect(result.lang, SettingLang.en);
      verify(() => mockDbHelper.saveSettings(any())).called(1);
    });

    test('keeps cached language and does not save when setting exists',
        () async {
      final entity = SettingCacheEntity(
        id: 1,
        themeValue: 'dark',
        langValue: 'es',
        windUnitValue: 'kmh',
        heatUnitValue: 'fahrenheit',
      );
      when(() => mockDbHelper.loadSettings()).thenReturn(entity);
      final repo = buildRepo(() => SettingLang.fr);

      final result = await repo.loadSettings();

      expect(result.lang, SettingLang.es);
      expect(result.theme, SettingTheme.dark);
      expect(result.windUnit, SettingWindUnit.kmh);
      expect(result.heatUnit, SettingHeatUnit.fahrenheit);
      verifyNever(() => mockDbHelper.saveSettings(any()));
    });

    test('should return cached entity converted to domain', () async {
      final entity = SettingCacheEntity(
        id: 1,
        themeValue: 'dark',
        langValue: 'fr',
        windUnitValue: 'kmh',
        heatUnitValue: 'fahrenheit',
      );
      when(() => mockDbHelper.loadSettings()).thenReturn(entity);
      final repo = buildRepo(() => SettingLang.ar);

      final result = await repo.loadSettings();

      expect(result.theme, SettingTheme.dark);
      expect(result.lang, SettingLang.fr);
      expect(result.windUnit, SettingWindUnit.kmh);
      expect(result.heatUnit, SettingHeatUnit.fahrenheit);
    });
  });

  group('saveSettings', () {
    test('should save through dbHelper', () async {
      final setting = const SettingEntity(
        theme: SettingTheme.light,
        lang: SettingLang.ar,
        windUnit: SettingWindUnit.ms,
        heatUnit: SettingHeatUnit.celsius,
      );
      when(() => mockDbHelper.saveSettings(any())).thenReturn(null);
      final repo = buildRepo(() => SettingLang.en);

      await repo.saveSettings(setting);

      verify(() => mockDbHelper.saveSettings(any())).called(1);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/settings/data/repositories/setting_repository_impl_test.dart`
Expected: FAIL — `withSystemLang` constructor does not exist.

- [ ] **Step 3: Write the minimal implementation**

Update `lib/features/settings/data/repositories/setting_repository_impl.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:sky_line/core/enums/setting_lang.dart';
import 'package:sky_line/core/utils/platform_utils.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';
import 'package:sky_line/features/settings/domain/repositories/setting_repository.dart';
import '../models/setting_model.dart';
import '../mappers/setting_mapper.dart';

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

Preserve the existing import block of the file exactly as it currently is (the snippet above shows the needed additions; adjust to keep current relative imports `../models/setting_model.dart` and `../mappers/setting_mapper.dart` untouched if already present).

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/settings/data/repositories/setting_repository_impl_test.dart`
Expected: PASS (all `loadSettings` and `saveSettings` tests).

- [ ] **Step 5: Run analyzer**

Run: `flutter analyze lib/features/settings/data/repositories/setting_repository_impl.dart test/features/settings/data/repositories/setting_repository_impl_test.dart`
Expected: No issues found.

- [ ] **Step 6: Run the full repository test suite**

Run: `flutter test test/features/settings/`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/settings/data/repositories/setting_repository_impl.dart test/features/settings/data/repositories/setting_repository_impl_test.dart
git commit -m "feat: resolve system language on first launch"
```

---

### Task 3: Full-suite validation

**Files:**
- None modified.

- [ ] **Step 1: Run analyzer on the whole project**

Run: `flutter analyze`
Expected: No issues found (0 warnings, 0 info).

- [ ] **Step 2: Run the full test suite**

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 3: Commit any incidental fixes**

If analyzer or tests surfaced issues, fix them and commit. Otherwise no commit needed.
