# Weather Content View Redesign — Design Spec

**Date:** 2026-06-20
**Status:** Approved

## Objective

Redesign the layout and visual structure of `WeatherContentView` and its child widgets (`WeatherMainCard`, `WeatherStatsCard`, `WeatherForecastSection`) to improve visual hierarchy and readability.

## Changes

### 1. WeatherMainCard

**Before:** Row layout with text column (date, condition, temperature) on the left and weather icon on the right, wrapped in a styled container with background color and border radius.

**After:**
- Remove outer container decoration (background color, border radius)
- Layout arranged as a centered Column: Icon (top) → Temperature (52pt, bold) → Condition → Date (bottom)
- All elements centered horizontally

### 2. WeatherStatsCard

**Before:** Single styled container with all 3 stats (Wind, Chance of Rain, Humidity) in a Row separated by vertical dividers.

**After:**
- Remove the outer container decoration
- Each stat (Wind, Rain, Humidity) rendered in its own individual card with `colorContainer` background and `BorderRadius.circular(18)`
- 3 individual cards arranged in a horizontal Row

### 3. WeatherForecastSection

**Before:** Tab-based toggle between "Today" (WeatherHourlyTileList) and "Next 7 Day" (WeatherDailyTileList) with animated underline indicator.

**After:**
- Remove the tab switcher entirely
- Both sections visible simultaneously
- **Hourly Forecast:** Horizontal scrollable card with title "Hourly Forecast" wrapping the WeatherHourlyTileList content
- **Next 7 Days:** Vertical card with title, each day rendered as a horizontal row (Day name · Weather icon · Temperature range)

### 4. WeatherContentView

No structural changes to the main view. Child widget order remains: WeatherMainCard → WeatherStatsCard → WeatherForecastSection → WeatherSunTimes.

## Files to Modify

| File | Change |
|---|---|
| `lib/features/weather_forecast/presentation/widgets/weather_main_card.dart` | Remove container decoration, change to centered Column layout |
| `lib/features/weather_forecast/presentation/widgets/weather_stats_card.dart` | Remove outer container, wrap each stat in individual card |
| `lib/features/weather_forecast/presentation/widgets/weather_forecast_section.dart` | Remove tab system, show both sections with titles and cards |

## Non-Goals

- No data model changes
- No BLoC/state changes
- No changes to WeatherHourlyTileList, WeatherDailyTileList, or WeatherSunTimes widgets
- No color/theme changes
