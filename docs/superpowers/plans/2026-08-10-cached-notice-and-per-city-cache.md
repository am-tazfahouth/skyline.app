# Cached Notice Refinement & Per-City Cache — Implementation Plan

**Date:** 2026-08-10
**Feature:** weather_forecast
**Status:** Implemented

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the weather cache per-city and restrict the "showing cached data" SnackBar to genuine loads (startup / city switch), showing a dedicated network-error message on failed refreshes.

**Architecture:** Store weather cache rows keyed by normalized coordinates (ObjectBox `latitude`/`longitude` columns). Add a transient `WeatherNotice` (`none | cachedData | refreshError`) to `WeatherLoaded` so the BLoC — the only layer that knows the triggering event — tells the presentation layer which SnackBar (if any) to show. The screen reacts to `notice` transitions via `BlocListener`.

**Tech Stack:** Flutter 3.x, flutter_bloc 9.x, ObjectBox 5.x (codegen via `dart run build_runner build`), flutter_gen l10n (`flutter gen-l10n`), dio 5.x, mocktail, bloc_test.

## Global Constraints

- All code, comments, database names and commits in English.
- All entities/models/states extend `Equatable` with explicit `props`; `copyWith` written manually. No `freezed`.
- `flutter analyze` must report zero warnings/infos; `flutter test` must be green after every task.
- After any `lib/core/config/db_helper/*_entity.dart` change run `dart run build_runner build` (regenerates `generated/objectbox.g.dart`).
- After any `lib/core/l10n/arb/*.arb` change run `flutter gen-l10n`.
- Cache coordinates are normalized (rounded to 4 decimals) on both save and load.
- The new l10n key is `weatherRefreshErrorMessage`; values per spec: en "Network error. Please try again later.", fr « Erreur réseau. Veuillez réessayer plus tard. », es "Error de red. Inténtelo de nuevo más tarde.", ar « خطأ في الشبكة. يرجى المحاولة لاحقًا. ».
- Reference spec: `docs/superpowers/specs/2026-08-10-cached-notice-and-per-city-cache-design.md`.

---

### Task 1: Per-city cache — ObjectBox entity + DbHelper

**Files:**
- Modify: `lib/core/config/db_helper/weather_cache_entity.dart`
- Modify: `lib/core/config/db_helper/db_helper.dart`
- Test: `test/core/config/db_helper/db_helper_test.dart`

**Interfaces:**
- Produces:
  - `DbHelper.saveWeather(WeatherModel model, {required double latitude, required double longitude})`
  - `DbHelper.loadWeather({required double latitude, required double longitude, int? maxAgeMillis})` → `WeatherModel?`
  - `DbHelper.clearWeather()` unchanged.
- Consumes: `WeatherModel.toJson()`, `WeatherModel.fromCacheJson(Map<String, dynamic>)`.

- [ ] **Step 1: Add coordinates to the ObjectBox entity**

`lib/core/config/db_helper/weather_cache_entity.dart` becomes:

```dart
import 'package:objectbox/objectbox.dart';

@Entity()
class WeatherCacheEntity {
  @Id()
  int id;
  String jsonData;
  int savedAt;
  double latitude;
  double longitude;

  WeatherCacheEntity({
    required this.id,
    required this.jsonData,
    required this.savedAt,
    required this.latitude,
    required this.longitude,
  });
}
```

- [ ] **Step 2: Regenerate ObjectBox codegen**

Run: `dart run build_runner build`
Expected: `generated/objectbox.g.dart` now contains `WeatherCacheEntity_.latitude` and `WeatherCacheEntity_.longitude` (`QueryDoubleProperty`).

- [ ] **Step 3: Write the failing DbHelper tests**

