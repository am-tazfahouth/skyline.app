# Creator Card Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a standalone CreatorCard widget to the Settings screen's About section with creator name, role, bio, and tappable GitHub/Email social links.

**Architecture:** New `CreatorCard` StatelessWidget follows the existing `SettingCard` container pattern (surface.colorContainer background, AppRadius.md, AppSpacing.md). Uses `url_launcher` for opening GitHub and mailto links. Localization keys added to all 4 ARB files and regenerated via `flutter gen-l10n`.

**Tech Stack:** Flutter, url_launcher ^6.3.0, flutter gen-l10n (l10n.yaml), flutter_test + mocktail

## Global Constraints

- Flutter >=3.35.0, Dart ^3.9.2
- Material3 enabled, SFPro font family
- All code in English (variables, comments, classes)
- Equatable for domain entities (not needed here — widget only)
- No code generation for immutability (freezed banned)
- Zero `flutter analyze` warnings tolerated
- Card pattern: `AppTheme.surfaceFor(brightness).colorContainer` background, `AppRadius.md` border radius
- Text colors: `surface.onColor` for primary, `surface.onColorContainer` for secondary
- Spacing: `AppSpacing.*` constants only
- Localization: ARB files in `lib/core/l10n/arb/`, generated via `flutter gen-l10n`

---

### Task 1: Add url_launcher dependency

**Files:**
- Modify: `pubspec.yaml:30-51` (dependencies section)

**Interfaces:**
- Consumes: nothing
- Produces: `url_launcher` package available project-wide

- [ ] **Step 1: Add url_launcher to pubspec.yaml**

In `pubspec.yaml`, add under `dependencies:` after the `package_info_plus` line (line 45):

```yaml
  url_launcher: ^6.3.0
```

- [ ] **Step 2: Run flutter pub get**

Run: `flutter pub get`
Expected: success with no errors

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add url_launcher dependency"
```

---

### Task 2: Add localization keys for creator card

**Files:**
- Modify: `lib/core/l10n/arb/intl_en.arb`
- Modify: `lib/core/l10n/arb/intl_fr.arb`
- Modify: `lib/core/l10n/arb/intl_es.arb`
- Modify: `lib/core/l10n/arb/intl_ar.arb`

**Interfaces:**
- Consumes: nothing
- Produces: 4 new l10n keys available via `AppLocalisation`: `settingsCreatorRole`, `settingsCreatorBio`, `settingsCreatorGithub`, `settingsCreatorContact`

- [ ] **Step 1: Add keys to intl_en.arb**

In `lib/core/l10n/arb/intl_en.arb`, add before the closing `}` (before line 228), after the `settingsCopyright` block (after line 68):

```json
  "settingsCreatorRole": "Creator & Developer",
  "@settingsCreatorRole": {
    "description": "Role label for the app creator"
  },
  "settingsCreatorBio": "Building SkyLine with passion for clean, professional weather experiences.",
  "@settingsCreatorBio": {
    "description": "Short bio of the app creator"
  },
  "settingsCreatorGithub": "GitHub",
  "@settingsCreatorGithub": {
    "description": "Label for the GitHub social link"
  },
  "settingsCreatorContact": "Contact",
  "@settingsCreatorContact": {
    "description": "Label for the email contact link"
  },
```

- [ ] **Step 2: Add keys to intl_fr.arb**

In `lib/core/l10n/arb/intl_fr.arb`, add before the closing `}` (before line 98), after `settingsCopyright` (line 20):

```json
  "settingsCreatorRole": "Créateur & Développeur",
  "settingsCreatorBio": "Construire SkyLine avec passion pour des expériences météo propres et professionnelles.",
  "settingsCreatorGithub": "GitHub",
  "settingsCreatorContact": "Contact",
```

- [ ] **Step 3: Add keys to intl_es.arb**

In `lib/core/l10n/arb/intl_es.arb`, add before the closing `}` (before line 98), after `settingsCopyright` (line 20):

```json
  "settingsCreatorRole": "Creador y Desarrollador",
  "settingsCreatorBio": "Construyendo SkyLine con pasión por experiencias climáticas limpias y profesionales.",
  "settingsCreatorGithub": "GitHub",
  "settingsCreatorContact": "Contacto",
```

- [ ] **Step 4: Add keys to intl_ar.arb**

In `lib/core/l10n/arb/intl_ar.arb`, add before the closing `}` (before line 98), after `settingsCopyright` (line 20):

```json
  "settingsCreatorRole": "المنشئ والمطور",
  "settingsCreatorBio": "بناء SkyLine بشغف من أجل تجارب طقس نظيفة واحترافية.",
  "settingsCreatorGithub": "GitHub",
  "settingsCreatorContact": "اتصل",
