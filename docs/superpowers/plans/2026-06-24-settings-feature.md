# Settings Feature — Implementation Plan

**Date:** 2026-06-24
**Feature:** settings
**Status:** Implemented

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a settings feature managing theme, language, wind unit, and temperature unit with ObjectBox persistence and ARB localization.

**Architecture:** Clean Architecture with feature-driven structure matching existing `weather_forecast` pattern. Domain entities use Equatable with manual `copyWith`. Data layer wraps ObjectBox via DbHelper. Presentation uses a SettingsBloc (2 events: LoadSettingsEvent / UpdateSettingsEvent). MaterialApp in main.dart listens via BlocBuilder.

**Tech Stack:** Flutter/Dart, flutter_bloc 9.x, equatable ^2.0.x, objectbox 5.x, flutter_localizations, ARB localization.

---

## Global Constraints

- **Equatable required:** All domain entities, models, events, and states must extend Equatable with explicit `props`.
- **copyWith manual:** No freezed. Manual `copyWith` on every entity.
- **English only:** All code in English (variables, classes, comments, commits).
- **Clean Architecture:** Strict layer isolation (domain never imports data/presentation).
- **No silent crashes:** Exceptions caught in data layer → Failure types.
- **Zero warnings:** `flutter analyze` must pass with 0 warnings/infos.
- **No commits** unless explicitly requested.

---

## File Structure

### New Files
| File | Responsibility |
|---|---|
| `lib/core/config/db_helper/setting_cache_entity.dart` | ObjectBox entity |
| `lib/features/settings/domain/entities/setting.dart` | Domain entity (Equatable) |
| `lib/features/settings/domain/repositories/setting_repository.dart` | Repository interface |
| `lib/features/settings/data/models/setting_model.dart` | DTO bridging ObjectBox ↔ domain |
| `lib/features/settings/data/repositories/setting_repository_impl.dart` | Repository impl |
| `lib/features/settings/presentation/blocs/settings_event.dart` | Events |
| `lib/features/settings/presentation/blocs/settings_state.dart` | State |
| `lib/features/settings/presentation/blocs/settings_bloc.dart` | Bloc |
| `lib/features/settings/presentation/screens/settings_screen.dart` | Settings screen |
| `lib/features/settings/presentation/widgets/setting_tile.dart` | Reusable settings row widget |
| `l10n.yaml` | Flutter localization config |
| `test/features/settings/data/models/setting_model_test.dart` | Model tests |
| `test/features/settings/data/repositories/setting_repository_impl_test.dart` | Repository tests |
| `test/features/settings/presentation/blocs/settings_bloc_test.dart` | Bloc tests |
| `test/features/settings/presentation/screens/settings_screen_test.dart` | Screen tests |

### Modified Files
| File | Change |
|---|---|
| `lib/core/config/db_helper/db_helper.dart` | Add `_settingsBox`, `loadSettings()`, `saveSettings()` |
| `lib/core/l10n/arb/intl_en.arb` | Add settings key-value pairs |
| `lib/core/l10n/arb/intl_fr.arb` | Add French translations |
| `lib/core/l10n/arb/intl_es.arb` | Add Spanish translations |
| `lib/core/l10n/arb/intl_ar.arb` | Add Arabic translations |
| `pubspec.yaml` | Add `flutter_localizations: sdk: flutter` |
| `lib/injection_container.dart` | Add `SettingRepository` + `SettingsBloc` |
| `lib/main.dart` | Add SettingsBloc to MultiBlocProvider + BlocBuilder for MaterialApp |
| `lib/features/weather_forecast/presentation/widgets/weather_header.dart` | Add navigation to SettingsScreen |

---

### Task 1: ObjectBox Settings Entity + DbHelper Extension

**Files:**
- Create: `lib/core/config/db_helper/setting_cache_entity.dart`
- Modify: `lib/core/config/db_helper/db_helper.dart`
- Regenerate: `dart run build_runner build`

**Interfaces:**
- Consumes: existing `DbHelper` singleton pattern
- Produces: `SettingCacheEntity`, `DbHelper.loadSettings() → SettingCacheEntity?`, `DbHelper.saveSettings(SettingCacheEntity)`

- [ ] **Step 1: Create SettingCacheEntity**

```dart
// lib/core/config/db_helper/setting_cache_entity.dart
import 'package:objectbox/objectbox.dart';

@Entity()
class SettingCacheEntity {
  @Id()
  int id;
  String themeValue;
  String langValue;
  String windUnitValue;
  String heatUnitValue;

  SettingCacheEntity({
    this.id = 0,
    required this.themeValue,
    required this.langValue,
    required this.windUnitValue,
    required this.heatUnitValue,
  });
}
```

- [ ] **Step 2: Extend DbHelper with settings operations**

Add to `lib/core/config/db_helper/db_helper.dart`:

```dart
import 'package:sky_line/core/config/db_helper/setting_cache_entity.dart';

class DbHelper {
  // ... existing fields ...
  late final Box<SettingCacheEntity> _settingsBox;

  DbHelper._(this._store)
      : _box = Box<WeatherCacheEntity>(_store),
        _settingsBox = Box<SettingCacheEntity>(_store);

  // ... existing methods ...

  SettingCacheEntity? loadSettings() {
    final entities = _settingsBox.getAll();
    if (entities.isEmpty) return null;
    return entities.first;
  }

  void saveSettings(SettingCacheEntity settings) {
    _settingsBox.put(settings);
  }
}
```

- [ ] **Step 3: Run ObjectBox code generation**

```bash
dart run build_runner build
```

---

### Task 2: Domain Layer — Setting Entity + Repository Interface

**Files:**
- Create: `lib/features/settings/domain/entities/setting.dart`
- Create: `lib/features/settings/domain/repositories/setting_repository.dart`

**Interfaces:**
- Produces: `Setting` (entity), `SettingRepository` (abstract class)

- [ ] **Step 1: Create domain Setting entity**

```dart
// lib/features/settings/domain/entities/setting.dart
import 'package:equatable/equatable.dart';
import 'package:sky_line/core/enums/setting_heat_unit.dart';
import 'package:sky_line/core/enums/setting_lang.dart';
import 'package:sky_line/core/enums/setting_theme.dart';
import 'package:sky_line/core/enums/setting_wind_unit.dart';

class Setting extends Equatable {
  final SettingTheme theme;
  final SettingLang lang;
  final SettingWindUnit windUnit;
  final SettingHeatUnit heatUnit;

  const Setting({
    this.theme = SettingTheme.system,
    this.lang = SettingLang.en,
    this.windUnit = SettingWindUnit.ms,
    this.heatUnit = SettingHeatUnit.celsius,
  });

  static const defaults = Setting();

  Setting copyWith({
    SettingTheme? theme,
    SettingLang? lang,
    SettingWindUnit? windUnit,
    SettingHeatUnit? heatUnit,
  }) {
    return Setting(
      theme: theme ?? this.theme,
      lang: lang ?? this.lang,
      windUnit: windUnit ?? this.windUnit,
      heatUnit: heatUnit ?? this.heatUnit,
    );
  }

  @override
  List<Object?> get props => [theme, lang, windUnit, heatUnit];
}
```

- [ ] **Step 2: Create SettingRepository interface**

```dart
// lib/features/settings/domain/repositories/setting_repository.dart
import 'package:sky_line/features/settings/domain/entities/setting.dart';

abstract class SettingRepository {
  Future<Setting> loadSettings();
  Future<void> saveSettings(Setting setting);
}
```

---

### Task 3: Data Layer — SettingModel + SettingRepositoryImpl

**Files:**
- Create: `lib/features/settings/data/models/setting_model.dart`
- Create: `lib/features/settings/data/repositories/setting_repository_impl.dart`

**Interfaces:**
- Consumes: `Setting`, `SettingRepository`, `SettingCacheEntity`, `DbHelper`
- Produces: `SettingModel`, `SettingRepositoryImpl`

- [ ] **Step 1: Create SettingModel (DTO)**

```dart
// lib/features/settings/data/models/setting_model.dart
import 'package:equatable/equatable.dart';
import 'package:sky_line/core/config/db_helper/setting_cache_entity.dart';
import 'package:sky_line/core/enums/setting_heat_unit.dart';
import 'package:sky_line/core/enums/setting_lang.dart';
import 'package:sky_line/core/enums/setting_theme.dart';
import 'package:sky_line/core/enums/setting_wind_unit.dart';
import 'package:sky_line/features/settings/domain/entities/setting.dart';

class SettingModel extends Equatable {
  final SettingTheme theme;
  final SettingLang lang;
  final SettingWindUnit windUnit;
  final SettingHeatUnit heatUnit;

  const SettingModel({
    this.theme = SettingTheme.system,
    this.lang = SettingLang.en,
    this.windUnit = SettingWindUnit.ms,
    this.heatUnit = SettingHeatUnit.celsius,
  });

  factory SettingModel.fromCacheEntity(SettingCacheEntity entity) {
    return SettingModel(
      theme: SettingTheme.getThemeFromString(entity.themeValue),
      lang: getLangFromString(entity.langValue),
      windUnit: getWindUnitFromString(entity.windUnitValue),
      heatUnit: getHeatUnitFromString(entity.heatUnitValue),
    );
  }

  SettingCacheEntity toCacheEntity() {
    return SettingCacheEntity(
      id: 0,
      themeValue: SettingTheme.getStringFromTheme(theme),
      langValue: getStringFromLang(lang),
      windUnitValue: getStringFromWindUnit(windUnit),
      heatUnitValue: getStringFromHeatUnit(heatUnit),
    );
  }

  Setting toEntity() {
    return Setting(
      theme: theme,
      lang: lang,
      windUnit: windUnit,
      heatUnit: heatUnit,
    );
  }

  factory SettingModel.fromEntity(Setting setting) {
    return SettingModel(
      theme: setting.theme,
      lang: setting.lang,
      windUnit: setting.windUnit,
      heatUnit: setting.heatUnit,
    );
  }

  @override
  List<Object?> get props => [theme, lang, windUnit, heatUnit];
}
```