Rewrite `test/core/config/db_helper/db_helper_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/core/config/db_helper/db_helper.dart';
import 'package:sky_line/features/weather_forecast/data/models/weather_model.dart';
import 'package:sky_line/features/weather_forecast/data/models/current_weather_model.dart';
import 'package:sky_line/features/weather_forecast/data/models/hourly_weather_model.dart';
import 'package:sky_line/features/weather_forecast/data/models/daily_weather_model.dart';

void main() {
  late DbHelper dbHelper;
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('sky_line_test_');
    dbHelper = await DbHelper.init(directory: tempDir.path);
  });

  tearDown(() {
    dbHelper.dispose();
    tempDir.deleteSync(recursive: true);
  });

  WeatherModel buildModel({required double temperature}) {
    return WeatherModel(
      current: CurrentWeatherModel(
        temperature: temperature,
        humidity: 65,
        isDay: true,
        windSpeed: 12.0,
        precipitation: 0.0,
        weatherCode: 0,
      ),
      hourly: [
        HourlyWeatherModel(
          time: DateTime(2026, 6, 17, 10),
          temperature: temperature,
          precipitationProbability: 10,
          weatherCode: 0,
        ),
      ],
      daily: [
        DailyWeatherModel(
          date: DateTime(2026, 6, 17),
          tempMax: temperature + 2,
          tempMin: temperature - 4,
          weatherCode: 0,
          sunrise: DateTime(2026, 6, 17, 6),
          sunset: DateTime(2026, 6, 17, 20),
        ),
      ],
    );
  }

  group('DbHelper weather cache', () {
    test('saveWeather and loadWeather roundtrip for the same city', () {
      dbHelper.saveWeather(buildModel(temperature: 22.5),
          latitude: 48.85, longitude: 2.35);
      final loaded = dbHelper.loadWeather(latitude: 48.85, longitude: 2.35);

      expect(loaded, isNotNull);
      expect(loaded!.current.temperature, 22.5);
      expect(loaded.hourly.length, 1);
      expect(loaded.daily.length, 1);
    });

    test('loadWeather returns null when nothing is cached', () {
      final loaded = dbHelper.loadWeather(latitude: 48.85, longitude: 2.35);
      expect(loaded, isNull);
    });

    test('loadWeather returns null for a city that was never cached', () {
      dbHelper.saveWeather(buildModel(temperature: 22.5),
          latitude: 48.85, longitude: 2.35);
      final other = dbHelper.loadWeather(latitude: -11.7022, longitude: 43.2551);
      expect(other, isNull);
    });

    test('two cities are cached independently', () {
      dbHelper.saveWeather(buildModel(temperature: 22.5),
          latitude: 48.85, longitude: 2.35);
      dbHelper.saveWeather(buildModel(temperature: 31.0),
          latitude: -11.7022, longitude: 43.2551);

      final paris = dbHelper.loadWeather(latitude: 48.85, longitude: 2.35);
      final moroni = dbHelper.loadWeather(latitude: -11.7022, longitude: 43.2551);
      expect(paris!.current.temperature, 22.5);
      expect(moroni!.current.temperature, 31.0);
    });

    test('re-saving the same city replaces its previous entry', () {
      dbHelper.saveWeather(buildModel(temperature: 22.5),
          latitude: 48.85, longitude: 2.35);
      dbHelper.saveWeather(buildModel(temperature: 27.0),
          latitude: 48.85, longitude: 2.35);

      final paris = dbHelper.loadWeather(latitude: 48.85, longitude: 2.35);
      expect(paris!.current.temperature, 27.0);
    });

    test('loadWeather respects maxAgeMillis', () {
      dbHelper.saveWeather(buildModel(temperature: 22.5),
          latitude: 48.85, longitude: 2.35);
      final expired = dbHelper.loadWeather(
          latitude: 48.85, longitude: 2.35, maxAgeMillis: 0);
      expect(expired, isNull);

      final fresh = dbHelper.loadWeather(latitude: 48.85, longitude: 2.35);
      expect(fresh, isNotNull);
    });
  });

  group('onboarding flag', () {
    test('default flag is false when nothing saved', () {
      expect(dbHelper.loadOnboardingFlag(), isFalse);
    });

    test('loadOnboardingFlag returns true after saveOnboardingFlag(true)', () {
      dbHelper.saveOnboardingFlag(true);
      expect(dbHelper.loadOnboardingFlag(), isTrue);
    });

    test('loadOnboardingFlag returns false after saveOnboardingFlag(false)', () {
      dbHelper.saveOnboardingFlag(true);
      dbHelper.saveOnboardingFlag(false);
      expect(dbHelper.loadOnboardingFlag(), isFalse);
    });
  });
}
```

- [ ] **Step 4: Run tests to verify they fail**

Run: `flutter test test/core/config/db_helper/db_helper_test.dart`
Expected: FAIL — `saveWeather`/`loadWeather` no longer match the new named-parameter signatures (compile error).

- [ ] **Step 5: Implement the per-city DbHelper**

`lib/core/config/db_helper/db_helper.dart` — replace `saveWeather` (lines 39-47) and `loadWeather` (lines 53-65) and add a private normalizer next to the class fields:

