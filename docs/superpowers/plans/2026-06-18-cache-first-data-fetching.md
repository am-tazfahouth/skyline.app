# Cache-First Data Fetching — Implementation Plan

**Date:** 2026-06-18
**Feature:** weather_forecast
**Status:** Implemented

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the full-screen loading spinner with a cache-first strategy — show cached/empty data immediately, overlay during background refresh.

**Architecture:** BLoC orchestrates a two-step flow: (1) load cache via `WeatherRepository.loadCachedWeather()`, (2) conditionally fetch fresh data based on connectivity. Two events (`FetchWeatherEvent` auto, `RefreshWeatherEvent` pull-to-refresh) control overlay behavior. The `WeatherEmpty` state mirrors `WeatherLoaded`'s visual structure but renders `--` placeholders.

**Tech Stack:** Flutter, flutter_bloc, equatable, mocktail, bloc_test, objectbox

---

## File Structure Map

### Modified files (18):

| # | File | Change |
|---|------|--------|
| 1 | `lib/core/config/db_helper/weather_cache_entity.dart` | Add `savedAt` field |
| 2 | `lib/core/config/db_helper/db_helper.dart` | Add timestamp on save, TTL on load |
| 3 | `lib/features/weather_forecast/domain/repositories/weather_repository.dart` | Add `loadCachedWeather()` |
| 4 | `lib/features/weather_forecast/data/repositories/weather_repository_impl.dart` | New `loadCachedWeather()`, simplified `fetchWeather()` |
| 5 | `lib/injection_container.dart` | Remove `FetchWeatherUseCase`, expose `WeatherRepository` |
| 6 | `lib/main.dart` | BLoC takes `WeatherRepository` instead of `FetchWeatherUseCase` |
| 7 | `lib/features/weather_forecast/presentation/blocs/weather_forecast_state.dart` | `WeatherEmpty`, `isFetching` flag, extension |
| 8 | `lib/features/weather_forecast/presentation/blocs/weather_forecast_event.dart` | `RefreshWeatherEvent` |
| 9 | `lib/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart` | Rewrite both handlers, injectable `isConnected` |
| 10 | `lib/features/weather_forecast/presentation/screens/weather_screen.dart` | `Stack` overlay, `WeatherEmpty` |
| 11 | `lib/features/weather_forecast/presentation/widgets/views/weather_content_view.dart` | `RefreshWeatherEvent` |
| 12 | `lib/features/weather_forecast/presentation/widgets/weather_main_card.dart` | Handle `WeatherEmpty` |
| 13 | `lib/features/weather_forecast/presentation/widgets/weather_stats_card.dart` | Handle `WeatherEmpty` |
| 14 | `lib/features/weather_forecast/presentation/widgets/weather_hourly_tile_list.dart` | Handle `WeatherEmpty` |
| 15 | `lib/features/weather_forecast/presentation/widgets/weather_daily_tile_list.dart` | Handle `WeatherEmpty` |
| 16 | `lib/features/weather_forecast/presentation/widgets/weather_sun_times.dart` | Handle `WeatherEmpty` |
| 17 | `lib/features/weather_forecast/presentation/widgets/views/weather_loading_view.dart` | **Delete** |

### Test files modified (4):

| # | File | Change |
|---|------|--------|
| 18 | `test/core/config/db_helper/db_helper_test.dart` | Add TTL test |
| 19 | `test/features/weather_forecast/data/repositories/weather_repository_impl_test.dart` | Add `loadCachedWeather` tests, remove cache-fallback tests |
| 20 | `test/features/weather_forecast/presentation/blocs/weather_forecast_bloc_test.dart` | Full rewrite for new flow |
| 21 | `test/features/weather_forecast/presentation/screens/weather_screen_test.dart` | `WeatherEmpty` + overlay assertions |

---

### Task 1: Cache Entity — add `savedAt` timestamp

**Files:**
- Modify: `lib/core/config/db_helper/weather_cache_entity.dart`
- Test: `test/core/config/db_helper/db_helper_test.dart`

- [ ] **Step 1: Write failing test for TTL**

