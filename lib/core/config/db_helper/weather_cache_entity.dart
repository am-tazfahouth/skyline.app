import 'package:objectbox/objectbox.dart';

@Entity()
class WeatherCacheEntity {
  @Id()
  int id;
  String jsonData;
  int savedAt;
  double latitude;
  double longitude;

  WeatherCacheEntity({
    required this.id,
    required this.jsonData,
    required this.savedAt,
    required this.latitude,
    required this.longitude,
  });
}
