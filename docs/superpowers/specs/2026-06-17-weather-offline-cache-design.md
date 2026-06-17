# Weather Offline Cache — Design Spec

**Date:** 2026-06-17
**Author:** AI-assisted design
**Status:** Approved

## 1. Problem

When the device has no internet connection, the weather UI shows an error state and no data. The user wants to see the last successfully fetched weather data instead of a blank error screen.

## 2. Constraints

- `WeatherEntity` (domain) must not be polluted with data-layer logic.
- `WeatherModel` (data) is the object to persist — it is converted to `WeatherEntity` for display.
- ObjectBox is the local database (already in `pubspec.yaml`).
- A singleton `DbHelper` in `lib/core/config/db_helper/` manages the database.
- Only one weather record is stored — fixed `id=1`.
- The repository handles fallback transparently; the BLoC knows whether data is cached (`isCached` indicator in state).
- No `freezed`, no `get_it`. Manual `copyWith`, manual DI via static container.

## 3. Architecture

### Data flow

```
WeatherForecastBloc
  → FetchWeatherUseCase
    → WeatherRepositoryImpl.fetchWeather()
      → 1. WeatherRemoteSource.fetchWeather()     (API call)
      → 2a. [success] → WeatherMapper.fromJson() → WeatherModel
                       → DbHelper.saveWeather(model)     (update cache)
                       → model.toEntity()
                       → return WeatherResult(weather, isCached: false)
      → 2b. [NetworkFailure] → DbHelper.loadWeather() → WeatherModel?
                              → if found → .toEntity() → WeatherResult(entity, isCached: true)
                              → if null  → rethrow NetworkFailure
```

### New files

| File | Purpose |
|------|---------|
| `lib/core/config/db_helper/weather_cache_entity.dart` | ObjectBox entity (id=1, jsonData string) |
| `lib/core/config/db_helper/db_helper.dart` | Singleton DbHelper (init, save, load, dispose) |
| `lib/injection_container.dart` | Static service locator (Dio, DbHelper, repos, use cases) |
| `lib/features/weather_forecast/domain/entities/weather_result.dart` | Domain wrapper: WeatherEntity + bool isCached |

### Modified files

| File | Change |
|------|--------|
| `lib/features/weather_forecast/data/weather_mapper.dart` | `fromJson()` returns `WeatherModel` instead of `WeatherEntity` |
| `lib/features/weather_forecast/data/models/weather_model.dart` | Add `factory WeatherModel.fromCacheJson(Map)` |
| `lib/features/weather_forecast/domain/repositories/weather_repository.dart` | Return type `Future<WeatherResult>` |
| `lib/features/weather_forecast/domain/usecases/fetch_weather_usecase.dart` | Return type `Future<WeatherResult>` |
| `lib/features/weather_forecast/data/repositories/weather_repository_impl.dart` | Inject `DbHelper`, implement fallback logic |
| `lib/features/weather_forecast/presentation/blocs/weather_forecast_state.dart` | `WeatherLoaded` holds `WeatherResult` |
| `lib/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart` | No logic change (type update only) |
| `lib/main.dart` | Replace inline DI with `InjectionContainer.init()` |

## 4. Component Details

### 4.1 WeatherCacheEntity

```dart
@Entity()
class WeatherCacheEntity {
  @Id()
  int id;
  String jsonData;

  WeatherCacheEntity({required this.id, required this.jsonData});
}
```

### 4.2 DbHelper

Singleton initialized once in `InjectionContainer.init()`:
- `static Future<DbHelper> init()` — creates Store, opens Box
- `void saveWeather(WeatherModel model)` — serializes via `model.toJson()` → `jsonEncode` → stores with id=1
- `WeatherModel? loadWeather()` — `box.get(1)` → `jsonDecode` → `WeatherModel.fromCacheJson(json)`
- `void dispose()` — `store.close()`