```dart
// Append to existing group in db_helper_test.dart

test('loadWeather respects maxAgeMillis', () {
  final model = WeatherModel(
    current: CurrentWeatherModel(
      temperature: 22.5, humidity: 65, isDay: true,
      windSpeed: 12.0, precipitation: 0.0, weatherCode: 0,
    ),
    hourly: [],
    daily: [],
  );

  dbHelper.saveWeather(model);
  // 1ms TTL should expire immediately
  final expired = dbHelper.loadWeather(maxAgeMillis: 1);
  expect(expired, isNull);

  // no TTL should return data
  final fresh = dbHelper.loadWeather();
  expect(fresh, isNotNull);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/config/db_helper/db_helper_test.dart`
Expected: FAIL — `loadWeather` doesn't accept `maxAgeMillis`

- [ ] **Step 3: Update `WeatherCacheEntity`**

```dart
@Entity()
class WeatherCacheEntity {
  @Id()
  int id;
  String jsonData;
  int savedAt;

  WeatherCacheEntity({
    required this.id,
    required this.jsonData,
    required this.savedAt,
  });
}
```

- [ ] **Step 4: Update `DbHelper.saveWeather()`**

```dart
void saveWeather(WeatherModel model) {
  _box.removeAll();
  final jsonStr = jsonEncode(model.toJson());
  _box.put(WeatherCacheEntity(
    id: 0,
    jsonData: jsonStr,
    savedAt: DateTime.now().millisecondsSinceEpoch,
  ));
}
```

- [ ] **Step 5: Update `DbHelper.loadWeather()`**

