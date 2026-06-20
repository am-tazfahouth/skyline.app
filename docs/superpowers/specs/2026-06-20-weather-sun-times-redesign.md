# WeatherSunTimes Redesign

## Summary

Redesign the `WeatherSunTimes` widget with a cleaner, minimalist UI showing a
sun/moon trajectory arc with 3 key points (start, peak, end). Add a title row
matching the existing `WeatherDailyTileList` / `WeatherHourlyTileList` pattern,
and support two visual modes (day/night) with sun vs moon icons.

## Architecture

### Files to modify

| File | Change |
|---|---|
| `lib/features/weather_forecast/presentation/widgets/weather_sun_times.dart` | Complete rewrite – replace `fl_chart` arc with `CustomPainter`, add title, 3-column layout |
| `lib/features/weather_forecast/presentation/widgets/sun_time/sun_times_ui_model.dart` | Refactor `PeriodConfig` to hold 3 `PeriodPoint` values + title/titleIcon; remove `ChartStyle` |
| `lib/features/weather_forecast/presentation/widgets/sun_time/time_row.dart` | Remove – replaced by inline column widgets |

### New files

None – everything stays in `sun_time/` directory.

### PeriodConfig (data model)

```dart
class PeriodPoint {
  final IconData icon;
  final Color iconColor;
  final String label;    // "Sunrise", "Midday", "Sunset", "Midnight"
  final String time;     // formatted HH:mm
}
```

`PeriodConfig` holds:
- `left`, `center`, `right` (`PeriodPoint`)
- `chartStart`, `chartEnd` (`DateTime`)
- `isDay` (`bool`)
- `title` (`String`) – "Sun Times" or "Night Times"
- `titleIcon` (`IconData`)

Computed values:
- Day center = sunrise + (sunset - sunrise) / 2
- Night center = sunset + (nextSunrise - sunset) / 2

### Widget layout

```
┌─────────────────────────────────────────────┐
│  ☀  Sun Times                               │  ← Title row
│                                              │
│    🌓          ☀          🌓                 │  ← 3 icons on arc
│   5:44       12:12       19:43              │  ← time (bold)
│  Sunrise     Midday      Sunset             │  ← label (light)
│       ╲       ●       ╱                     │  ← parabolic arc
│        ╲     ╱╲     ╱                      │    (CustomPainter)
│         ╲   ╱  ╲   ╱                       │
│          ╲ ╱    ╲ ╱                        │
│                                              │
└─────────────────────────────────────────────┘
```

- Arc: `CustomPainter` drawing `y = sin(x * π)`, golden-orange stroke, 2px.
- Progress dot: small filled circle at current time position on the arc.
- Icons: custom half-sun (sunrise/sunset), full sun+corona (midday), crescent moon (night sides), full moon (midnight center).
- Text: 2 lines per column – time (semi-bold, ~15px) + label (regular, ~11px, reduced opacity).
- Card uses `surface.colorContainer` background matching other widgets.

### Night mode

When `isDay == false`:
- `title` → "Night Times", `titleIcon` → moon icon
- All 3 points use moon icons
- left = sunset (crescent), center = midnight (full moon), right = next sunrise (crescent)

### Dependencies removed

- `fl_chart` import and `_SunPathChart` class removed from `weather_sun_times.dart`
- `ChartStyle` class removed from `sun_times_ui_model.dart`
- `TimeRow` widget removed (no longer referenced)

## Testing

- Update existing tests for `PeriodConfig` to cover 3-point structure.
- Add widget test verifying title text changes between day/night modes.