```dart
  static double _roundCoordinate(double value) =>
      (value * 10000).roundToDouble() / 10000;

  void saveWeather(
    WeatherModel model, {
    required double latitude,
    required double longitude,
  }) {
    final lat = _roundCoordinate(latitude);
    final lon = _roundCoordinate(longitude);
    final existing = _box
        .query(WeatherCacheEntity_.latitude.equals(lat) &
            WeatherCacheEntity_.longitude.equals(lon))
        .build()
        .find();
    for (final entity in existing) {
      _box.remove(entity.id);
    }
    final jsonStr = jsonEncode(model.toJson());
    _box.put(WeatherCacheEntity(
      id: 0,
      jsonData: jsonStr,
      savedAt: DateTime.now().millisecondsSinceEpoch,
      latitude: lat,
      longitude: lon,
    ));
  }

  void clearWeather() {
    _box.removeAll();
  }

  WeatherModel? loadWeather({
    required double latitude,
    required double longitude,
    int? maxAgeMillis,
  }) {
    final lat = _roundCoordinate(latitude);
    final lon = _roundCoordinate(longitude);
    final entities = _box
        .query(WeatherCacheEntity_.latitude.equals(lat) &
            WeatherCacheEntity_.longitude.equals(lon))
        .build()
        .find();
    if (entities.isEmpty) return null;

    final entity = entities.first;
    if (maxAgeMillis != null) {
      final age = DateTime.now().millisecondsSinceEpoch - entity.savedAt;
      if (age >= maxAgeMillis) return null;
    }

    final json = jsonDecode(entity.jsonData) as Map<String, dynamic>;
    return WeatherModel.fromCacheJson(json);
  }
```

`WeatherCacheEntity` constructions elsewhere in the file (none — only these two methods touch it) are already updated. The existing `saveSettings`/`loadSettings` and other methods are untouched.

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/core/config/db_helper/db_helper_test.dart`
Expected: PASS (all 9 weather-cache + onboarding tests).

- [ ] **Step 7: Commit**

```bash
git add lib/core/config/db_helper/weather_cache_entity.dart lib/core/config/db_helper/generated/objectbox.g.dart lib/core/config/db_helper/db_helper.dart test/core/config/db_helper/db_helper_test.dart
git commit -m "feat(weather): make weather cache per-city"
```

---

### Task 2: Per-city cache — repository contract, impl, bloc call-site and test mocks

**Files:**
- Modify: `lib/features/weather_forecast/domain/repositories/weather_repository.dart:5`
- Modify: `lib/features/weather_forecast/data/repositories/weather_repository_impl.dart`
- Modify: `lib/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart:74`
- Test: `test/features/weather_forecast/data/repositories/weather_repository_impl_test.dart`
- Test: `test/features/weather_forecast/presentation/blocs/weather_forecast_bloc_test.dart`
- Test: `test/features/weather_forecast/presentation/screens/weather_screen_test.dart`
- Test: `test/features/settings/presentation/screens/settings_screen_test.dart`
- Test: `test/core/config/app_routes_test.dart`

**Interfaces:**
- Consumes: `DbHelper.loadWeather({required double latitude, required double longitude, int? maxAgeMillis})` and `DbHelper.saveWeather(WeatherModel, {required double latitude, required double longitude})` from Task 1.
- Produces:
  - `WeatherRepository.loadCachedWeather({required double latitude, required double longitude})` → `Future<WeatherResult?>`
  - `WeatherRepository.fetchWeather({required double latitude, required double longitude})` unchanged.
  - `WeatherRepository.clearCachedWeather()` unchanged.

- [ ] **Step 1: Update the repository contract**

`lib/features/weather_forecast/domain/repositories/weather_repository.dart`:

```dart
import 'package:sky_line/features/weather_forecast/domain/entities/weather_result.dart';

abstract class WeatherRepository {
  Future<WeatherResult> fetchWeather({required double latitude, required double longitude});
  Future<WeatherResult?> loadCachedWeather({required double latitude, required double longitude});
  Future<void> clearCachedWeather();
}
```

- [ ] **Step 2: Update the repository implementation**

`lib/features/weather_forecast/data/repositories/weather_repository_impl.dart` — keep the file's existing imports unchanged; change the two methods' bodies as follows:

`loadCachedWeather`:

```dart
  @override
  Future<WeatherResult?> loadCachedWeather({
    required double latitude,
    required double longitude,
  }) async {
    final cached = _dbHelper.loadWeather(
      latitude: latitude,
      longitude: longitude,
      maxAgeMillis: _cacheMaxAgeDays * 24 * 60 * 60 * 1000,
    );
    if (cached == null) return null;
    return WeatherResult(weather: cached.toEntity(), isCached: true);
  }
