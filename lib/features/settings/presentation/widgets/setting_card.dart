import 'package:flutter/material.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/constants/app_radius.dart';
import 'package:sky_line/core/constants/app_spacing.dart';
import 'package:sky_line/core/constants/app_text_styles.dart';

class SettingCard extends StatelessWidget {
  final String title; 
  final List<Widget> options;
  const SettingCard({super.key, required this.title, required this.options});

  @override
  Widget build(BuildContext context) {
    final surface = AppTheme.surfaceFor(Theme.of(context).brightness);
    final styles = Theme.of(context).extension<TextStyleCatalog>()!;
    final cardColor = surface.colorContainer;
    final primaryText = surface.onColor;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppRadius.md)
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: styles.headlineMedium.copyWith(color: primaryText),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm,),
              ...options
            ],
          ),
        ),
      ),
    );
  }
}
