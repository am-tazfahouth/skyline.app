import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/features/location/presentation/widgets/location_onboarding_sheet.dart';

void main() {
  Widget buildSheet({
    Locale locale = const Locale('en'),
    VoidCallback? onEnableLocation,
    VoidCallback? onLater,
    VoidCallback? onClose,
  }) {
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalisation.supportedLocales,
      localizationsDelegates: AppLocalisation.localizationsDelegates,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: LocationOnboardingSheet(
              onEnableLocation: onEnableLocation ?? () {},
              onLater: onLater ?? () {},
              onClose: onClose ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders title, body and both buttons in English', (
    tester,
  ) async {
    await tester.pumpWidget(buildSheet());

    expect(find.text('Set your location'), findsOneWidget);
    expect(
      find.text(
        'Enable location access to see the weather for your current position.',
      ),
      findsOneWidget,
    );
    expect(find.text('Enable location'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
  });

  testWidgets('renders title, body and both buttons in French', (tester) async {
    await tester.pumpWidget(buildSheet(locale: const Locale('fr')));

    expect(find.text('Définir votre position'), findsOneWidget);
    expect(
      find.text(
        'Autorisez la localisation pour voir la météo à votre position actuelle.',
      ),
      findsOneWidget,
    );
    expect(find.text('Activer la localisation'), findsOneWidget);
    expect(find.text('Plus tard'), findsOneWidget);
  });

  testWidgets('tapping the close icon triggers onClose', (tester) async {
    var closed = false;
    await tester.pumpWidget(buildSheet(onClose: () => closed = true));

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(closed, isTrue);
  });

  testWidgets('tapping the Later button triggers onLater', (tester) async {
    var later = false;
    await tester.pumpWidget(buildSheet(onLater: () => later = true));

    await tester.tap(find.text('Later'));
    await tester.pump();

    expect(later, isTrue);
  });

  testWidgets('tapping the Enable button triggers onEnableLocation', (
    tester,
  ) async {
    var enabled = false;
    await tester.pumpWidget(buildSheet(onEnableLocation: () => enabled = true));

    await tester.tap(find.text('Enable location'));
    await tester.pump();

    expect(enabled, isTrue);
  });

  testWidgets('system back navigation triggers onLater through PopScope', (
    tester,
  ) async {
    var later = false;
    await tester.pumpWidget(buildSheet(onLater: () => later = true));

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(later, isTrue);
  });
}
