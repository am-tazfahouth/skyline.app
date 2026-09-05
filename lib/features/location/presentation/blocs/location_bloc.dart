import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/errors/app_error.dart';
import 'package:sky_line/core/errors/location_error_codes.dart';
import 'package:sky_line/core/errors/location_exceptions.dart';
import 'package:sky_line/core/enums/setting_lang.dart';
import 'package:sky_line/core/services/logger_services.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';
import 'package:sky_line/features/location/domain/repositories/location_repository.dart';
import 'package:sky_line/features/location/presentation/blocs/location_event.dart';
import 'package:sky_line/features/location/presentation/blocs/location_state.dart';
import 'package:sky_line/features/settings/domain/repositories/setting_repository.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState>
    with WidgetsBindingObserver {
  final AppLogger logger;
  final LocationRepository repository;
  final SettingRepository settingRepository;

  LocationBloc({
    required this.logger,
    required this.repository,
    required this.settingRepository,
  }) : super(const LocationInitial()) {
    WidgetsBinding.instance.addObserver(this);
    on<DetectCurrentLocationEvent>(_onDetectCurrentLocation);
    on<OpenLocationSettingsEvent>(_onOpenLocationSettings);
    on<OpenAppSettingsEvent>(_onOpenAppSettings);
    on<SearchLocationsEvent>(_onSearchLocations);
    on<SelectLocationEvent>(_onSelectLocation);
    on<AddFavoriteEvent>(_onAddFavorite);
    on<RemoveFavoriteEvent>(_onRemoveFavorite);
    on<ReorderFavoritesEvent>(_onReorderFavorites);
    on<LoadFavoritesEvent>(_onLoadFavorites);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        this.state is LocationWaitingForSettings) {
      add(const DetectCurrentLocationEvent());
    }
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    return super.close();
  }

  Future<String> _resolveLanguage() async {
    final settings = await settingRepository.loadSettings();
    return getStringFromLang(settings.lang);
  }

  Future<void> _onDetectCurrentLocation(
    DetectCurrentLocationEvent event,
    Emitter<LocationState> emit,
  ) async {
    emit(const LocationDetecting());
    try {
      final language = await _resolveLanguage();
      final location = await repository.detectCurrentLocation(language);
      await repository.saveLastLocation(location);
      final favorites = repository.loadFavorites();
      emit(LocationSelected(location: location, favorites: favorites));
    } on LocationPermissionPermanentlyDeniedException {
      emit(
        const LocationError(LocationErrorCodes.gpsPermissionPermanentlyDenied),
      );
    } on LocationPermissionDeniedException {
      emit(const LocationError(LocationErrorCodes.gpsPermissionDenied));
    } on LocationServiceDisabledException {
      emit(const LocationError(LocationErrorCodes.gpsDisabled));
    } catch (e, stackTrace) {
      logger.e(
        AppError.getDebugErrorMessage(LocationErrorCodes.gpsFailed),
        error: e,
        stackTrace: stackTrace,
      );
      emit(const LocationError(LocationErrorCodes.gpsFailed));
    }
  }

  Future<void> _onOpenLocationSettings(
    OpenLocationSettingsEvent event,
    Emitter<LocationState> emit,
  ) async {
    emit(const LocationWaitingForSettings());
    try {
      await repository.openLocationSettings();
    } catch (e, stackTrace) {
      logger.e(
        AppError.getDebugErrorMessage(LocationErrorCodes.gpsFailed),
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _onOpenAppSettings(
    OpenAppSettingsEvent event,
    Emitter<LocationState> emit,
  ) async {
    emit(const LocationWaitingForSettings());
    try {
      await repository.openAppSettings();
    } catch (e, stackTrace) {
      logger.e(
        AppError.getDebugErrorMessage(LocationErrorCodes.gpsFailed),
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _onSearchLocations(
    SearchLocationsEvent event,
    Emitter<LocationState> emit,
  ) async {
    if (event.query.trim().isEmpty) return;
    emit(const LocationSearchLoading());
    try {
      final language = await _resolveLanguage();
      final results = await repository.searchLocations(event.query, language);
      emit(LocationSearchLoaded(results));
    } catch (e, stackTrace) {
      logger.e(
        AppError.getDebugErrorMessage(LocationErrorCodes.searchFailed),
        error: e,
        stackTrace: stackTrace,
      );
      emit(const LocationSearchError(LocationErrorCodes.searchFailed));
    }
  }

  Future<void> _onSelectLocation(
    SelectLocationEvent event,
    Emitter<LocationState> emit,
  ) async {
    try {
      await repository.saveLastLocation(event.location);
      final favorites = repository.loadFavorites();
      emit(LocationSelected(location: event.location, favorites: favorites));
    } catch (e, stackTrace) {
      logger.e(
        AppError.getDebugErrorMessage(LocationErrorCodes.unexpected),
        error: e,
        stackTrace: stackTrace,
      );
      emit(const LocationError(LocationErrorCodes.unexpected));
    }
  }

  Future<void> _onAddFavorite(
    AddFavoriteEvent event,
    Emitter<LocationState> emit,
  ) async {
    try {
      await repository.saveFavorite(event.location);
      final favorites = repository.loadFavorites();
      final currentState = state;
      final currentLocation = currentState is LocationSelected
          ? currentState.location
          : null;
      emit(
        LocationFavoritesLoaded(
          favorites: favorites,
          currentLocation: currentLocation,
        ),
      );
    } catch (e, stackTrace) {
      logger.e(
        AppError.getDebugErrorMessage(LocationErrorCodes.saveFavoriteFailed),
        error: e,
        stackTrace: stackTrace,
      );
      emit(const LocationError(LocationErrorCodes.saveFavoriteFailed));
    }
  }

  Future<void> _onRemoveFavorite(
    RemoveFavoriteEvent event,
    Emitter<LocationState> emit,
  ) async {
    try {
      await repository.removeFavorite(event.location);
      final favorites = repository.loadFavorites();
      final currentState = state;
      final previousLocation = currentState is LocationSelected
          ? currentState.location
          : currentState is LocationFavoritesLoaded
          ? currentState.currentLocation
          : null;
      final isStillFavorite =
          previousLocation != null &&
          favorites.any(
            (f) =>
                f.latitude == previousLocation.latitude &&
                f.longitude == previousLocation.longitude,
          );
      final LocationEntity? currentLocation;
      if (isStillFavorite) {
        currentLocation = previousLocation;
      } else if (previousLocation != null && favorites.isNotEmpty) {
        currentLocation = favorites.first;
        await repository.saveLastLocation(currentLocation);
      } else {
        currentLocation = null;
      }
      if (favorites.isEmpty ||
          (previousLocation != null && currentLocation == null)) {
        await repository.clearLastLocation();
      }
      emit(
        LocationFavoritesLoaded(
          favorites: favorites,
          currentLocation: currentLocation,
        ),
      );
    } catch (e, stackTrace) {
      logger.e(
        AppError.getDebugErrorMessage(LocationErrorCodes.saveFavoriteFailed),
        error: e,
        stackTrace: stackTrace,
      );
      emit(const LocationError(LocationErrorCodes.saveFavoriteFailed));
    }
  }

  Future<void> _onReorderFavorites(
    ReorderFavoritesEvent event,
    Emitter<LocationState> emit,
  ) async {
    try {
      final favorites = repository.loadFavorites().toList();
      final isValidRange =
          event.oldIndex >= 0 &&
          event.oldIndex < favorites.length &&
          event.newIndex >= 0 &&
          event.newIndex <= favorites.length;
      if (isValidRange) {
        final item = favorites.removeAt(event.oldIndex);
        final insertAt = event.newIndex > event.oldIndex
            ? event.newIndex - 1
            : event.newIndex;
        favorites.insert(insertAt, item);
        await repository.saveAllFavorites(favorites);
      }
      final updatedFavorites = repository.loadFavorites();
      final currentState = state;
      final currentLocation = currentState is LocationSelected
          ? currentState.location
          : null;
      emit(
        LocationFavoritesLoaded(
          favorites: updatedFavorites,
          currentLocation: currentLocation,
        ),
      );
    } catch (e, stackTrace) {
      logger.e(
        AppError.getDebugErrorMessage(LocationErrorCodes.saveFavoriteFailed),
        error: e,
        stackTrace: stackTrace,
      );
      emit(const LocationError(LocationErrorCodes.saveFavoriteFailed));
    }
  }

  Future<void> _onLoadFavorites(
    LoadFavoritesEvent event,
    Emitter<LocationState> emit,
  ) async {
    try {
      final favorites = repository.loadFavorites();
      var lastLocation = repository.loadLastLocation();
      if (favorites.isEmpty) {
        if (lastLocation != null) {
          await repository.clearLastLocation();
        }
        lastLocation = null;
      }
      emit(
        LocationFavoritesLoaded(
          favorites: favorites,
          currentLocation: lastLocation,
        ),
      );
    } catch (e, stackTrace) {
      logger.e(
        AppError.getDebugErrorMessage(LocationErrorCodes.loadFavoritesFailed),
        error: e,
        stackTrace: stackTrace,
      );
      emit(const LocationError(LocationErrorCodes.loadFavoritesFailed));
    }
  }
}
