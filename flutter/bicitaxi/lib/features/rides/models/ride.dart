import 'ride_status.dart';
import 'ride_location_point.dart';

/// A ride request in the Bici Taxi system.
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
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'driverId': driverId,
      'pickup': pickup.toMap(),
      'dropoff': dropoff?.toMap(),
      'status': status.index,
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
      status: RideStatus.values[map['status'] as int],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
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