```dart
WeatherModel? loadWeather({int? maxAgeMillis}) {
  final entities = _box.getAll();
  if (entities.isEmpty) return null;

  final entity = entities.first;
  if (maxAgeMillis != null) {
    final age = DateTime.now().millisecondsSinceEpoch - entity.savedAt;
    if (age > maxAgeMillis) return null;
  }

  final json = jsonDecode(entity.jsonData) as Map<String, dynamic>;
  return WeatherModel.fromCacheJson(json);
}
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/core/config/db_helper/db_helper_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 7: Commit**

```bash
git add lib/core/config/db_helper/weather_cache_entity.dart lib/core/config/db_helper/db_helper.dart test/core/config/db_helper/db_helper_test.dart
git commit -m "feat: add savedAt and TTL support to weather cache"
```

---

### Task 2: Repository — add `loadCachedWeather()`

**Files:**
- Modify: `lib/features/weather_forecast/domain/repositories/weather_repository.dart`
- Modify: `lib/features/weather_forecast/data/repositories/weather_repository_impl.dart`
- Modify: `lib/injection_container.dart`
- Test: `test/features/weather_forecast/data/repositories/weather_repository_impl_test.dart`

- [ ] **Step 1: Write failing tests for `loadCachedWeather()`**

In `weather_repository_impl_test.dart`, add a new group:

```dart
group('loadCachedWeather', () {
  test('returns WeatherResult when cache is fresh', () async {
    when(() => mockDbHelper.loadWeather(
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

    final result = await repository.loadCachedWeather();

    expect(result, isA<WeatherResult>());
    expect(result!.isCached, true);
    expect(result.weather.current.temperature, 26.5);
  });

  test('returns null when cache is empty', () async {
    when(() => mockDbHelper.loadWeather(
      maxAgeMillis: any(named: 'maxAgeMillis'),
    )).thenReturn(null);

    final result = await repository.loadCachedWeather();
    expect(result, isNull);
  });
});
```

Also update the existing `fetchWeather` tests:
- Remove the "returns cached data on NetworkFailure" test (no longer needed — cache is read via `loadCachedWeather` not in `fetchWeather`)
- Keep: "returns WeatherResult on success", "throws ParsingFailure on unexpected error"
- Update the `setUp` — constructor now takes 3 params (add `cacheMaxAgeDays`)

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/weather_forecast/data/repositories/weather_repository_impl_test.dart`
Expected: FAIL — `loadCachedWeather` doesn't exist

- [ ] **Step 3: Update repository interface**

```dart
abstract class WeatherRepository {
  Future<WeatherResult> fetchWeather();
  Future<WeatherResult?> loadCachedWeather();
}
```

- [ ] **Step 4: Update `WeatherRepositoryImpl`**

```dart
class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherRemoteSource _remoteSource;
  final DbHelper _dbHelper;
  final int _cacheMaxAgeDays;

  WeatherRepositoryImpl(this._remoteSource, this._dbHelper, [this._cacheMaxAgeDays = 6]);

  Future<WeatherResult?> loadCachedWeather() async {
    final cached = _dbHelper.loadWeather(
      maxAgeMillis: _cacheMaxAgeDays * 24 * 60 * 60 * 1000,
    );
    if (cached == null) return null;
    return WeatherResult(weather: cached.toEntity(), isCached: true);
  }

  Future<WeatherResult> fetchWeather() async {
    try {
      final json = await _remoteSource.fetchWeather();
      final model = WeatherMapper.fromJson(json);
      _dbHelper.saveWeather(model);
      return WeatherResult(weather: model.toEntity(), isCached: false);
    } on Failure {
      rethrow;
    } catch (e, s) {
      throw ParsingFailure('Failed to parse weather data: $e', s);
    }
  }
}
```

- [ ] **Step 5: Update `InjectionContainer`**

Remove `fetchWeatherUseCase` and `FetchWeatherUseCase` import (the BLoC will use `WeatherRepository` directly). Keep `weatherRepository`:

```dart
import 'package:dio/dio.dart';
import 'package:sky_line/core/config/db_helper/db_helper.dart';
import 'package:sky_line/features/weather_forecast/data/repositories/weather_repository_impl.dart';
import 'package:sky_line/features/weather_forecast/data/sources/weather_remote_source.dart';

class InjectionContainer {
  static late final Dio dio;
  static late final DbHelper dbHelper;
  static late final WeatherRemoteSource weatherRemoteSource;
  static late final WeatherRepositoryImpl weatherRepository;

  static Future<void> init() async {
    dbHelper = await DbHelper.init();
    dio = Dio();
    weatherRemoteSource = WeatherRemoteSource(dio);
    weatherRepository = WeatherRepositoryImpl(weatherRemoteSource, dbHelper);
  }

  static void dispose() {
    dbHelper.dispose();
  }
}
```

The `FetchWeatherUseCase` class can also be deleted since nothing references it anymore (`lib/features/weather_forecast/domain/usecases/fetch_weather_usecase.dart`).

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/features/weather_forecast/data/repositories/weather_repository_impl_test.dart`
Expected: PASS (3 tests remaining: success, cache loaded, cache null, parsing error)

- [ ] **Step 7: Commit**

```bash
git add lib/features/weather_forecast/domain/repositories/weather_repository.dart lib/features/weather_forecast/data/repositories/weather_repository_impl.dart lib/injection_container.dart test/features/weather_forecast/data/repositories/weather_repository_impl_test.dart
git commit -m "feat: add loadCachedWeather to repository with TTL support"
```

---

### Task 3: BLoC State & Events

**Files:**
- Modify: `lib/features/weather_forecast/presentation/blocs/weather_forecast_state.dart`
- Modify: `lib/features/weather_forecast/presentation/blocs/weather_forecast_event.dart`

- [ ] **Step 1: Update `WeatherForecastState`**

```dart
abstract class WeatherForecastState extends Equatable {
  const WeatherForecastState();

  bool get isFetching => false;

  @override
  List<Object?> get props => [];
}

class WeatherInitial extends WeatherForecastState {
  const WeatherInitial();
}

class WeatherLoaded extends WeatherForecastState {
  final WeatherResult result;
  final bool isFetching;

  const WeatherLoaded(this.result, {this.isFetching = false});

  WeatherLoaded copyWith({WeatherResult? result, bool? isFetching}) {
    return WeatherLoaded(
      result ?? this.result,
      isFetching: isFetching ?? this.isFetching,
    );
  }

  @override
  List<Object?> get props => [result, isFetching];
}

class WeatherEmpty extends WeatherForecastState {
  final bool isFetching;

  const WeatherEmpty({this.isFetching = false});

  @override
  List<Object?> get props => [isFetching];
}

class WeatherError extends WeatherForecastState {
  final Failure failure;

  const WeatherError(this.failure);

  @override
  List<Object?> get props => [failure];
}

extension WeatherStateX on WeatherForecastState {
  bool get hasData => this is WeatherLoaded || this is WeatherEmpty;
  bool get hasWeather => this is WeatherLoaded;
  WeatherEntity? get weatherOrNull => switch (this) {
    WeatherLoaded(result: final r) => r.weather,
    _ => null,
  };
}
```

- [ ] **Step 2: Update `WeatherForecastEvent`**

```dart
abstract class WeatherForecastEvent extends Equatable {
  const WeatherForecastEvent();
  @override
  List<Object?> get props => [];
}

class FetchWeatherEvent extends WeatherForecastEvent {
  const FetchWeatherEvent();
}

class RefreshWeatherEvent extends WeatherForecastEvent {
  const RefreshWeatherEvent();
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/weather_forecast/presentation/blocs/weather_forecast_state.dart lib/features/weather_forecast/presentation/blocs/weather_forecast_event.dart
git commit -m "feat: add WeatherEmpty state and RefreshWeatherEvent"
```

---

### Task 4: BLoC Handlers rewrite

**Files:**
- Modify: `lib/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart`
- Test: `test/features/weather_forecast/presentation/blocs/weather_forecast_bloc_test.dart`

- [ ] **Step 1: Write new bloc tests**

Replace the entire test file content with:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/errors/failure.dart';
import 'package:sky_line/core/utils/platform_utils.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/current_weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/daily_weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/hourly_weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/weather_result.dart';
import 'package:sky_line/features/weather_forecast/domain/repositories/weather_repository.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_event.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_state.dart';

class MockWeatherRepository extends Mock implements WeatherRepository {}

void main() {
  late MockWeatherRepository mockRepository;

  setUp(() {
    mockRepository = MockWeatherRepository();
  });

  final testWeather = WeatherEntity(
    current: const CurrentWeatherEntity(
      temperature: 28.0, humidity: 65, isDay: true,
      windSpeed: 12.0, precipitation: 0.0, weatherCode: 51,
    ),
    hourly: [
      HourlyWeatherEntity(
        time: DateTime(2026, 5, 16, 12, 0),
        temperature: 28.0, precipitationProbability: 10, weatherCode: 0,
      ),
    ],
    daily: [
      DailyWeatherEntity(
        date: DateTime(2026, 5, 16),
        tempMax: 29.0, tempMin: 23.0, weatherCode: 51,
        sunrise: DateTime(2026, 5, 16, 3, 16),
        sunset: DateTime(2026, 5, 16, 14, 50),
      ),
    ],
  );

  final cachedResult = WeatherResult(weather: testWeather, isCached: true);
  final freshResult = WeatherResult(weather: testWeather, isCached: false);

  group('FetchWeatherEvent (auto-load)', () {
    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'emits [Loaded(cached)] when cache valid + offline',
      setUp: () {
        when(() => mockRepository.loadCachedWeather()).thenAnswer((_) async => cachedResult);
      },
      build: () => WeatherForecastBloc(mockRepository, isConnected: () async => false),
      act: (bloc) => bloc.add(const FetchWeatherEvent()),
      expect: () => [
        isA<WeatherLoaded>().having((s) => s.result.isCached, 'cached', true),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'emits [Loaded(cached), Loaded(cached, fetching), Loaded(fresh)] when '
      'cache valid + online + fetch succeeds',
      setUp: () {
        when(() => mockRepository.loadCachedWeather()).thenAnswer((_) async => cachedResult);
        when(() => mockRepository.fetchWeather()).thenAnswer((_) async => freshResult);
      },
      build: () => WeatherForecastBloc(mockRepository, isConnected: () async => true),
      act: (bloc) => bloc.add(const FetchWeatherEvent()),
      expect: () => [
        isA<WeatherLoaded>().having((s) => s.result.isCached, 'first cached', true),
        isA<WeatherLoaded>().having((s) => s.isFetching, 'fetching', true),
        isA<WeatherLoaded>().having((s) => s.isFetching, 'done', false)
          .having((s) => s.result.isCached, 'fresh', false),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'emits [Loaded(cached)] → [Loaded(cached)] when cache valid + fetch fails',
      setUp: () {
        when(() => mockRepository.loadCachedWeather()).thenAnswer((_) async => cachedResult);
        when(() => mockRepository.fetchWeather()).thenThrow(const ServerFailure('API down'));
      },
      build: () => WeatherForecastBloc(mockRepository, isConnected: () async => true),
      act: (bloc) => bloc.add(const FetchWeatherEvent()),
      expect: () => [
        isA<WeatherLoaded>().having((s) => s.result.isCached, 'first', true),
        isA<WeatherLoaded>().having((s) => s.isFetching, 'fetching', true),
        isA<WeatherLoaded>().having((s) => s.isFetching, 'back to idle', false),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'emits [Empty(fetching), Loaded] when no cache + online + fetch succeeds',
      setUp: () {
        when(() => mockRepository.loadCachedWeather()).thenAnswer((_) async => null);
        when(() => mockRepository.fetchWeather()).thenAnswer((_) async => freshResult);
      },
      build: () => WeatherForecastBloc(mockRepository, isConnected: () async => true),
      act: (bloc) => bloc.add(const FetchWeatherEvent()),
      expect: () => [
        isA<WeatherEmpty>().having((s) => s.isFetching, 'fetching', true),
        isA<WeatherLoaded>().having((s) => s.isFetching, 'done', false),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'emits [Empty] when no cache + no connectivity',
      setUp: () {
        when(() => mockRepository.loadCachedWeather()).thenAnswer((_) async => null);
      },
      build: () => WeatherForecastBloc(mockRepository, isConnected: () async => false),
      act: (bloc) => bloc.add(const FetchWeatherEvent()),
      expect: () => [
        isA<WeatherEmpty>().having((s) => s.isFetching, 'idle', false),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'emits [Empty(fetching), Error] when no cache + online + fetch fails',
      setUp: () {
        when(() => mockRepository.loadCachedWeather()).thenAnswer((_) async => null);
        when(() => mockRepository.fetchWeather()).thenThrow(const ServerFailure('API down'));
      },
      build: () => WeatherForecastBloc(mockRepository, isConnected: () async => true),
      act: (bloc) => bloc.add(const FetchWeatherEvent()),
      expect: () => [
        isA<WeatherEmpty>().having((s) => s.isFetching, 'fetching', true),
        isA<WeatherError>(),
      ],
    );
  });

  group('RefreshWeatherEvent (pull-to-refresh)', () {
    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'from Loaded → fetch succeeds → Loaded(fresh)',
      seed: () => WeatherLoaded(cachedResult),
      setUp: () {
        when(() => mockRepository.fetchWeather()).thenAnswer((_) async => freshResult);
      },
      build: () => WeatherForecastBloc(mockRepository, isConnected: () async => true),
      act: (bloc) => bloc.add(const RefreshWeatherEvent()),
      expect: () => [
        isA<WeatherLoaded>().having((s) => s.isFetching, 'fetching', true),
        isA<WeatherLoaded>().having((s) => s.isFetching, 'done', false)
          .having((s) => s.result.isCached, 'fresh', false),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'from Loaded → fetch fails → stays Loaded(original)',
      seed: () => WeatherLoaded(cachedResult),
      setUp: () {
        when(() => mockRepository.fetchWeather()).thenThrow(const NetworkFailure('No net'));
      },
      build: () => WeatherForecastBloc(mockRepository, isConnected: () async => true),
      act: (bloc) => bloc.add(const RefreshWeatherEvent()),
      expect: () => [
        isA<WeatherLoaded>().having((s) => s.isFetching, 'fetching', true),
        isA<WeatherLoaded>().having((s) => s.isFetching, 'done', false)
          .having((s) => s.result.isCached, 'still cached', true),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'from Empty → fetch succeeds → Loaded',
      seed: () => const WeatherEmpty(),
      setUp: () {
        when(() => mockRepository.fetchWeather()).thenAnswer((_) async => freshResult);
      },
      build: () => WeatherForecastBloc(mockRepository, isConnected: () async => true),
      act: (bloc) => bloc.add(const RefreshWeatherEvent()),
      expect: () => [
        isA<WeatherEmpty>().having((s) => s.isFetching, 'fetching', true),
        isA<WeatherLoaded>(),
      ],
    );

    blocTest<WeatherForecastBloc, WeatherForecastState>(
      'from Empty → fetch fails → stays Empty',
      seed: () => const WeatherEmpty(),
      setUp: () {
        when(() => mockRepository.fetchWeather()).thenThrow(const NetworkFailure('No net'));
      },
      build: () => WeatherForecastBloc(mockRepository, isConnected: () async => true),
      act: (bloc) => bloc.add(const RefreshWeatherEvent()),
      expect: () => [
        isA<WeatherEmpty>().having((s) => s.isFetching, 'fetching', true),
        isA<WeatherEmpty>().having((s) => s.isFetching, 'idle', false),
      ],
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/weather_forecast/presentation/blocs/weather_forecast_bloc_test.dart`
Expected: FAIL — bloc doesn't compile with new architecture

- [ ] **Step 3: Rewrite BLoC with injectable connectivity**

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/errors/failure.dart';
import 'package:sky_line/core/utils/platform_utils.dart';
import 'package:sky_line/features/weather_forecast/domain/repositories/weather_repository.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_event.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_state.dart';

class WeatherForecastBloc
    extends Bloc<WeatherForecastEvent, WeatherForecastState> {
  final WeatherRepository _repository;
  final Future<bool> Function() _isConnected;

  WeatherForecastBloc(
    this._repository, {
    Future<bool> Function()? isConnected,
  })  : _isConnected = isConnected ?? PlatformUtils.isConnected,
        super(const WeatherInitial()) {
    on<FetchWeatherEvent>(_onFetchWeather);
    on<RefreshWeatherEvent>(_onRefreshWeather);
  }

  Future<void> _onFetchWeather(
    FetchWeatherEvent event,
    Emitter<WeatherForecastState> emit,
  ) async {
    final cached = await _repository.loadCachedWeather();
    final connected = await _isConnected();

    if (cached != null) {
      if (connected) {
        emit(WeatherLoaded(cached));
        emit(WeatherLoaded(cached, isFetching: true));
        try {
          final fresh = await _repository.fetchWeather();
          emit(WeatherLoaded(fresh, isFetching: false));
        } on Failure {
          emit(WeatherLoaded(cached, isFetching: false));
        }
      } else {
        emit(WeatherLoaded(cached, isFetching: false));
      }
    } else if (connected) {
      emit(const WeatherEmpty(isFetching: true));
      try {
        final fresh = await _repository.fetchWeather();
        emit(WeatherLoaded(fresh, isFetching: false));
      } on Failure catch (f) {
        emit(WeatherError(f));
      }
    } else {
      emit(const WeatherEmpty(isFetching: false));
    }
  }

  Future<void> _onRefreshWeather(
    RefreshWeatherEvent event,
    Emitter<WeatherForecastState> emit,
  ) async {
    final currentState = state;

    if (currentState is WeatherLoaded) {
      emit(WeatherLoaded(currentState.result, isFetching: true));
      try {
        final fresh = await _repository.fetchWeather();
        emit(WeatherLoaded(fresh, isFetching: false));
      } on Failure {
        emit(WeatherLoaded(currentState.result, isFetching: false));
      }
    } else if (currentState is WeatherEmpty) {
      emit(const WeatherEmpty(isFetching: true));
      try {
        final fresh = await _repository.fetchWeather();
        emit(WeatherLoaded(fresh, isFetching: false));
      } on Failure {
        emit(const WeatherEmpty(isFetching: false));
      }
    } else {
      await _onFetchWeather(const FetchWeatherEvent(), emit);
    }
  }
}
```

- [ ] **Step 4: Update `main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
            InjectionContainer.weatherRepository,
          )..add(const FetchWeatherEvent()),
        ),
      ],
      child: MyApp(),
    ),
  );
}
```

- [ ] **Step 5: Find and remove `WeatherLoading` + `FetchWeatherUseCase` references**

Search for `WeatherLoading` in the entire codebase — remove all references.
Search for `FetchWeatherUseCase` — remove file + test:

```bash
rm lib/features/weather_forecast/domain/usecases/fetch_weather_usecase.dart
rm test/features/weather_forecast/domain/usecases/fetch_weather_usecase_test.dart
```

- [ ] **Step 6: Delete `weather_loading_view.dart`**

```bash
rm lib/features/weather_forecast/presentation/widgets/views/weather_loading_view.dart
```

- [ ] **Step 4: Find and remove `WeatherLoading` imports**

Search for `WeatherLoading` in the entire codebase and remove all references (the screen, bloc, tests).

- [ ] **Step 5: Delete `weather_loading_view.dart`**

```bash
rm lib/features/weather_forecast/presentation/widgets/views/weather_loading_view.dart
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/features/weather_forecast/presentation/blocs/weather_forecast_bloc_test.dart`
Expected: PASS (10 tests)

- [ ] **Step 7: Commit**

```bash
git add lib/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart test/features/weather_forecast/presentation/blocs/weather_forecast_bloc_test.dart lib/main.dart
git rm lib/features/weather_forecast/presentation/widgets/views/weather_loading_view.dart lib/features/weather_forecast/domain/usecases/fetch_weather_usecase.dart test/features/weather_forecast/domain/usecases/fetch_weather_usecase_test.dart
git commit -m "feat: rewrite BLoC with cache-first flow and RefreshWeatherEvent"
```

---

### Task 5: WeatherScreen — overlay and WeatherEmpty support

**Files:**
- Modify: `lib/features/weather_forecast/presentation/screens/weather_screen.dart`
- Modify: `test/features/weather_forecast/presentation/screens/weather_screen_test.dart`

- [ ] **Step 1: Write failing screen tests**

```dart
// In the test file, change MockFetchWeatherUseCase to MockWeatherRepository:
class MockWeatherRepository extends Mock implements WeatherRepository {}

