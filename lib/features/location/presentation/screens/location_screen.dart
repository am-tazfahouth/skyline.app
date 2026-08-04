import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/config/app_routes.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/errors/app_error.dart';
import 'package:sky_line/core/errors/app_error_code.dart';
import 'package:sky_line/core/errors/location_error_codes.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_event.dart';
import 'package:sky_line/features/location/presentation/blocs/location_state.dart';
import 'package:sky_line/features/location/presentation/widgets/favorites_list_widget.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  bool _isGpsError(AppErrorCode code) =>
      code == LocationErrorCodes.gpsDisabled ||
      code == LocationErrorCodes.gpsPermissionDenied ||
      code == LocationErrorCodes.gpsFailed;

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.surfaceFor(Theme.of(context).brightness).color;
    
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
        } else if (state is LocationError && _isGpsError(state.errorCode)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppError.getUserErrorMessage(state.errorCode)),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: const Text('Location'),
          backgroundColor: bgColor,
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
                  tooltip: 'Current location',
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
            Navigator.pushNamed(context, AppRoutes.locationSearch);
          },
          child: const Icon(Icons.add),
        ),
        body: BlocBuilder<LocationBloc, LocationState>(
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
