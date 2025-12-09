import '../models/ride.dart';
import '../models/ride_status.dart';
import 'ride_repository.dart';

/// In-memory implementation of RideRepository for development/testing.
/// TODO: Replace with Firebase / Firestore implementation.
class InMemoryRideRepository implements RideRepository {
  final Map<String, Ride> _rides = {};

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  @override
  Future<Ride> create(Ride ride) async {
    final now = DateTime.now();
    final newRide = ride.copyWith(
      id: ride.id.isEmpty ? _generateId() : ride.id,
      createdAt: ride.createdAt,
      updatedAt: now,
    );
    _rides[newRide.id] = newRide;
    return newRide;
  }

  @override
  Future<void> update(Ride ride) async {
    final updatedRide = ride.copyWith(updatedAt: DateTime.now());
    _rides[ride.id] = updatedRide;
  }

  @override
  Future<List<Ride>> historyForClient(String clientId) async {
    return _rides.values
        .where((ride) => ride.clientId == clientId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<Ride>> historyForDriver(String driverId) async {
    return _rides.values
        .where((ride) => ride.driverId == driverId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Ride?> getById(String id) async {
    return _rides[id];
  }

  @override
  Future<List<Ride>> getPendingRides() async {
    return _rides.values
        .where((ride) =>
            ride.status == RideStatus.requested ||
            ride.status == RideStatus.searchingDriver)
        .where((ride) => ride.driverId == null)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}