// Rewrite setUp to use MockWeatherRepository:
late MockWeatherRepository mockRepository;

setUp(() {
  mockRepository = MockWeatherRepository();
});

// Add new tests:

testWidgets('shows overlay when isFetching is true', (tester) async {
  final bloc = WeatherForecastBloc(mockRepository, isConnected: () async => true);
  bloc.emit(WeatherLoaded(
    WeatherResult(weather: testWeather, isCached: true),
    isFetching: true,
  ));
  await tester.pumpWidget(createTestScreen(bloc));

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});

testWidgets('shows empty structure with -- when WeatherEmpty', (tester) async {
  final bloc = WeatherForecastBloc(mockRepository, isConnected: () async => true);
  bloc.emit(const WeatherEmpty());
  await tester.pumpWidget(createTestScreen(bloc));

  expect(find.byType(CircularProgressIndicator), findsNothing);
  expect(find.byType(RefreshIndicator), findsOneWidget);
});
```

- [ ] **Step 2: Update `WeatherScreen`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_state.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/views/weather_content_view.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/views/weather_error_view.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/views/weather_initial_view.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeatherForecastBloc, WeatherForecastState>(
      builder: (context, state) => Stack(
        children: [
          switch (state) {
            WeatherInitial() => const WeatherInitialView(),
            WeatherLoaded() || WeatherEmpty() => const WeatherContentView(),
            WeatherError(failure: final f) => WeatherErrorView(message: f.message),
            _ => const WeatherInitialView(),
          },
          if (state.isFetching)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Run tests to verify they pass**

Run: `flutter test test/features/weather_forecast/presentation/screens/weather_screen_test.dart`
Expected: PASS (update any existing tests that referenced `WeatherLoadingView`)

- [ ] **Step 4: Commit**

```bash
git add lib/features/weather_forecast/presentation/screens/weather_screen.dart test/features/weather_forecast/presentation/screens/weather_screen_test.dart
git commit -m "feat: add loading overlay and WeatherEmpty support to WeatherScreen"
```

---

### Task 6: Content View — use RefreshWeatherEvent

**Files:**
- Modify: `lib/features/weather_forecast/presentation/widgets/views/weather_content_view.dart`

- [ ] **Step 1: Update `WeatherContentView`**

Change `FetchWeatherEvent` → `RefreshWeatherEvent` in the pull-to-refresh handler, and update the awaited stream to also match `WeatherEmpty`:

```dart
RefreshIndicator(
  onRefresh: () async {
    context.read<WeatherForecastBloc>().add(const RefreshWeatherEvent());
    await context.read<WeatherForecastBloc>().stream.firstWhere(
      (s) => s is WeatherLoaded || s is WeatherEmpty || s is WeatherError,
    );
  },
  child: SafeArea(
    // ... rest unchanged
  ),
)
```

That's the only change in this file.

- [ ] **Step 2: Commit**

```bash
git add lib/features/weather_forecast/presentation/widgets/views/weather_content_view.dart
git commit -m "feat: use RefreshWeatherEvent for pull-to-refresh"
```

---

### Task 7: Data Widgets — handle WeatherEmpty

**Files:**
- Modify: `lib/features/weather_forecast/presentation/widgets/weather_main_card.dart`
- Modify: `lib/features/weather_forecast/presentation/widgets/weather_stats_card.dart`
- Modify: `lib/features/weather_forecast/presentation/widgets/weather_hourly_tile_list.dart`
- Modify: `lib/features/weather_forecast/presentation/widgets/weather_daily_tile_list.dart`
- Modify: `lib/features/weather_forecast/presentation/widgets/weather_sun_times.dart`

For each widget, apply the same two changes:

1. Change the guard from `state is! WeatherLoaded` → `!state.hasData`
2. Replace direct `state.result.weather` access → `state.weatherOrNull?.current?.xxx ?? '--'`

- [ ] **Step 1: Update `WeatherMainCard`**

```dart
// Inside BlocBuilder:
if (!state.hasData) return const SizedBox.shrink();

