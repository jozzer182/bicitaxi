import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'request_service.dart';

/// Smart GPS location tracker for conductors.
///
/// Implements intelligent location publishing to reduce Firebase writes:
/// - Samples GPS every 30 seconds locally
/// - Maintains rolling buffer of last 3 positions
/// - Only publishes to Firebase if current position differs >3m from buffer average
class DriverLocationTracker {
  final RequestService _requestService;

  Timer? _locationTimer;
  String? _activeCellId;
  String? _activeRequestId;

  // Rolling buffer of recent positions for smart filtering
  final List<Position> _recentPositions = [];
  static const int _bufferSize = 3;
  static const double _movementThresholdMeters = 3.0;
  static const Duration _samplingInterval = Duration(seconds: 30);

  bool _isTracking = false;

  DriverLocationTracker({required RequestService requestService})
    : _requestService = requestService;

  /// Whether location tracking is currently active.
  bool get isTracking => _isTracking;

  /// Start tracking driver location for a request.
  /// Call this when driver accepts a request.
  void startTracking(String cellId, String requestId) {
    if (_isTracking) {
      stopTracking();
    }

    _activeCellId = cellId;
    _activeRequestId = requestId;
    _recentPositions.clear();
    _isTracking = true;

    print('📍 DriverLocationTracker: Started tracking for request $requestId');

    // Immediately get and publish first position
    _sampleLocation();

    // Start periodic sampling
    _locationTimer = Timer.periodic(_samplingInterval, (_) {
      _sampleLocation();
    });
  }

  /// Stop tracking driver location.
  /// Call this when request is completed or cancelled.
  void stopTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _activeCellId = null;
    _activeRequestId = null;
    _recentPositions.clear();
    _isTracking = false;

    print('📍 DriverLocationTracker: Stopped tracking');
  }

  /// Sample current location and publish if movement is significant.
  Future<void> _sampleLocation() async {
    if (!_isTracking || _activeCellId == null || _activeRequestId == null) {
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final shouldPublish = _shouldPublish(position);

      // Add to buffer
      _recentPositions.add(position);
      if (_recentPositions.length > _bufferSize) {
        _recentPositions.removeAt(0);
      }

      if (shouldPublish) {
        await _publishLocation(position);
      } else {
        print('📍 DriverLocationTracker: Skipping publish (minimal movement)');
      }
    } catch (e) {
      print('❌ DriverLocationTracker: Error sampling location: $e');
    }
  }

  /// Determine if position should be published based on movement from buffer average.
  bool _shouldPublish(Position current) {
    // Always publish first position
    if (_recentPositions.isEmpty) {
      return true;
    }

    // Calculate average of recent positions
    double avgLat = 0;
    double avgLng = 0;
    for (final pos in _recentPositions) {
      avgLat += pos.latitude;
      avgLng += pos.longitude;
    }
    avgLat /= _recentPositions.length;
    avgLng /= _recentPositions.length;

    // Calculate distance from average
    final distance = Geolocator.distanceBetween(
      avgLat,
      avgLng,
      current.latitude,
      current.longitude,
    );

    // Only publish if movement exceeds threshold
    return distance > _movementThresholdMeters;
  }

  /// Publish location to Firebase.
  Future<void> _publishLocation(Position position) async {
    if (_activeCellId == null || _activeRequestId == null) return;

    await _requestService.updateDriverLocation(
      _activeCellId!,
      _activeRequestId!,
      position.latitude,
      position.longitude,
    );

    print(
      '📍 DriverLocationTracker: Published location (${position.latitude}, ${position.longitude})',
    );
  }

  /// Dispose of resources.
  void dispose() {
    stopTracking();
  }
}
