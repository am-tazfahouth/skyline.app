import 'package:flutter/material.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/weather_daily_tile_list.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/weather_hourly_tile_list.dart';

class WeatherForecastSection extends StatefulWidget {
  const WeatherForecastSection({super.key});

  @override
  State<WeatherForecastSection> createState() => _WeatherForecastSectionState();
}

class _WeatherForecastSectionState extends State<WeatherForecastSection> {
  int _selectedTab = 0;
  final _tabs = const ['Today', 'Next 7 Day'];

  @override
  Widget build(BuildContext context) {
    final surface = AppTheme.surfaceFor(Theme.of(context).brightness);
    final primaryText = surface.onColor;
    final secondaryText = surface.onColorContainer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(_tabs.length, (i) {
            final selected = _selectedTab == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(right: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tabs[i],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                        color: selected ? primaryText : secondaryText,
                      ),
                    ),
                    const SizedBox(height: 5),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 2.5,
                      width: selected ? 24 : 0,
                      decoration: BoxDecoration(
                        color: primaryText,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 18),
        if (_selectedTab == 0)
          const WeatherHourlyTileList()
        else
          const WeatherDailyTileList(),
      ],
    );
  }
}
