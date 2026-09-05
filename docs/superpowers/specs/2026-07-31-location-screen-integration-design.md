# Location Screen Integration — Design Spec

**Date:** 2026-07-31
**Feature:** Favorites location screen + WeatherHeader integration
**Status:** Approved

---

## 1. Overview

The `location` feature (bloc, search screen, favorites widget, ObjectBox storage) already exists and is wired into `main.dart`, but is **not connected to the weather UI**. This spec:

1. Adds a **`LocationScreen`** that lists favorite locations, with:
   - An AppBar titled `"Location"` and a **current-location (GPS) action button**
   - A **FloatingActionButton** (`add`) that navigates to the existing `LocationSearchScreen`
   - The list of favorite locations (reusing the existing `FavoritesListWidget`)
2. Integrates it into the weather UI:
   - The `WeatherHeader` **grid icon** navigates to `LocationScreen`
   - The hard-coded header title `'Moroni, Comoros'` is replaced by the **selected location title**, with the app title **`SkyLine`** as fallback when no location is selected
   - Selecting a location (favorite, search result, or GPS) **switches the displayed weather** via a `LocationBloc` → `WeatherForecastBloc` bridge

### User Flows

1. **Favorites list**: Weather screen → grid icon → `LocationScreen` shows favorites, reorderable and swipe-to-delete. FAB → search screen → tap a result → the city is **added to favorites** and **selected** → back to weather showing that city.
2. **GPS**: From `LocationScreen`, tap the GPS action → detect current position → position is **added to favorites** (if not present) and **selected** → back to weather.
3. **Header title**: Displays the currently selected location (`cityName, country`), or `SkyLine` when nothing is selected yet.

---

## 2. Architecture

**Approach:** Presentation-level wiring. No changes to `LocationBloc`, repository, data sources, or ObjectBox. Existing events (`AddFavoriteEvent`, `SelectLocationEvent`, `DetectCurrentLocationEvent`) are reused as-is; orchestration happens in widgets. This keeps `SelectLocationEvent` semantics pure ("select for display"), leaving room for a future star/remove-button UX.

### Files

| Action | File |
|---|---|
| Modify | `lib/features/location/domain/entities/location_entity.dart` — add `title` getter |
| Create | `lib/features/location/presentation/screens/location_screen.dart` |
| Modify | `lib/features/location/presentation/screens/location_search_screen.dart` — add-then-select on result tap |
| Modify | `lib/features/weather_forecast/presentation/widgets/weather_header.dart` |
| Modify | `lib/features/weather_forecast/presentation/screens/weather_screen.dart` |
| Test | `test/features/location/domain/entities/location_entity_test.dart` |
| Test | `test/features/location/presentation/screens/location_screen_test.dart` (new) |
| Test | `test/features/location/presentation/screens/location_search_screen_test.dart` (update) |
| Test | `test/features/weather_forecast/presentation/screens/weather_screen_test.dart` |

### Component Responsibilities

- **`LocationEntity.title`**: Domain getter — `cityName` + `country` (non-empty parts joined with `", "`). Single source for the header label.
- **`LocationScreen`**: Stateless scaffold that reads favorites from `LocationBloc` state, lets the user select a favorite or trigger GPS detection, and adds the GPS location to favorites when selected.
- **`WeatherHeader`**: Displays the location title from `LocationBloc` state; grid icon pushes `LocationScreen`.
- **`WeatherScreen`**: Bridges `LocationSelected` → `FetchWeatherEvent(latitude:, longitude:)` on `WeatherForecastBloc`.

---

## 3. `LocationEntity.title`

```dart
String get title => [cityName, country]
    .where((e) => e != null && e.isNotEmpty)
    .join(', ');
```

Examples:
- `cityName: 'Moroni', country: 'Comoros'` → `'Moroni, Comoros'`
- `cityName: 'Paris', country: null` → `'Paris'`
- `cityName: 'Current Location', country: null` → `'Current Location'`

---

## 4. `LocationScreen`

Location: `lib/features/location/presentation/screens/location_screen.dart`

- `Scaffold` with:
  - **AppBar**: title `Text('Location')`. Action: `IconButton(Icons.my_location_rounded)` that dispatches `DetectCurrentLocationEvent`. While the state is `LocationDetecting`, the icon is replaced by a small `CircularProgressIndicator`.
  - **Body**: `BlocBuilder<LocationBloc, LocationState>` that extracts `favorites` from either `LocationFavoritesLoaded.favorites` or `LocationSelected.favorites`, and renders the existing `FavoritesListWidget`. `onLocationTap` dispatches `SelectLocationEvent(location: location)` (no manual pop — the listener handles it).
  - **FloatingActionButton**: `Icons.add`, `onPressed` → `Navigator.push(LocationSearchScreen)`.
- `BlocListener<LocationBloc>`:
  - `LocationSelected`:
    1. If `state.location.isGpsLocation` and the location is **not** already among `state.favorites` (matched by coordinates), dispatch `AddFavoriteEvent(location: state.location)`.
    2. `Navigator.pop(context)` (guarded by `context.mounted`).
  - `LocationError` with code `gpsDisabled`, `gpsPermissionDenied`, or `gpsFailed` → `SnackBar` with `AppError.getUserErrorMessage(errorCode)`. Other `LocationError` codes are intentionally ignored here: search errors are rendered inline by `LocationSearchScreen`.