```

`fetchWeather` — change only the `_dbHelper.saveWeather(model);` line (currently line 27):

```dart
    _dbHelper.saveWeather(model, latitude: latitude, longitude: longitude);
```

- [ ] **Step 3: Update the bloc call site**

`lib/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart:74`:

```dart
    final cached = await weatherRepository.loadCachedWeather(latitude: lat, longitude: lon);
```

- [ ] **Step 4: Update the repository tests**

`test/features/weather_forecast/data/repositories/weather_repository_impl_test.dart`:

- `loadCachedWeather` group — stub with coordinates and call with coordinates:

```dart
  group('loadCachedWeather', () {
    test('returns WeatherResult when cache is fresh', () async {
      when(() => mockDbHelper.loadWeather(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        maxAgeMillis: any(named: 'maxAgeMillis'),
      )).thenReturn(
        WeatherModel(
          current: CurrentWeatherModel(
            temperature: 26.5, humidity: 80, isDay: true,
            windSpeed: 12.0, precipitation: 0.0, weatherCode: 0,
          ),
          hourly: [],
          daily: [],
        ),
      );

      final result = await repository.loadCachedWeather(
          latitude: -11.7022, longitude: 43.2551);

      expect(result, isA<WeatherResult>());
      expect(result!.isCached, true);
      expect(result.weather.current.temperature, 26.5);
      verify(() => mockDbHelper.loadWeather(
        latitude: -11.7022,
        longitude: 43.2551,
        maxAgeMillis: any(named: 'maxAgeMillis'),
      )).called(1);
    });

    test('returns null when cache is empty', () async {
      when(() => mockDbHelper.loadWeather(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        maxAgeMillis: any(named: 'maxAgeMillis'),
      )).thenReturn(null);

      final result = await repository.loadCachedWeather(
          latitude: -11.7022, longitude: 43.2551);
      expect(result, isNull);
    });
  });
```

- `fetchWeather` group — add a `saveWeather` verification to the success test (after the existing expectations):

```dart
      verify(() => mockDbHelper.saveWeather(
        any(),
        latitude: -11.7022,
        longitude: 43.2551,
      )).called(1);
```

- [ ] **Step 5: Update all remaining `loadCachedWeather` mocks to the new signature**

Apply the following replacement in the four files below. The exact stub becomes:

```dart
      when(() => mockRepository.loadCachedWeather(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ))
```

and the `verifyNever` becomes:

```dart
      verifyNever(() => mockRepository.loadCachedWeather(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ));
```

Sites:

1. `test/features/weather_forecast/presentation/blocs/weather_forecast_bloc_test.dart`:
   - lines 92, 114, 139, 163, 184, 203, 224, 268 (stubs) → `when(() => mockRepository.loadCachedWeather(latitude: any(named: 'latitude'), longitude: any(named: 'longitude')))`
   - line 259 (`verifyNever(() => mockRepository.loadCachedWeather());`) → add the two named `any(...)` arguments.
2. `test/features/weather_forecast/presentation/screens/weather_screen_test.dart`:
   - lines 149, 822, 842, 863, 888, 929 (stubs) → add the two named `any(...)` arguments.
3. `test/features/settings/presentation/screens/settings_screen_test.dart` line 48 → add the two named `any(...)` arguments.
4. `test/core/config/app_routes_test.dart` line 49 → add the two named `any(...)` arguments.

For mocktail, named `any(...)` requires a value; the exact form is:

```dart
    when(() => mockRepository.loadCachedWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    )).thenAnswer((_) async => ...);
