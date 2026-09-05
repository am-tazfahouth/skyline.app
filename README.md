<p align="center">
  <img src="assets/images/logo/ic_launcher.png" alt="SkyLine logo" width="120" />
</p>

<h1 align="center">SkyLine</h1>

<p align="center">
  Simple and professional mobile weather app for iOS and Android, built with Flutter.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.35+-blue?logo=flutter" alt="Flutter 3.35+" />
  <img src="https://img.shields.io/badge/Dart-3.9.2+-blue?logo=dart" alt="Dart 3.9.2+" />
  <img src="https://img.shields.io/badge/platform-iOS%20%7C%20Android-lightgrey" alt="platform" />
  <img src="https://img.shields.io/badge/state%20management-flutter_bloc-red" alt="flutter_bloc" />
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License: MIT" />
</p>

---

## Overview

**SkyLine** is a clean and professional weather application for iOS and Android. It delivers current conditions, hourly and daily forecasts, backed by an offline-first cache and a strict Clean Architecture, feature-driven codebase.

## Features

- **Current weather** with real-time conditions and key metrics
- **Hourly & daily forecasts** for the selected location
- **Location search** and **favorite locations** management
- **GPS geolocation** with reverse geocoding
- **Offline-first caching** — cached weather displayed when offline
- **Light & Dark themes** (follows system or manual preference)
- **4 languages**: English, French, Spanish, Arabic
- **Adjustable units** for temperature and wind speed
- **Custom SF Pro typography** and apple-inspired design system

## Getting Started

### Prerequisites

- Flutter **>= 3.35.0**
- Dart **^3.9.2**

### Installation

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Generate ObjectBox code (required after any model change)
dart run build_runner build

# 3. Run the app
flutter run

# 4. Run the test suite
flutter test

# 5. Static analysis (zero warnings tolerated)
flutter analyze
```

## Architecture

The project applies a strict **Clean Architecture** split by feature (`core/` for cross-cutting concerns, `features/` for business modules). Data flows inward, from **data** → **domain** → **presentation**, with dedicated mapper classes isolating each layer.

```
lib/
├── core/                    # Cross-cutting concerns
│   ├── config/              # Themes, DI, routing, ObjectBox helper
│   ├── constants/           # API keys, dimensions, durations
│   ├── enums/               # Settings & error enumerations
│   ├── errors/              # Unified failure system (Failures, AppErrorCode)
│   ├── l10n/                # Localization (AR, EN, ES, FR)
│   ├── services/            # Shared services (logging)
│   └── utils/               # Formatters, weather conversion helpers
├── features/                # Business modules
│   ├── location/            # Geolocation, search & favorites
│   ├── settings/            # Preferences (theme, language, units)
│   └── weather_forecast/    # Current, hourly & daily weather
│       ├── data/            # Models, repositories, sources (Open-Meteo / ObjectBox)
│       ├── domain/          # Entities, repository contracts, use cases
│       └── presentation/    # BLoCs, screens, widgets
└── main.dart                # Application entry point
```

### Dependency Injection

Dependencies are wired centrally in `lib/injection_container.dart`, providing the BLoCs and repositories to the widget tree via `flutter_bloc`.

## Tech Stack

| Domain                | Technology                       | Usage                                    |
| --------------------- | -------------------------------- | ---------------------------------------- |
| Framework             | Flutter / Dart                   | Cross-platform UI                        |
| State Management      | `flutter_bloc` 9.x               | Strict BLoC pattern                      |
| Immutability          | `equatable` 2.x                  | Value-based equality                     |
| Networking            | `dio` 5.x                        | Centralized HTTP client (Open-Meteo)     |
| Local Database        | `objectbox` 5.x                  | Offline NoSQL cache                      |
| Geolocation           | `geolocator` 14.x                | GPS positioning                          |
| Localization          | `intl` + custom `AppLocalisation`| Multi-language (AR, EN, ES, FR)          |
| Icons & Typography    | `weather_icons`, SF Pro          | Apple-inspired design system             |
| Testing               | `flutter_test`, `mocktail`, `bloc_test` | Unit & BLoC tests                |

## Testing

The project follows a **TDD** approach with unit and BLoC tests:

```bash
flutter test
```

- **`bloc_test`** — validate BLoC event/state transitions
- **`mocktail`** — mocking of repositories and sources
- **`flutter_test`** — widget and unit tests

## Static Analysis

Zero warnings and zero infos tolerated:

```bash
flutter analyze
```

## Roadmap

- [x] Current, hourly & daily forecast
- [x] Location search & favorites
- [x] Geolocation & reverse geocoding
- [x] Offline cache with cached-weather notice
- [x] Light/Dark themes & multi-language
- [x] Adjustable temperature & wind units

## Architecture Documentation

The full engineering history of the project — every feature design spec and its implementation plan — is available in [docs/](docs/README.md), indexed by feature.

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for the development workflow, code conventions, and pull request process.

## Author

[am-tazfahouth](https://github.com/am-tazfahouth)

## License

Distributed under the **MIT License**. See [LICENSE](LICENSE) for more information.