### Why the listener pops on any `LocationSelected`

The search screen dispatches `SelectLocationEvent` then pops itself synchronously. When the bloc handler completes and emits `LocationSelected`, the `LocationScreen` listener (mounted below) pops the `LocationScreen` route, landing the user back on the weather screen. Net result: selecting a city from search returns to weather showing that city. Favorites tap and GPS detection follow the same single-pop mechanism — one code path, no manual pops in handlers.

---

## 5. `LocationSearchScreen` — add-then-select

Location: `lib/features/location/presentation/screens/location_search_screen.dart`

Replace the result-tap handler so a picked city is **added to favorites** (when not already present) **and selected**:

```dart
final bloc = context.read<LocationBloc>();
final favorites = switch (bloc.state) {
  LocationFavoritesLoaded(favorites: final f) => f,
  LocationSelected(favorites: final f) => f,
  _ => const <LocationEntity>[],
};
final isAlreadyFavorite = favorites.any(
  (f) => f.latitude == location.latitude && f.longitude == location.longitude,
);
if (!isAlreadyFavorite) {
  bloc.add(AddFavoriteEvent(location: location));
}
bloc.add(SelectLocationEvent(location: location));
Navigator.pop(context);
```

Behavior:
- **New city** → `AddFavoriteEvent` (saves + emits `LocationFavoritesLoaded`) then `SelectLocationEvent` (emits `LocationSelected`). The `LocationScreen` listener pops on `LocationSelected`.
- **Already-favorite city** → duplicate guard skips `AddFavoriteEvent`; only selection occurs.

No other changes to the search screen (searching, loading, inline errors unchanged).

---

## 6. `WeatherHeader`

Location: `lib/features/weather_forecast/presentation/widgets/weather_header.dart`

- **Leading `grid_view_rounded` IconButton** `onPressed` → `Navigator.push(MaterialPageRoute(builder: (_) => const LocationScreen()))`.
- **Title**: replaced by a `BlocBuilder<LocationBloc, LocationState>` that resolves the label:
  - `LocationSelected(location)` → `location.title`
  - `LocationFavoritesLoaded(currentLocation)` → `currentLocation?.title`
  - otherwise → `'SkyLine'` (app title fallback)

Title styling is unchanged (`fontSize: 16`, `FontWeight.w800`).

---

## 7. `WeatherScreen` Bridge

Location: `lib/features/weather_forecast/presentation/screens/weather_screen.dart`

Wrap the existing content (loaded/error/initial views and the refresh overlay) in a `BlocListener<LocationBloc>`:

```dart
BlocListener<LocationBloc, LocationState>(
  listener: (context, state) {
    if (state is LocationSelected) {
      context.read<WeatherForecastBloc>().add(
        FetchWeatherEvent(
          latitude: state.location.latitude,
          longitude: state.location.longitude,
        ),
      );
    }
  },
  child: /* existing content / overlay logic */,
)
```

Only `LocationSelected` triggers a fetch — `LocationFavoritesLoaded` (startup) does not.

---

## 8. Error Handling

- GPS errors surface as a `SnackBar` on `LocationScreen` using the localized user message from `AppError.getUserErrorMessage` (debug strings never shown to the user).
- Search errors continue to render inline in `LocationSearchScreen`.
- No new error codes; `LocationErrorCodes` and `AppError` are unchanged.

---

## 9. Testing Strategy

TDD throughout; run `flutter test` and `flutter analyze` (zero warnings) before each commit.

- **Unit — `LocationEntity.title`**: with country, without country, empty country.
- **Widget — `LocationScreen`** (`location_screen_test.dart`, new):
  - renders title `'Location'`
  - renders favorites list and the empty state (`'No favorites yet'`)
  - FAB navigates to `LocationSearchScreen`
  - GPS action dispatches `DetectCurrentLocationEvent`
  - GPS result (`LocationSelected` with `isGpsLocation`) dispatches `AddFavoriteEvent` and pops
  - non-GPS `LocationSelected` pops without dispatching `AddFavoriteEvent`
  - favorite tap dispatches `SelectLocationEvent`
  - GPS `LocationError` shows a `SnackBar`
- **Widget — `LocationSearchScreen`** (`location_search_screen_test.dart`, update):
  - result tap dispatches `AddFavoriteEvent` then `SelectLocationEvent` for a new city
  - result tap skips `AddFavoriteEvent` when the city is already a favorite
- **Widget — `WeatherScreen`** (`weather_screen_test.dart`, update):
  - fallback header title is `'SkyLine'` when no location is selected (replaces the `'Moroni, Comoros'` assertion)
  - header shows the selected location title when `LocationBloc` emits `LocationSelected` / `LocationFavoritesLoaded`
  - grid icon navigates to `LocationScreen`
  - `LocationSelected` triggers `FetchWeatherEvent(latitude:, longitude:)` on the weather bloc

---

## 10. Non-Goals / Out of Scope

- No changes to `LocationBloc`, repository, data sources, or ObjectBox.
- No GPS auto-detection at app startup (existing behavior unchanged).
- No PageView/favorites-swipe on the weather screen (a later integration).
- No reverse geocoding for the GPS label (`'Current Location'` stays).
- No changes to `AddFavoriteEvent`/`RemoveFavoriteEvent`/`ReorderFavoritesEvent` contracts.
