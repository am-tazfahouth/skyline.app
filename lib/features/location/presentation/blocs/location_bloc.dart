import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/errors/app_error.dart';
import 'package:sky_line/core/errors/location_error_codes.dart';
import 'package:sky_line/core/services/logger_sevices.dart';
import 'package:sky_line/features/location/domain/repositories/location_repository.dart';
import 'package:sky_line/features/location/presentation/blocs/location_event.dart';
import 'package:sky_line/features/location/presentation/blocs/location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final AppLogger logger;
  final LocationRepository repository;

  LocationBloc({required this.logger, required this.repository})
      : super(const LocationInitial()) {
    on<DetectCurrentLocationEvent>(_onDetectCurrentLocation);
    on<SearchLocationsEvent>(_onSearchLocations);
    on<SelectLocationEvent>(_onSelectLocation);
    on<AddFavoriteEvent>(_onAddFavorite);
    on<RemoveFavoriteEvent>(_onRemoveFavorite);
    on<ReorderFavoritesEvent>(_onReorderFavorites);
    on<LoadFavoritesEvent>(_onLoadFavorites);
  }

  Future<void> _onDetectCurrentLocation(
    DetectCurrentLocationEvent event,
    Emitter<LocationState> emit,
  ) async {
    emit(const LocationDetecting());
    try {
      final location = await repository.detectCurrentLocation();
      await repository.saveLastLocation(location);
      final favorites = repository.loadFavorites();
      emit(LocationSelected(location: location, favorites: favorites));
    } catch (e, stackTrace) {
      logger.e(
        AppError.getDebugErrorMessage(LocationErrorCodes.gpsFailed),
        error: e,
        stackTrace: stackTrace,
      );
      emit(const LocationError(LocationErrorCodes.gpsFailed));
    }
  }

  Future<void> _onSearchLocations(
    SearchLocationsEvent event,
    Emitter<LocationState> emit,
  ) async {
    if (event.query.trim().isEmpty) return;
    emit(const LocationSearchLoading());
    try {
      final results = await repository.searchLocations(event.query);
      emit(LocationSearchLoaded(results));
    } catch (e, stackTrace) {
      logger.e(
        AppError.getDebugErrorMessage(LocationErrorCodes.searchFailed),
        error: e,
        stackTrace: stackTrace,
      );
      emit(const LocationError(LocationErrorCodes.searchFailed));
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
      final currentLocation = currentState is LocationSelected ? currentState.location : null;
      emit(LocationFavoritesLoaded(favorites: favorites, currentLocation: currentLocation));
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
      final currentLocation = currentState is LocationSelected ? currentState.location : null;
      emit(LocationFavoritesLoaded(favorites: favorites, currentLocation: currentLocation));
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
      final isValidRange = event.oldIndex >= 0 &&
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
      final currentLocation = currentState is LocationSelected ? currentState.location : null;
      emit(LocationFavoritesLoaded(favorites: updatedFavorites, currentLocation: currentLocation));
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
      final lastLocation = repository.loadLastLocation();
      emit(LocationFavoritesLoaded(favorites: favorites, currentLocation: lastLocation));
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
