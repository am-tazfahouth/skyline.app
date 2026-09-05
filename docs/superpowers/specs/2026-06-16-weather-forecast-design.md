# Weather Forecast Feature — Design Spec

**Date:** 2026-06-16
**Feature:** weather_forecast
**Goal:** Fetch and display weather data for a hardcoded location (Moroni, Comoros) using the Open-Meteo API.
**Status:** Approved

---

## 1. Architecture & Layers

Follows the existing Clean Architecture pattern (feature-first) defined in `AGENTS.md`.

```
lib/features/weather_forecast/
├── data/
│   ├── models/
│   │   ├── current_weather_model.dart
│   │   ├── hourly_weather_model.dart
│   │   ├── daily_weather_model.dart
│   │   └── weather_model.dart
│   ├── repositories/
│   │   └── weather_repository_impl.dart
│   └── sources/
│       └── weather_remote_source.dart
├── domain/
│   ├── entities/
│   │   ├── current_weather_entity.dart
│   │   ├── hourly_weather_entity.dart
│   │   ├── daily_weather_entity.dart
│   │   └── weather_entity.dart
│   ├── repositories/
│   │   └── weather_repository.dart      # abstract contract
│   └── usecases/
│       └── fetch_weather_usecase.dart
└── presentation/
    ├── blocs/
    │   ├── weather_forecast_bloc.dart
    │   ├── weather_forecast_event.dart
    │   └── weather_forecast_state.dart
    ├── screens/
    │   └── weather_screen.dart
    └── widgets/
        ├── weather_header.dart
        ├── current_weather_card.dart
        ├── stats_card.dart
        ├── forecast_tabs.dart
        ├── hourly_carousel.dart
        └── ephemeride_card.dart
```

---

## 2. Entities (Domain Layer)

All entities extend `Equatable` with manually written `copyWith` and `props`.

### `CurrentWeatherEntity`
| Field | Type | Description |
|-------|------|-------------|
| `temperature` | `double` | Current temperature in °C |
| `humidity` | `int` | Relative humidity (%) |
| `isDay` | `bool` | 1 = day, 0 = night |
| `windSpeed` | `double` | Wind speed in km/h |
| `precipitation` | `double` | Precipitation in mm |
| `weatherCode` | `int` | WMO weather code |

### `HourlyWeatherEntity`
| Field | Type | Description |
|-------|------|-------------|
| `time` | `DateTime` | ISO 8601 timestamp |
| `temperature` | `double` | Temperature in °C |
| `precipitationProbability` | `int` | Precipitation probability (%) |
| `weatherCode` | `int` | WMO weather code |

### `DailyWeatherEntity`
| Field | Type | Description |
|-------|------|-------------|
| `date` | `DateTime` | Date |
| `tempMax` | `double` | Max temperature in °C |
| `tempMin` | `double` | Min temperature in °C |
| `weatherCode` | `int` | WMO weather code |
| `sunrise` | `DateTime` | Sunrise time (ISO 8601) |
| `sunset` | `DateTime` | Sunset time (ISO 8601) |

### `WeatherEntity` (container)
| Field | Type | Description |
|-------|------|-------------|
| `current` | `CurrentWeatherEntity` | Current conditions |
| `hourly` | `List<HourlyWeatherEntity>` | Next hours forecast |
| `daily` | `List<DailyWeatherEntity>` | Daily forecast (7 days) |

---

## 3. Models (Data Layer)

Mirror entities exactly (same fields) but with:
- `factory` constructors `fromJson(Map<String, dynamic>)` for JSON deserialization
- `toJson()` for serialization (future use)
- `.toEntity()` method to convert to domain entity

### `WeatherMapper` (static utility class)
- `WeatherMapper.currentFromJson(Map<String, dynamic> currentJson)` → `CurrentWeatherEntity`
- `WeatherMapper.hourlyFromJson(Map<String, dynamic> hourlyJson)` → `List<HourlyWeatherEntity>`
- `WeatherMapper.dailyFromJson(Map<String, dynamic> dailyJson)` → `List<DailyWeatherEntity>`
- `WeatherMapper.weatherFromJson(Map<String, dynamic> json)` → `WeatherEntity`

Parses the nested Open-Meteo response format (`current`, `hourly`, `daily` sub-objects).

---

## 4. Data Sources

### `WeatherRemoteSource`
- Uses `Dio` HTTP client (injected via constructor)
- Calls the hardcoded Open-Meteo URL with fixed lat/long
- Returns raw `Map<String, dynamic>` JSON
- Catches Dio exceptions and rethrows as `ServerFailure` or `NetworkFailure`

**URL** (hardcoded):
```
https://api.open-meteo.com/v1/forecast?latitude=-11.7022&longitude=43.2551&daily=temperature_2m_max,temperature_2m_min,weather_code,sunset,sunrise&hourly=temperature_2m,precipitation_probability,weather_code&current=temperature_2m,relative_humidity_2m,is_day,wind_speed_10m,precipitation,weather_code&timezone=auto
```

---

## 5. Repository

### Abstract contract: `WeatherRepository`
```dart
Future<WeatherEntity> fetchWeather();
```
Throws `Failure` on error.

