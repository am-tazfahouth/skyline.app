import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/features/weather_forecast/presentation/utils/cached_weather_feedback.dart';

void main() {
  Future<void> pumpFeedback(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: AppLocalisation.supportedLocales,
        localizationsDelegates: AppLocalisation.localizationsDelegates,
        home: Builder(
          builder: (context) => Scaffold(
            body: Builder(
              builder: (innerContext) => ElevatedButton(
                onPressed: () => showCachedWeatherSnackBar(innerContext),
                child: const Text('trigger'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the localized cached-data message with no action',
      (tester) async {
    await pumpFeedback(tester);

    expect(
      find.text('No internet connection. Showing cached data.'),
      findsOneWidget,
    );
    expect(find.byType(SnackBarAction), findsNothing);
  });
}
