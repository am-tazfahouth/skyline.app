import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/config/app_routes.dart';
import 'package:sky_line/core/constants/app_text_styles.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_state.dart';

class WeatherHeader extends StatelessWidget implements PreferredSizeWidget {
  const WeatherHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalisation.of(context)!;
    final styles = Theme.of(context).extension<TextStyleCatalog>()!;
    final primaryText = Theme.of(context).colorScheme.onSurface;
    return AppBar(
      notificationPredicate: (_) => false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.grid_view_rounded),
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.location);
        },
      ),
      centerTitle: true,
      title: BlocBuilder<LocationBloc, LocationState>(
        builder: (context, state) {
          final title = switch (state) {
            LocationSelected(location: final l) => l.title,
            LocationFavoritesLoaded(currentLocation: final c) => c?.title,
            _ => null,
          } ?? l10n.appTitle;
          return Text(
            title,
            style: styles.headlineSmall.copyWith(color: primaryText),
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.settings);
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
