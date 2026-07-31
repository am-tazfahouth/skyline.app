import 'package:equatable/equatable.dart';
import 'package:sky_line/core/errors/app_error_code.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';

abstract class LocationState extends Equatable {
  const LocationState();
  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {
  const LocationInitial();
}

class LocationDetecting extends LocationState {
  const LocationDetecting();
}

class LocationSearchLoading extends LocationState {
  const LocationSearchLoading();
}

class LocationSearchLoaded extends LocationState {
  final List<LocationEntity> results;
  const LocationSearchLoaded(this.results);
  @override
  List<Object?> get props => [results];
}

class LocationSelected extends LocationState {
  final LocationEntity location;
  final List<LocationEntity> favorites;
  const LocationSelected({required this.location, this.favorites = const []});
  @override
  List<Object?> get props => [location, favorites];
}

class LocationFavoritesLoaded extends LocationState {
  final List<LocationEntity> favorites;
  final LocationEntity? currentLocation;
  const LocationFavoritesLoaded({required this.favorites, this.currentLocation});
  @override
  List<Object?> get props => [favorites, currentLocation];
}

class LocationError extends LocationState {
  final AppErrorCode errorCode;
  const LocationError(this.errorCode);
  @override
  List<Object?> get props => [errorCode];
}
