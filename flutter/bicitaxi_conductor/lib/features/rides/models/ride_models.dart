import 'package:latlong2/latlong.dart';

/// DEPRECATED: Legacy ride data models.
/// 
/// ⚠️ DO NOT USE THESE MODELS FOR NEW CODE ⚠️
/// 
/// Use the canonical models instead:
/// - `ride.dart` for [Ride]
/// - `ride_status.dart` for [RideStatus]
/// - `ride_location_point.dart` for location data
/// - `user_basic.dart` for user references
/// 
/// These legacy models will be removed in a future version.
/// They have different enum values and field structures that are
/// not compatible with the Firebase backend schema.

@Deprecated('Use ride_status.dart instead. This has different enum values.')
/// Represents the status of a ride.
enum LegacyRideStatus {
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

@Deprecated('Use RideLocationPoint from ride_location_point.dart instead.')
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
}

@Deprecated('Use UserBasic from user_basic.dart instead.')
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

@Deprecated('Use Ride from ride.dart instead. This has different field structure.')
/// Represents a complete ride (legacy).
class LegacyRide {
  const LegacyRide({
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
  final LegacyRideStatus status;
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
      status == LegacyRideStatus.requested ||
      status == LegacyRideStatus.accepted ||
      status == LegacyRideStatus.driverEnRoute ||
      status == LegacyRideStatus.driverArrived ||
      status == LegacyRideStatus.inProgress;

  /// Returns true if the ride has ended (completed or cancelled).
  bool get hasEnded =>
      status == LegacyRideStatus.completed || status == LegacyRideStatus.cancelled;

  /// Returns true if the driver can accept this ride.
  bool get canAccept => status == LegacyRideStatus.requested;
}

@Deprecated('Use Ride from ride.dart instead.')
/// Represents a ride request shown to drivers (legacy).
class RideRequest {
  const RideRequest({
    required this.ride,
    required this.distanceToPickup,
    required this.estimatedTimeToPickup,
  });

  final LegacyRide ride;
  final double distanceToPickup; // in kilometers
  final Duration estimatedTimeToPickup;
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
}