- [ ] **Step 2: Add enum helper functions for wind/heat unit parsing**

Add to `lib/core/enums/setting_wind_unit.dart`:
```dart
SettingWindUnit getWindUnitFromString(String unit) {
  switch (unit) {
    case 'kmh':
      return SettingWindUnit.kmh;
    default:
      return SettingWindUnit.ms;
  }
}

String getStringFromWindUnit(SettingWindUnit unit) {
  switch (unit) {
    case SettingWindUnit.kmh:
      return 'kmh';
    case SettingWindUnit.ms:
      return 'ms';
  }
}
```

Add to `lib/core/enums/setting_heat_unit.dart`:
```dart
SettingHeatUnit getHeatUnitFromString(String unit) {
  switch (unit) {
    case 'fahrenheit':
      return SettingHeatUnit.fahrenheit;
    default:
      return SettingHeatUnit.celsius;
  }
}

String getStringFromHeatUnit(SettingHeatUnit unit) {
  switch (unit) {
    case SettingHeatUnit.fahrenheit:
      return 'fahrenheit';
    case SettingHeatUnit.celsius:
      return 'celsius';
  }
}
```

- [ ] **Step 3: Create SettingRepositoryImpl**

```dart
// lib/features/settings/data/repositories/setting_repository_impl.dart
import 'package:sky_line/core/config/db_helper/db_helper.dart';
import 'package:sky_line/features/settings/data/models/setting_model.dart';
import 'package:sky_line/features/settings/domain/entities/setting.dart';
import 'package:sky_line/features/settings/domain/repositories/setting_repository.dart';

class SettingRepositoryImpl implements SettingRepository {
  final DbHelper _dbHelper;

  SettingRepositoryImpl(this._dbHelper);

  @override
  Future<Setting> loadSettings() async {
    final cached = _dbHelper.loadSettings();
    if (cached == null) return Setting.defaults;
    return SettingModel.fromCacheEntity(cached).toEntity();
  }

  @override
  Future<void> saveSettings(Setting setting) async {
    final model = SettingModel.fromEntity(setting);
    _dbHelper.saveSettings(model.toCacheEntity());
  }
}
```

---

### Task 4: Localization Setup — l10n.yaml + ARB Files

**Files:**
- Create: `l10n.yaml`
- Modify: `lib/core/l10n/arb/intl_en.arb`
- Modify: `lib/core/l10n/arb/intl_fr.arb`
- Modify: `lib/core/l10n/arb/intl_es.arb`
- Modify: `lib/core/l10n/arb/intl_ar.arb`
- Modify: `pubspec.yaml`

**Interfaces:**
- Produces: Generated `lib/generated/app_localisation.dart` (via `flutter gen-l10n`)

- [ ] **Step 1: Create `l10n.yaml`**

```yaml
arb-dir: lib/core/l10n/arb
template-arb-file: intl_en.arb
output-localization-file: app_localisation.dart
output-class: AppLocalisation
synthetic-package: false
```

