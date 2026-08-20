import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/features/settings/presentation/widgets/creator_card.dart';

void main() {
  Widget createTestWidget() {
    final appTheme = AppTheme(ThemeData().textTheme);
    return MaterialApp(
      theme: appTheme.light(),
      localizationsDelegates: AppLocalisation.localizationsDelegates,
      supportedLocales: AppLocalisation.supportedLocales,
      home: const Scaffold(
        body: SingleChildScrollView(
          child: CreatorCard(),
        ),
      ),
    );
  }

  testWidgets('should display creator name and role', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('TzfLab'), findsOneWidget);
    expect(find.text('Creator & Developer'), findsOneWidget);
  });

  testWidgets('should display bio text', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Building SkyLine with passion for clean, professional weather experiences.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('should display social link labels', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('GitHub'), findsOneWidget);
    expect(find.text('Contact'), findsOneWidget);
  });

  testWidgets('should display social link icons', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.code_rounded), findsOneWidget);
    expect(find.byIcon(Icons.email_outlined), findsOneWidget);
  });

  testWidgets('should display app logo', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(
      find.image(const AssetImage('assets/images/logo/ic_launcher.png')),
      findsOneWidget,
    );
  });
}
