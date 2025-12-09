/// Status of a ride throughout its lifecycle.
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

/// Extension to provide display names for ride statuses.
extension RideStatusExtension on RideStatus {
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

