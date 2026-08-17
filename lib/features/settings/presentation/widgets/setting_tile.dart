import 'package:flutter/material.dart';
import 'package:sky_line/core/constants/app_spacing.dart';

class SettingTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const SettingTile({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: ListTile(
        title: Text(
          label,
          style: theme.textTheme.bodyLarge,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
