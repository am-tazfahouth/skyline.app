import 'package:flutter/material.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';

class SearchResultTile extends StatelessWidget {
  final LocationEntity location;
  final VoidCallback onTap;

  const SearchResultTile({
    super.key,
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      location.admin1,
      location.country,
    ].where((e) => e != null && e.isNotEmpty).join(', ');

    return ListTile(
      title: Text(location.cityName),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
