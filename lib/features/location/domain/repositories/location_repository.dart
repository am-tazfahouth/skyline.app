import 'package:sky_line/features/location/domain/entities/location_entity.dart';

abstract class LocationRepository {
  Future<List<LocationEntity>> searchLocations(String query);
  List<LocationEntity> loadFavorites();
  Future<void> saveFavorite(LocationEntity location);
  Future<void> removeFavorite(LocationEntity location);
  Future<void> saveAllFavorites(List<LocationEntity> favorites);
  LocationEntity? loadLastLocation();
  Future<void> saveLastLocation(LocationEntity location);
  Future<LocationEntity> detectCurrentLocation();
  Future<void> openLocationSettings();
  Future<void> openAppSettings();
}