- [ ] **Step 2: Add `flutter_localizations` to pubspec.yaml**

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  # ... rest unchanged ...
```

- [ ] **Step 3: Populate `intl_en.arb`**

```json
{
  "@@locale": "en",

  "settingsTitle": "Settings",
  "@settingsTitle": {
    "description": "Title for the settings screen"
  },

  "settingsTheme": "Theme",
  "settingsLanguage": "Language",
  "settingsWindUnit": "Wind Unit",
  "settingsTemperatureUnit": "Temperature Unit",

  "settingsThemeLight": "Light",
  "settingsThemeDark": "Dark",
  "settingsThemeSystem": "System",

  "settingsLangEn": "English",
  "settingsLangFr": "Français",
  "settingsLangEs": "Español",
  "settingsLangAr": "العربية",

  "settingsWindUnitMs": "m/s",
  "settingsWindUnitKmh": "km/h",

  "settingsTempUnitCelsius": "Celsius",
  "settingsTempUnitFahrenheit": "Fahrenheit"
}
```

- [ ] **Step 4: Populate `intl_fr.arb`**

```json
{
  "@@locale": "fr",

  "settingsTitle": "Paramètres",
  "settingsTheme": "Thème",
  "settingsLanguage": "Langue",
  "settingsWindUnit": "Unité du vent",
  "settingsTemperatureUnit": "Unité de température",

  "settingsThemeLight": "Clair",
  "settingsThemeDark": "Sombre",
  "settingsThemeSystem": "Système",

  "settingsLangEn": "English",
  "settingsLangFr": "Français",
  "settingsLangEs": "Español",
  "settingsLangAr": "العربية",

  "settingsWindUnitMs": "m/s",
  "settingsWindUnitKmh": "km/h",

  "settingsTempUnitCelsius": "Celsius",
  "settingsTempUnitFahrenheit": "Fahrenheit"
}
```

- [ ] **Step 5: Populate `intl_es.arb`**

```json
{
  "@@locale": "es",

  "settingsTitle": "Ajustes",
  "settingsTheme": "Tema",
  "settingsLanguage": "Idioma",
  "settingsWindUnit": "Unidad del viento",
  "settingsTemperatureUnit": "Unidad de temperatura",

  "settingsThemeLight": "Claro",
  "settingsThemeDark": "Oscuro",
  "settingsThemeSystem": "Sistema",

  "settingsLangEn": "English",
  "settingsLangFr": "Français",
  "settingsLangEs": "Español",
  "settingsLangAr": "العربية",

  "settingsWindUnitMs": "m/s",
  "settingsWindUnitKmh": "km/h",

  "settingsTempUnitCelsius": "Celsius",
  "settingsTempUnitFahrenheit": "Fahrenheit"
}
```

- [ ] **Step 6: Populate `intl_ar.arb`**

```json
{
  "@@locale": "ar",

  "settingsTitle": "الإعدادات",
  "settingsTheme": "المظهر",
  "settingsLanguage": "اللغة",
  "settingsWindUnit": "وحدة الرياح",
  "settingsTemperatureUnit": "وحدة درجة الحرارة",

  "settingsThemeLight": "فاتح",
  "settingsThemeDark": "داكن",
  "settingsThemeSystem": "النظام",

  "settingsLangEn": "English",
  "settingsLangFr": "Français",
  "settingsLangEs": "Español",
  "settingsLangAr": "العربية",

  "settingsWindUnitMs": "م/ث",
  "settingsWindUnitKmh": "كم/س",

  "settingsTempUnitCelsius": "مئوية",
  "settingsTempUnitFahrenheit": "فهرنهايت"
}
```

- [ ] **Step 7: Run `flutter gen-l10n`**

```bash
flutter gen-l10n
```

Expected: Creates `lib/generated/app_localisation.dart` with `AppLocalisation` class.

---

### Task 5: SettingsBloc — Events + State + Bloc

**Files:**
- Create: `lib/features/settings/presentation/blocs/settings_event.dart`
- Create: `lib/features/settings/presentation/blocs/settings_state.dart`
- Create: `lib/features/settings/presentation/blocs/settings_bloc.dart`

**Interfaces:**
- Consumes: `Setting`, `SettingRepository`
- Produces: `SettingsBloc`, `SettingsEvent`, `SettingsState`

- [ ] **Step 1: Create SettingsEvent**

```dart
// lib/features/settings/presentation/blocs/settings_event.dart
import 'package:equatable/equatable.dart';
import 'package:sky_line/features/settings/domain/entities/setting.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettingsEvent extends SettingsEvent {
  const LoadSettingsEvent();
}

class UpdateSettingsEvent extends SettingsEvent {
  final Setting setting;

  const UpdateSettingsEvent(this.setting);

  @override
  List<Object?> get props => [setting];
}
```

- [ ] **Step 2: Create SettingsState**

```dart
// lib/features/settings/presentation/blocs/settings_state.dart
import 'package:equatable/equatable.dart';
import 'package:sky_line/features/settings/domain/entities/setting.dart';

class SettingsState extends Equatable {
  final Setting setting;
  final bool isLoaded;

  const SettingsState({
    this.setting = const Setting(),
    this.isLoaded = false,
  });

  SettingsState copyWith({Setting? setting, bool? isLoaded}) {
    return SettingsState(
      setting: setting ?? this.setting,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  List<Object?> get props => [setting, isLoaded];
}
```

- [ ] **Step 3: Create SettingsBloc**

```dart
// lib/features/settings/presentation/blocs/settings_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/features/settings/domain/repositories/setting_repository.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_event.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingRepository _repository;

  SettingsBloc(this._repository) : super(const SettingsState()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<UpdateSettingsEvent>(_onUpdateSettings);
  }

  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final setting = await _repository.loadSettings();
    emit(state.copyWith(setting: setting, isLoaded: true));
  }

  Future<void> _onUpdateSettings(
    UpdateSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.saveSettings(event.setting);
    emit(state.copyWith(setting: event.setting));
  }
}
```

---

### Task 6: Settings Screen + SettingTile Widget

**Files:**
- Create: `lib/features/settings/presentation/widgets/setting_tile.dart`
- Create: `lib/features/settings/presentation/screens/settings_screen.dart`

**Interfaces:**
- Consumes: `SettingsBloc`, `AppLocalisation`
- Produces: `SettingsScreen`

- [ ] **Step 1: Create SettingTile widget**

```dart
// lib/features/settings/presentation/widgets/setting_tile.dart
import 'package:flutter/material.dart';

class SettingTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const SettingTile({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(
          label,
          style: theme.textTheme.bodyLarge,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
```

- [ ] **Step 2: Create SettingsScreen**

```dart
// lib/features/settings/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/enums/setting_heat_unit.dart';
import 'package:sky_line/core/enums/setting_lang.dart';
import 'package:sky_line/core/enums/setting_theme.dart';
import 'package:sky_line/core/enums/setting_wind_unit.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_event.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_state.dart';
import 'package:sky_line/features/settings/presentation/widgets/setting_tile.dart';
import 'package:sky_line/generated/app_localisation.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalisation.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          final setting = state.setting;
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              SettingTile(
                label: l10n.settingsTheme,
                value: _themeLabel(context, setting.theme),
                onTap: () => _showThemePicker(context, setting),
              ),
              SettingTile(
                label: l10n.settingsLanguage,
                value: _langLabel(context, setting.lang),
                onTap: () => _showLangPicker(context, setting),
              ),
              SettingTile(
                label: l10n.settingsWindUnit,
                value: _windUnitLabel(context, setting.windUnit),
                onTap: () => _showWindUnitPicker(context, setting),
              ),
              SettingTile(
                label: l10n.settingsTemperatureUnit,
                value: _tempUnitLabel(context, setting.heatUnit),
                onTap: () => _showTempUnitPicker(context, setting),
              ),
            ],
          );
        },
      ),
    );
  }

  String _themeLabel(BuildContext context, SettingTheme theme) {
    final l10n = AppLocalisation.of(context);
    switch (theme) {
      case SettingTheme.light:
        return l10n.settingsThemeLight;
      case SettingTheme.dark:
        return l10n.settingsThemeDark;
      case SettingTheme.system:
        return l10n.settingsThemeSystem;
    }
  }

  String _langLabel(BuildContext context, SettingLang lang) {
    final l10n = AppLocalisation.of(context);
    switch (lang) {
      case SettingLang.en:
        return l10n.settingsLangEn;
      case SettingLang.fr:
        return l10n.settingsLangFr;
      case SettingLang.es:
        return l10n.settingsLangEs;
      case SettingLang.ar:
        return l10n.settingsLangAr;
    }
  }

  String _windUnitLabel(BuildContext context, SettingWindUnit unit) {
    final l10n = AppLocalisation.of(context);
    switch (unit) {
      case SettingWindUnit.ms:
        return l10n.settingsWindUnitMs;
      case SettingWindUnit.kmh:
        return l10n.settingsWindUnitKmh;
    }
  }

  String _tempUnitLabel(BuildContext context, SettingHeatUnit unit) {
    final l10n = AppLocalisation.of(context);
    switch (unit) {
      case SettingHeatUnit.celsius:
        return l10n.settingsTempUnitCelsius;
      case SettingHeatUnit.fahrenheit:
        return l10n.settingsTempUnitFahrenheit;
    }
  }

  void _showThemePicker(BuildContext context, Setting current) {
    final l10n = AppLocalisation.of(context);
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.settingsTheme),
        children: [
          SimpleDialogOption(
            child: Text(l10n.settingsThemeSystem),
            onPressed: () => _update(context, current.copyWith(theme: SettingTheme.system)),
          ),
          SimpleDialogOption(
            child: Text(l10n.settingsThemeLight),
            onPressed: () => _update(context, current.copyWith(theme: SettingTheme.light)),
          ),
          SimpleDialogOption(
            child: Text(l10n.settingsThemeDark),
            onPressed: () => _update(context, current.copyWith(theme: SettingTheme.dark)),
          ),
        ],
      ),
    );
  }

  void _showLangPicker(BuildContext context, Setting current) {
    final l10n = AppLocalisation.of(context);
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.settingsLanguage),
        children: [
          SimpleDialogOption(
            child: Text(l10n.settingsLangEn),
            onPressed: () => _update(context, current.copyWith(lang: SettingLang.en)),
          ),
          SimpleDialogOption(
            child: Text(l10n.settingsLangFr),
            onPressed: () => _update(context, current.copyWith(lang: SettingLang.fr)),
          ),
          SimpleDialogOption(
            child: Text(l10n.settingsLangEs),
            onPressed: () => _update(context, current.copyWith(lang: SettingLang.es)),
          ),
          SimpleDialogOption(
            child: Text(l10n.settingsLangAr),
            onPressed: () => _update(context, current.copyWith(lang: SettingLang.ar)),
          ),
        ],
      ),
    );
  }

  void _showWindUnitPicker(BuildContext context, Setting current) {
    final l10n = AppLocalisation.of(context);
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.settingsWindUnit),
        children: [
          SimpleDialogOption(
            child: Text(l10n.settingsWindUnitMs),
            onPressed: () => _update(context, current.copyWith(windUnit: SettingWindUnit.ms)),
          ),
          SimpleDialogOption(
            child: Text(l10n.settingsWindUnitKmh),
            onPressed: () => _update(context, current.copyWith(windUnit: SettingWindUnit.kmh)),
          ),
        ],
      ),
    );
  }

  void _showTempUnitPicker(BuildContext context, Setting current) {
    final l10n = AppLocalisation.of(context);
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.settingsTemperatureUnit),
        children: [
          SimpleDialogOption(
            child: Text(l10n.settingsTempUnitCelsius),
            onPressed: () => _update(context, current.copyWith(heatUnit: SettingHeatUnit.celsius)),
          ),
          SimpleDialogOption(
            child: Text(l10n.settingsTempUnitFahrenheit),
            onPressed: () => _update(context, current.copyWith(heatUnit: SettingHeatUnit.fahrenheit)),
          ),
        ],
      ),
    );
  }

  void _update(BuildContext context, Setting updated) {
    context.read<SettingsBloc>().add(UpdateSettingsEvent(updated));
    Navigator.pop(context);
  }
}
```

---

### Task 7: Integration — Injection Container + main.dart + Navigation

**Files:**
- Modify: `lib/injection_container.dart`
- Modify: `lib/main.dart`
- Modify: `lib/features/weather_forecast/presentation/widgets/weather_header.dart`

**Interfaces:**
- Consumes: `SettingsBloc`, `SettingRepositoryImpl`, `SettingRepository`, `DbHelper`, `SettingsScreen`

- [ ] **Step 1: Update InjectionContainer**

```dart
// lib/injection_container.dart
import 'package:dio/dio.dart';
import 'package:sky_line/core/config/db_helper/db_helper.dart';
import 'package:sky_line/features/settings/data/repositories/setting_repository_impl.dart';
import 'package:sky_line/features/settings/domain/repositories/setting_repository.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:sky_line/features/weather_forecast/data/repositories/weather_repository_impl.dart';
import 'package:sky_line/features/weather_forecast/data/sources/weather_remote_source.dart';
import 'package:sky_line/features/weather_forecast/domain/repositories/weather_repository.dart';

