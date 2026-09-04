import 'package:sky_line/features/location/domain/entities/location_entity.dart';

abstract class LocationRepository {
  Future<List<LocationEntity>> searchLocations(String query, String language);
  List<LocationEntity> loadFavorites();
  Future<void> saveFavorite(LocationEntity location);
  Future<void> removeFavorite(LocationEntity location);
  Future<void> saveAllFavorites(List<LocationEntity> favorites);
  LocationEntity? loadLastLocation();
  Future<void> saveLastLocation(LocationEntity location);
  Future<void> clearLastLocation();
  Future<LocationEntity> detectCurrentLocation(String language);
  Future<void> openLocationSettings();
  Future<void> openAppSettings();
  Future<bool> hasSeenLocationOnboarding();
  Future<void> markLocationOnboardingSeen();
}
