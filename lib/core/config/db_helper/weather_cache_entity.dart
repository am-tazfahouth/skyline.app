import 'package:objectbox/objectbox.dart';

@Entity()
class WeatherCacheEntity {
  @Id()
  int id;
  String jsonData;
  int savedAt;

  WeatherCacheEntity({
    required this.id,
    required this.jsonData,
    required this.savedAt,
  });
}