class InjectionContainer {
  static late final Dio dio;
  static late final DbHelper dbHelper;
  static late final WeatherRemoteSource weatherRemoteSource;
  static late final WeatherRepository weatherRepository;
  static late final SettingRepository settingRepository;
  static late final SettingsBloc settingsBloc;

  static Future<void> init() async {
    dbHelper = await DbHelper.init();
    dio = Dio();
    weatherRemoteSource = WeatherRemoteSource(dio);
    weatherRepository = WeatherRepositoryImpl(weatherRemoteSource, dbHelper);
    settingRepository = SettingRepositoryImpl(dbHelper);
    settingsBloc = SettingsBloc(settingRepository);
  }

  static void dispose() {
    dbHelper.dispose();
  }
}
```

- [ ] **Step 2: Update main.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/enums/setting_lang.dart';
import 'package:sky_line/core/enums/setting_theme.dart';
import 'package:sky_line/core/utils/platform_utils.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_event.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_state.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_event.dart';
import 'package:sky_line/features/weather_forecast/presentation/screens/weather_screen.dart';
import 'package:sky_line/generated/app_localisation.dart';
import 'package:sky_line/injection_container.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await InjectionContainer.init();
  FlutterNativeSplash.remove();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => InjectionContainer.weatherBloc..add(FetchWeatherEvent()),
        ),
        BlocProvider(
          create: (_) => InjectionContainer.settingsBloc..add(const LoadSettingsEvent()),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        if (!state.isLoaded) return const SizedBox.shrink();
        final appTheme = AppTheme(Theme.of(context).textTheme);
        final setting = state.setting;
        return AnnotatedRegion(
          value: PlatformUtils.getSystemUiStyle(setting.theme, context),
          child: MaterialApp(
            title: 'SkyLine',
            locale: Locale(getStringFromLang(setting.lang)),
            localizationsDelegates: AppLocalisation.localizationsDelegates,
            supportedLocales: AppLocalisation.supportedLocales,
            home: WeatherScreen(),
            theme: appTheme.light(),
            darkTheme: appTheme.dark(),
            debugShowCheckedModeBanner: false,
            themeMode: SettingTheme.getThemeMode(setting.theme),
          ),
        );
      },
    );
  }
}
```

Note: `weatherBloc` needs to be added to `InjectionContainer` — create it there too:
```dart
// Add to InjectionContainer:
static late final WeatherForecastBloc weatherBloc;

// In init():
weatherBloc = WeatherForecastBloc(weatherRepository);
```

And update main.dart to use `InjectionContainer.weatherBloc` instead of inline creation.

- [ ] **Step 3: Update WeatherHeader navigation**

```dart
// In lib/features/weather_forecast/presentation/widgets/weather_header.dart
import 'package:flutter/material.dart';
import 'package:sky_line/features/settings/presentation/screens/settings_screen.dart';

class WeatherHeader extends StatelessWidget implements PreferredSizeWidget {
  const WeatherHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      notificationPredicate: (_) => false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.grid_view_rounded),
        onPressed: () {},
      ),
      centerTitle: true,
      title: Text(
        'Moroni, Comoros',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
```

- [ ] **Step 4: Add `weatherBloc` to InjectionContainer**

Add after `weatherRepository` in init:

```dart
static late final WeatherForecastBloc weatherBloc;

// In init():
weatherBloc = WeatherForecastBloc(weatherRepository);
```

---

### Task 8: Tests

