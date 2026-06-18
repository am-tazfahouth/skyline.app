# Weather Offline Cache — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist the last successful weather API response via ObjectBox so the UI shows cached data when offline, with an `isCached` indicator in the BLoC state.

**Architecture:** JSON-in-ObjectBox approach — single `WeatherCacheEntity` with id=1 + serialized JSON string. Repository catches `NetworkFailure`, falls back to `DbHelper.loadWeather()`, returns `WeatherResult` with `isCached: true`. A static `InjectionContainer` centralizes DI.

**Tech Stack:** ObjectBox 5.x, flutter_bloc 9.x, equatable, dio

---

### Task 1: Create DbHelper + WeatherCacheEntity

**Files:**
- Create: `lib/core/config/db_helper/weather_cache_entity.dart`
- Create: `lib/core/config/db_helper/db_helper.dart`
- Create: `test/core/config/db_helper/db_helper_test.dart`

- [ ] **Step 1: Write WeatherCacheEntity**

```dart
import 'package:objectbox/objectbox.dart';

@Entity()
class WeatherCacheEntity {
  @Id()
  int id;
  String jsonData;

  WeatherCacheEntity({required this.id, required this.jsonData});
}
```

- [ ] **Step 2: Write the failing test for DbHelper**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/core/config/db_helper/db_helper.dart';
import 'package:sky_line/features/weather_forecast/data/models/weather_model.dart';
import 'package:sky_line/features/weather_forecast/data/models/current_weather_model.dart';
import 'package:sky_line/features/weather_forecast/data/models/hourly_weather_model.dart';
import 'package:sky_line/features/weather_forecast/data/models/daily_weather_model.dart';

void main() {
  late DbHelper dbHelper;

  setUp(() async {
    dbHelper = await DbHelper.init();
  });

  tearDown(() {
    dbHelper.dispose();
  });

  group('DbHelper', () {
    test('saveWeather and loadWeather roundtrip', () {
      final model = WeatherModel(
        current: CurrentWeatherModel(
          temperature: 22.5, humidity: 65, isDay: true,
          windSpeed: 12.0, precipitation: 0.0, weatherCode: 0,
        ),
        hourly: [HourlyWeatherModel(
          time: DateTime(2026, 6, 17, 10), temperature: 22.5,
          precipitationProbability: 10, weatherCode: 0,
        )],
        daily: [DailyWeatherModel(
          date: DateTime(2026, 6, 17), tempMax: 25.0, tempMin: 18.0,
          weatherCode: 0, sunrise: DateTime(2026, 6, 17, 6),
          sunset: DateTime(2026, 6, 17, 20),
        )],
      );

      dbHelper.saveWeather(model);
      final loaded = dbHelper.loadWeather();

      expect(loaded, isNotNull);
      expect(loaded!.current.temperature, 22.5);
      expect(loaded.hourly.length, 1);
      expect(loaded.daily.length, 1);
    });

    test('loadWeather returns null when empty', () {
      final loaded = dbHelper.loadWeather();
      expect(loaded, isNull);
    });
  });
}
```

- [ ] **Step 3: Write DbHelper implementation**

```dart
import 'dart:convert';
import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sky_line/core/config/db_helper/weather_cache_entity.dart';
import 'package:sky_line/features/weather_forecast/data/models/weather_model.dart';

class DbHelper {
  static DbHelper? _instance;
  late final Store _store;
  late final Box<WeatherCacheEntity> _box;

  DbHelper._(this._store) : _box = Box<WeatherCacheEntity>(_store);

  static Future<DbHelper> init({String? directory}) async {
    if (_instance != null) return _instance!;
    final dir = directory ?? (await getApplicationDocumentsDirectory()).path;
    final store = await openStore(directory: '$dir/objectbox');
    _instance = DbHelper._(store);
    return _instance!;
  }

  void saveWeather(WeatherModel model) {
    final jsonStr = jsonEncode(model.toJson());
    _box.put(WeatherCacheEntity(id: 1, jsonData: jsonStr));
  }

