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

  String get title =>
      [cityName, country].where((e) => e != null && e.isNotEmpty).join(', ');

  /// Returns true when [other] refers to the same geographic point as this
  /// location. Coordinates are compared after rounding to 4 decimals
  /// (~11 m precision) so that a GPS fix and a geocoding result for the same
  /// place are considered equal regardless of their precision.
  bool isAtSamePointAs(LocationEntity other) =>
      _roundCoordinate(latitude) == _roundCoordinate(other.latitude) &&
      _roundCoordinate(longitude) == _roundCoordinate(other.longitude);

  static double _roundCoordinate(double value) =>
      (value * 10000).roundToDouble() / 10000;
}
