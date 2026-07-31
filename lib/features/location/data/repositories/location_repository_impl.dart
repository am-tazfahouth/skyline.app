import 'package:geolocator/geolocator.dart';
import 'package:sky_line/features/location/data/mappers/location_mapper.dart';
import 'package:sky_line/features/location/data/sources/location_remote_source.dart';
import 'package:sky_line/features/location/data/sources/location_local_source.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';
import 'package:sky_line/features/location/domain/repositories/location_repository.dart';
import 'package:sky_line/core/config/db_helper/location_cache_entity.dart';
import 'package:sky_line/core/config/db_helper/last_location_entity.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteSource _remoteSource;
  final LocationLocalSource _localSource;

  LocationRepositoryImpl(this._remoteSource, this._localSource);

  @override
  Future<List<LocationEntity>> searchLocations(String query) async {
    final json = await _remoteSource.search(query);
    final models = LocationMapper.fromJsonList(json);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  List<LocationEntity> loadFavorites() {
    return _localSource.loadFavorites().map((e) => LocationEntity(
      latitude: e.latitude,
      longitude: e.longitude,
      cityName: e.cityName,
      country: e.country,
      admin1: e.admin1,
      isGpsLocation: e.isGpsLocation,
      sortOrder: e.sortOrder,
    )).toList();
  }

  @override
  Future<void> saveFavorite(LocationEntity location) async {
    _localSource.saveFavorite(LocationCacheEntity(
      latitude: location.latitude,
      longitude: location.longitude,
      cityName: location.cityName,
      country: location.country,
      admin1: location.admin1,
      isGpsLocation: location.isGpsLocation,
      sortOrder: location.sortOrder,
    ));
  }

  @override
  Future<void> removeFavorite(LocationEntity location) async {
    final favorites = _localSource.loadFavorites();
    for (final f in favorites) {
      if (f.cityName == location.cityName && f.country == location.country) {
        _localSource.removeFavorite(f.id);
        break;
      }
    }
  }

  @override
  Future<void> saveAllFavorites(List<LocationEntity> favorites) async {
    // List index IS the intended sort order (used for reordering).
    _localSource.saveAllFavorites(favorites.asMap().entries.map((e) => LocationCacheEntity(
      latitude: e.value.latitude,
      longitude: e.value.longitude,
      cityName: e.value.cityName,
      country: e.value.country,
      admin1: e.value.admin1,
      isGpsLocation: e.value.isGpsLocation,
      sortOrder: e.key,
    )).toList());
  }

  @override
  LocationEntity? loadLastLocation() {
    final entity = _localSource.loadLastLocation();
    if (entity == null) return null;
    return LocationEntity(
      latitude: entity.latitude,
      longitude: entity.longitude,
      cityName: entity.cityName,
      country: entity.country,
      admin1: entity.admin1,
      isGpsLocation: entity.isGpsLocation,
    );
  }

  @override
  Future<void> saveLastLocation(LocationEntity location) async {
    _localSource.saveLastLocation(LastLocationEntity(
      latitude: location.latitude,
      longitude: location.longitude,
      cityName: location.cityName,
      country: location.country,
      admin1: location.admin1,
      isGpsLocation: location.isGpsLocation,
    ));
  }

  @override
  Future<LocationEntity> detectCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('gpsDisabled');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw Exception('gpsPermissionDenied');
    }
    if (permission == LocationPermission.deniedForever) throw Exception('gpsPermissionDenied');

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );

    return LocationEntity(
      latitude: position.latitude,
      longitude: position.longitude,
      cityName: 'Current Location',
      isGpsLocation: true,
    );
  }
}
