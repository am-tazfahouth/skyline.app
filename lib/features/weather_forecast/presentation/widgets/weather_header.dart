import 'package:flutter/material.dart';

class WeatherHeader extends StatelessWidget implements PreferredSizeWidget {
  const WeatherHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      notificationPredicate: (_) => false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.grid_view_rounded),
        onPressed: () {},
      ),
      centerTitle: true,
      title: Text(
        'Moroni, Comoros',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () {},
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
