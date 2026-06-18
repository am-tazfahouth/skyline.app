import 'dart:convert';

import 'package:sky_line/core/config/db_helper/weather_cache_entity.dart';
import 'package:sky_line/features/weather_forecast/data/models/weather_model.dart';
import 'package:sky_line/core/config/db_helper/objectbox.g.dart';

class DbHelper {
  static DbHelper? _instance;
  late final Store _store;
  late final Box<WeatherCacheEntity> _box;

  DbHelper._(this._store) : _box = Box<WeatherCacheEntity>(_store);

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

  void dispose() {
    _store.close();
    _instance = null;
  }
}
