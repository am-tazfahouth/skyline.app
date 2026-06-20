# WeatherContentView Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign WeatherMainCard, WeatherStatsCard, and WeatherForecastSection layout and visual structure.

**Architecture:** Pure UI changes to 3 presentation-layer widgets. No data model, BLoC, or domain changes. Each widget is modified independently.

**Tech Stack:** Flutter, Dart, flutter_bloc

---

### Task 1: WeatherMainCard — Column layout, remove decoration

**Files:**
- Modify: `lib/features/weather_forecast/presentation/widgets/weather_main_card.dart`

- [ ] **Step 1: Modify WeatherMainCard layout**

Replace the current `Container` (with decoration + Row) with a plain Column layout centered, no background container.

```dart
// Current (Container with Row):
return Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
  decoration: BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(22),
  ),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date, ...),
            SizedBox(height: 6),
            Text(condition, ...),
            SizedBox(height: 10),
            Text(temperature, ...),
          ],
        ),
      ),
      Icon(iconData, color: primaryText, size: iconSize),
    ],
  ),
);

// New (centered Column, no container decoration):
return Column(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Icon(iconData, color: primaryText, size: iconSize),
    const SizedBox(height: 12),
    Text(
      temperature,
      style: TextStyle(
        fontSize: 52,
        fontWeight: FontWeight.bold,
        color: primaryText,
        height: 1,
      ),
    ),
    const SizedBox(height: 6),
    Text(
      condition,
      style: TextStyle(
        fontSize: 15,
        color: primaryText,
        fontWeight: FontWeight.w500,
      ),
    ),
    const SizedBox(height: 4),
    Text(date,
        style: TextStyle(fontSize: 12, color: secondaryText)),
  ],
);
```

- [ ] **Step 2: Run flutter analyze**

```bash
flutter analyze
```
Expected: No errors or warnings.

- [ ] **Step 3: Commit**

```bash
git add lib/features/weather_forecast/presentation/widgets/weather_main_card.dart
git commit -m "refactor: WeatherMainCard now uses centered Column without container decoration"
```

---

### Task 2: WeatherStatsCard — Individual stat cards in Row

**Files:**
- Modify: `lib/features/weather_forecast/presentation/widgets/weather_stats_card.dart`

- [ ] **Step 1: Modify WeatherStatsCard layout**

Replace the outer `Container` decoration with a simple Row wrapping 3 individual card containers.
Remove `_buildVerticalDivider`, wrap each `_buildStatItem` in its own card-style Container.

```dart
// Current build method body:
return Container(
  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
  decoration: BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(22),
  ),
  child: Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(...),
          _buildVerticalDivider(secondaryText: secondaryText),
          _buildStatItem(...),
          _buildVerticalDivider(secondaryText: secondaryText),
          _buildStatItem(...),
        ],
      ),
    ],
  ),
);

// New:
return Row(
  children: [
    Expanded(child: _buildStatCard(
      icon: Icons.air_rounded,
      value: wind,
      label: 'Wind',
      cardColor: cardColor,
      primaryText: primaryText,
      secondaryText: secondaryText,
    )),
    const SizedBox(width: 10),
    Expanded(child: _buildStatCard(
      icon: Icons.umbrella_rounded,
      value: rain,
      label: 'Chance of rain',
      cardColor: cardColor,
      primaryText: primaryText,
      secondaryText: secondaryText,
    )),
    const SizedBox(width: 10),
    Expanded(child: _buildStatCard(
      icon: Icons.water_drop_outlined,
      value: humidity,
      label: 'Humidity',
      cardColor: cardColor,
      primaryText: primaryText,
      secondaryText: secondaryText,
    )),
  ],
);
```

Replace `_buildStatItem` and `_buildVerticalDivider` with `_buildStatCard`:

```dart
Widget _buildStatCard({
  required IconData icon,
  required String value,
  required String label,
  required Color cardColor,
  required Color primaryText,
  required Color secondaryText,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: secondaryText, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: primaryText,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(color: secondaryText, fontSize: 11)),
      ],
    ),
  );
}
```

- [ ] **Step 2: Run flutter analyze**