```

- [ ] **Step 6: Run the affected tests to verify they pass**

Run: `flutter test test/features/weather_forecast/data/repositories/weather_repository_impl_test.dart test/features/weather_forecast/presentation/blocs/weather_forecast_bloc_test.dart test/features/settings/presentation/screens/settings_screen_test.dart test/core/config/app_routes_test.dart`
Expected: PASS.

- [ ] **Step 7: Run static analysis**

Run: `flutter analyze`
Expected: no issues.

- [ ] **Step 8: Commit**

```bash
git add lib/features/weather_forecast/domain/repositories/weather_repository.dart lib/features/weather_forecast/data/repositories/weather_repository_impl.dart lib/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart test/features/weather_forecast/data/repositories/weather_repository_impl_test.dart test/features/weather_forecast/presentation/blocs/weather_forecast_bloc_test.dart test/features/weather_forecast/presentation/screens/weather_screen_test.dart test/features/settings/presentation/screens/settings_screen_test.dart test/core/config/app_routes_test.dart
git commit -m "refactor(weather): scope weather cache lookup by coordinates"
```

---

### Task 3: WeatherNotice — state field + bloc emission rules + bloc tests

**Files:**
- Modify: `lib/features/weather_forecast/presentation/blocs/weather_forecast_state.dart`
- Modify: `lib/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart`
- Test: `test/features/weather_forecast/presentation/blocs/weather_forecast_bloc_test.dart`

**Interfaces:**
- Consumes: `WeatherRepository.loadCachedWeather({required double latitude, required double longitude})` (Task 2).
- Produces:
  - `enum WeatherNotice { none, cachedData, refreshError }` (exported from `weather_forecast_state.dart`).
  - `WeatherLoaded` gains `final WeatherNotice notice` (default `WeatherNotice.none`), included in `copyWith` and `props`.

- [ ] **Step 1: Write the failing bloc tests**

In `test/features/weather_forecast/presentation/blocs/weather_forecast_bloc_test.dart`:

1. Add the import for the enum (already imported via `weather_forecast_state.dart` — `WeatherNotice` is exported from it, so no new import needed).
2. In the FetchWeatherEvent test *"emits [Loaded(fetching), Loaded(done)] when cache valid + offline"* (line 89), add to the second expected state:

```dart
        isA<WeatherLoaded>()
            .having((s) => s.isFetching, 'done', false)
            .having((s) => s.notice, 'notice', WeatherNotice.cachedData),
```

3. In the FetchWeatherEvent test *"emits [Loaded(cached,fetching), Loaded(fresh)] when cache + online + succeeds"* (line 111), add to the final expected state:

```dart
        isA<WeatherLoaded>()
            .having((s) => s.isFetching, 'done', false)
            .having((s) => s.result.isCached, 'fresh', false)
            .having((s) => s.notice, 'notice', WeatherNotice.none),
```

4. In the FetchWeatherEvent test *"cache valid + fetch fails with DioException → stays Loaded(cached)"* (line 136), add to the final expected state:

```dart
        isA<WeatherLoaded>()
            .having((s) => s.isFetching, 'done', false)
            .having((s) => s.notice, 'notice', WeatherNotice.cachedData),
```

5. In the RefreshWeatherEvent test *"from Loaded → fetch fails with DioException → stays Loaded(original)"* (line 315), add to the final expected state:

```dart
        isA<WeatherLoaded>()
            .having((s) => s.isFetching, 'done', false)
            .having((s) => s.result.isCached, 'still cached', true)
            .having((s) => s.notice, 'notice', WeatherNotice.refreshError),
```

6. In the ApplySettingsEvent test *"from WeatherLoaded → updates settings"* (line 449), add:

```dart
        isA<WeatherLoaded>()
            .having((s) => s.settings.windUnit, 'windUnit', SettingWindUnit.kmh)
            .having((s) => s.settings.heatUnit, 'heatUnit', SettingHeatUnit.fahrenheit)
            .having((s) => s.notice, 'notice', WeatherNotice.none),
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/weather_forecast/presentation/blocs/weather_forecast_bloc_test.dart`
Expected: FAIL — `notice` is not a field of `WeatherLoaded` (compile error).

- [ ] **Step 3: Add `WeatherNotice` and the `notice` field**

`lib/features/weather_forecast/presentation/blocs/weather_forecast_state.dart` — add before `WeatherLoaded`:

```dart
enum WeatherNotice { none, cachedData, refreshError }
```

And replace the `WeatherLoaded` class body:

```dart
class WeatherLoaded extends WeatherForecastState {
  final WeatherResult result;
  final SettingEntity settings;
  @override
  final bool isFetching;
  final WeatherNotice notice;

  const WeatherLoaded(
    this.result, {
    this.isFetching = false,
    required this.settings,
    this.notice = WeatherNotice.none,
  });

  WeatherLoaded copyWith({
    WeatherResult? result,
    SettingEntity? settings,
    bool? isFetching,
    WeatherNotice? notice,
  }) {
    return WeatherLoaded(
      result ?? this.result,
      isFetching: isFetching ?? this.isFetching,
      settings: settings ?? this.settings,
      notice: notice ?? this.notice,
    );
  }