### 4.3 WeatherResult (domain entity)

```dart
class WeatherResult extends Equatable {
  final WeatherEntity weather;
  final bool isCached;

  const WeatherResult({required this.weather, required this.isCached});

  WeatherResult copyWith({WeatherEntity? weather, bool? isCached}) { ... }

  @override
  List<Object?> get props => [weather, isCached];
}
```

### 4.4 WeatherMapper change

Current `fromJson()` returns `WeatherEntity`. It will return `WeatherModel` so the repository can both persist the model and convert it.

```dart
static WeatherModel fromJson(Map<String, dynamic> json) {
  // same parsing logic, but returns WeatherModel instead of WeatherEntity
  return WeatherModel(current: ..., hourly: ..., daily: ...);
}
```

### 4.5 WeatherModel — fromCacheJson factory

```dart
factory WeatherModel.fromCacheJson(Map<String, dynamic> json) {
  return WeatherModel(
    current: CurrentWeatherModel.fromJson(json['current']),
    hourly: (json['hourly'] as List).map((e) => HourlyWeatherModel.fromJson(e)).toList(),
    daily: (json['daily'] as List).map((e) => DailyWeatherModel.fromJson(e)).toList(),
  );
}
```

Note: `CurrentWeatherModel.fromJson()`, `HourlyWeatherModel.fromJson()`, and `DailyWeatherModel.fromJson()` already exist with the correct key names matching their `toJson()` output, so they are reusable directly.

### 4.6 InjectionContainer

```dart
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

### 4.7 WeatherRepositoryImpl — fallback logic

```dart
Future<WeatherResult> fetchWeather() async {
  try {
    final json = await _remoteSource.fetchWeather();
    final model = WeatherMapper.fromJson(json);
    await _dbHelper.saveWeather(model);
    return WeatherResult(weather: model.toEntity(), isCached: false);
  } on NetworkFailure {
    final cached = _dbHelper.loadWeather();
    if (cached != null) {
      return WeatherResult(weather: cached.toEntity(), isCached: true);
    }
    rethrow;
  }
}
```

Other `Failure` types (ServerFailure, ParsingFailure) still propagate up — only `NetworkFailure` triggers the cache fallback.

### 4.8 BLoC state update

```dart
class WeatherLoaded extends WeatherForecastState {
  final WeatherResult result;
  bool get isCached => result.isCached;

  const WeatherLoaded(this.result);

  @override
  List<Object?> get props => [result];
}
```

UI widgets access `state.result.weather` (entity) and `state.result.isCached` (display indicator).

## 5. Error handling

- `NetworkFailure` → fallback to cache. If cache is empty, error propagates to BLoC as before.
- `ServerFailure`, `ParsingFailure`, `UnexpectedFailure` → propagate normally (no cache fallback).
- `DbHelper` exceptions → caught in repository, wrapped in `UnexpectedFailure` (already exists in `core/errors/`).
- Cache miss (no data saved yet) → `NetworkFailure` reaches BLoC → UI shows error view as before.

## 6. Testing

| Test | Scope |
|------|-------|
| DbHelper save + load roundtrip | Unit test (with temporary ObjectBox store) |
| DbHelper.loadWeather returns null when empty | Unit test |
| Repository returns cached data on NetworkFailure | Unit test (mock remote + mock db or real db) |
| Repository rethrows on cache miss + NetworkFailure | Unit test |
| Repository returns fresh data on success + saves to db | Unit test |
| BLoC emits WeatherLoaded(isCached=true) on cache hit | bloc_test with mock use case |
| BLoC emits WeatherError on cache miss + network fail | bloc_test |
| InjectionContainer.init creates all dependencies | Unit test |

## 7. Out of scope

- Multiple weather locations (future feature).
- Cache invalidation / TTL (always overwrites on successful fetch).
- UI "last updated" timestamp (can be added later).
- Other features use the cache (future container extensions).
