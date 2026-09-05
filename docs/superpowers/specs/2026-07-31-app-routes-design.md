# App Routes Centralization — Design Spec

**Date:** 2026-07-31
**Feature:** Centralized named routing via `RouteGenerator`
**Status:** Approved

---

## 1. Overview

The app currently navigates with direct `Navigator.push(MaterialPageRoute(...))` calls scattered across `weather_header.dart` and `location_screen.dart`, and `main.dart` sets `home: WeatherScreen()`. This spec centralizes routing in a single `lib/core/config/app_routes.dart` file, following the pattern of a named-route generator (`AppRoutes` constants + `RouteGenerator`) adapted to the current app.

### User-visible behavior

No behavior change: weather stays the initial screen, and the grid icon, settings icon, and search FAB still open the same screens. The only difference is internal — all navigation goes through named routes resolved by `RouteGenerator`, with a slide right-to-left transition on every platform.

---

## 2. Route Table

| Route | Constant | Screen |
|---|---|---|
| `/` | `AppRoutes.weather` | `WeatherScreen` |
| `/location` | `AppRoutes.location` | `LocationScreen` |
| `/location/search` | `AppRoutes.locationSearch` | `LocationSearchScreen` |
| `/settings` | `AppRoutes.settings` | `SettingsScreen` |

Naming follows the hierarchy style of the inspiration code (`/location/search`).

---

## 3. `lib/core/config/app_routes.dart`

Location: `lib/core/config/app_routes.dart` (in the existing `core/config` folder).

### `AppRoutes`

```dart
class AppRoutes {
  static const String weather = '/';
  static const String location = '/location';
  static const String locationSearch = '/location/search';
  static const String settings = '/settings';
}
```

### `RouteGenerator`

```dart
class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.weather:
        return _slideRoute(const WeatherScreen());
      case AppRoutes.location:
        return _slideRoute(const LocationScreen());
      case AppRoutes.locationSearch:
        return _slideRoute(const LocationSearchScreen());
      case AppRoutes.settings:
        return _slideRoute(const SettingsScreen());
      default:
        return _slideRoute(const WeatherScreen());
    }
  }

  static Route<dynamic> _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;
        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}
```

Notes:

- The inspiration code had two defects that are corrected here: an empty `case null:` and a `switch` with no `default`. Both are replaced by a single `default` case that gracefully falls back to the weather home screen instead of crashing on an unknown or null route.
- `settings.arguments` is not consumed today (no screen takes arguments) but the `switch` is structured to extend to argument-passing routes later.
- All routes use the same slide transition (right-to-left, `Curves.ease`), identical on iOS and Android.

---

## 4. `main.dart` Wiring

In `MyApp.build`, replace:

```dart
home: WeatherScreen(),
```

with:

```dart
initialRoute: AppRoutes.weather,
onGenerateRoute: RouteGenerator.generateRoute,
```

The `MaterialApp` is already built inside a `BlocBuilder<SettingsBloc>` gate, so `initialRoute` is resolved only after settings are loaded — no change to that startup flow.

---

## 5. Widget Navigation Updates

| File | Change |
|---|---|
| `lib/features/weather_forecast/presentation/widgets/weather_header.dart` | Grid icon: `Navigator.pushNamed(context, AppRoutes.location)`; settings icon: `Navigator.pushNamed(context, AppRoutes.settings)`. Remove `MaterialPageRoute` usage and the now-unused screen imports. |
| `lib/features/location/presentation/screens/location_screen.dart` | FAB: `Navigator.pushNamed(context, AppRoutes.locationSearch)`. |

The existing `Navigator.pop(context)` calls (`location_screen.dart`, `location_search_screen.dart`) are unchanged.

---

## 6. Error Handling

- Unknown or null route name → `RouteGenerator` `default` case returns the weather home screen (no crash).
- No new error codes; `AppError` / error handling is untouched.

---

## 7. Testing Strategy

TDD throughout; run `flutter test` and `flutter analyze` (zero warnings) before commit.

- **Unit — `test/core/config/app_routes_test.dart` (new)**: each route name resolves to the expected screen type; unknown route name resolves to `WeatherScreen`; null route name resolves to `WeatherScreen`.
- **Widget — `test/features/weather_forecast/presentation/screens/weather_screen_test.dart` (update)**: the `MaterialApp` in `createTestScreen` gains `onGenerateRoute: RouteGenerator.generateRoute` so the "grid icon navigates to LocationScreen" test passes with `pushNamed`.
- **Widget — `test/features/location/presentation/screens/location_screen_test.dart` (update)**: the test `MaterialApp` gains `onGenerateRoute: RouteGenerator.generateRoute` so the "FAB navigates to LocationSearchScreen" test passes with `pushNamed`.
- Other tests that use `MaterialPageRoute` only as a test harness to reach a screen under test are unchanged.

---

## 8. Documentation

`AGENTS.md` section 2 lists `core/config` as "Thèmes, injection de dépendances, configuration ObjectBox". Add "routing" to that description so the file location stays documented.

---

## 9. Non-Goals / Out of Scope

- No new screens or routes.
- No deep-linking / URL handling.
- No arguments on routes (no screen needs them today).
- No changes to `MaterialApp` localization, themes, or startup gating.
- No changes to the `Navigator.pop` flows.
