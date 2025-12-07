import 'package:latlong2/latlong.dart';

/// Ride data models for Bici Taxi Conductor.
/// These models will be used with Firebase Firestore in future implementations.
///
/// TODO: Add JSON serialization with json_annotation
/// TODO: Connect with Firebase Firestore
/// TODO: Add real-time ride status updates

/// Represents the status of a ride.
enum RideStatus {
  /// Ride has been requested, waiting for a driver.
  requested,

  /// Driver has accepted the ride.
  accepted,

  /// Driver is on the way to pickup location.
  driverEnRoute,

  /// Driver has arrived at pickup location.
  driverArrived,

  /// Ride is in progress.
  inProgress,

  /// Ride has been completed.
  completed,

  /// Ride was cancelled.
  cancelled,
}

/// Represents a location with coordinates and an optional address.
class RideLocation {
  const RideLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.name,
  });

  final double latitude;
  final double longitude;
  final String? address;
  final String? name;

  /// Converts to LatLng for use with flutter_map.
  LatLng toLatLng() => LatLng(latitude, longitude);

  // TODO: Add fromJson and toJson for Firebase serialization
}

/// Represents a user (client or driver).
class RideUser {
  const RideUser({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.photoUrl,
    this.rating,
  });

  final String id;
  final String name;
  final String? phoneNumber;
  final String? photoUrl;
  final double? rating;

  // TODO: Add fromJson and toJson for Firebase serialization
}

/// Represents driver availability status.
enum DriverStatus {
  /// Driver is offline and not accepting rides.
  offline,

  /// Driver is online and available for rides.
  available,

  /// Driver is currently on a ride.
  busy,

  /// Driver is on a break.
  onBreak,
}

/// Represents a complete ride.
class Ride {
  const Ride({
    required this.id,
    required this.client,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.status,
    required this.requestedAt,
    this.driver,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.estimatedFare,
    this.finalFare,
    this.distance,
    this.duration,
  });

  final String id;
  final RideUser client;
  final RideUser? driver;
  final RideLocation pickupLocation;
  final RideLocation dropoffLocation;
  final RideStatus status;
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final double? estimatedFare;
  final double? finalFare;
  final double? distance; // in kilometers
  final Duration? duration;

  /// Returns true if the ride is currently active.
  bool get isActive =>
      status == RideStatus.requested ||
      status == RideStatus.accepted ||
      status == RideStatus.driverEnRoute ||
      status == RideStatus.driverArrived ||
      status == RideStatus.inProgress;

  /// Returns true if the ride has ended (completed or cancelled).
  bool get hasEnded =>
      status == RideStatus.completed || status == RideStatus.cancelled;

  /// Returns true if the driver can accept this ride.
  bool get canAccept => status == RideStatus.requested;

  // TODO: Add fromJson and toJson for Firebase serialization
  // TODO: Add copyWith method for state updates
}

/// Represents a ride request shown to drivers.
class RideRequest {
  const RideRequest({
    required this.ride,
    required this.distanceToPickup,
    required this.estimatedTimeToPickup,
  });

  final Ride ride;
  final double distanceToPickup; // in kilometers
  final Duration estimatedTimeToPickup;

  // TODO: Add accept/decline methods
}

/// Represents driver statistics.
class DriverStats {
  const DriverStats({
    required this.totalRides,
    required this.totalEarnings,
    required this.rating,
    required this.acceptanceRate,
    required this.completionRate,
  });

  final int totalRides;
  final double totalEarnings;
  final double rating;
  final double acceptanceRate;
  final double completionRate;

  // TODO: Add fromJson for Firebase serialization
}