  WeatherModel? loadWeather() {
    final entity = _box.get(1);
    if (entity == null) return null;
    final json = jsonDecode(entity.jsonData) as Map<String, dynamic>;
    return WeatherModel.fromCacheJson(json);
  }

  void dispose() {
    _store.close();
    _instance = null;
  }
}
```

Run: `flutter test test/core/config/db_helper/db_helper_test.dart`

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/config/db_helper/db_helper_test.dart`

- [ ] **Step 5: Commit**

```bash
git add lib/core/config/db_helper/ test/core/config/db_helper/
git commit -m "feat(core): add ObjectBox DbHelper for weather cache"
```

---

### Task 2: Add WeatherResult domain entity

**Files:**
- Create: `lib/features/weather_forecast/domain/entities/weather_result.dart`

- [ ] **Step 1: Write the implementation**

```dart
import 'package:equatable/equatable.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/weather_entity.dart';

class WeatherResult extends Equatable {
  final WeatherEntity weather;
  final bool isCached;

  const WeatherResult({required this.weather, required this.isCached});

  WeatherResult copyWith({WeatherEntity? weather, bool? isCached}) {
    return WeatherResult(
      weather: weather ?? this.weather,
      isCached: isCached ?? this.isCached,
    );
  }

  @override
  List<Object?> get props => [weather, isCached];
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/weather_forecast/domain/entities/weather_result.dart
git commit -m "feat(domain): add WeatherResult with isCached flag"
```

---

### Task 3: Update WeatherModel with fromCacheJson + WeatherMapper returns WeatherModel

**Files:**
- Modify: `lib/features/weather_forecast/data/models/weather_model.dart`
- Modify: `lib/features/weather_forecast/data/weather_mapper.dart`

- [ ] **Step 1: Add fromCacheJson factory to WeatherModel**

```dart
factory WeatherModel.fromCacheJson(Map<String, dynamic> json) {
  return WeatherModel(
    current: CurrentWeatherModel.fromJson(json['current'] as Map<String, dynamic>),
    hourly: (json['hourly'] as List<dynamic>)
        .map((e) => HourlyWeatherModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    daily: (json['daily'] as List<dynamic>)
        .map((e) => DailyWeatherModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
```

- [ ] **Step 2: Change WeatherMapper.fromJson to return WeatherModel**

- [ ] **Step 3: Run existing tests to verify no regression**

Run: `flutter test`

- [ ] **Step 4: Commit**

```bash
git add lib/features/weather_forecast/data/models/weather_model.dart lib/features/weather_forecast/data/weather_mapper.dart
git commit -m "feat(data): add WeatherModel.fromCacheJson, WeatherMapper returns WeatherModel"
```

---

### Task 4: Update repository contract + use case to return WeatherResult

**Files:**
- Modify: `lib/features/weather_forecast/domain/repositories/weather_repository.dart`
- Modify: `lib/features/weather_forecast/domain/usecases/fetch_weather_usecase.dart`

- [ ] **Step 1: Update WeatherRepository interface**

```dart
import 'package:sky_line/features/weather_forecast/domain/entities/weather_result.dart';

abstract class WeatherRepository {
  Future<WeatherResult> fetchWeather();
}
```

- [ ] **Step 2: Update FetchWeatherUseCase**

```dart
import 'package:sky_line/features/weather_forecast/domain/entities/weather_result.dart';

class FetchWeatherUseCase {
  final WeatherRepository _repository;

  FetchWeatherUseCase(this._repository);

  Future<WeatherResult> call() {
    return _repository.fetchWeather();
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/weather_forecast/domain/repositories/weather_repository.dart lib/features/weather_forecast/domain/usecases/fetch_weather_usecase.dart
git commit -m "feat(domain): update repository + use case to return WeatherResult"
```

---

### Task 5: Implement WeatherRepositoryImpl with cache fallback

