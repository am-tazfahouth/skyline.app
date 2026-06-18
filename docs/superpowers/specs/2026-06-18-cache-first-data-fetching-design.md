# Cache-First Data Fetching — Design Spec

## Problem

When the app launches, it currently shows a blank page with a full-screen `CircularProgressIndicator` (`WeatherLoading`) while fetching weather data from the API. This creates a poor first-launch experience. Additionally, the existing ObjectBox cache has no TTL and is only used as a fallback when the network fails, rather than being leveraged proactively.

## Goals

1. **Eliminate the loading spinner** — show the weather screen structure immediately on launch
2. **Cache-first strategy** — display cached data (if valid) immediately, then refresh in background
3. **TTL-enforced cache** — cached data expires after a configurable number of days (default: 6)
4. **Graceful offline** — when no connection and no valid cache, show the weather structure with placeholder values (`--`) instead of an error page
5. **Loading overlay** — during background refresh, show a semi-transparent overlay on top of the cached data, not a full-page spinner

## Architecture Decisions

### Approach A: BLoC-driven state machine (selected)

The `WeatherForecastBloc` orchestrates the entire flow: load cache, check connectivity, fetch from API, manage overlay visibility. Two events differentiate auto-load from manual refresh. The repository exposes two separate methods (`loadCachedWeather`, `fetchWeather`) so the BLoC controls ordering. All widget state is read-only via `BlocBuilder`.

This keeps logic centralized, testable, and avoids mixing concerns across layers.

## Detailed Design

### 1. Cache Layer

#### WeatherCacheEntity (`core/config/db_helper/weather_cache_entity.dart`)
- Add field `int savedAt` — stores `DateTime.now().millisecondsSinceEpoch` at save time
- Existing fields (`id`, `jsonData`) unchanged

#### DbHelper (`core/config/db_helper/db_helper.dart`)
- **`saveWeather(WeatherModel model)`** — after encoding JSON, sets `savedAt` on the entity
- **`loadWeather({int? maxAgeMillis})`** — if `maxAgeMillis` is provided, compares `now.savedAt` and returns `null` if the cache is too old
- **`loadCacheMeta()`** — returns just the `savedAt` timestamp without decoding JSON (optional optimization, skip in initial implementation)

#### WeatherRepository (abstract, `domain/repositories/`)
```dart
abstract class WeatherRepository {
  Future<WeatherResult> fetchWeather();
  Future<WeatherResult?> loadCachedWeather();
}
```

#### WeatherRepositoryImpl (`data/repositories/`)
- **`loadCachedWeather()`** — calls `DbHelper.loadWeather(maxAgeMillis: days * 24 * 60 * 60 * 1000)`. Returns `WeatherResult` with `isCached: true` if cache exists and is fresh, `null` otherwise
- **`fetchWeather()`** — simplified: calls remote source, parses model, saves to cache (with `savedAt`), returns `WeatherResult(isCached: false)`. No automatic cache fallback. No connectivity check
- Constructor accepts `int cacheMaxAgeDays` (default `6`)

### 2. BLoC Layer

#### States (`presentation/blocs/weather_forecast_state.dart`)
- **`WeatherLoaded(result, {isFetching = false})`** — added `isFetching` flag
- **`WeatherEmpty({isFetching = false})`** — new state, same visual structure as WeatherLoaded but all values rendered as `--`
- **`WeatherInitial`** — unchanged, shown only before first event
- **`WeatherLoading`** — **removed**, no longer used
- **`WeatherError`** — unchanged

Abstract base gains:
```dart
bool get isFetching => false;  // default false
```

Extension helper:
```dart
extension WeatherStateX on WeatherForecastState {
  bool get hasData => this is WeatherLoaded || this is WeatherEmpty;
  bool get hasWeather => this is WeatherLoaded;
  WeatherEntity? get weatherOrNull => switch (this) {
    WeatherLoaded(result: final r) => r.weather,
    _ => null,
  };
}
```

#### Events (`presentation/blocs/weather_forecast_event.dart`)
- **`FetchWeatherEvent`** — auto-load on app start (cache-first, shows overlay)
- **`RefreshWeatherEvent`** — pull-to-refresh (no overlay, uses RefreshIndicator)

#### BLoC (`presentation/blocs/weather_forecast_bloc.dart`)

**`_onFetchWeather`** (auto-load):
1. `final cached = await _repository.loadCachedWeather()`
2. `final connected = await PlatformUtils.isConnected()`
3. If cache valid + offline → `WeatherLoaded(cached, isFetching: false)` — stop
4. If cache valid + online:
   - `WeatherLoaded(cached, isFetching: false)` → `WeatherLoaded(cached, isFetching: true)` (overlay)
   - Fetch → success: `WeatherLoaded(fresh, isFetching: false)`
   - Fetch → failure: `WeatherLoaded(cached, isFetching: false)` — keep cache silently
5. If no cache + online:
   - `WeatherEmpty(isFetching: true)` (overlay)
   - Fetch → success: `WeatherLoaded(fresh, isFetching: false)`
   - Fetch → failure: `WeatherError(failure)`
6. If no cache + offline: `WeatherEmpty(isFetching: false)`

**`_onRefreshWeather`** (pull-to-refresh):
1. From `WeatherLoaded(data)`:
   - `WeatherLoaded(data, isFetching: true)` → fetch
   - Success: `WeatherLoaded(fresh, isFetching: false)`
   - Failure: `WeatherLoaded(data, isFetching: false)` — keep data silently