  @override
  List<Object?> get props => [result, settings, isFetching, notice];
}
```

- [ ] **Step 4: Implement the bloc emission rules**

`lib/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart`:

- `_onFetchWeather` offline short-circuit — cached branch (currently `emit(WeatherLoaded(cached, settings: settings));`):

```dart
    if (!online) {
      if (cached != null) {
        emit(WeatherLoaded(
          cached,
          settings: settings,
          notice: WeatherNotice.cachedData,
        ));
      } else {
        emit(WeatherEmpty(settings: settings));
      }
      return;
    }
```

- `_onFetchWeather` DioException catch — cached branch (currently `emit(WeatherLoaded(cached, settings: settings));`):

```dart
      if (cached != null) {
        emit(WeatherLoaded(
          cached,
          settings: settings,
          notice: WeatherNotice.cachedData,
        ));
      } else {
        emit(WeatherError(errorCode: code));
      }
```

- `_onFetchWeather` generic catch — cached branch: same change (emit `WeatherLoaded(cached, settings: settings, notice: WeatherNotice.cachedData)`).

- `_onRefreshWeather` DioException catch — loaded branch (currently `emit(loaded.copyWith(isFetching: false));`):

```dart
      if (state case WeatherLoaded loaded) {
        emit(loaded.copyWith(
          isFetching: false,
          notice: WeatherNotice.refreshError,
        ));
      } else {
        emit(WeatherEmpty(settings: currentSettings));
      }
```

- `_onRefreshWeather` generic catch — loaded branch: same change (`notice: WeatherNotice.refreshError`).

- `_onApplySettings` — no change needed: the existing `WeatherLoaded(result, isFetching: isFetching, settings: event.settings)` construction already defaults `notice` to `WeatherNotice.none`, resetting any prior notice.

- `_onFetchWeather` / `_onRefreshWeather` intermediate loading emissions already construct `WeatherLoaded(..., isFetching: true, ...)` without a notice → defaults to `none`.

- [ ] **Step 5: Run the bloc tests to verify they pass**

Run: `flutter test test/features/weather_forecast/presentation/blocs/weather_forecast_bloc_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/weather_forecast/presentation/blocs/weather_forecast_state.dart lib/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart test/features/weather_forecast/presentation/blocs/weather_forecast_bloc_test.dart
git commit -m "feat(weather): signal cached-data and refresh-error notices from bloc"
```

---

### Task 4: Localization — `weatherRefreshErrorMessage`

**Files:**
- Modify: `lib/core/l10n/arb/intl_en.arb`
- Modify: `lib/core/l10n/arb/intl_fr.arb`
- Modify: `lib/core/l10n/arb/intl_es.arb`
- Modify: `lib/core/l10n/arb/intl_ar.arb`
- Generated: `lib/core/l10n/app_localisation*.dart` (via `flutter gen-l10n`)

**Interfaces:**
- Produces: `AppLocalisation.weatherRefreshErrorMessage` getter on the generated class.
- Consumes: nothing.

- [ ] **Step 1: Add the key to the English template**

`lib/core/l10n/arb/intl_en.arb` — insert right after the `weatherCachedDataMessage` block (after its `@weatherCachedDataMessage` metadata entry):

```json
  "weatherRefreshErrorMessage": "Network error. Please try again later.",
  "@weatherRefreshErrorMessage": {
    "description": "Shown when a manual weather refresh fails while existing data stays on screen."
  },
```

- [ ] **Step 2: Add the key to the French, Spanish and Arabic files**

Same insertion point (after the `@weatherCachedDataMessage` block) in each file:

`intl_fr.arb`:

```json
  "weatherRefreshErrorMessage": "Erreur réseau. Veuillez réessayer plus tard.",
  "@weatherRefreshErrorMessage": {
    "description": "Shown when a manual weather refresh fails while existing data stays on screen."
  },
```

`intl_es.arb`:

```json
  "weatherRefreshErrorMessage": "Error de red. Inténtelo de nuevo más tarde.",
  "@weatherRefreshErrorMessage": {
    "description": "Shown when a manual weather refresh fails while existing data stays on screen."
  },
```

`intl_ar.arb`:

```json
  "weatherRefreshErrorMessage": "خطأ في الشبكة. يرجى المحاولة لاحقًا.",
  "@weatherRefreshErrorMessage": {
    "description": "Shown when a manual weather refresh fails while existing data stays on screen."
  },
