import '../models/ride.dart';

/// Abstract repository for ride operations.
/// 
/// This is the base interface for ride data operations.
/// Currently implemented by [InMemoryRideRepository] for development.
/// 
/// TODO: Firebase Integration Points:
/// - Create [FirebaseRideRepository] implementing this interface
/// - Use Firestore collection: 'rides' (see [kRidesCollection])
/// - Use [Ride.fromFirestore] and [Ride.toFirestore] for serialization
/// - Add real-time listeners for active rides using snapshots
/// - Implement offline persistence with Firestore cache
abstract class RideRepository {
  /// Creates a new ride.
  /// TODO: Firebase - Write to Firestore with auto-generated document ID.
  Future<Ride> create(Ride ride);

  /// Updates an existing ride.
  /// TODO: Firebase - Update Firestore document, trigger real-time listeners.
  Future<void> update(Ride ride);

  /// Gets ride history for a specific client.
  /// TODO: Firebase - Query: rides where clientId == id, order by createdAt desc.
  Future<List<Ride>> historyForClient(String clientId);

  /// Gets ride history for a specific driver.
  /// TODO: Firebase - Query: rides where driverId == id, order by createdAt desc.
  Future<List<Ride>> historyForDriver(String driverId);

  /// Gets a single ride by ID.
  /// TODO: Firebase - Get document from 'rides' collection.
  Future<Ride?> getById(String id);

  /// Gets all pending rides (for drivers to see available requests).
  /// TODO: Firebase - Query: status in [requested, searchingDriver], driverId == null.
  Future<List<Ride>> getPendingRides();
}

