import 'package:equatable/equatable.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();
  @override
  List<Object?> get props => [];
}

class DetectCurrentLocationEvent extends LocationEvent {
  const DetectCurrentLocationEvent();
}

class SearchLocationsEvent extends LocationEvent {
  final String query;
  const SearchLocationsEvent(this.query);
  @override
  List<Object?> get props => [query];
}

class SelectLocationEvent extends LocationEvent {
  final LocationEntity location;
  const SelectLocationEvent({required this.location});
  @override
  List<Object?> get props => [location];
}

class AddFavoriteEvent extends LocationEvent {
  final LocationEntity location;
  const AddFavoriteEvent({required this.location});
  @override
  List<Object?> get props => [location];
}

class RemoveFavoriteEvent extends LocationEvent {
  final LocationEntity location;
  const RemoveFavoriteEvent({required this.location});
  @override
  List<Object?> get props => [location];
}

class ReorderFavoritesEvent extends LocationEvent {
  final int oldIndex;
  final int newIndex;
  const ReorderFavoritesEvent({required this.oldIndex, required this.newIndex});
  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class LoadFavoritesEvent extends LocationEvent {
  const LoadFavoritesEvent();
}
