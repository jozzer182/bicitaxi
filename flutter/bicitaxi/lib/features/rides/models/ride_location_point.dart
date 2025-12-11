import '../../../core/utils/coordinate_formatter.dart';

/// A geographic point for ride pickup or dropoff.
/// 
/// Uses canonical field names (lat, lng) that match iOS app
/// for Firebase/backend consistency.
class RideLocationPoint {
  const RideLocationPoint({required this.lat, required this.lng, this.address});

  final double lat;
  final double lng;
  final String? address;

  /// Converts to a map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {'lat': lat, 'lng': lng, 'address': address};
  }

  /// Creates from a map (e.g., from Firestore).
  factory RideLocationPoint.fromMap(Map<String, dynamic> map) {
    return RideLocationPoint(
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      address: map['address'] as String?,
    );
  }

  // MARK: - Firebase Helpers
  // TODO: These methods will be used when Firebase is integrated.

  /// Converts to Firestore document data.
  Map<String, dynamic> toFirestore() => toMap();

  /// Creates from Firestore document data.
  factory RideLocationPoint.fromFirestore(Map<String, dynamic> data) {
    return RideLocationPoint.fromMap(data);
  }

  RideLocationPoint copyWith({double? lat, double? lng, String? address}) {
    return RideLocationPoint(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
    );
  }

  /// Returns coordinates in DMS format (degrees, minutes, seconds).
  /// Example: 4°44'50"N, 74°5'20"W
  String get dmsCoords => CoordinateFormatter.formatDMS(lat, lng);

  /// Returns a short decimal string representation of coordinates.
  String get shortCoords =>
      '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';

  /// Returns display text - coordinates in DMS format.
  String get displayText => dmsCoords;

  /// Returns display text with address below coordinates if available.
  String get displayTextWithAddress {
    if (address != null && address!.isNotEmpty) {
      return '$dmsCoords\n📍 $address';
    }
    return dmsCoords;
  }
}
