import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_event.dart';

class FavoritesListWidget extends StatelessWidget {
  final List<LocationEntity> favorites;
  final ValueChanged<LocationEntity> onLocationTap;

  const FavoritesListWidget({
    super.key,
    required this.favorites,
    required this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty) {
      return const Center(child: Text('No favorites yet'));
    }

    return ReorderableListView.builder(
      itemCount: favorites.length,
      onReorder: (oldIndex, newIndex) {
        context.read<LocationBloc>().add(
          ReorderFavoritesEvent(oldIndex: oldIndex, newIndex: newIndex),
        );
      },
      itemBuilder: (context, index) {
        final location = favorites[index];
        final subtitle = [location.admin1, location.country]
            .where((e) => e != null && e.isNotEmpty)
            .join(', ');

        return Dismissible(
          key: ValueKey('${location.latitude}_${location.longitude}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            context.read<LocationBloc>().add(
              RemoveFavoriteEvent(location: location),
            );
          },
          child: ListTile(
            key: ValueKey('${location.latitude}_${location.longitude}'),
            title: Text(location.cityName),
            subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
            trailing: const Icon(Icons.drag_handle),
            onTap: () => onLocationTap(location),
          ),
        );
      },
    );
  }
}
