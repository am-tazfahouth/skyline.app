import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/errors/app_error.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_event.dart';
import 'package:sky_line/features/location/presentation/blocs/location_state.dart';
import 'package:sky_line/features/location/presentation/widgets/search_bar_widget.dart';
import 'package:sky_line/features/location/presentation/widgets/search_result_tile.dart';

class LocationSearchScreen extends StatelessWidget {
  const LocationSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = AppTheme.surfaceFor(Theme.of(context).brightness).color;
    final l10n = AppLocalisation.of(context)!;
    
    return Scaffold(      
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text(l10n.locationSearchTitle),
      ),
      backgroundColor: bgColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SearchBarWidget(
              onSearch: (query) {
                context.read<LocationBloc>().add(SearchLocationsEvent(query));
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<LocationBloc, LocationState>(
                builder: (context, state) {
                  if (state is LocationSearchLoading) {
                    return Center(
                      child: LoadingAnimationWidget.staggeredDotsWave(
                        color: theme.colorScheme.primary,
                        size: 40,
                      ),
                    );
                  }
                  if (state is LocationSearchLoaded) {
                    if (state.results.isEmpty) {
                      return Center(child: Text(l10n.locationSearchNoResults));
                    }
                    return ListView.builder(
                      itemCount: state.results.length,
                      itemBuilder: (context, index) {
                        final location = state.results[index];
                        return SearchResultTile(
                          location: location,
                          onTap: () {
                            final bloc = context.read<LocationBloc>();
                            final favorites = bloc.repository.loadFavorites();
                            final isAlreadyFavorite = favorites.any(
                              (f) => f.latitude == location.latitude &&
                                  f.longitude == location.longitude,
                            );
                            if (!isAlreadyFavorite) {
                              bloc.add(AddFavoriteEvent(location: location));
                            }
                            bloc.add(SelectLocationEvent(location: location));
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  }
                  if (state is LocationSearchError) {
                    return Center(
                      child: Text(
                        AppError.getUserErrorMessage(state.errorCode, l10n),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    );
                  }
                  return Center(child: Text(l10n.locationSearchPrompt));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
