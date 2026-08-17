import 'package:flutter/material.dart';
import 'package:sky_line/core/constants/app_spacing.dart';
import 'package:sky_line/core/constants/app_text_styles.dart';

class SettingItem extends StatelessWidget {
  final String title; 
  final String? description; 
  final Function? onClick;
  final IconData icon;
  const SettingItem({super.key, required this.title, this.description, required this.icon, required this.onClick});

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).extension<TextStyleCatalog>()!;
    final primaryText = Theme.of(context).colorScheme.onSurface;
    final secondaryText = Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onClick != null ? () =>  onClick!() : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(
              icon,
              size: 25,
            ),
            SizedBox(width: AppSpacing.md,),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: styles.titleSmall.copyWith(color: primaryText),
                ),
                SizedBox(height: AppSpacing.xs,),
                description != null ? 
                  Text(
                    description!,
                    style: styles.bodyMedium.copyWith(color: secondaryText),
                  ) : 
                  const SizedBox()
              ],
            )
          ],
        ),
      ),
    );
  }
}
