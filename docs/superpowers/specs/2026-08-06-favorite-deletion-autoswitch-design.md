# Favorite Deletion Auto-Switch — Design Spec

**Date:** 2026-08-06
**Feature:** Automatically switch to another favorite when the favorite driving the weather content is deleted
**Status:** Approved

---

## 1. Overview

When a favorite is removed from the list (swipe-to-delete on `LocationScreen`), the app clears the location currently displayed by `WeatherContentView` (`currentLocation` in the location state). This resets the weather screen to the empty fallback (`--°C`) via `ResetWeatherEvent`, even when other favorites remain.

This spec changes the behavior: **when the deleted favorite is the one used by the weather content and other favorites remain, the app automatically promotes a replacement favorite as the new current location and fetches its weather.** If no favorite remains, the existing reset behavior is kept.

The replacement favorite is **the first favorite in the list** (list order respects the user's sort order from reordering). This decision was confirmed with the user.

---

## 2. Approach

Two approaches were considered:

- **A. Promote inside `LocationBloc._onRemoveFavorite` + react in `WeatherScreen` (chosen)** — The location bloc is already the single source of truth for the current location and last-location persistence. On removal it computes the replacement, persists it via `saveLastLocation`, and emits `LocationFavoritesLoaded` with the new `currentLocation`. The weather screen's existing listener gains one new trigger: a change of `currentLocation` to a different non-null location fetches weather for the new coordinates. No new events/states, no UI change.
- **B. Emit `LocationSelected` after removal to reuse the existing fetch path** — Rejected: `LocationSelected` has side effects in `LocationScreen` (it pops the navigator and auto-adds GPS locations as favorites), which would break the delete flow.

Approach A is minimal, reuses existing patterns, and keeps `LocationFavoritesLoaded` as the single state type emitted by favorite list mutations.

---

## 3. Architecture & Component Changes

### 3.1 `features/location/presentation/blocs/location_bloc.dart` — `_onRemoveFavorite`

After `repository.removeFavorite(...)` and reloading favorites, the current-location resolution changes:

- `previousLocation` (from `LocationSelected.location` or `LocationFavoritesLoaded.currentLocation`) is still read from the current state.
- `isStillFavorite` still determines whether `previousLocation` remains in the reloaded list.
- New logic:

| Condition | `currentLocation` emitted | Persistence |
|---|---|---|
| `isStillFavorite` | `previousLocation` (unchanged) | — |
| `!isStillFavorite`, `previousLocation != null`, `favorites.isNotEmpty` | `favorites.first` | `saveLastLocation(favorites.first)` |
| otherwise | `null` | `clearLastLocation()` when `favorites.isEmpty \|\| (previousLocation != null && currentLocation == null)` |

The `clearLastLocation()` condition is preserved from the current implementation. The promotion branch is the only behavioral change.

### 3.2 `features/weather_forecast/presentation/screens/weather_screen.dart`

**`listenWhen`** — add a trigger for `LocationFavoritesLoaded` transitions where the displayed location changes to a different non-null location:

```dart
listenWhen: (previous, current) {
  if (current is LocationSelected) return true;
  if (current is LocationFavoritesLoaded) {
    final previousLocation = switch (previous) {
      LocationSelected(location: final l) => l,
      LocationFavoritesLoaded(currentLocation: final c) => c,
      _ => null,
    };
    final currentLocation = current.currentLocation;
    if (currentLocation == null) return previousLocation != null;
    return previousLocation != null &&
        (previousLocation.latitude != currentLocation.latitude ||
            previousLocation.longitude != currentLocation.longitude);
  }
  return false;
},
```

**`listener`** — fetch for the promoted location:

```dart
if (state is LocationSelected) {
  ...fetch(state.location)...          // unchanged
} else if (state is LocationFavoritesLoaded) {
  final location = state.currentLocation;
  if (location == null) {
    ...ResetWeatherEvent...             // unchanged
  } else {
    context.read<WeatherForecastBloc>().add(FetchWeatherEvent(
      latitude: location.latitude,
      longitude: location.longitude,
    ));
  }
}
```

The `WeatherHeader` title already reflects `LocationFavoritesLoaded.currentLocation` (`weather_header.dart`), so the promoted city name appears immediately.

### 3.3 Deliberately non-triggering transitions

`listenWhen` must return `false` (no duplicate fetch) for:

- **Startup**: `LocationInitial` → `LocationFavoritesLoaded(favorites, lastLocation)` (`previousLocation == null`). The weather bloc already fetched via its own `getLastLocation()`.
- **Removing a non-current favorite**: same coordinates.
- **`AddFavoriteEvent` / `ReorderFavoritesEvent`**: same `currentLocation` coordinates.

---

## 4. Data Flow

```
Swipe-delete on LocationScreen (RemoveFavoriteEvent)
  → LocationBloc removes favorite, reloads list
  → favorite was current && others remain → promote favorites.first, saveLastLocation
  → emit LocationFavoritesLoaded(favorites, favorites.first)
  → WeatherHeader title updates (LocationBloc rebuild)
  → WeatherScreen.listenWhen true (coords changed)
  → FetchWeatherEvent(new lat/lon) → WeatherForecastBloc fetches and renders new location
```

---

## 5. Error Handling

- If `saveLastLocation` throws, the catch block in `_onRemoveFavorite` emits `LocationError(LocationErrorCodes.saveFavoriteFailed)` exactly as today; the removal is still persisted. No new error path is introduced.
- The weather fetch for the promoted location reuses the existing `FetchWeatherEvent` error handling (cached data fallback, `WeatherError` view, offline behavior). No changes.

---

## 6. Testing Strategy

TDD; `flutter analyze` (zero warnings) and `flutter test` must pass.

- **`test/features/location/presentation/blocs/location_bloc_test.dart`** — update the test `'removing the current favorite clears it even when other favorites remain'`: it now expects `currentLocation == otherLocation` (first remaining favorite), `saveLastLocation(otherLocation)` called once, and `clearLastLocation` **not** called. Add a case: removing the current favorite when it is the last remaining favorite still clears the persisted location (existing test already covers the empty case).
- **`test/features/weather_forecast/presentation/screens/weather_screen_test.dart`** — add a test: removing the currently displayed favorite switches weather to the first remaining favorite (verify `fetchWeather` called with the promoted coordinates and the screen renders the new location). Existing tests (`clearing the current location resets weather to the empty fallback`, GPS failure, startup) must stay green unchanged.

---

## 7. Commands

| Step | Command |
|---|---|
| Static analysis | `flutter analyze` |
| Targeted tests | `flutter test test/features/location/presentation/blocs/location_bloc_test.dart` |
| | `flutter test test/features/weather_forecast/presentation/screens/weather_screen_test.dart` |
| Full test suite | `flutter test` |

---

## 8. Non-Goals / Out of Scope

- No UI changes (no indication of the promoted favorite on `LocationScreen`).
- No new events, states, or repositories.
- No change to the GPS-failure or offline handling paths.
- No change to `_onLoadFavorites` or `_onAddFavorite` behaviors.