### Implementation: `WeatherRepositoryImpl`
- Injects `WeatherRemoteSource`
- Calls remote source, maps JSON → Models → Entities via `WeatherMapper`
- Wraps Dio exceptions in typed `Failure` objects (`ServerFailure`, `NetworkFailure`, `ParsingFailure`)
- Propagates `Failure` as thrown exception (caught at BLoC level)

### Error hierarchy (`core/errors/`)
```
Failure (base)
├── NetworkFailure      — no internet / timeout
├── ServerFailure       — API error (5xx, 4xx)
├── ParsingFailure      — invalid JSON / type mismatch
└── UnexpectedFailure   — unknown error (catch-all)
```
Each `Failure` carries a `message` string and optional `stackTrace`.

---

## 6. Use Case

### `FetchWeatherUseCase`
```dart
class FetchWeatherUseCase {
  final WeatherRepository repository;
  
  Future<WeatherEntity> call();
}
```
Delegates to repository. `Failure` exceptions propagate up to BLoC.

---

## 7. BLoC (Presentation State Management)

### Event
- `FetchWeatherEvent` — triggers fetch (no payload, location is hardcoded)

### States (all extend Equatable)
| State | Contents | UI Behavior |
|-------|----------|-------------|
| `WeatherInitial` | – | Blank screen |
| `WeatherLoading` | – | Full-screen shimmer / loading indicator |
| `WeatherLoaded` | `WeatherEntity` | Renders full weather UI |
| `WeatherError` | `Failure` | Error message + retry button |

### BLoC
```dart
class WeatherForecastBloc extends Bloc<WeatherForecastEvent, WeatherForecastState> {
  final FetchWeatherUseCase fetchWeatherUseCase;
  
  on<FetchWeatherEvent>((event, emit) async {
    emit(WeatherLoading());
    try {
      final weather = await fetchWeatherUseCase();
      emit(WeatherLoaded(weather));
    } on Failure catch (failure) {
      emit(WeatherError(failure));
    } catch (e, s) {
      emit(WeatherError(UnexpectedFailure(e.toString(), s)));
    }
  });
}
```

---

## 8. Screen & Widgets

### `WeatherScreen`
- Single `BlocProvider` wrapping `WeatherForecastBloc`
- `BlocBuilder` switching on state:
  - `Initial` → empty
  - `Loading` → shimmer placeholder
  - `Loaded` → full scrollable UI (see below)
  - `Error` → error view with retry button

### Scrollable layout (top to bottom):

1. **Header** (`weather_header.dart`)
   - Left: dashboard grid icon
   - Center: "Moroni, Comoros" with pin icon + dropdown arrow
   - Right: settings gear icon

2. **Current Weather Card** (`current_weather_card.dart`)
   - Large rounded rectangle
   - Left: date, condition label (from WMO code), large temperature
   - Right: weather icon

3. **Stats Card** (`stats_card.dart`)
   - Horizontal row, 3 columns (wind / rain chance / humidity)
   - Divided by thin vertical lines

4. **Forecast Tabs** (`forecast_tabs.dart`)
   - "Today" / "Next 7 Day" text tabs
   - Active tab: white text, underlined; inactive: gray

5. **Hourly Carousel** (`hourly_carousel.dart`)
   - Horizontal scroll of pill-shaped cards
   - Each: time, weather icon, temperature

6. **Ephemeride Card** (`ephemeride_card.dart`)
   - Left: sunrise/sunset times with icons
   - Right: parabolic sun path graph (`fl_chart` or custom painter)

---

## 9. WMO Weather Codes

A static utility mapping WMO codes to human-readable conditions + appropriate icons. Minimal set based on data:

| Code Range | Condition |
|------------|-----------|
| 0 | Clear sky |
| 1-3 | Mainly clear / partly cloudy |
| 45-48 | Foggy |
| 51-55 | Drizzle |
| 61-65 | Rain |
| 80-82 | Rain showers |
| 95-99 | Thunderstorm |

---

## 10. Out of Scope (Future)
- Dynamic location selection / search
- ObjectBox caching / offline support
- Pull-to-refresh
- Unit/language preferences
- Location-based auto-detect

---

## 11. Testing Strategy

| Layer | Testing Approach |
|-------|-----------------|
| **Models** | Unit test `fromJson` / `toEntity` with CSV sample data |
| **Mapper** | Unit test mapping from JSON → Entity |
| **Repository** | Unit test with mocked remote source |
| **UseCase** | Unit test with mocked repository |
| **BLoC** | `bloc_test` with mocked use case (all states) |
| **Widgets** | `flutter_test` with `BlocProvider` + mocked bloc |
| **Remote Source** | Integration test (optional, requires network) |

---

## 12. Error Handling

- `DioException` (network) → `NetworkFailure`
- `DioException` (server error) → `ServerFailure`
- `FormatException` (bad JSON) → `ParsingFailure`
- Unknown → `UnexpectedFailure`

All errors displayed via `WeatherError` state → `SnackBar` or inline error view with retry CTA.

---

## 13. Dependencies Added
None beyond what's already declared in `pubspec.yaml`. The stack (dio, flutter_bloc, equatable) already covers this feature.
