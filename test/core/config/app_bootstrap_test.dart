import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/config/app_bootstrap.dart';
import 'package:sky_line/core/services/logger_services.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';
import 'package:sky_line/features/location/domain/repositories/location_repository.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_onboarding_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_onboarding_state.dart';
import 'package:sky_line/features/location/presentation/blocs/location_state.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';
import 'package:sky_line/features/settings/domain/repositories/setting_repository.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_state.dart';

class MockLocationRepository extends Mock implements LocationRepository {}

class MockSettingRepository extends Mock implements SettingRepository {}

class MockAppLogger extends Mock implements AppLogger {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('hydrate leaves location, onboarding and settings blocs loaded', () async {
    final locationRepo = MockLocationRepository();
    when(() => locationRepo.loadFavorites())
        .thenReturn(const <LocationEntity>[]);
    when(() => locationRepo.loadLastLocation()).thenReturn(null);

    final onboardingRepo = MockLocationRepository();
    when(() => onboardingRepo.hasSeenLocationOnboarding())
        .thenAnswer((_) async => false);

    final settingRepo = MockSettingRepository();
    when(() => settingRepo.loadSettings())
        .thenAnswer((_) async => const SettingEntity());

    final locationBloc =
        LocationBloc(logger: MockAppLogger(), repository: locationRepo, settingRepository: settingRepo);
    final onboardingBloc = LocationOnboardingBloc(
      logger: MockAppLogger(),
      repository: onboardingRepo,
    );
    final settingsBloc =
        SettingsBloc(logger: MockAppLogger(), repository: settingRepo);

    await AppBootstrap.hydrate(
      locationBloc: locationBloc,
      onboardingBloc: onboardingBloc,
      settingsBloc: settingsBloc,
    );

    expect(locationBloc.state, isA<LocationFavoritesLoaded>());
    expect(onboardingBloc.state, isA<LocationOnboardingLoaded>());
    expect(settingsBloc.state, isA<SettingsLoadSuccess>());
    expect((settingsBloc.state as SettingsLoadSuccess).isLoaded, isTrue);
  });

  test('hydrate completes without throwing when a repository read fails', () async {
    final locationRepo = MockLocationRepository();
    when(() => locationRepo.loadFavorites()).thenThrow(Exception('boom'));

    final onboardingRepo = MockLocationRepository();
    when(() => onboardingRepo.hasSeenLocationOnboarding())
        .thenThrow(Exception('boom'));

    final settingRepo = MockSettingRepository();
    when(() => settingRepo.loadSettings()).thenThrow(Exception('boom'));

    final locationBloc =
        LocationBloc(logger: MockAppLogger(), repository: locationRepo, settingRepository: settingRepo);
    final onboardingBloc = LocationOnboardingBloc(
      logger: MockAppLogger(),
      repository: onboardingRepo,
    );
    final settingsBloc =
        SettingsBloc(logger: MockAppLogger(), repository: settingRepo);

    await expectLater(
      AppBootstrap.hydrate(
        locationBloc: locationBloc,
        onboardingBloc: onboardingBloc,
        settingsBloc: settingsBloc,
      ),
      completes,
    );

    expect(locationBloc.state, isA<LocationError>());
    expect(onboardingBloc.state, isA<LocationOnboardingError>());
    expect(settingsBloc.state, isA<SettingsError>());
  });

  test('hydrate never blocks launch when a read never completes', () async {
    final locationRepo = MockLocationRepository();
    when(() => locationRepo.loadFavorites())
        .thenReturn(const <LocationEntity>[]);
    when(() => locationRepo.loadLastLocation()).thenReturn(null);

    final onboardingRepo = MockLocationRepository();
    when(() => onboardingRepo.hasSeenLocationOnboarding())
        .thenAnswer((_) => Completer<bool>().future);

    final settingRepo = MockSettingRepository();
    when(() => settingRepo.loadSettings())
        .thenAnswer((_) async => const SettingEntity());

    await expectLater(
      AppBootstrap.hydrate(
        locationBloc:
            LocationBloc(logger: MockAppLogger(), repository: locationRepo, settingRepository: settingRepo),
        onboardingBloc: LocationOnboardingBloc(
          logger: MockAppLogger(),
          repository: onboardingRepo,
        ),
        settingsBloc:
            SettingsBloc(logger: MockAppLogger(), repository: settingRepo),
        timeout: const Duration(milliseconds: 50),
      ),
      completes,
    );
  });
}
