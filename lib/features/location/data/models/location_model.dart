import 'package:equatable/equatable.dart';
import 'package:sky_line/features/location/domain/entities/location_entity.dart';

class LocationModel extends Equatable {
  final double latitude;
  final double longitude;
  final String cityName;
  final String? country;
  final String? admin1;

  const LocationModel({
    required this.latitude,
    required this.longitude,
    required this.cityName,
    this.country,
    this.admin1,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      cityName: json['name'] as String,
      country: json['country'] as String?,
      admin1: json['admin1'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'name': cityName,
    'country': country,
    'admin1': admin1,
  };

  LocationEntity toEntity() => LocationEntity(
    latitude: latitude,
    longitude: longitude,
    cityName: cityName,
    country: country,
    admin1: admin1,
  );

  LocationModel copyWith({
    double? latitude,
    double? longitude,
    String? cityName,
    String? country,
    String? admin1,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cityName: cityName ?? this.cityName,
      country: country ?? this.country,
      admin1: admin1 ?? this.admin1,
    );
  }

  @override
  List<Object?> get props => [latitude, longitude, cityName, country, admin1];
}
