import 'package:flutter/foundation.dart';
import '../models/ride.dart';
import '../models/ride_status.dart';
import '../models/ride_location_point.dart';
import '../repository/ride_repository.dart';

/// Controller for driver-side ride operations.
class DriverRideController extends ChangeNotifier {
  DriverRideController({required this.repo}) {
    _initDummyRides();
  }

  final RideRepository repo;

  /// List of pending ride requests.
  List<Ride> pendingRides = [];

  /// Current active ride (if any).
  Ride? activeRide;

  /// Demo driver ID (will be replaced with Firebase Auth).
  final String currentDriverId = 'driver-demo';

  /// Whether a ride operation is in progress.
  bool isLoading = false;

  /// Whether the driver is online.
  bool isOnline = false;

  /// Initialize with some dummy ride requests.
  Future<void> _initDummyRides() async {
    // Base coordinates (Mexico City area)
    const baseLat = 19.4326;
    const baseLng = -99.1332;

    final dummyRequests = [
      Ride(
        id: '',
        clientId: 'client-001',
        driverId: null,
        pickup: RideLocationPoint(
          lat: baseLat + 0.003,
          lng: baseLng + 0.002,
          address: 'Centro Histórico',
        ),
        dropoff: RideLocationPoint(
          lat: baseLat + 0.01,
          lng: baseLng - 0.005,
          address: 'Universidad',
        ),
        status: RideStatus.searchingDriver,
        createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
        updatedAt: DateTime.now(),
      ),
      Ride(
        id: '',
        clientId: 'client-002',
        driverId: null,
        pickup: RideLocationPoint(
          lat: baseLat - 0.002,
          lng: baseLng + 0.004,
          address: 'Plaza Norte',
        ),
        dropoff: RideLocationPoint(
          lat: baseLat + 0.008,
          lng: baseLng + 0.003,
          address: 'Hospital Central',
        ),
        status: RideStatus.searchingDriver,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        updatedAt: DateTime.now(),
      ),
      Ride(
        id: '',
        clientId: 'client-003',
        driverId: null,
        pickup: RideLocationPoint(
          lat: baseLat + 0.001,
          lng: baseLng - 0.003,
          address: 'Estación Metro',
        ),
        dropoff: RideLocationPoint(
          lat: baseLat - 0.006,
          lng: baseLng + 0.001,
          address: 'Centro Comercial',
        ),
        status: RideStatus.searchingDriver,
        createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
        updatedAt: DateTime.now(),
      ),
    ];

    for (final ride in dummyRequests) {
      final created = await repo.create(ride);
      pendingRides.add(created);
    }

    notifyListeners();
  }

  /// Toggles online/offline status.
  void toggleOnlineStatus() {
    isOnline = !isOnline;
    notifyListeners();
  }

  /// Accepts a ride request.
  Future<void> acceptRide(Ride ride) async {
    isLoading = true;
    notifyListeners();

    try {
      final accepted = ride.copyWith(
        driverId: currentDriverId,
        status: RideStatus.driverAssigned,
        updatedAt: DateTime.now(),
      );

      await repo.update(accepted);
      activeRide = accepted;
      pendingRides.removeWhere((r) => r.id == ride.id);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Marks that driver is arriving to pickup.
  Future<void> markArriving() async {
    if (activeRide == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final updated = activeRide!.copyWith(
        status: RideStatus.driverArriving,
        updatedAt: DateTime.now(),
      );
      await repo.update(updated);
      activeRide = updated;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Starts the ride (passenger on board).
  Future<void> startRide() async {
    if (activeRide == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final updated = activeRide!.copyWith(
        status: RideStatus.inProgress,
        updatedAt: DateTime.now(),
      );
      await repo.update(updated);
      activeRide = updated;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Finishes the ride.
  Future<void> finishRide() async {
    if (activeRide == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final updated = activeRide!.copyWith(
        status: RideStatus.completed,
        updatedAt: DateTime.now(),
      );
      await repo.update(updated);
      activeRide = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Cancels the active ride.
  Future<void> cancelActiveRide() async {
    if (activeRide == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final cancelled = activeRide!.copyWith(
        status: RideStatus.cancelled,
        driverId: null,
        updatedAt: DateTime.now(),
      );
      await repo.update(cancelled);
      activeRide = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Gets ride history for the current driver.
  Future<List<Ride>> getHistory() async {
    return repo.historyForDriver(currentDriverId);
  }

  /// Gets completed rides for earnings calculation.
  Future<List<Ride>> getCompletedRides() async {
    final history = await getHistory();
    return history.where((r) => r.status == RideStatus.completed).toList();
  }

  /// Clears the active ride.
  void clearActiveRide() {
    activeRide = null;
    notifyListeners();
  }
}