**Files:**
- Create: `test/features/settings/data/models/setting_model_test.dart`
- Create: `test/features/settings/data/repositories/setting_repository_impl_test.dart`
- Create: `test/features/settings/presentation/blocs/settings_bloc_test.dart`
- Create: `test/features/settings/presentation/screens/settings_screen_test.dart`

- [ ] **Step 1: SettingModel tests**

```dart
// test/features/settings/data/models/setting_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/core/config/db_helper/setting_cache_entity.dart';
import 'package:sky_line/core/enums/setting_heat_unit.dart';
import 'package:sky_line/core/enums/setting_lang.dart';
import 'package:sky_line/core/enums/setting_theme.dart';
import 'package:sky_line/core/enums/setting_wind_unit.dart';
import 'package:sky_line/features/settings/data/models/setting_model.dart';
import 'package:sky_line/features/settings/domain/entities/setting.dart';

void main() {
  group('SettingModel', () {
    final tModel = const SettingModel(
      theme: SettingTheme.light,
      lang: SettingLang.fr,
      windUnit: SettingWindUnit.kmh,
      heatUnit: SettingHeatUnit.fahrenheit,
    );

    test('props returns correct list', () {
      expect(tModel.props, [SettingTheme.light, SettingLang.fr, SettingWindUnit.kmh, SettingHeatUnit.fahrenheit]);
    });

    test('fromCacheEntity creates correct model', () {
      final entity = SettingCacheEntity(
        themeValue: 'light',
        langValue: 'fr',
        windUnitValue: 'kmh',
        heatUnitValue: 'fahrenheit',
      );
      final model = SettingModel.fromCacheEntity(entity);
      expect(model.theme, SettingTheme.light);
      expect(model.lang, SettingLang.fr);
      expect(model.windUnit, SettingWindUnit.kmh);
      expect(model.heatUnit, SettingHeatUnit.fahrenheit);
    });

    test('toCacheEntity creates correct entity', () {
      final entity = tModel.toCacheEntity();
      expect(entity.themeValue, 'light');
      expect(entity.langValue, 'fr');
      expect(entity.windUnitValue, 'kmh');
      expect(entity.heatUnitValue, 'fahrenheit');
    });

    test('toEntity creates correct domain entity', () {
      final entity = tModel.toEntity();
      expect(entity.theme, SettingTheme.light);
      expect(entity.lang, SettingLang.fr);
      expect(entity.windUnit, SettingWindUnit.kmh);
      expect(entity.heatUnit, SettingHeatUnit.fahrenheit);
    });

    test('fromEntity creates correct model', () {
      final setting = const Setting(
        theme: SettingTheme.dark,
        lang: SettingLang.ar,
        windUnit: SettingWindUnit.ms,
        heatUnit: SettingHeatUnit.celsius,
      );
      final model = SettingModel.fromEntity(setting);
      expect(model.theme, SettingTheme.dark);
      expect(model.lang, SettingLang.ar);
      expect(model.windUnit, SettingWindUnit.ms);
      expect(model.heatUnit, SettingHeatUnit.celsius);
    });

    test('defaults are correct', () {
      final model = const SettingModel();
      expect(model.theme, SettingTheme.system);
      expect(model.lang, SettingLang.en);
      expect(model.windUnit, SettingWindUnit.ms);
      expect(model.heatUnit, SettingHeatUnit.celsius);
    });
  });
}
```

- [ ] **Step 2: SettingRepositoryImpl tests**

```dart
// test/features/settings/data/repositories/setting_repository_impl_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/config/db_helper/db_helper.dart';
import 'package:sky_line/core/config/db_helper/setting_cache_entity.dart';
import 'package:sky_line/core/enums/setting_heat_unit.dart';
import 'package:sky_line/core/enums/setting_lang.dart';
import 'package:sky_line/core/enums/setting_theme.dart';
import 'package:sky_line/core/enums/setting_wind_unit.dart';
import 'package:sky_line/features/settings/data/repositories/setting_repository_impl.dart';
import 'package:sky_line/features/settings/domain/entities/setting.dart';

class MockDbHelper extends Mock implements DbHelper {}

void main() {
  late MockDbHelper mockDbHelper;
  late SettingRepositoryImpl repository;

  setUp(() {
    mockDbHelper = MockDbHelper();
    repository = SettingRepositoryImpl(mockDbHelper);
  });

  group('loadSettings', () {
    test('should return defaults when cache is null', () async {
      when(() => mockDbHelper.loadSettings()).thenReturn(null);

      final result = await repository.loadSettings();

      expect(result, Setting.defaults);
    });

    test('should return cached entity converted to domain', () async {
      final entity = SettingCacheEntity(
        themeValue: 'dark',
        langValue: 'fr',
        windUnitValue: 'kmh',
        heatUnitValue: 'fahrenheit',
      );
      when(() => mockDbHelper.loadSettings()).thenReturn(entity);

      final result = await repository.loadSettings();

      expect(result.theme, SettingTheme.dark);
      expect(result.lang, SettingLang.fr);
      expect(result.windUnit, SettingWindUnit.kmh);
      expect(result.heatUnit, SettingHeatUnit.fahrenheit);
    });
  });

  group('saveSettings', () {
    test('should save through dbHelper', () async {
      final setting = const Setting(
        theme: SettingTheme.light,
        lang: SettingLang.ar,
        windUnit: SettingWindUnit.ms,
        heatUnit: SettingHeatUnit.celsius,
      );
      when(() => mockDbHelper.saveSettings(any())).thenReturn(null);

      await repository.saveSettings(setting);

      verify(() => mockDbHelper.saveSettings(any())).called(1);
    });
  });
}
```

