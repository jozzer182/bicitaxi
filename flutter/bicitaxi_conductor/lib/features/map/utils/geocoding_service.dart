import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for reverse geocoding using Nominatim (OpenStreetMap).
/// Implements debouncing to respect API rate limits (1 request/second).
class GeocodingService {
  static final GeocodingService _instance = GeocodingService._internal();
  factory GeocodingService() => _instance;
  GeocodingService._internal();

  Timer? _debounceTimer;
  DateTime? _lastRequestTime;

  /// Minimum delay between API requests (1 second as per Nominatim policy).
  static const Duration _minRequestInterval = Duration(seconds: 1);

  /// Debounce delay before making a request (wait for user to stop moving).
  static const Duration _debounceDelay = Duration(milliseconds: 500);

  /// User agent for Nominatim requests (required by their usage policy).
  static const String _userAgent =
      'BiciTaxiConductor/1.0 (dev.zarabanda.bicitaxiConductor)';

  /// Reverse geocodes coordinates to an address.
  /// Returns null if geocoding fails or is unavailable.
  ///
  /// Uses debouncing to wait until user stops moving the marker,
  /// and respects Nominatim's 1 request/second rate limit.
  Future<String?> reverseGeocode(
    double lat,
    double lng, {
    void Function(String?)? onResult,
  }) async {
    // Cancel any pending request
    _debounceTimer?.cancel();

    // Create a completer for the debounced result
    final completer = Completer<String?>();

    _debounceTimer = Timer(_debounceDelay, () async {
      // Ensure we respect the rate limit
      await _waitForRateLimit();

      try {
        final result = await _fetchAddress(lat, lng);
        _lastRequestTime = DateTime.now();

        if (!completer.isCompleted) {
          completer.complete(result);
        }
        onResult?.call(result);
      } catch (e) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
        onResult?.call(null);
      }
    });

    return completer.future;
  }

  /// Waits if necessary to respect the rate limit.
  Future<void> _waitForRateLimit() async {
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < _minRequestInterval) {
        await Future.delayed(_minRequestInterval - elapsed);
      }
    }
  }

  /// Fetches the address from Nominatim API.
  Future<String?> _fetchAddress(double lat, double lng) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?format=json'
      '&lat=$lat'
      '&lon=$lng'
      '&zoom=18'
      '&addressdetails=1',
    );

    final response = await http.get(url, headers: {'User-Agent': _userAgent});

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return _formatAddress(data);
    }

    return null;
  }

  /// Formats the Nominatim response into a readable address.
  /// Focuses on street-level details only (no city/locality/neighbourhood).
  /// For Colombia, shows only the road name (Carrera/Calle) and house number if available.
  String? _formatAddress(Map<String, dynamic> data) {
    final address = data['address'] as Map<String, dynamic>?;
    if (address == null) {
      return _extractStreetOnly(data['display_name'] as String?);
    }

    // Primary: Street/Road name only
    final road = address['road'] as String?;
    final houseNumber = address['house_number'] as String?;

    if (road != null) {
      if (houseNumber != null) {
        // Format: "Carrera 100 # 148-78"
        return '$road # $houseNumber';
      }
      return road;
    }

    // Fallback: Only use amenity or building name, NOT neighbourhood
    final amenity = address['amenity'] as String?;
    if (amenity != null) return amenity;

    final building = address['building'] as String?;
    if (building != null) return building;

    // Last resort: extract only the road from display_name
    return _extractStreetOnly(data['display_name'] as String?);
  }

  /// Extracts only the street/road name from the display name.
  /// Filters out localidad, barrio, city, etc.
  String? _extractStreetOnly(String? displayName) {
    if (displayName == null) return null;

    final parts = displayName.split(',').map((p) => p.trim()).toList();

    // Look for parts that start with "Carrera", "Calle", "Avenida", "Diagonal", "Transversal"
    for (final part in parts) {
      final lowerPart = part.toLowerCase();
      if (lowerPart.startsWith('carrera') ||
          lowerPart.startsWith('calle') ||
          lowerPart.startsWith('avenida') ||
          lowerPart.startsWith('diagonal') ||
          lowerPart.startsWith('transversal') ||
          lowerPart.startsWith('av.') ||
          lowerPart.startsWith('av ') ||
          lowerPart.startsWith('cra') ||
          lowerPart.startsWith('cl')) {
        return part;
      }
    }

    // If no street pattern found, try the first non-numeric part
    for (final part in parts) {
      // Skip if it looks like a house number, postcode, or locality
      if (RegExp(r'^\d+$').hasMatch(part)) continue;
      if (part.toLowerCase().contains('localidad')) continue;
      if (part.toLowerCase().contains('bogotá')) continue;
      if (part.toLowerCase().contains('colombia')) continue;
      if (part.toLowerCase().contains('upz')) continue;

      // Return the first meaningful part
      return part;
    }

    return parts.isNotEmpty ? parts[0] : displayName;
  }

  /// Cancels any pending geocoding request.
  void cancel() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }
}
