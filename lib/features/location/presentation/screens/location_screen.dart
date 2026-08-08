import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/config/app_routes.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_event.dart';
import 'package:sky_line/features/location/presentation/blocs/location_state.dart';
import 'package:sky_line/features/location/presentation/utils/gps_error_feedback.dart';
import 'package:sky_line/features/location/presentation/widgets/favorites_list_widget.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.surfaceFor(Theme.of(context).brightness).color;
    final l10n = AppLocalisation.of(context)!;
    
    return BlocListener<LocationBloc, LocationState>(
      listener: (context, state) {
        if (state is LocationSelected) {
          final location = state.location;
          final alreadyFavorite = state.favorites.any(
            (f) => f.latitude == location.latitude &&
                f.longitude == location.longitude,
          );
          if (location.isGpsLocation && !alreadyFavorite) {
            context
                .read<LocationBloc>()
                .add(AddFavoriteEvent(location: location));
          }
          if (context.mounted) {
            Navigator.pop(context);
          }
        } else if (state is LocationError && isGpsError(state.errorCode)) {
          showGpsErrorSnackBar(context, state.errorCode);
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          title: Text(l10n.locationTitle),
          notificationPredicate: (_) => false,
          actions: [
            BlocBuilder<LocationBloc, LocationState>(
              builder: (context, state) {
                if (state is LocationDetecting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return IconButton(
                  icon: const Icon(Icons.my_location_rounded),
                  tooltip: l10n.locationCurrentLocationTooltip,
                  onPressed: () {
                    context
                        .read<LocationBloc>()
                        .add(const DetectCurrentLocationEvent());
                  },
                );
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            Navigator.pushNamed(context, AppRoutes.locationSearch);
          },
          child: const Icon(Icons.add),
        ),
        body: BlocBuilder<LocationBloc, LocationState>(
          buildWhen: (_, state) =>
              state is LocationFavoritesLoaded || state is LocationSelected,
          builder: (context, state) {
            final favorites = switch (state) {
              LocationFavoritesLoaded(favorites: final f) => f,
              LocationSelected(favorites: final f) => f,
              _ => const <LocationEntity>[],
            };
            return FavoritesListWidget(
              favorites: favorites,
              onLocationTap: (location) {
                context
                    .read<LocationBloc>()
                    .add(SelectLocationEvent(location: location));
              },
            );
          },
        ),
      ),
    );
  }
}
