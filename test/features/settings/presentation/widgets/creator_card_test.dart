import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/features/settings/presentation/widgets/creator_card.dart';

Widget createTestScreen() {
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

void main() {
  group('CreatorCard', () {
    testWidgets('should display the creator name', (tester) async {
      await tester.pumpWidget(createTestScreen());
      expect(find.text('TzfLab'), findsOneWidget);
    });

    testWidgets('should display the creator role from l10n', (tester) async {
      await tester.pumpWidget(createTestScreen());
      expect(find.text('Creator & Developer'), findsOneWidget);
    });

    testWidgets('should display the creator bio from l10n', (tester) async {
      await tester.pumpWidget(createTestScreen());
      expect(find.textContaining('Building SkyLine'), findsOneWidget);
    });

    testWidgets('should display GitHub social link', (tester) async {
      await tester.pumpWidget(createTestScreen());
      expect(find.text('GitHub'), findsOneWidget);
    });

    testWidgets('should display Contact social link', (tester) async {
      await tester.pumpWidget(createTestScreen());
      expect(find.text('Contact'), findsOneWidget);
    });

    testWidgets('should have tappable GitHub link', (tester) async {
      await tester.pumpWidget(createTestScreen());
      final githubLink = find.text('GitHub');
      expect(githubLink, findsOneWidget);
      final inkWell = find.ancestor(
        of: githubLink,
        matching: find.byType(InkWell),
      );
      expect(inkWell, findsOneWidget);
    });

    testWidgets('should have tappable Contact link', (tester) async {
      await tester.pumpWidget(createTestScreen());
      final contactLink = find.text('Contact');
      expect(contactLink, findsOneWidget);
      final inkWell = find.ancestor(
        of: contactLink,
        matching: find.byType(InkWell),
      );
      expect(inkWell, findsOneWidget);
    });
  });
}
