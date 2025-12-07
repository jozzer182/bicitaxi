import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'map_constants.dart';

/// Result of a location request.
class LocationResult {
  const LocationResult({
    required this.position,
    required this.isReal,
    this.errorMessage,
  });

  /// The position (real or fallback).
  final LatLng position;

  /// Whether this is the user's real location or a fallback.
  final bool isReal;

  /// Error message if location couldn't be obtained.
  final String? errorMessage;

  /// Creates a successful result with real location.
  factory LocationResult.success(Position position) {
    return LocationResult(
      position: LatLng(position.latitude, position.longitude),
      isReal: true,
    );
  }

  /// Creates a fallback result with default location.
  factory LocationResult.fallback(String errorMessage) {
    return LocationResult(
      position: MapConstants.defaultCenter,
      isReal: false,
      errorMessage: errorMessage,
    );
  }
}

/// Service for handling device location.
class LocationService {
  /// Checks if location services are enabled.
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Requests location permission.
  /// Returns true if permission was granted.
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Gets the current location permission status.
  Future<LocationPermission> getPermissionStatus() async {
    return await Geolocator.checkPermission();
  }

  /// Gets the current position.
  /// Returns a [LocationResult] with either the real position or a fallback.
  Future<LocationResult> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult.fallback(
          'Los servicios de ubicación están desactivados.',
        );
      }

      // Check/request permission
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        return LocationResult.fallback(
          'Permiso de ubicación denegado.',
        );
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return LocationResult.success(position);
    } catch (e) {
      return LocationResult.fallback(
        'Error al obtener ubicación: $e',
      );
    }
  }

  /// Streams position updates.
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Calculates distance between two points in meters.
  double calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }
}