2. From `WeatherEmpty`:
   - `WeatherEmpty(isFetching: true)` → fetch
   - Success: `WeatherLoaded(fresh, isFetching: false)`
   - Failure: `WeatherEmpty(isFetching: false)` — stay empty
3. From `WeatherError` or `WeatherInitial`: delegate to `_onFetchWeather`

### 3. Presentation Layer

#### WeatherScreen (`presentation/screens/weather_screen.dart`)
- `BlocBuilder` → `Stack`:
  - Background: one of `WeatherInitialView`, `WeatherContentView` (for both `WeatherLoaded` and `WeatherEmpty`), `WeatherErrorView`
  - Foreground: if `state.isFetching`, a `Positioned.fill` overlay with `Colors.black26` and centered `CircularProgressIndicator`

#### WeatherContentView (`presentation/widgets/views/weather_content_view.dart`)
- `RefreshIndicator` dispatches `RefreshWeatherEvent` (not `FetchWeatherEvent`)
- Awaits next `WeatherLoaded`, `WeatherEmpty`, or `WeatherError` from stream

#### Data widgets (`WeatherMainCard`, `WeatherStatsCard`, `WeatherHourlyTileList`, `WeatherDailyTileList`, `WeatherSunTimes`)
- Guard changed from `state is! WeatherLoaded` → `!state.hasData`
- `state.result.weather.current.xxx` → `weatherOrNull?.current.xxx ?? '--'`
- Lists (hourly, daily) rendered from `weatherOrNull?.hourly ?? []` / `weatherOrNull?.daily ?? []`
- Empty lists result in `SizedBox.shrink()` (existing behavior)

#### Removed files
- `WeatherLoadingView` — no longer used or referenced

#### Modified files (10)
- `weather_cache_entity.dart` — add `savedAt`
- `db_helper.dart` — timestamp on save, TTL on load
- `weather_repository.dart` — add `loadCachedWeather()` to interface
- `weather_repository_impl.dart` — implement cache loading, simplify fetch
- `weather_forecast_state.dart` — add `WeatherEmpty`, `isFetching` flag, extension
- `weather_forecast_event.dart` — add `RefreshWeatherEvent`
- `weather_forecast_bloc.dart` — two handlers, new flow
- `weather_screen.dart` — handle `WeatherEmpty`, overlay via `Stack`
- `weather_content_view.dart` — dispatch `RefreshWeatherEvent`
- `api_constants.dart` — add `cacheMaxAgeDays` constant (optional, could be in repository)
- `injection_container.dart` — pass cache max age to repository

Data widgets (5): `weather_main_card.dart`, `weather_stats_card.dart`, `weather_hourly_tile_list.dart`, `weather_daily_tile_list.dart`, `weather_sun_times.dart` — guard + null-safe access

### 4. Error Handling

- **Network failure with cache**: silently keep cached data (no error visible to user)
- **Network failure without cache**: show `WeatherEmpty` with `--` values
- **Server/parsing error with cache**: silently keep cached data
- **Server/parsing error without cache**: show `WeatherError` with retry button
- **Unexpected exception**: caught by BLoC, `WeatherError` with `UnexpectedFailure`

## Testing Strategy

### BLoC tests (`bloc_test`)
- Cache valid + offline → only `WeatherLoaded(cached, isFetching: false)` emitted
- Cache valid + online + fetch succeeds → three emissions (loaded, loading overlay, loaded fresh)
- Cache valid + online + fetch fails → stays on `WeatherLoaded(cached, isFetching: false)`
- No cache + online → `[WeatherEmpty(isFetching: true), WeatherLoaded]`
- No cache + offline → `[WeatherEmpty(isFetching: false)]`
- Pull-to-refresh from loaded → fetch OK → `WeatherLoaded(fresh, isFetching: false)`
- Pull-to-refresh from loaded → fetch KO → stays `WeatherLoaded(original, isFetching: false)`
- Pull-to-refresh from empty → fetch OK → `WeatherLoaded`
- Pull-to-refresh from empty → fetch KO → stays `WeatherEmpty(isFetching: false)`

### Repository tests
- `loadCachedWeather()` returns `null` when cache is empty
- `loadCachedWeather()` returns `null` when cache exceeds TTL
- `loadCachedWeather()` returns data when cache is fresh
- `fetchWeather()` saves to cache with `savedAt` timestamp

### DbHelper tests
- `saveWeather()` stores `savedAt`
- `loadWeather(maxAgeMillis:)` returns `null` if age exceeds threshold
- `loadWeather(maxAgeMillis:)` returns data if age is within threshold

### Widget tests
- `WeatherEmpty` renders `--` for temperature, wind, humidity, etc.
- `WeatherLoaded` with `isFetching: true` shows overlay
- `WeatherLoaded` with `isFetching: false` does not show overlay

## Open Questions / Future Considerations

- `cacheMaxAgeDays` is currently a constructor parameter on the repository. Future: expose via settings screen
- Connectivity check uses `PlatformUtils.isConnected()` (DNS lookup). Future: consider `connectivity_plus` for more robust detection
- The `WeatherForecastSection` tab state is UI-local (`StatefulWidget`). If complexity grows, move to BLoC
