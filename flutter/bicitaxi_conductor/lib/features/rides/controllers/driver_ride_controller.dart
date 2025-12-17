import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/ride.dart';
import '../models/ride_status.dart';
import '../models/ride_location_point.dart';
import '../repository/ride_repository.dart';
import '../../../core/services/presence_service.dart';
import '../../../core/services/demo_mode_service.dart';
import '../../../core/services/request_service.dart';
import '../../../core/services/driver_location_tracker.dart';

/// Controller for driver-side ride operations.
class DriverRideController extends ChangeNotifier {
  DriverRideController({required this.repo}) {
    // Initialize location tracker
    _locationTracker = DriverLocationTracker(requestService: _requestService);
    // Initialize based on current demo mode state
    _refreshPendingRides();
    // Listen for demo mode changes
    DemoModeService().isDemoMode.addListener(_onDemoModeChanged);
  }

  final RideRepository repo;

  /// Demo mode service reference
  final DemoModeService _demoModeService = DemoModeService();

  /// Presence service for publishing driver location
  final PresenceService _presenceService = PresenceService(
    appName: 'bicitaxi_conductor',
    role: PresenceRole.driver,
  );

  /// Request service for Firebase ride requests
  final RequestService _requestService = RequestService();

  /// Driver location tracker for smart GPS updates
  late final DriverLocationTracker _locationTracker;

  /// Active Firebase request tracking info (null for demo rides)
  String? _activeCellId;
  String? _activeRequestId;

  /// Current driver position (updated from views)
  Position? _currentPosition;

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

  /// Called when demo mode changes
  void _onDemoModeChanged() {
    _refreshPendingRides();
  }

  /// Refreshes pending rides based on demo mode state
  void _refreshPendingRides() {
    pendingRides.clear();
    if (_demoModeService.isDemoMode.value) {
      _initDummyRides();
    }
    notifyListeners();
  }

  /// Initialize with some dummy ride requests (only in demo mode).
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

  /// Updates the current driver position (called from views with location)
  void updatePosition(Position position) {
    _currentPosition = position;
  }

  /// Toggles online/offline status and manages presence.
  Future<void> toggleOnlineStatus() async {
    if (isOnline) {
      // Going offline
      await _goOffline();
    } else {
      // Going online
      await _goOnline();
    }
  }

  /// Go online and start presence heartbeat
  Future<void> _goOnline() async {
    if (_currentPosition == null) {
      // Try to get current position
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        print('⚠️ DriverRideController: Could not get location: $e');
      }
    }

    isOnline = true;
    notifyListeners();

    // Start presence heartbeat
    _presenceService.startHeartbeat(
      getLatitude: () => _currentPosition?.latitude ?? 0,
      getLongitude: () => _currentPosition?.longitude ?? 0,
      getActiveRideId: () => activeRide?.id,
    );
  }

  /// Go offline and stop presence
  Future<void> _goOffline() async {
    isOnline = false;
    notifyListeners();
    await _presenceService.goOffline();
  }

  /// Dispose resources
  @override
  void dispose() {
    _demoModeService.isDemoMode.removeListener(_onDemoModeChanged);
    _presenceService.dispose();
    _locationTracker.dispose();
    super.dispose();
  }

  /// Accepts a ride request.
  /// Optionally pass cellId and requestId for Firebase request tracking.
  Future<void> acceptRide(
    Ride ride, {
    String? cellId,
    String? requestId,
  }) async {
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

      // Store Firebase request info for location tracking
      _activeCellId = cellId;
      _activeRequestId = requestId;

      // Start location tracking if we have Firebase request info
      if (cellId != null && requestId != null) {
        _locationTracker.startTracking(cellId, requestId);
      }
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

      // Complete Firebase request if we have real request info
      if (_activeCellId != null && _activeRequestId != null) {
        await _requestService.completeRequest(
          _activeCellId!,
          _activeRequestId!,
        );
      }

      // Stop location tracking
      _locationTracker.stopTracking();
      _activeCellId = null;
      _activeRequestId = null;

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

      // Cancel Firebase request if we have real request info
      if (_activeCellId != null && _activeRequestId != null) {
        await _requestService.cancelRequest(_activeCellId!, _activeRequestId!);
      }

      // Stop location tracking
      _locationTracker.stopTracking();
      _activeCellId = null;
      _activeRequestId = null;

      activeRide = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Dismisses/rejects a pending ride request.
  void dismissRide(Ride ride) {
    pendingRides.removeWhere((r) => r.id == ride.id);
    notifyListeners();
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
