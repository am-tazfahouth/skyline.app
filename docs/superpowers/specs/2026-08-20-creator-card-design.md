# Creator Card — Settings Section Design

## Overview

Add a standalone "Creator Card" widget to the Settings screen's About section, highlighting the app creator (TzfLab) with a name, role, bio, and tappable social links (GitHub, Email). The card visually follows the existing `SettingCard` design language while adding enough personality to feel like a deliberate credits section.

## Goal

Give the creator visibility within the app's settings in a way that feels native to the existing UI — not bolted on. The card should be immediately recognizable as a "credits" element while remaining consistent with the app's Material3 + custom surface color system.

## Scope

- New `CreatorCard` widget in `lib/features/settings/presentation/widgets/`
- Integration into `settings_screen.dart` below the existing About card
- `url_launcher` dependency for opening GitHub profile and email compose
- Localization for all 4 locales (EN, FR, ES, AR)

Out of scope: Share functionality (existing stub), any changes to the licenses page.

---

## Layout

```
┌──────────────────────────────────────────────┐
│  ┌──────┐                                    │
│  │ logo │  TzfLab                            │
│  │ 60px │  Creator & Developer               │
│  └──────┘                                    │
│                                              │
│  Building SkyLine with passion for           │
│  clean, professional weather experiences.    │
│                                              │
│  [GitHub icon] GitHub   [Email icon] Contact │
└──────────────────────────────────────────────┘
```

### Inner structure

1. **Header row** — `Row` containing:
   - App logo (`assets/images/logo/ic_launcher.png`, 60×60, clipped with `AppRadius.sm`)
   - `SizedBox(width: AppSpacing.md)`
   - `Column` (crossAxisAlignment: start):
     - Name: "TzfLab" using `styles.headlineMedium`, colored `surface.onColor`
     - Role: localized string using `styles.bodyMedium`, colored `surface.onColorContainer`

2. **Bio paragraph** — `Padding(vertical: AppSpacing.sm)` wrapping a `Text` widget:
   - Localized bio string
   - Style: `styles.bodyMedium`, color: `surface.onColorContainer`

3. **Social row** — `Row` with two tappable items:
   - Each item: `InkWell` → `Row` with `Icon` + `Text` label
   - GitHub: `Icons.code_rounded` → opens `https://github.com/<username>` via `url_launcher`
   - Email: `Icons.email_outlined` → opens `mailto:<email>` via `url_launcher`
   - Spacing between items: `AppSpacing.md`

### Container styling

Matches existing `SettingCard` pattern:
- Background: `surface.colorContainer` (from `AppTheme.surfaceFor(brightness)`)
- Border radius: `AppRadius.md` (10px)
- Outer padding: `AppSpacing.md` (12px) horizontal
- Inner padding: `AppSpacing.md` (12px) all sides

---

## Placement in Settings Screen

Inserted as a **4th section** after the existing About `SettingCard`, separated by `SizedBox(height: AppSpacing.xl)`:

```dart
// ... existing About card ...
SizedBox(height: AppSpacing.xl),
CreatorCard(),
```

Bottom padding of `SingleChildScrollView` remains `AppSpacing.xxl` (32px).

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `url_launcher` | `^6.3.0` | Open GitHub URL and mailto: compose |

---

## Localization

### New keys

| Key | EN | FR | ES | AR |
|-----|----|----|----|----|
| `settingsCreatorRole` | Creator & Developer | Créateur & Développeur | Creador y Desarrollador | المنشئ والمطور |
| `settingsCreatorBio` | Building SkyLine with passion for clean, professional weather experiences. | Construire SkyLine avec passion pour des expériences météo propres et professionnelles. | Construyendo SkyLine con pasión por experiencias climáticas limpias y profesionales. | بناء SkyLine بشغف من أجل تجارب طقس نظيفة واحترافية. |
| `settingsCreatorGithub` | GitHub | GitHub | GitHub | GitHub |
| `settingsCreatorContact` | Contact | Contact | Contacto | اتصل |

### Files to modify

- `lib/core/l10n/arb/intl_en.arb`
- `lib/core/l10n/arb/intl_fr.arb`
- `lib/core/l10n/arb/intl_es.arb`
- `lib/core/l10n/arb/intl_ar.arb`

---

## Testing

### Widget test (`test/features/settings/presentation/widgets/creator_card_test.dart`)

1. **Renders correctly** — verify name, role, bio, and both social buttons are present
2. **Social links launch** — mock `url_launcher` and verify correct URLs are launched on tap
3. **Theme adaptivity** — verify the card renders under both light and dark themes without errors

---

## File Changes Summary

| Action | File |
|--------|------|
| **Create** | `lib/features/settings/presentation/widgets/creator_card.dart` |
| **Create** | `test/features/settings/presentation/widgets/creator_card_test.dart` |
| **Modify** | `lib/features/settings/presentation/screens/settings_screen.dart` — add `CreatorCard()` widget |
| **Modify** | `pubspec.yaml` — add `url_launcher` dependency |
| **Modify** | `lib/core/l10n/arb/intl_en.arb` — add 4 creator keys |
| **Modify** | `lib/core/l10n/arb/intl_fr.arb` — add 4 creator keys |
| **Modify** | `lib/core/l10n/arb/intl_es.arb` — add 4 creator keys |
| **Modify** | `lib/core/l10n/arb/intl_ar.arb` — add 4 creator keys |
