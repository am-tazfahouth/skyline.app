# Release Naming & Share Button — Design Spec

**Date:** 2026-09-06
**Feature:** delivery / CI-CD + settings (share)
**Status:** Approved

## Problem

Two polish gaps after the first published release:

1. The GitHub Release assets are named `app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk` and `app-x86_64-release.apk` (Flutter defaults). The asset names carry no product identity.
2. The **Share** tile in Settings → About (`settings_screen.dart`) has an empty tap handler (`onClick: () {}`), while its label and description (`settingsShare`, `settingsShareDescription`) promise sharing the app with friends.

## Goal

- Release assets and the release title carry the product name **SkyLine**.
- Tapping Share opens the native system share sheet with a short localized invite and the URL of the latest GitHub release (`/releases/latest`, which redirects to the newest release).

## Chosen Approach

### 1. Release assets & title — `.github/workflows/ci.yml`

Rename the three built APKs in a dedicated step **after** `Build release APKs` and **before** `Publish release`. The ABI stays in the name; the version is derived from the tag (`v1.0.0` → `1.0.0`):

```
VERSION="${GITHUB_REF_NAME#v}"
dir="build/app/outputs/flutter-apk"
mv "$dir/app-arm64-v8a-release.apk"    "$dir/SkyLine-${VERSION}-arm64-v8a.apk"
mv "$dir/app-armeabi-v7a-release.apk"  "$dir/SkyLine-${VERSION}-armeabi-v7a.apk"
mv "$dir/app-x86_64-release.apk"       "$dir/SkyLine-${VERSION}-x86_64.apk"
```

Result: `SkyLine-1.0.0-arm64-v8a.apk`, `SkyLine-1.0.0-armeabi-v7a.apk`, `SkyLine-1.0.0-x86_64.apk`. The existing `files: build/app/outputs/flutter-apk/*.apk` glob is unchanged and now matches only the renamed files.

The release **title** becomes `SkyLine ${{ github.ref_name }}` (e.g. `SkyLine v1.0.0`) instead of the bare tag.

Rationale over Gradle output renaming (`build.gradle.kts`): renaming in the workflow keeps local builds untouched, avoids the split-per-abi output-name quirks, and keeps CI asset naming an explicit, reviewable step.

### 2. Share button — native share sheet

- **Dependency:** `flutter pub add share_plus`. Pub resolves the newest version compatible with this project (Dart `^3.9.2`, Flutter 3.35.5). share_plus 13.x requires Dart ≥ 3.10, so the resolved version is expected to be 11.x/12.x. API used: `SharePlus.instance.share(ShareParams(...))` (the static `Share.share` API is deprecated in these versions).
- **URL constant:** new `lib/core/constants/app_links.dart`:
  ```
  class AppLinks {
    static const github = 'https://github.com/am-tazfahouth';
    static const githubReleases =
        'https://github.com/am-tazfahouth/skyline.app/releases/latest';
  }
  ```
  `CreatorCard` switches from its private `_githubUrl` to `AppLinks.github` (single source of truth, no behavior change).
- **Localization:** new key `settingsShareMessage` in the abstract `AppLocalisation` and the four locals (`en`, `fr`, `es`, `ar`), e.g. fr: `Découvrez SkyLine — application météo simple et professionnelle :`. The share text is `'${l10n.settingsShareMessage} ${AppLinks.githubReleases}'`.
- **Wiring:** in `settings_screen.dart`, the Share `SettingItem` is wrapped in a `Builder` so the handler can resolve a non-zero `sharePositionOrigin` from the tile's `RenderBox` — required on iOS, where a zero origin throws (share sheet not presented). Handler `_shareApp(BuildContext context, AppLocalisation l10n)`:
  ```dart
  try {
    final box = context.findRenderObject() as RenderBox?;
    final origin = (box == null)
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    await SharePlus.instance.share(ShareParams(
      text: '${l10n.settingsShareMessage} ${AppLinks.githubReleases}',
      sharePositionOrigin: origin,
    ));
  } on Exception {
    // Non-blocking failure; keep the settings screen usable.
  }
  ```

  In practice the `Builder` wrapping the tile always provides a box; `origin` is omitted defensively only.
  Swallowing the exception is safe: a failed share sheet must never crash or block Settings (same policy as `CreatorCard._launchSafe`).

## Data

- No data-layer change. The releases URL is a compile-time constant.

## Error Handling

- Missing/renamed APK after build → `mv` fails early in the workflow (`set -e`), no release is published.
- Share invocation failure (no share target, plugin exception) → caught silently; Settings stays interactive.

## Tests

- `test/features/settings/presentation/screens/settings_screen_test.dart`: new widget test tapping the Share tile. The share platform instance is replaced with a recording fake (`SharePlus.custom(...)`); assertions check that `share` was invoked with a text containing `AppLinks.githubReleases` and the current-locale message. Existing tests must stay green (the Share tile previously had a no-op handler, so no existing assertion breaks).
- If the resolved share_plus version's fake-interface surface makes recording awkward, fall back to asserting the composed message through a unit test and a tap smoke test that must not throw.

### Factory Verification

- `flutter analyze --fatal-infos` : 0 warning, 0 info.
- `flutter test --exclude-tags integration` : all green.
- YAML validity of `.github/workflows/ci.yml`.
- Push to `main` runs `analyze-and-test` (green); the naming/title change is exercised on the next `v*` tag.

## Out of Scope (YAGNI)

- No App Bundle / Play Store publishing.
- No share of APK files themselves (link only).
- No in-app GitHub release list/fetcher.
- No change to the existing CreatorCard GitHub/email links.