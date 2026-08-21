import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/section_header.dart';

void main() {
  Widget buildWidget({
    IconData icon = Icons.access_time_filled_outlined,
    String title = 'Hourly',
    Color color = Colors.white,
  }) {
    return MaterialApp(
      theme: AppTheme(ThemeData().textTheme).light(),
      home: Scaffold(
        body: WeatherSectionHeader(icon: icon, title: title, color: color),
      ),
    );
  }

  testWidgets('renders the icon, title and color', (tester) async {
    await tester.pumpWidget(buildWidget());

    expect(find.text('Hourly'), findsOneWidget);
    expect(find.byIcon(Icons.access_time_filled_outlined), findsOneWidget);
  });

  testWidgets('applies the provided color to icon and title', (tester) async {
    await tester.pumpWidget(
      buildWidget(title: 'Daily', color: const Color(0xFFFF0000)),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.access_time_filled_outlined));
    final text = tester.widget<Text>(find.text('Daily'));

    expect(icon.color, const Color(0xFFFF0000));
    expect(text.style?.color, const Color(0xFFFF0000));
    expect(text.style?.fontSize, 14);
    expect(text.style?.fontWeight, FontWeight.w700);
  });
}
