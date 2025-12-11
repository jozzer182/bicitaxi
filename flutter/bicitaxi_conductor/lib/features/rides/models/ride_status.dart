/// Status of a ride throughout its lifecycle.
/// 
/// Canonical status values for Firebase/backend synchronization.
/// All platforms (Flutter & iOS) use the same string values.
enum RideStatus {
  /// Client has requested a ride.
  requested,

  /// System is searching for an available driver.
  searchingDriver,

  /// A driver has been assigned to the ride.
  driverAssigned,

  /// Driver is en route to pickup location.
  driverArriving,

  /// Ride is in progress (passenger on board).
  inProgress,

  /// Ride has been completed successfully.
  completed,

  /// Ride was cancelled.
  cancelled,
}

/// Extension to provide serialization and display names for ride statuses.
extension RideStatusExtension on RideStatus {
  /// Canonical string value for Firebase/backend serialization.
  /// Must match iOS app values exactly.
  String get value {
    switch (this) {
      case RideStatus.requested:
        return 'requested';
      case RideStatus.searchingDriver:
        return 'searchingDriver';
      case RideStatus.driverAssigned:
        return 'driverAssigned';
      case RideStatus.driverArriving:
        return 'driverArriving';
      case RideStatus.inProgress:
        return 'inProgress';
      case RideStatus.completed:
        return 'completed';
      case RideStatus.cancelled:
        return 'cancelled';
    }
  }

  /// Creates a RideStatus from its canonical string value.
  static RideStatus fromValue(String value) {
    switch (value) {
      case 'requested':
        return RideStatus.requested;
      case 'searchingDriver':
        return RideStatus.searchingDriver;
      case 'driverAssigned':
        return RideStatus.driverAssigned;
      case 'driverArriving':
        return RideStatus.driverArriving;
      case 'inProgress':
        return RideStatus.inProgress;
      case 'completed':
        return RideStatus.completed;
      case 'cancelled':
        return RideStatus.cancelled;
      default:
        return RideStatus.requested;
    }
  }
  String get displayName {
    switch (this) {
      case RideStatus.requested:
        return 'Solicitado';
      case RideStatus.searchingDriver:
        return 'Buscando conductor';
      case RideStatus.driverAssigned:
        return 'Conductor asignado';
      case RideStatus.driverArriving:
        return 'Conductor en camino';
      case RideStatus.inProgress:
        return 'En progreso';
      case RideStatus.completed:
        return 'Completado';
      case RideStatus.cancelled:
        return 'Cancelado';
    }
  }

  /// Returns the next status in the workflow (for simulation).
  RideStatus? get nextStatus {
    switch (this) {
      case RideStatus.requested:
        return RideStatus.searchingDriver;
      case RideStatus.searchingDriver:
        return RideStatus.driverAssigned;
      case RideStatus.driverAssigned:
        return RideStatus.driverArriving;
      case RideStatus.driverArriving:
        return RideStatus.inProgress;
      case RideStatus.inProgress:
        return RideStatus.completed;
      case RideStatus.completed:
      case RideStatus.cancelled:
        return null;
    }
  }

  /// Whether the ride is still active (not terminal).
  bool get isActive {
    return this != RideStatus.completed && this != RideStatus.cancelled;
  }
}

