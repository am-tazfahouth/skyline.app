import 'package:equatable/equatable.dart';

class LocationEntity extends Equatable {
  final double latitude;
  final double longitude;
  final String cityName;
  final String? country;
  final String? admin1;
  final bool isGpsLocation;
  final int sortOrder;

  const LocationEntity({
    required this.latitude,
    required this.longitude,
    required this.cityName,
    this.country,
    this.admin1,
    this.isGpsLocation = false,
    this.sortOrder = 0,
  });

  LocationEntity copyWith({
    double? latitude,
    double? longitude,
    String? cityName,
    String? country,
    String? admin1,
    bool? isGpsLocation,
    int? sortOrder,
  }) {
    return LocationEntity(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cityName: cityName ?? this.cityName,
      country: country ?? this.country,
      admin1: admin1 ?? this.admin1,
      isGpsLocation: isGpsLocation ?? this.isGpsLocation,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        cityName,
        country,
        admin1,
        isGpsLocation,
        sortOrder,
      ];

  String get title => [cityName, country]
      .where((e) => e != null && e.isNotEmpty)
      .join(', ');
}
