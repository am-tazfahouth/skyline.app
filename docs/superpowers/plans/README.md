# Implementation Plans

Implementation plans break a validated design into **task-by-task steps** for agentic workers. Each plan follows the TDD cycle per task (failing test → implementation → verification), with `[ ]`/`[x]` checkboxes for tracking.

Execute plans with the **subagent-driven-development** (or **executing-plans**) workflow, one task at a time.

## Index

### Weather Forecast

| Date | Title | Description | Plan |
|------|-------|-------------|------|
| 2026-06-17 | Weather Offline Cache | Persist the last weather API response in ObjectBox | [plan](2026-06-17-weather-offline-cache.md) |
| 2026-06-18 | Cache-First Data Fetching | Cache-first strategy with background refresh | [plan](2026-06-18-cache-first-data-fetching.md) |
| 2026-06-20 | Weather Content View Redesign | Restructure main card, stats and forecast layout | [plan](2026-06-20-weather-content-view-redesign.md) |
| 2026-08-06 | Weather Content Localization | Localize weather UI strings and formats | [plan](2026-08-06-weather-content-localization.md) |
| 2026-08-09 | Cached Weather Notice | SnackBar for cached weather display | [plan](2026-08-09-cached-weather-notice.md) |
| 2026-08-10 | Cached Notice & Per-City Cache | Per-city cache + refined cached-data notice | [plan](2026-08-10-cached-notice-and-per-city-cache.md) |
| 2026-09-03 | Replace Error View with SnackBar | Drop `WeatherErrorView`, surface errors via SnackBar | [plan](2026-09-03-replace-error-view-with-snackbar.md) |

### Location

| Date | Title | Description | Plan |
|------|-------|-------------|------|
| 2026-07-27 | Location Feature | GPS, city search and favorites with swipe navigation | [plan](2026-07-27-location-feature.md) |
| 2026-07-31 | Location Screen Integration | Favorite list screen and location→weather wiring | [plan](2026-07-31-location-screen-integration.md) |
| 2026-08-05 | Reverse Geocoding Current Location | Real city name via BigDataCloud reverse geocoding | [plan](2026-08-05-reverse-geocoding-current-location.md) |
| 2026-08-06 | Favorite Deletion Auto-Switch | Auto-promote the next favorite after deletion | [plan](2026-08-06-favorite-deletion-autoswitch.md) |
| 2026-08-07 | Location Onboarding | First-launch onboarding bottom sheet + manual search fallback | [plan](2026-08-07-location-onboarding.md) |

### Settings

| Date | Title | Description | Plan |
|------|-------|-------------|------|
| 2026-06-24 | Settings Feature | Theme, language and unit preferences | [plan](2026-06-24-settings-feature.md) |
| 2026-08-11 | Settings Back-to-App | Android back button returns to the app | [plan](2026-08-11-settings-back-to-app.md) |
| 2026-08-20 | Creator Card | Credits card with creator info and social links | [plan](2026-08-20-creator-card.md) |
| 2026-09-04 | System Language First-Launch | Auto-detect system language on first launch | [plan](2026-09-04-system-language-first-launch.md) |

### Core / Cross-Cutting

| Date | Title | Description | Plan |
|------|-------|-------------|------|
| 2026-07-31 | App Routes Centralization | Centralized named-route generator with slide transitions | [plan](2026-07-31-app-routes-centralization.md) |
| 2026-08-09 | Boot Hydration | Hydrate favorites, onboarding and settings before `runApp` | [plan](2026-08-09-boot-hydration.md) |