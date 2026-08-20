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
                          style: styles.headlineMedium
                              .copyWith(color: primaryText),
                        ),
                        Text(
                          l10n.settingsCreatorRole,
                          style: styles.bodyMedium
                              .copyWith(color: secondaryText),
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
