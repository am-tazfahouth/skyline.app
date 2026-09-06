# Design Specs

Design documents describe the **what** and the **why** of each change before any implementation: problem, chosen approach, architecture, errors, and test strategy.

Every feature or cross-cutting change goes through **Spec → Plan → Implementation**. The current phase of each spec is reflected in its `Status` metadata.

## Index

### Weather Forecast

| Date | Title | Description | Doc |
|------|-------|-------------|-----|
| 2026-06-16 | Weather Forecast Feature | Initial feature: current, hourly and daily weather from Open-Meteo | [spec](2026-06-16-weather-forecast-design.md) |
| 2026-06-17 | Weather Offline Cache | Persist the last weather response via ObjectBox for offline display | [spec](2026-06-17-weather-offline-cache-design.md) |
| 2026-06-18 | Cache-First Data Fetching | Show cached data immediately, refresh in the background | [spec](2026-06-18-cache-first-data-fetching-design.md) |
| 2026-06-20 | Weather Content View Redesign | Redesign the main weather card, stats card and forecast section | [spec](2026-06-20-weather-content-view-redesign-design.md) |
| 2026-08-06 | Weather Content Localization | Localize every user-visible string and date/time format on weather UI | [spec](2026-08-06-weather-content-localization-design.md) |
| 2026-08-09 | Cached Weather Notice | Show a SnackBar when weather comes from the offline cache | [spec](2026-08-09-cached-weather-notice-design.md) |
| 2026-08-10 | Cached Notice & Per-City Cache | Per-city weather cache + restrict cached-data notice to genuine loads | [spec](2026-08-10-cached-notice-and-per-city-cache-design.md) |

### Location

| Date | Title | Description | Doc |
|------|-------|-------------|-----|
| 2026-07-27 | Location Feature | GPS detection, city search and favorites management | [spec](2026-07-27-location-feature-design.md) |
| 2026-07-31 | Location Screen Integration | Favorite list screen and location→weather navigation | [spec](2026-07-31-location-screen-integration-design.md) |
| 2026-08-06 | Favorite Deletion Auto-Switch | Promote the first remaining favorite when the displayed one is deleted | [spec](2026-08-06-favorite-deletion-autoswitch-design.md) |
| 2026-08-22 | Prevent Duplicate Favorites | Block adding the same location twice as a favorite | [spec](2026-08-22-prevent-duplicate-favorites-design.md) |

### Settings

| Date | Title | Description | Doc |
|------|-------|-------------|-----|
| 2026-06-24 | Settings Feature | Theme, language and unit preferences with ObjectBox persistence | [spec](2026-06-24-settings-feature-design.md) |
| 2026-08-11 | Settings Back-to-App | Android back button returns to the app after opening settings | [spec](2026-08-11-settings-back-to-app-design.md) |
| 2026-08-20 | Creator Card | Credits card in Settings with creator info and social links | [spec](2026-08-20-creator-card-design.md) |
| 2026-09-04 | System Language First-Launch | Auto-detect the device system language on first launch | [spec](2026-09-04-system-language-first-launch-design.md) |

### Core / Cross-Cutting

| Date | Title | Description | Doc |
|------|-------|-------------|-----|
| 2026-07-31 | App Routes Centralization | Centralized named-route generator with slide transitions | [spec](2026-07-31-app-routes-design.md) |
| 2026-08-09 | Boot Hydration | Hydrate favorites, onboarding and settings before `runApp` | [spec](2026-08-09-boot-hydration-design.md) |
| 2026-09-05 | APK GitHub Releases Delivery | Signed per-ABI APKs published to GitHub Releases on versioned tags | [spec](2026-09-05-apk-github-releases-design.md) |
| 2026-09-06 | Release Naming & Share Button | SkyLine-branded release assets/title + share latest Release from Settings | [spec](2026-09-06-release-naming-and-share-button-design.md) |