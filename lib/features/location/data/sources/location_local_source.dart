import 'package:sky_line/core/config/db_helper/db_helper.dart';
import 'package:sky_line/core/config/db_helper/location_cache_entity.dart';
import 'package:sky_line/core/config/db_helper/last_location_entity.dart';

class LocationLocalSource {
  final DbHelper _dbHelper;

  LocationLocalSource(this._dbHelper);

  List<LocationCacheEntity> loadFavorites() => _dbHelper.loadFavorites();

  void saveFavorite(LocationCacheEntity favorite) => _dbHelper.saveFavorite(favorite);

  void removeFavorite(int id) => _dbHelper.removeFavorite(id);

  void saveAllFavorites(List<LocationCacheEntity> favorites) => _dbHelper.saveAllFavorites(favorites);

  LastLocationEntity? loadLastLocation() => _dbHelper.loadLastLocation();

  void saveLastLocation(LastLocationEntity location) => _dbHelper.saveLastLocation(location);

  void clearLastLocation() => _dbHelper.clearLastLocation();
}
