import 'package:flutter/material.dart';

class ForecastTabs extends StatelessWidget {
  final bool isTodaySelected;
  final VoidCallback onTodayTap;
  final VoidCallback onNext7Tap;

  const ForecastTabs({
    super.key,
    required this.isTodaySelected,
    required this.onTodayTap,
    required this.onNext7Tap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _TabButton(
            label: 'Today',
            isSelected: isTodaySelected,
            onTap: onTodayTap,
            theme: theme,
          ),
          const SizedBox(width: 24),
          _TabButton(
            label: 'Next 7 Day',
            isSelected: !isTodaySelected,
            onTap: onNext7Tap,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              color: isSelected
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: 24,
              color: theme.colorScheme.primary,
            ),
        ],
      ),
    );
  }
}
