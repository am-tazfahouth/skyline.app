import 'package:flutter/material.dart';

class WeatherHeader extends StatefulWidget implements PreferredSizeWidget {
  const WeatherHeader({super.key});

  @override
  State<WeatherHeader> createState() => _WeatherHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _WeatherHeaderState extends State<WeatherHeader> {
  String _selectedLocation = 'Moroni, Comoros';

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.grid_view_rounded),
        onPressed: () {},
      ),
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_rounded, size: 18),
          const SizedBox(width: 4),
          DropdownButton<String>(
            value: _selectedLocation,
            underline: const SizedBox(),
            isDense: true,
            items: const [
              DropdownMenuItem(value: 'Moroni, Comoros', child: Text('Moroni, Comoros')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _selectedLocation = v);
            },
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () {},
        ),
      ],
    );
  }
}