```

- [ ] **Step 3: Regenerate the localizations**

Run: `flutter gen-l10n`
Expected: `lib/core/l10n/app_localisation.dart` and the four locale implementations gain the `weatherRefreshErrorMessage` getter.

- [ ] **Step 4: Verify no analysis issues and commit**

Run: `flutter analyze`
Expected: no issues.

```bash
git add lib/core/l10n/arb lib/core/l10n/app_localisation.dart lib/core/l10n/app_localisation_ar.dart lib/core/l10n/app_localisation_en.dart lib/core/l10n/app_localisation_es.dart lib/core/l10n/app_localisation_fr.dart
git commit -m "feat(l10n): add weather refresh error message"
```

---

### Task 5: Presentation — feedback helper + weather screen listener + screen tests

**Files:**
- Modify: `lib/features/weather_forecast/presentation/utils/cached_weather_feedback.dart`
- Modify: `lib/features/weather_forecast/presentation/screens/weather_screen.dart`
- Test: `test/features/weather_forecast/presentation/screens/weather_screen_test.dart`
- Test: `test/features/weather_forecast/presentation/utils/cached_weather_feedback_test.dart`

**Interfaces:**
- Consumes: `WeatherNotice` enum and `WeatherLoaded.notice` (Task 3), `AppLocalisation.weatherRefreshErrorMessage` (Task 4).
- Produces:
  - `void showRefreshErrorSnackBar(BuildContext context)` in `cached_weather_feedback.dart`.

- [ ] **Step 1: Add the refresh-error helper**

`lib/features/weather_forecast/presentation/utils/cached_weather_feedback.dart` — append after `showCachedWeatherSnackBar`:

```dart
void showRefreshErrorSnackBar(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalisation.of(context)!;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(content: Text(l10n.weatherRefreshErrorMessage)),
  );
}
```

- [ ] **Step 2: Add the helper test**

`test/features/weather_forecast/presentation/utils/cached_weather_feedback_test.dart` — mirror the existing cached-message test structure. Add a new group:

```dart
  group('showRefreshErrorSnackBar', () {
    testWidgets('shows the localized refresh-error message with no action',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalisation.localizationsDelegates,
          supportedLocales: AppLocalisation.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showRefreshErrorSnackBar(context),
                  child: const Text('trigger'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('trigger'));
      await tester.pump();

      expect(find.text('Network error. Please try again later.'), findsOneWidget);
      expect(find.byType(SnackBarAction), findsNothing);
    });
  });
```

Keep the existing `showCachedWeatherSnackBar` tests unchanged.

- [ ] **Step 3: Rewrite the cached-data detection in the weather screen**

`lib/features/weather_forecast/presentation/screens/weather_screen.dart`:

1. Remove the `_showsCachedData` predicate (currently at lines 34-35).

2. `initState` post-frame — replace:

```dart
      if (_showsCachedData(weatherState)) {
        showCachedWeatherSnackBar(context);
      }
```

with:

```dart
      if (weatherState is WeatherLoaded &&
          weatherState.notice == WeatherNotice.cachedData) {
        showCachedWeatherSnackBar(context);
      }
```

3. Replace the dedicated cached-data `BlocListener<WeatherForecastBloc>` (currently at weather_screen.dart:111-124, including its `listenWhen`) with:

```dart
          listenWhen: (previous, current) =>
              current is WeatherLoaded &&
              current.notice != WeatherNotice.none &&
              (previous is! WeatherLoaded ||
                  previous.notice != current.notice),
          listener: (context, state) {
            switch (state.notice) {
              case WeatherNotice.cachedData:
                showCachedWeatherSnackBar(context);
              case WeatherNotice.refreshError:
                showRefreshErrorSnackBar(context);
              case WeatherNotice.none:
                break;
            }
          },
