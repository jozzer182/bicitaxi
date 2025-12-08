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
  static const String _userAgent = 'BiciTaxi/1.0 (dev.zarabanda.bicitaxi)';

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
  String? _formatAddress(Map<String, dynamic> data) {
    final address = data['address'] as Map<String, dynamic>?;
    if (address == null) return data['display_name'] as String?;

    // Build a concise address from components
    final parts = <String>[];

    // Street + house number
    final road = address['road'] as String?;
    final houseNumber = address['house_number'] as String?;
    if (road != null) {
      if (houseNumber != null) {
        parts.add('$road #$houseNumber');
      } else {
        parts.add(road);
      }
    }

    // Neighborhood/suburb
    final suburb =
        address['suburb'] as String? ??
        address['neighbourhood'] as String? ??
        address['quarter'] as String?;
    if (suburb != null) {
      parts.add(suburb);
    }

    // City
    final city =
        address['city'] as String? ??
        address['town'] as String? ??
        address['village'] as String?;
    if (city != null && parts.length < 3) {
      parts.add(city);
    }

    if (parts.isEmpty) {
      return data['display_name'] as String?;
    }

    return parts.join(', ');
  }

  /// Cancels any pending geocoding request.
  void cancel() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }
}
