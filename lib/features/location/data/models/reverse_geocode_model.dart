import 'package:equatable/equatable.dart';

class ReverseGeocodeModel extends Equatable {
  final String? city;
  final String? locality;
  final String? principalSubdivision;
  final String? countryName;
  final String? countryCode;

  const ReverseGeocodeModel({
    this.city,
    this.locality,
    this.principalSubdivision,
    this.countryName,
    this.countryCode,
  });

  factory ReverseGeocodeModel.fromJson(Map<String, dynamic> json) {
    return ReverseGeocodeModel(
      city: json['city'] as String?,
      locality: json['locality'] as String?,
      principalSubdivision: json['principalSubdivision'] as String?,
      countryName: _cleanCountryName(json['countryName'] as String?),
      countryCode: json['countryCode'] as String?,
    );
  }

  static String? _cleanCountryName(String? raw) {
    if (raw == null || raw.isEmpty) return raw;
    return raw.replaceAll(RegExp(r'\s*\(.*\)\s*$'), '').trim();
  }

  ReverseGeocodeModel copyWith({
    String? city,
    String? locality,
    String? principalSubdivision,
    String? countryName,
    String? countryCode,
  }) {
    return ReverseGeocodeModel(
      city: city ?? this.city,
      locality: locality ?? this.locality,
      principalSubdivision: principalSubdivision ?? this.principalSubdivision,
      countryName: countryName ?? this.countryName,
      countryCode: countryCode ?? this.countryCode,
    );
  }

  @override
  List<Object?> get props => [
    city,
    locality,
    principalSubdivision,
    countryName,
    countryCode,
  ];
}