- [ ] **Step 3: SettingsBloc tests**

```dart
// test/features/settings/presentation/blocs/settings_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/enums/setting_heat_unit.dart';
import 'package:sky_line/core/enums/setting_lang.dart';
import 'package:sky_line/core/enums/setting_theme.dart';
import 'package:sky_line/core/enums/setting_wind_unit.dart';
import 'package:sky_line/features/settings/domain/entities/setting.dart';
import 'package:sky_line/features/settings/domain/repositories/setting_repository.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_event.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_state.dart';

class MockSettingRepository extends Mock implements SettingRepository {}

void main() {
  late MockSettingRepository mockRepository;

  setUp(() {
    mockRepository = MockSettingRepository();
  });

  group('SettingsBloc', () {
    blocTest<SettingsBloc, SettingsState>(
      'emits loaded state when LoadSettingsEvent is added',
      setUp: () {
        when(() => mockRepository.loadSettings()).thenAnswer(
          (_) async => Setting.defaults,
        );
      },
      build: () => SettingsBloc(mockRepository),
      act: (bloc) => bloc.add(const LoadSettingsEvent()),
      expect: () => [
        isA<SettingsState>().having((s) => s.isLoaded, 'isLoaded', true),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits updated state when UpdateSettingsEvent is added',
      setUp: () {
        when(() => mockRepository.saveSettings(any())).thenAnswer((_) async {});
        when(() => mockRepository.loadSettings()).thenAnswer(
          (_) async => Setting.defaults,
        );
      },
      build: () => SettingsBloc(mockRepository),
      seed: () => const SettingsState(setting: Setting.defaults, isLoaded: true),
      act: (bloc) => bloc.add(const UpdateSettingsEvent(
        Setting(theme: SettingTheme.dark, lang: SettingLang.fr),
      )),
      expect: () => [
        isA<SettingsState>().having((s) => s.setting.theme, 'theme', SettingTheme.dark),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'initial state is not loaded with defaults',
      build: () => SettingsBloc(mockRepository),
      act: (_) {},
      expect: () => [],
    );
  });
}
```

- [ ] **Step 4: SettingsScreen widget tests**

```dart
// test/features/settings/presentation/screens/settings_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/features/settings/domain/entities/setting.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_state.dart';
import 'package:sky_line/features/settings/presentation/screens/settings_screen.dart';
import 'package:sky_line/generated/app_localisation.dart';

class MockSettingsBloc extends Mock implements SettingsBloc {}

void main() {
  late MockSettingsBloc mockBloc;

  setUp(() {
    mockBloc = MockSettingsBloc();
  });

  Future<void> pumpScreen(WidgetTester tester, SettingsState state) async {
    when(() => mockBloc.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalisation.localizationsDelegates,
        supportedLocales: AppLocalisation.supportedLocales,
        home: BlocProvider<SettingsBloc>.value(
          value: mockBloc,
          child: const SettingsScreen(),
        ),
      ),
    );
  }

  testWidgets('should display settings title', (tester) async {
    await pumpScreen(tester, const SettingsState(
      setting: Setting.defaults,
      isLoaded: true,
    ));

    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('should display all setting tiles', (tester) async {
    await pumpScreen(tester, const SettingsState(
      setting: Setting.defaults,
      isLoaded: true,
    ));

    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Wind Unit'), findsOneWidget);
    expect(find.text('Temperature Unit'), findsOneWidget);
  });

  testWidgets('should display current values', (tester) async {
    await pumpScreen(tester, const SettingsState(
      setting: Setting.defaults,
      isLoaded: true,
    ));

    expect(find.text('System'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('m/s'), findsOneWidget);
    expect(find.text('Celsius'), findsOneWidget);
  });
}
```

---

## Self-Review Checklist

1. **Spec coverage:** All spec requirements covered — ObjectBox entity, domain entity, repository, DTO, localization setup, SettingsBloc with 2 events, main.dart integration, navigation, screen with tiles and pickers.
2. **Placeholder scan:** No TBD, TODO, or incomplete code. Every step has complete code.
3. **Type consistency:** `SettingModel.fromCacheEntity` accepts `SettingCacheEntity`, `toCacheEntity()` returns `SettingCacheEntity`. `SettingRepository.loadSettings()` returns `Future<Setting>`. All consistent across tasks.
4. **Scope check:** Focused on single settings feature — no scope creep.
