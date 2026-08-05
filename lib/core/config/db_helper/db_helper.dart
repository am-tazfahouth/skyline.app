import 'dart:convert';

import 'package:sky_line/core/config/db_helper/weather_cache_entity.dart';
import 'package:sky_line/core/config/db_helper/setting_cache_entity.dart';
import 'package:sky_line/core/config/db_helper/location_cache_entity.dart';
import 'package:sky_line/core/config/db_helper/last_location_entity.dart';
import 'package:sky_line/core/enums/setting_heat_unit.dart';
import 'package:sky_line/core/enums/setting_lang.dart';
import 'package:sky_line/core/enums/setting_theme.dart';
import 'package:sky_line/core/enums/setting_wind_unit.dart';
import 'package:sky_line/features/settings/data/models/setting_model.dart';
import 'package:sky_line/features/weather_forecast/data/models/weather_model.dart';
import 'package:sky_line/core/config/db_helper/generated/objectbox.g.dart';

class DbHelper {
  static DbHelper? _instance;
  late final Store _store;
  late final Box<WeatherCacheEntity> _box;
  late final Box<SettingCacheEntity> _settingsBox;
  late final Box<LocationCacheEntity> _locationBox;
  late final Box<LastLocationEntity> _lastLocationBox;

  DbHelper._(this._store)
      : _box = Box<WeatherCacheEntity>(_store),
        _settingsBox = Box<SettingCacheEntity>(_store),
        _locationBox = Box<LocationCacheEntity>(_store),
        _lastLocationBox = Box<LastLocationEntity>(_store);

  static Future<DbHelper> init({String? directory}) async {
    if (_instance != null) return _instance!;
    final store = await openStore(directory: directory);
    _instance = DbHelper._(store);
    return _instance!;
  }

  void saveWeather(WeatherModel model) {
    _box.removeAll();
    final jsonStr = jsonEncode(model.toJson());
    _box.put(WeatherCacheEntity(
      id: 0,
      jsonData: jsonStr,
      savedAt: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  void clearWeather() {
    _box.removeAll();
  }

  WeatherModel? loadWeather({int? maxAgeMillis}) {
    final entities = _box.getAll();
    if (entities.isEmpty) return null;

    final entity = entities.first;
    if (maxAgeMillis != null) {
      final age = DateTime.now().millisecondsSinceEpoch - entity.savedAt;
      if (age >= maxAgeMillis) return null;
    }

    final json = jsonDecode(entity.jsonData) as Map<String, dynamic>;
    return WeatherModel.fromCacheJson(json);
  }

  SettingCacheEntity? loadSettings() {
    final entities = _settingsBox.getAll();
    if (entities.isEmpty) return null;
    
    return entities.first;
  }

  void saveSettings(SettingModel model) {
    _settingsBox.removeAll();
    _settingsBox.put(SettingCacheEntity(
      id: 0,
      themeValue: SettingTheme.getStringFromTheme(model.theme),
      langValue: getStringFromLang(model.lang),
      windUnitValue: SettingWindUnit.getStringFromWindUnit(model.windUnit),
      heatUnitValue: SettingHeatUnit.getStringFromHeatUnit(model.heatUnit),
    ));
  }

  List<LocationCacheEntity> loadFavorites() {
    final list = _locationBox.getAll();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  void saveFavorite(LocationCacheEntity favorite) {
    _locationBox.put(favorite);
  }

  void removeFavorite(int id) {
    _locationBox.remove(id);
  }

  void saveAllFavorites(List<LocationCacheEntity> favorites) {
    _locationBox.removeAll();
    for (final f in favorites) {
      _locationBox.put(f);
    }
  }

  LastLocationEntity? loadLastLocation() {
    final list = _lastLocationBox.getAll();
    return list.isNotEmpty ? list.first : null;
  }

  void saveLastLocation(LastLocationEntity location) {
    _lastLocationBox.removeAll();
    _lastLocationBox.put(location);
  }

  void clearLastLocation() {
    _lastLocationBox.removeAll();
  }

  void dispose() {
    _store.close();
    _instance = null;
  }
}
