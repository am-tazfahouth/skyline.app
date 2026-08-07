import 'package:flutter/material.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';

class LocationOnboardingSheet extends StatelessWidget {
  const LocationOnboardingSheet({
    super.key,
    required this.onEnableLocation,
    required this.onLater,
    required this.onClose,
  });

  final VoidCallback onEnableLocation;
  final VoidCallback onLater;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalisation.of(context)!;
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          onLater();
        }
      },
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.locationOnboardingTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.locationOnboardingBody,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.my_location),
                label: Text(l10n.locationOnboardingEnable),
                onPressed: onEnableLocation,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onLater,
                child: Text(l10n.locationOnboardingLater),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
