# Settings Feature — Design Spec

**Date:** 2026-06-24
**Feature:** settings
**Status:** Approved

## Objective
Add a `settings` feature managing theme, language, wind speed unit, and temperature unit, with ObjectBox persistence and Flutter ARB localization.

## Folder Structure

```
lib/features/settings/
├── data/
│   ├── models/setting_model.dart
│   └── repositories/setting_repository_impl.dart
├── domain/
│   ├── entities/setting.dart
│   └── repositories/setting_repository.dart
└── presentation/
    ├── blocs/
    │   ├── settings_bloc.dart
    │   ├── settings_event.dart
    │   └── settings_state.dart
    ├── screens/settings_screen.dart
    └── widgets/
```

## ObjectBox Persistence

### `SettingCacheEntity` (`lib/core/config/db_helper/setting_cache_entity.dart`)
```dart
@Entity()
class SettingCacheEntity {
  @Id() int id;
  String themeValue;
  String langValue;
  String windUnitValue;
  String heatUnitValue;
}
```

### `DbHelper` Extension
- `Box<SettingCacheEntity> _settingsBox`
- `SettingCacheEntity? loadSettings()` — returns the single settings row (last saved)
- `void saveSettings(SettingCacheEntity s)` — insert/update (single row, id=0)

## Data Model

### Domain Entity `Setting` (`lib/features/settings/domain/entities/setting.dart`)
- Extends `Equatable`
- Fields: `SettingTheme theme`, `SettingLang lang`, `SettingWindUnit windUnit`, `SettingHeatUnit heatUnit`
- Manual `copyWith`
- `props: [theme, lang, windUnit, heatUnit]`

### Default Values
- `SettingTheme.system`, `SettingLang.en`, `SettingWindUnit.ms`, `SettingHeatUnit.celsius`

### `SettingModel` (`lib/features/settings/data/models/setting_model.dart`)
- DTO bridging `SettingCacheEntity` (ObjectBox) ↔ `Setting` (domain)
- Methods: `Setting toEntity()` , `factory SettingModel.fromCacheEntity(SettingCacheEntity entity)`, `SettingCacheEntity toCacheEntity()`

## Repository

### Interface (`lib/features/settings/domain/repositories/setting_repository.dart`)
```dart
abstract class SettingRepository {
  Future<Setting> loadSettings();
  Future<void> saveSettings(Setting setting);
}
```

### Implementation (`lib/features/settings/data/repositories/setting_repository_impl.dart`)
- Wraps `DbHelper` calls
- Returns defaults when no cached row exists

## Localization

### Configuration (`l10n.yaml` at project root)
```yaml
arb-dir: lib/core/l10n/arb
template-arb-file: intl_en.arb
output-localization-file: app_localisation.dart
output-class: AppLocalisation
synthetic-package: false
```

### ARB Files
- `intl_en.arb` — template with settings keys (screen title, section labels, option labels)
- `intl_fr.arb`, `intl_es.arb`, `intl_ar.arb` — translations

### Generated Code
- Run `flutter gen-l10n` → `lib/generated/app_localisation.dart`
- Configure `localizationsDelegates` + `supportedLocales` in `MaterialApp`

### Pubspec Dependency
- Add `flutter_localizations: sdk: flutter`

## SettingsBloc

### Events
| Event | Action |
|---|---|
| `LoadSettingsEvent` | Load from ObjectBox, emit loaded state |
| `UpdateSettingsEvent(Setting)` | Persist to ObjectBox, emit new state |

### State
```dart
class SettingsState extends Equatable {
  final Setting setting;
  final bool isLoaded;
  // copyWith, props
}
```

### Bloc
- `SettingsBloc(SettingRepository repository)`
- `on<LoadSettingsEvent>(...)` → load, emit `SettingsState(setting: loaded, isLoaded: true)`
- `on<UpdateSettingsEvent>(...)` → save, emit `SettingsState(setting: event.setting, isLoaded: true)`
- Initial state: `SettingsState(setting: Setting.defaults(), isLoaded: false)`

## main.dart Integration

```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => InjectionContainer.weatherBloc..add(FetchWeatherEvent())),
    BlocProvider(create: (_) => InjectionContainer.settingsBloc..add(LoadSettingsEvent())),
  ],
  child: MyApp(),
)

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        if (!state.isLoaded) return const SizedBox.shrink();
        return AnnotatedRegion(
          value: PlatformUtils.getSystemUiStyle(state.setting.theme, context),
          child: MaterialApp(
            locale: Locale(getStringFromLang(state.setting.lang)),
            localizationsDelegates: AppLocalisation.localizationsDelegates,
            supportedLocales: AppLocalisation.supportedLocales,
            themeMode: SettingTheme.getThemeMode(state.setting.theme),
            title: 'SkyLine',
            home: WeatherScreen(),
            theme: appTheme.light(),
            darkTheme: appTheme.dark(),
            debugShowCheckedModeBanner: false,
          ),
        );
      },
    );
  }
}
```

## Navigation
- `WeatherHeader` `settings_rounded` icon `onPressed` → `Navigator.push(MaterialPageRoute(builder: (_) => SettingsScreen()))`
- `SettingsScreen` uses `context.read<SettingsBloc>()` to dispatch events

## Injection Container
```dart
static late final SettingRepository settingRepository;
static late final SettingsBloc settingsBloc;

// In init():
settingRepository = SettingRepositoryImpl(dbHelper);
settingsBloc = SettingsBloc(settingRepository);
```

## Settings Screen UI
- List of setting sections
- Each section: label + current value + tap → open picker dialog/bottom sheet
- Sections: Theme, Language, Wind Unit, Temperature Unit
- Changes dispatch `UpdateSettingsEvent(setting: currentSetting.copyWith(...))`

## Testing Plan
- `SettingModel`: toEntity, fromCacheEntity, toCacheEntity, props
- `SettingRepositoryImpl`: load returns defaults when empty, save then load returns saved values
- `SettingsBloc`: initial state, load event emits loaded with defaults/DB values, update event saves + emits new state
- `SettingsScreen`: widget test with mocked bloc

## Out of Scope
- Importing `flutter_localizations` and running `flutter gen-l10n` (covered in implementation plan)
- Refactoring existing `weather_forecast` strings to use localization (future work)
