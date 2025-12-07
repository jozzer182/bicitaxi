/// A geographic point for ride pickup or dropoff.
class RideLocationPoint {
  const RideLocationPoint({
    required this.lat,
    required this.lng,
    this.address,
  });

  final double lat;
  final double lng;
  final String? address;

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'address': address,
    };
  }

  factory RideLocationPoint.fromMap(Map<String, dynamic> map) {
    return RideLocationPoint(
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      address: map['address'] as String?,
    );
  }

  RideLocationPoint copyWith({
    double? lat,
    double? lng,
    String? address,
  }) {
    return RideLocationPoint(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
    );
  }

  /// Returns a short string representation of coordinates.
  String get shortCoords => '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';

  /// Returns display text (address if available, otherwise coordinates).
  String get displayText => address ?? shortCoords;
}

