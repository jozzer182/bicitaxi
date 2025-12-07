import 'package:flutter/foundation.dart';
import '../models/ride.dart';
import '../models/ride_status.dart';
import '../models/ride_location_point.dart';
import '../repository/ride_repository.dart';

/// Controller for client-side ride operations.
class ClientRideController extends ChangeNotifier {
  ClientRideController({required this.repo});

  final RideRepository repo;

  /// Current active ride (if any).
  Ride? activeRide;

  /// Demo user ID (will be replaced with Firebase Auth).
  final String currentUserId = 'client-demo';

  /// Whether a ride operation is in progress.
  bool isLoading = false;

  /// Requests a new ride.
  Future<void> requestRide(
    RideLocationPoint pickup,
    RideLocationPoint? dropoff,
  ) async {
    isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final ride = Ride(
        id: '',
        clientId: currentUserId,
        driverId: null,
        pickup: pickup,
        dropoff: dropoff,
        status: RideStatus.requested,
        createdAt: now,
        updatedAt: now,
      );

      activeRide = await repo.create(ride);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Cancels the active ride.
  Future<void> cancelRide() async {
    if (activeRide == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final cancelled = activeRide!.copyWith(
        status: RideStatus.cancelled,
        updatedAt: DateTime.now(),
      );
      await repo.update(cancelled);
      activeRide = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Simulates advancing to the next status (for demo purposes).
  Future<void> simulateNextStatus() async {
    if (activeRide == null) return;

    final nextStatus = activeRide!.status.nextStatus;
    if (nextStatus == null) {
      // Ride is complete or cancelled
      activeRide = null;
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      final updated = activeRide!.copyWith(
        status: nextStatus,
        updatedAt: DateTime.now(),
      );
      await repo.update(updated);
      activeRide = updated;

      // If completed, clear active ride
      if (nextStatus == RideStatus.completed) {
        activeRide = null;
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Gets ride history for the current user.
  Future<List<Ride>> getHistory() async {
    return repo.historyForClient(currentUserId);
  }

  /// Clears the active ride (e.g., after viewing completion).
  void clearActiveRide() {
    activeRide = null;
    notifyListeners();
  }
}