```

The child `BlocListener` (empty-state) and `BlocBuilder` structure stays as-is.

- [ ] **Step 4: Update the weather screen tests**

In `test/features/weather_forecast/presentation/screens/weather_screen_test.dart`:

1. The `setUp` stub (line 149) already has coordinates from Task 2 (`loadCachedWeather` with `any(named: 'latitude')` / `any(named: 'longitude')`).

2. Replace the test *"shows cached-data snackbar again when refresh fails on cached data"* (currently at line 886) with:

```dart
  testWidgets('shows network-error snackbar when refresh fails on cached data',
      (tester) async {
    when(() => mockRepository.loadCachedWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    )).thenAnswer((_) async => buildCachedWeatherResult());
    when(() => mockRepository.fetchWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    )).thenThrow(DioException(
      requestOptions: RequestOptions(path: ''),
      type: DioExceptionType.connectionError,
    ));

    final bloc = WeatherForecastBloc(
      logger: MockAppLogger(),
      weatherRepository: mockRepository,
      getSettings: mockGetSettings,
      isConnected: () async => false,
    );
    bloc.add(const FetchWeatherEvent());
    await tester.pumpWidget(createTestScreen(bloc));
    await tester.pumpAndSettle();
    expect(
      find.text('No internet connection. Showing cached data.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(
      find.text('No internet connection. Showing cached data.'),
      findsNothing,
    );

    bloc.add(const RefreshWeatherEvent());
    await tester.pumpAndSettle();
    expect(
      find.text('Network error. Please try again later.'),
      findsOneWidget,
    );
    expect(
      find.text('No internet connection. Showing cached data.'),
      findsNothing,
    );
  });
```

3. Add a new test after it (still within the snackbar group):

```dart
  testWidgets('shows cached-data snackbar when loading another city offline',
      (tester) async {
    when(() => mockRepository.loadCachedWeather(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
    )).thenAnswer((_) async => buildCachedWeatherResult());

    final locationRepo = MockLocationRepository();
    when(() => locationRepo.saveLastLocation(any())).thenAnswer((_) async {});
    when(() => locationRepo.loadFavorites()).thenReturn([]);
    final locationBloc = LocationBloc(
      logger: MockAppLogger(),
      repository: locationRepo,
    );

    final bloc = WeatherForecastBloc(
      logger: MockAppLogger(),
      weatherRepository: mockRepository,
      getSettings: mockGetSettings,
      isConnected: () async => false,
    );
    bloc.add(const FetchWeatherEvent());
    await tester.pumpWidget(createTestScreen(bloc, locationBloc: locationBloc));
    await tester.pumpAndSettle();
    expect(
      find.text('No internet connection. Showing cached data.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(
      find.text('No internet connection. Showing cached data.'),
      findsNothing,
    );

    locationBloc.add(const SelectLocationEvent(location: paris));
    await tester.pumpAndSettle();
    expect(
      find.text('No internet connection. Showing cached data.'),
      findsOneWidget,
    );
  });
```

The other existing snackbar tests (*"shows cached-data snackbar when offline with cached weather"*, *"shows cached-data snackbar localized in French"*, *"does not show cached-data snackbar when weather is fresh"*, *"does not re-show cached-data snackbar on settings change"*) keep their existing assertions and pass unchanged.

- [ ] **Step 5: Run the affected tests**

Run: `flutter test test/features/weather_forecast/presentation/screens/weather_screen_test.dart test/features/weather_forecast/presentation/utils/cached_weather_feedback_test.dart`
Expected: PASS.

- [ ] **Step 6: Run full analysis and full suite**

Run: `flutter analyze` then `flutter test`
Expected: no issues; all tests green.

- [ ] **Step 7: Commit**

```bash
git add lib/features/weather_forecast/presentation/utils/cached_weather_feedback.dart lib/features/weather_forecast/presentation/screens/weather_screen.dart test/features/weather_forecast/presentation/screens/weather_screen_test.dart test/features/weather_forecast/presentation/utils/cached_weather_feedback_test.dart
git commit -m "fix(weather): show network-error snackbar on failed refresh, cache notice on loads"
```

---

## Self-Review

**Spec coverage:**
- Per-city cache: Tasks 1-2.
- `WeatherNotice` signal: Task 3.
- l10n `weatherRefreshErrorMessage`: Task 4.
- Screen listener + helpers: Task 5.
- Tests for DbHelper, repository, bloc, screen, feedback helper: Tasks 1-5.
- `_onApplySettings` reset, `_onRefreshWeather` kept-data behavior: Task 3.
- No changes to `WeatherEmpty`/`WeatherError`/`WeatherStateX`/fetch contract: respected.

**Placeholder scan:** every code step carries concrete, complete code or an exact anchor (file:line) and expected result.

**Type consistency:** `WeatherNotice` (`none | cachedData | refreshError`), `showRefreshErrorSnackBar(BuildContext)`, `loadCachedWeather({required double latitude, required double longitude})`, `saveWeather(WeatherModel, {required double latitude, required double longitude})` are used consistently across all tasks.
