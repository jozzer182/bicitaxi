import 'ride_status.dart';
import 'ride_location_point.dart';

/// Firebase collection name for rides.
/// Use this constant when integrating with Firestore.
const String kRidesCollection = 'rides';

/// A ride request in the Bici Taxi system.
/// 
/// This model is designed to be compatible with Firebase Firestore.
/// The toMap/fromMap methods use canonical field names that match
/// the iOS native app for cross-platform consistency.
class Ride {
  Ride({
    required this.id,
    required this.clientId,
    this.driverId,
    required this.pickup,
    this.dropoff,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String clientId;
  final String? driverId;
  final RideLocationPoint pickup;
  final RideLocationPoint? dropoff;
  final RideStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Converts to a map suitable for Firestore storage.
  /// Uses canonical field names matching iOS app.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'driverId': driverId,
      'pickup': pickup.toMap(),
      'dropoff': dropoff?.toMap(),
      'status': status.value,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Creates a Ride from a map (e.g., from Firestore).
  factory Ride.fromMap(Map<String, dynamic> map) {
    return Ride(
      id: map['id'] as String,
      clientId: map['clientId'] as String,
      driverId: map['driverId'] as String?,
      pickup: RideLocationPoint.fromMap(map['pickup'] as Map<String, dynamic>),
      dropoff: map['dropoff'] != null
          ? RideLocationPoint.fromMap(map['dropoff'] as Map<String, dynamic>)
          : null,
      status: RideStatusExtension.fromValue(map['status'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  // MARK: - Firebase Helpers
  // TODO: These methods will be used when Firebase is integrated.

  /// Converts to Firestore document data.
  /// Alias for toMap() - use this explicitly for Firebase operations.
  Map<String, dynamic> toFirestore() => toMap();

  /// Creates a Ride from Firestore document data.
  /// TODO: Update to handle Firestore Timestamp types when Firebase is added.
  factory Ride.fromFirestore(Map<String, dynamic> data, {String? documentId}) {
    final map = Map<String, dynamic>.from(data);
    if (documentId != null) {
      map['id'] = documentId;
    }
    return Ride.fromMap(map);
  }

  /// Creates a copy of this ride with the given fields replaced.
  Ride copyWith({
    String? id,
    String? clientId,
    String? driverId,
    RideLocationPoint? pickup,
    RideLocationPoint? dropoff,
    RideStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Ride(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      driverId: driverId ?? this.driverId,
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