**Files:**
- Modify: `lib/features/weather_forecast/data/repositories/weather_repository_impl.dart`
- Test: `test/features/weather_forecast/data/repositories/weather_repository_impl_test.dart`

- [ ] **Step 1: Write failing test for cache fallback**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/errors/failure.dart';
import 'package:sky_line/core/config/db_helper/db_helper.dart';
import 'package:sky_line/features/weather_forecast/data/repositories/weather_repository_impl.dart';
import 'package:sky_line/features/weather_forecast/data/sources/weather_remote_source.dart';
import 'package:sky_line/features/weather_forecast/data/models/weather_model.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/weather_result.dart';

class MockRemoteSource extends Mock implements WeatherRemoteSource {}
class MockDbHelper extends Mock implements DbHelper {}

void main() {
  late WeatherRepositoryImpl repository;
  late MockRemoteSource mockRemote;
  late MockDbHelper mockDb;

  setUp(() {
    mockRemote = MockRemoteSource();
    mockDb = MockDbHelper();
    repository = WeatherRepositoryImpl(mockRemote, mockDb);
  });

  group('fetchWeather', () {
    test('returns fresh data on success', () async {
      when(mockRemote.fetchWeather).thenReturn({'current': {}, 'hourly': {}, 'daily': {}});
      when(mockDb.saveWeather).thenReturn(null);

      final result = await repository.fetchWeather();

      expect(result, isA<WeatherResult>());
      expect(result.isCached, false);
    });

    test('returns cached data on NetworkFailure', () async {
      when(mockRemote.fetchWeather).thenThrow(NetworkFailure('no net', StackTrace.empty));
      when(mockDb.loadWeather).thenReturn(WeatherModel(
        current: mockCurrentModel(), hourly: [], daily: [],
      ));

      final result = await repository.fetchWeather();

      expect(result.isCached, true);
    });

    test('rethrows NetworkFailure when cache is empty', () async {
      when(mockRemote.fetchWeather).thenThrow(NetworkFailure('no net', StackTrace.empty));
      when(mockDb.loadWeather).thenReturn(null);

      expect(() => repository.fetchWeather(), throwsA(isA<NetworkFailure>()));
    });
  });
}
```

- [ ] **Step 2: Write implementation**

```dart
import 'package:sky_line/core/config/db_helper/db_helper.dart';
import 'package:sky_line/core/errors/failure.dart';
import 'package:sky_line/features/weather_forecast/data/sources/weather_remote_source.dart';
import 'package:sky_line/features/weather_forecast/data/weather_mapper.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/weather_result.dart';
import 'package:sky_line/features/weather_forecast/domain/repositories/weather_repository.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherRemoteSource _remoteSource;
  final DbHelper _dbHelper;

  WeatherRepositoryImpl(this._remoteSource, this._dbHelper);

  @override
  Future<WeatherResult> fetchWeather() async {
    try {
      final json = await _remoteSource.fetchWeather();
      final model = WeatherMapper.fromJson(json);
      _dbHelper.saveWeather(model);
      return WeatherResult(weather: model.toEntity(), isCached: false);
    } on NetworkFailure {
      final cached = _dbHelper.loadWeather();
      if (cached != null) {
        return WeatherResult(weather: cached.toEntity(), isCached: true);
      }
      rethrow;
    } on Failure {
      rethrow;
    } catch (e, s) {
      throw ParsingFailure('Failed to parse weather data: $e', s);
    }
  }
}
```

Run: `flutter test test/features/weather_forecast/data/repositories/weather_repository_impl_test.dart`

- [ ] **Step 3: Commit**

```bash
git add lib/features/weather_forecast/data/repositories/weather_repository_impl.dart test/features/weather_forecast/data/repositories/
git commit -m "feat(data): add cache fallback to WeatherRepositoryImpl"
```

---

### Task 6: Update BLoC state + integrate WeatherResult

**Files:**
- Modify: `lib/features/weather_forecast/presentation/blocs/weather_forecast_state.dart`
- Modify: `lib/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart`

- [ ] **Step 1: Update WeatherLoaded state**

```dart
class WeatherLoaded extends WeatherForecastState {
  final WeatherResult result;
  bool get isCached => result.isCached;

