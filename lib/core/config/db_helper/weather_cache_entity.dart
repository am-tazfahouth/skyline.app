import 'package:objectbox/objectbox.dart';

@Entity()
class WeatherCacheEntity {
  @Id()
  int id;
  String jsonData;

  WeatherCacheEntity({required this.id, required this.jsonData});
}