```

- [ ] **Step 5: Regenerate localization files**

Run: `flutter gen-l10n`
Expected: success, regenerated `lib/core/l10n/app_localisation.dart` and locale-specific files with new getters

- [ ] **Step 6: Verify generated getters exist**

Run: `grep -n "settingsCreatorRole\|settingsCreatorBio\|settingsCreatorGithub\|settingsCreatorContact" lib/core/l10n/app_localisation.dart`
Expected: 4 abstract getter declarations found

- [ ] **Step 7: Commit**

```bash
git add lib/core/l10n/
git commit -m "feat(l10n): add creator card localization keys"
```

---

### Task 3: Create CreatorCard widget

**Files:**
- Create: `lib/features/settings/presentation/widgets/creator_card.dart`

**Interfaces:**
- Consumes: `AppLocalisation` for 4 localized strings, `AppTheme.surfaceFor()` for colors, `TextStyleCatalog` for text styles, `url_launcher` for launching URLs
- Produces: `CreatorCard` StatelessWidget (no parameters — self-contained)

- [ ] **Step 1: Write CreatorCard widget**

Create `lib/features/settings/presentation/widgets/creator_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/constants/app_radius.dart';
import 'package:sky_line/core/constants/app_spacing.dart';
import 'package:sky_line/core/constants/app_text_styles.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:url_launcher/url_launcher.dart';

class CreatorCard extends StatelessWidget {
  const CreatorCard({super.key});

  static const String _githubUrl = 'https://github.com/PLACEHOLDER_USERNAME';
  static const String _emailAddress = 'PLACEHOLDER_EMAIL';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalisation.of(context)!;
    final surface = AppTheme.surfaceFor(Theme.of(context).brightness);
    final styles = Theme.of(context).extension<TextStyleCatalog>()!;
    final cardColor = surface.colorContainer;
    final primaryText = surface.onColor;
    final secondaryText = surface.onColorContainer;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Image.asset(
                      'assets/images/logo/ic_launcher.png',
                      height: 60,
                      width: 60,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TzfLab',
                          style: styles.headlineMedium.copyWith(color: primaryText),
                        ),
                        Text(
                          l10n.settingsCreatorRole,
                          style: styles.bodyMedium.copyWith(color: secondaryText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.settingsCreatorBio,
                style: styles.bodyMedium.copyWith(color: secondaryText),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _SocialLink(
                    icon: Icons.code_rounded,
                    label: l10n.settingsCreatorGithub,
                    onTap: () => launchUrl(Uri.parse(_githubUrl)),
                    color: secondaryText,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _SocialLink(
                    icon: Icons.email_outlined,
                    label: l10n.settingsCreatorContact,
                    onTap: () => launchUrl(Uri.parse('mailto:$_emailAddress')),
                    color: secondaryText,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _SocialLink({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context)
                  .extension<TextStyleCatalog>()!
                  .bodyMedium
                  .copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: zero warnings, zero errors

- [ ] **Step 3: Commit**

```bash
git add lib/features/settings/presentation/widgets/creator_card.dart
git commit -m "feat(settings): add CreatorCard widget"
```

---

### Task 4: Integrate CreatorCard into SettingsScreen

**Files:**
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart:100-123`

**Interfaces:**
- Consumes: `CreatorCard` widget from Task 3
- Produces: CreatorCard rendered as 4th section in settings body

- [ ] **Step 1: Add import for CreatorCard**

In `lib/features/settings/presentation/screens/settings_screen.dart`, add after line 13 (`setting_item.dart` import):

```dart
import 'package:sky_line/features/settings/presentation/widgets/creator_card.dart';
```

- [ ] **Step 2: Add CreatorCard after About section**

In `settings_screen.dart`, replace the bottom padding line (line 123):

```dart
                  SizedBox(height: AppSpacing.xxl),
```

with:

```dart
                  const SizedBox(height: AppSpacing.xl),
                  const CreatorCard(),
                  SizedBox(height: AppSpacing.xxl),
```

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze`
Expected: zero warnings, zero errors

- [ ] **Step 4: Commit**

```bash
git add lib/features/settings/presentation/screens/settings_screen.dart
git commit -m "feat(settings): integrate CreatorCard into settings screen"
```

---

### Task 5: Write widget tests for CreatorCard

**Files:**
- Create: `test/features/settings/presentation/widgets/creator_card_test.dart`

**Interfaces:**
- Consumes: `CreatorCard` widget from Task 3, test patterns from `settings_screen_test.dart`
- Produces: passing test suite for CreatorCard

- [ ] **Step 1: Write the test file**

Create `test/features/settings/presentation/widgets/creator_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/features/settings/presentation/widgets/creator_card.dart';
import 'package:url_launcher/url_launcher.dart';

class MockUrlLauncher extends Mock implements UrlLauncher {}

void main() {
  late MockUrlLauncher mockUrlLauncher;

  setUp(() {
    mockUrlLauncher = MockUrlLauncher();
  });

  Widget createTestWidget() {
    return MaterialApp(
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
```

- [ ] **Step 2: Run the tests**

Run: `flutter test test/features/settings/presentation/widgets/creator_card_test.dart`
Expected: all 5 tests PASS

- [ ] **Step 3: Commit**

```bash
git add test/features/settings/presentation/widgets/creator_card_test.dart
git commit -m "test(settings): add CreatorCard widget tests"
```

---

### Task 6: Run full test suite and analyze

**Files:**
- No file changes

**Interfaces:**
- Consumes: all prior tasks complete
- Produces: verified clean codebase

- [ ] **Step 1: Run flutter analyze**

Run: `flutter analyze`
Expected: zero warnings, zero errors

- [ ] **Step 2: Run full test suite**

Run: `flutter test`
Expected: all tests PASS (including new CreatorCard tests)

- [ ] **Step 3: Commit any fixups if needed**

If analyze or tests fail, fix and commit before proceeding.