  const WeatherLoaded(this.result);

  @override
  List<Object?> get props => [result];
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/weather_forecast/presentation/blocs/weather_forecast_state.dart
git commit -m "feat(presentation): WeatherLoaded holds WeatherResult with isCached"
```

---

### Task 7: Create InjectionContainer + update main.dart

**Files:**
- Create: `lib/injection_container.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Write InjectionContainer**

```dart
import 'package:dio/dio.dart';
import 'package:sky_line/core/config/db_helper/db_helper.dart';
import 'package:sky_line/features/weather_forecast/data/repositories/weather_repository_impl.dart';
import 'package:sky_line/features/weather_forecast/data/sources/weather_remote_source.dart';
import 'package:sky_line/features/weather_forecast/domain/usecases/fetch_weather_usecase.dart';

class InjectionContainer {
  static late final Dio dio;
  static late final DbHelper dbHelper;
  static late final WeatherRemoteSource weatherRemoteSource;
  static late final WeatherRepositoryImpl weatherRepository;
  static late final FetchWeatherUseCase fetchWeatherUseCase;

  static Future<void> init() async {
    dbHelper = await DbHelper.init();
    dio = Dio();
    weatherRemoteSource = WeatherRemoteSource(dio);
    weatherRepository = WeatherRepositoryImpl(weatherRemoteSource, dbHelper);
    fetchWeatherUseCase = FetchWeatherUseCase(weatherRepository);
  }

  static void dispose() {
    dbHelper.dispose();
  }
}
```

- [ ] **Step 2: Update main.dart**

```dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/enums/setting_theme.dart';
import 'package:sky_line/core/utils/platform_utils.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_event.dart';
import 'package:sky_line/features/weather_forecast/presentation/screens/weather_screen.dart';
import 'package:sky_line/injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await InjectionContainer.init();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => WeatherForecastBloc(
            InjectionContainer.fetchWeatherUseCase,
          )..add(FetchWeatherEvent()),
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
    final appTheme = AppTheme(Theme.of(context).textTheme);

    return AnnotatedRegion(
      value: PlatformUtils.getSystemUiStyle(SettingTheme.system, context),
      child: MaterialApp(
        title: 'SkyLine',
        home: WeatherScreen(),
        theme: appTheme.light(),
        darkTheme: appTheme.dark(),
        debugShowCheckedModeBanner: false,
        themeMode: SettingTheme.getThemeMode(SettingTheme.system),
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/injection_container.dart lib/main.dart
git commit -m "refactor: add InjectionContainer, simplify main.dart"
```

---

### Task 8: Run build_runner + final verification

- [ ] **Step 1: Run ObjectBox code generator**

```bash
dart run build_runner build
```

- [ ] **Step 2: Verify full analysis**

```bash
flutter analyze
```

- [ ] **Step 3: Verify tests pass**

```bash
flutter test
```

- [ ] **Step 4: Commit generated files**

```bash
git add lib/core/config/db_helper/objectbox.g.dart
git commit -m "chore: add ObjectBox generated code"
```

---

### Task 9: Fix failing tests from signature changes

**Files:**
- Modify: `test/features/weather_forecast/data/repositories/weather_repository_impl_test.dart` (existing tests)
- Modify: `test/features/weather_forecast/presentation/blocs/weather_forecast_bloc_test.dart`
- Modify: `test/features/weather_forecast/domain/usecases/fetch_weather_usecase_test.dart`

- [ ] **Step 1: Update existing repository impl test for new signature**

- [ ] **Step 2: Update bloc test for WeatherResult**

- [ ] **Step 3: Update use case test for WeatherResult**

- [ ] **Step 4: Verify all tests pass**

```bash
flutter test
```

- [ ] **Step 5: Commit**

```bash
git add test/
git commit -m "test: update tests for WeatherResult + cache changes"
```
