# Sun Times Redesign

## Overview

Redesign `WeatherSunTimes` widget to a simpler, more elegant layout showing 3 time
points (instead of the current 2) connected by an arc path CustomPainter. Add a
title matching the pattern used by `WeatherDailyTileList` and
`WeatherHourlyTileList`. Remove the `fl_chart` dependency from this widget.

## Motivation

The current widget uses `fl_chart` for a sun-path chart that is complex and
consumes unnecessary horizontal space. The design also only shows 2 time points
(sunrise/sunset or sunset/sunrise) without indicating the full progression.

## Design

### `TimePoint` Widget

Small inline stateless widget (defined inside `weather_sun_times.dart`):
`Column(icon, label, time)` — no separate file.

### `SunArcData` Value Object

Holds the data for `SunArcPainter`: `startFraction`, `endFraction`,
`progressFraction` (0.0–1.0), `pastColor`, `futureColor`, `dotColor`,
`dotShadowColor`. Passed from `PeriodConfig` computed values.

### Data Model — `PeriodConfig` Extension

`PeriodConfig` (in `sun_times_ui_model.dart`) gains 3 time points:

- **Day mode:** sunrise, zenith (computed), sunset
- **Night mode:** sunset, middle of night (computed), sunrise

Computed values:
- Zenith = `sunrise + (sunset - sunrise) / 2`
- Middle of night = `sunset + (nextSunrise - sunset) / 2`

Each time point carries: `IconData`, `Color`, `String label`, `String time`.

The config also exposes:
- `periodProgress` (double 0.0–1.0) — current position in the period
- `isDay` (bool) — which mode

### Widget Layout

```
WeatherSunTimes (StatelessWidget)
└── BlocBuilder<WeatherForecastBloc, WeatherForecastState>
    └── Container (card styling, padding 16, border radius 14)
        └── Column
            ├── Row (title) → Icon + "Sun Times" text (W700, size 14)
            ├── SizedBox(height: 12)
            └── SizedBox(height: ~100)
                └── Stack
                    ├── SunArcPainter (CustomPainter)
                    └── Row of 3 TimePoint widgets
```

**TimePoint widget:** A `Column` with icon (size 20), label text (size 11,
secondary color), and time text (size 15, W700, primary color). Spaced evenly
in the row.

### `SunArcPainter` (CustomPainter)

Draws a quadratic bezier curve from the first time point position to the last,
with the control point at the top center. The arc is split into:
- **Elapsed portion** — solid stroke, bright color (amber for day, indigo for night)
- **Future portion** — dashed stroke, muted color

A filled circle dot at the current time position on the curve with a subtle
shadow glow.

Uses only `dart:ui` Canvas — no fl_chart dependency.

### Colors

| Mode | Time | Icon | Color |
|---|---|---|---|
| Day | Sunrise | `Icons.wb_sunny_outlined` | Primary (amber) |
| Day | Zenith | `Icons.wb_sunny` | Bright yellow/amber |
| Day | Sunset | `Icons.nightlight_round_outlined` | Secondary (indigo) |
| Night | Sunset | `Icons.nightlight_round_outlined` | Secondary |
| Night | Midnight | `Icons.dark_mode_outlined` | Deep indigo |
| Night | Sunrise | `Icons.wb_sunny_outlined` | Primary |

### Placeholder State

When no data is available, render 3 grayed-out `TimePoint` widgets with `--:--`
times, no arc.

### Files Changed

| File | Change |
|---|---|
| `weather_sun_times.dart` | Rewrite: remove fl_chart import, remove `_SunPathChart`, add title, add `SunArcPainter`, use new `PeriodConfig` fields |
| `sun_times_ui_model.dart` | Add 3rd time point to `PeriodConfig`, add `periodProgress`, add `SunArcData` value object for painter input |
| `time_row.dart` | No change (kept for potential reuse) |

### Files Unchanged

`weather_forecast_section.dart`, `weather_content_view.dart`, all BLoC files.

### Testing

- Unit test `PeriodConfig` — verify zenith and middle-of-night computation
- Unit test `SunArcPainter` — verify paint output with known inputs
- Widget test `WeatherSunTimes` — verify title renders, 3 time points visible,
  placeholder fallback
