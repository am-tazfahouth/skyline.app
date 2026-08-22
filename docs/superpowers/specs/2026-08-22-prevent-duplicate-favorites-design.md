# Design: Prevent Duplicate Favorite Locations

**Date:** 2026-08-22
**Status:** Approved

## Problem

Users can add the same location multiple times to their favorites. Today the only
protection is duplicated, fragile UI-level checks:

- `location_search_screen.dart` — exact double equality on lat/lng before dispatching `AddFavoriteEvent`
- `location_screen.dart` — same exact-equality check for the GPS auto-add flow

Exact double equality fails when coordinates come from different sources (GPS fix
vs geocoding API result) at different precision. The data layer (`DbHelper.saveFavorite`)
always inserts a new row.

## Decisions

| Question | Decision |
|---|---|
| Duplicate criterion | Rounded coordinates (4 decimals, ~11 m precision), consistent with the existing `_roundCoordinate` pattern in DbHelper. City name is NOT compared (homonyms cause false positives). |
| Behavior on duplicate | Silent skip: no insert, favorites reloaded, selection proceeds as usual. No error state — adding an existing favorite is not an error. |
| Enforcement point | Repository layer (`LocationRepositoryImpl.saveFavorite`) — guarantees the invariant for every caller, present and future. |

## Changes

1. **Domain** — `LocationEntity.isAtSamePointAs(LocationEntity other)`:
   rounds lat/lng to 4 decimals and compares.
2. **Data** — `LocationRepositoryImpl.saveFavorite`: early-return if any loaded
   favorite satisfies `isAtSamePointAs(location)`.
3. **Presentation cleanup**:
   - `location_search_screen.dart`: remove manual favorites check; always dispatch
     `AddFavoriteEvent` + `SelectLocationEvent`.
   - `location_screen.dart`: remove `alreadyFavorite` check; keep only the
     `location.isGpsLocation` condition.

## Testing

- Entity test: same point at different precisions → true; > 11 m apart → false.
- Repository test: duplicate is not persisted; distinct location is persisted.
- Bloc/screen tests unchanged (dedup lives behind the repository mock).

## Out of scope

- Migration/cleanup of already-stored duplicates in existing installs (none expected
  in production; dedup applies at write time only).