```bash
flutter analyze
```
Expected: No errors or warnings.

- [ ] **Step 3: Commit**

```bash
git add lib/features/weather_forecast/presentation/widgets/weather_stats_card.dart
git commit -m "refactor: WeatherStatsCard wraps each stat in individual card, removes dividers"
```

---

### Task 3: WeatherForecastSection — Remove tabs, show both sections with titles

**Files:**
- Modify: `lib/features/weather_forecast/presentation/widgets/weather_forecast_section.dart`
- Modify: `lib/features/weather_forecast/presentation/widgets/weather_daily_tile_list.dart`

- [ ] **Step 1: Modify WeatherForecastSection layout**

Convert from `StatefulWidget` (tab switcher) to `StatelessWidget`. Show both Hourly (horizontal scroll card) and 7-Day (vertical list card) sections with titles.

```dart
class WeatherForecastSection extends StatelessWidget {
  const WeatherForecastSection({super.key});

  @override
  Widget build(BuildContext context) {
    final surface = AppTheme.surfaceFor(Theme.of(context).brightness);
    final cardColor = surface.colorContainer;
    final primaryText = surface.onColor;
    final secondaryText = surface.onColorContainer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Hourly Forecast ---
        Text(
          'Hourly Forecast',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: primaryText,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const WeatherHourlyTileList(),
        ),
        const SizedBox(height: 28),
        // --- Next 7 Days ---
        Text(
          'Next 7 Days',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: primaryText,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const WeatherDailyTileList(),
        ),
      ],
    );
  }
}
```

**Important:** The `WeatherDailyTileList` currently scrolls horizontally, but the spec says each day should be a horizontal row in a vertical card. We need to modify `WeatherDailyTileList` to display vertically (each day as a Row in a Column) instead of horizontal scroll.

- [ ] **Step 1b: Modify WeatherDailyTileList for vertical layout**

Change `weather_daily_tile_list.dart` from horizontal `SingleChildScrollView` > `Row` to a vertical `Column` of row items.

```dart
// Replace the return in the builder:
// Before:
return SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  clipBehavior: Clip.none,
  child: Row(
    children: items.map((item) { ... }).toList(),
  ),
);

// After:
return Column(
  children: items.map((item) {
    final day = DateFormat('E').format(item.date);
    final temp =
        '${item.tempMax.toStringAsFixed(0)}° / ${item.tempMin.toStringAsFixed(0)}°';
    return _buildRowTile(
      day: day,
      icon: WeatherIconMapper.fromWeatherCode(item.weatherCode),
      temp: temp,
      primaryText: primaryText,
      secondaryText: secondaryText,
      cardColor: cardColor,
    );
  }).toList(),
);
```

Add `_buildRowTile` method and replace old `_buildTile`:

```dart
Widget _buildRowTile({
  required String day,
  required IconData icon,
  required String temp,
  required Color primaryText,
  required Color secondaryText,
  required Color cardColor,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(
            day,
            style: TextStyle(color: secondaryText, fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, color: secondaryText, size: 22),
        const Spacer(),
        Text(
          temp,
          style: TextStyle(
            color: primaryText,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
```

Also update `_buildPlaceholder` to match the new vertical pattern:

```dart
// In _buildPlaceholder, replace the horizontal scroll Row with a Column:
return Column(
  children: List.generate(
    5,
    (_) => _buildRowTile(
      day: '--',
      icon: Icons.cloud_rounded,
      temp: '--° / --°',
      primaryText: primaryText,
      secondaryText: secondaryText,
      cardColor: cardColor,
    ),
  ),
);
```

- [ ] **Step 2: Run flutter analyze**

```bash
flutter analyze
```
Expected: No errors or warnings.

- [ ] **Step 3: Commit**

```bash
git add lib/features/weather_forecast/presentation/widgets/weather_forecast_section.dart lib/features/weather_forecast/presentation/widgets/weather_daily_tile_list.dart
git commit -m "refactor: WeatherForecastSection shows both sections simultaneously, daily tiles vertical"
```

---

### Verification

- [ ] **Run flutter analyze**

```bash
flutter analyze
```

- [ ] **Run flutter test**

```bash
flutter test
```
