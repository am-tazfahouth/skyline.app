import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:sky_line/core/errors/location_exceptions.dart';
import 'package:sky_line/features/location/data/mappers/location_mapper.dart';
import 'package:sky_line/features/location/data/sources/location_remote_source.dart';
import 'package:sky_line/features/location/data/sources/location_local_source.dart';
import 'package:sky_line/features/location/data/sources/location_permission_source.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';
import 'package:sky_line/features/location/domain/repositories/location_repository.dart';
import 'package:sky_line/core/config/db_helper/location_cache_entity.dart';
import 'package:sky_line/core/config/db_helper/last_location_entity.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteSource _remoteSource;
  final LocationLocalSource _localSource;
  final LocationPermissionSource _permissionSource;

  LocationRepositoryImpl(
    this._remoteSource,
    this._localSource,
    this._permissionSource,
  );

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
  Future<void> clearLastLocation() async {
    _localSource.clearLastLocation();
  }

  @override
  Future<LocationEntity> detectCurrentLocation() async {
    final status = await _permissionSource.requestLocationPermission();
    if (status.isRestricted || status.isDenied) {
      throw const LocationPermissionDeniedException();
    }
    if (status.isPermanentlyDenied) {
      throw const LocationPermissionPermanentlyDeniedException();
    }

    final serviceEnabled = await _permissionSource.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    final position = await _permissionSource.getCurrentPosition();
    return _resolveDetectedLocation(position.latitude, position.longitude);
  }

  Future<LocationEntity> _resolveDetectedLocation(
    double latitude,
    double longitude,
  ) async {
    try {
      final place =
          await _remoteSource.reverseGeocode(latitude: latitude, longitude: longitude);
      final city = _firstNonEmpty([place.city, place.locality]);
      if (city == null) return _gpsFallback(latitude, longitude);
      return LocationEntity(
        latitude: latitude,
        longitude: longitude,
        cityName: city,
        country: place.countryName,
        admin1: place.principalSubdivision,
        isGpsLocation: true,
      );
    } catch (_) {
      return _gpsFallback(latitude, longitude);
    }
  }

  LocationEntity _gpsFallback(double latitude, double longitude) {
    return LocationEntity(
      latitude: latitude,
      longitude: longitude,
      cityName: 'Current Location',
      isGpsLocation: true,
    );
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value;
    }
    return null;
  }

  @override
  Future<void> openLocationSettings() async {
    await _permissionSource.openLocationSettings();
  }

  @override
  Future<void> openAppSettings() async {
    await _permissionSource.openAppSettings();
  }

  @override
  Future<bool> hasSeenLocationOnboarding() async {
    return _localSource.loadOnboardingFlag();
  }

  @override
  Future<void> markLocationOnboardingSeen() async {
    _localSource.saveOnboardingFlag(true);
  }
}
