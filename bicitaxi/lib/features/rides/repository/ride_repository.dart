import '../models/ride.dart';

/// Abstract repository for ride operations.
/// TODO: Replace with Firebase / Firestore implementation.
abstract class RideRepository {
  /// Creates a new ride.
  Future<Ride> create(Ride ride);

  /// Updates an existing ride.
  Future<void> update(Ride ride);

  /// Gets ride history for a specific client.
  Future<List<Ride>> historyForClient(String clientId);

  /// Gets ride history for a specific driver.
  Future<List<Ride>> historyForDriver(String driverId);

  /// Gets a single ride by ID.
  Future<Ride?> getById(String id);

  /// Gets all pending rides (for drivers to see available requests).
  Future<List<Ride>> getPendingRides();
}

