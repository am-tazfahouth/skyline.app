import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/features/settings/presentation/widgets/creator_card.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class MockUrlLauncherPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  String? lastLaunchedUrl;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUrl = url;
    return true;
  }

  @override
  Future<bool> canLaunch(String url) async => true;
}

void main() {
  late MockUrlLauncherPlatform mockPlatform;

  setUp(() {
    mockPlatform = MockUrlLauncherPlatform();
    UrlLauncherPlatform.instance = mockPlatform;
  });

  Widget createTestWidget({ThemeData? theme}) {
    final appTheme = AppTheme(ThemeData().textTheme);
    return MaterialApp(
      theme: theme ?? appTheme.light(),
      localizationsDelegates: AppLocalisation.localizationsDelegates,
      supportedLocales: AppLocalisation.supportedLocales,
      home: const Scaffold(body: SingleChildScrollView(child: CreatorCard())),
    );
  }

  testWidgets('should display creator name and role', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Ali Mohamed Tazfahouth'), findsOneWidget);
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

  testWidgets('should launch GitHub URL on tap', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('GitHub'));
    await tester.pumpAndSettle();

    expect(mockPlatform.lastLaunchedUrl, 'https://github.com/am-tazfahouth');
  });

  testWidgets('should launch email URL on tap', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Contact'));
    await tester.pumpAndSettle();

    expect(mockPlatform.lastLaunchedUrl, 'mailto:am.tazfahouth@gmail.com');
  });

  testWidgets('should render correctly in dark theme', (tester) async {
    final appTheme = AppTheme(ThemeData().textTheme);
    await tester.pumpWidget(createTestWidget(theme: appTheme.dark()));
    await tester.pumpAndSettle();

    expect(find.text('Ali Mohamed Tazfahouth'), findsOneWidget);
    expect(find.text('Creator & Developer'), findsOneWidget);
    expect(find.text('GitHub'), findsOneWidget);
    expect(find.text('Contact'), findsOneWidget);
    expect(find.byIcon(Icons.code_rounded), findsOneWidget);
    expect(find.byIcon(Icons.email_outlined), findsOneWidget);
  });
}