final surface = AppTheme.surfaceFor(Theme.of(context).brightness);
final cardColor = surface.colorContainer;
final primaryText = surface.onColor;
final secondaryText = surface.onColorContainer;

final weather = state.weatherOrNull;
final current = weather?.current;
final date = current != null ? WeatherFormat.date(DateTime.now()) : '--';
final condition = current != null ? WeatherFormat.condition(current.weatherCode) : '--';
final temperature = current != null ? WeatherFormat.temperature(current.temperature) : '--';

// ... widget uses these variables instead of inline state access
// Change the Icon condition too:
Icon(
  current != null
    ? WeatherIconMapper.fromWeatherCode(current.weatherCode, isDay: current.isDay)
    : Icons.cloud_off_rounded,
  color: primaryText,
  size: 72,
),
```

- [ ] **Step 2: Update `WeatherStatsCard`**

```dart
if (!state.hasData) return const SizedBox.shrink();

final weather = state.weatherOrNull;
final current = weather?.current;
final wind = current != null ? WeatherFormat.wind(current.windSpeed) : '--';
final rain = current != null ? WeatherFormat.percent(current.precipitation) : '--';
final humidity = current != null ? WeatherFormat.percentInt(current.humidity) : '--';
```

- [ ] **Step 3: Update `WeatherHourlyTileList`**

```dart
if (!state.hasData) return const SizedBox.shrink();

