import 'package:objectbox/objectbox.dart';

@Entity()
class LastLocationEntity {
  @Id()
  int id;

  double latitude;
  double longitude;
  String cityName;
  String? country;
  String? admin1;
  bool isGpsLocation;

  LastLocationEntity({
    this.id = 0,
    required this.latitude,
    required this.longitude,
    required this.cityName,
    this.country,
    this.admin1,
    this.isGpsLocation = false,
  });
}
