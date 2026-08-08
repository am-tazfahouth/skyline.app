import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_event.dart';
import 'package:sky_line/features/location/presentation/blocs/location_onboarding_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_onboarding_event.dart';
import 'package:sky_line/features/location/presentation/blocs/location_onboarding_state.dart';
import 'package:sky_line/features/location/presentation/blocs/location_state.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_event.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_state.dart';
import 'package:sky_line/injection_container.dart';

abstract final class AppBootstrap {
  static Future<void> hydrate({
    SettingsBloc? settingsBloc,
    LocationBloc? locationBloc,
    LocationOnboardingBloc? onboardingBloc,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final settings = settingsBloc ?? InjectionContainer.settingsBloc;
    final location = locationBloc ?? InjectionContainer.locationBloc;
    final onboarding =
        onboardingBloc ?? InjectionContainer.locationOnboardingBloc;

    final settingsFuture = _waitFor(
      settings,
      (s) => (s is SettingsLoadSuccess && s.isLoaded) || s is SettingsError,
      timeout,
    );
    final locationFuture = _waitFor(
      location,
      (s) => s is LocationFavoritesLoaded || s is LocationError,
      timeout,
    );
    final onboardingFuture = _waitFor(
      onboarding,
      (s) => s is LocationOnboardingLoaded || s is LocationOnboardingError,
      timeout,
    );

    settings.add(const LoadSettingsEvent());
    location.add(const LoadFavoritesEvent());
    onboarding.add(const LoadOnboardingStatusEvent());

    await Future.wait([settingsFuture, locationFuture, onboardingFuture]);
  }

  static Future<void> _waitFor<Event, State>(
    Bloc<Event, State> bloc,
    bool Function(State) done,
    Duration timeout,
  ) async {
    final completer = Completer<void>();
    late final StreamSubscription<State> subscription;
    subscription = bloc.stream.listen((state) {
      if (done(state) && !completer.isCompleted) {
        completer.complete();
      }
    });
    try {
      await completer.future.timeout(timeout);
    } catch (_) {
      // A local hydration failure or timeout must never block app launch.
    } finally {
      await subscription.cancel();
    }
  }
}
