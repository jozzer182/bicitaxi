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
}

/// Represents a fare estimate for a ride.
class FareEstimate {
  const FareEstimate({
    required this.minFare,
    required this.maxFare,
    required this.estimatedDistance,
    required this.estimatedDuration,
  });

  final double minFare;
  final double maxFare;
  final double estimatedDistance; // in kilometers
  final Duration estimatedDuration;

  /// Returns the average of min and max fare.
  double get averageFare => (minFare + maxFare) / 2;
}