final weather = state.weatherOrNull;
if (weather == null) return const SizedBox.shrink();

final now = DateTime.now();
final filtered = weather.hourly.where((h) =>
  h.time.isAfter(now) && h.time.isBefore(now.add(const Duration(hours: 12)))
).toList();
```

- [ ] **Step 4: Update `WeatherDailyTileList`**

```dart
if (!state.hasData) return const SizedBox.shrink();

final weather = state.weatherOrNull;
if (weather == null) return const SizedBox.shrink();

final items = weather.daily.take(7).toList();
```

- [ ] **Step 5: Update `WeatherSunTimes`**

```dart
// Change the guard from:
if (state is! WeatherLoaded || state.result.weather.daily.isEmpty) {
  return const SizedBox.shrink();
}

// To:
if (!state.hasWeather || state.weatherOrNull!.daily.isEmpty) {
  return const SizedBox.shrink();
}
```

- [ ] **Step 6: Run analyze to verify no compile errors**

Run: `flutter analyze`
Expected: No warnings

- [ ] **Step 7: Commit**

```bash
git add lib/features/weather_forecast/presentation/widgets/weather_main_card.dart lib/features/weather_forecast/presentation/widgets/weather_stats_card.dart lib/features/weather_forecast/presentation/widgets/weather_hourly_tile_list.dart lib/features/weather_forecast/presentation/widgets/weather_daily_tile_list.dart lib/features/weather_forecast/presentation/widgets/weather_sun_times.dart
git commit -m "feat: handle WeatherEmpty state in all data widgets"
```

---

### Task 8: Build verification

- [ ] **Step 1: Run static analysis**

Run: `flutter analyze`
Expected: 0 warnings, 0 errors

- [ ] **Step 2: Run all tests**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 3: Fix any failures**

If tests fail, fix them and re-run.

- [ ] **Step 4: Final commit if fixes needed**

```bash
git add -A
git commit -m "fix: address analyze and test failures"
```
