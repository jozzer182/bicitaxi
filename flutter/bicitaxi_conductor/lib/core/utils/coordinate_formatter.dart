/// Utility class for formatting coordinates in DMS (Degrees, Minutes, Seconds) format.
///
/// Example: 4.7473, -74.0890 → 4°44'50"N, 74°5'20"W
abstract final class CoordinateFormatter {
  /// Formats latitude and longitude as a single DMS string.
  static String formatDMS(double lat, double lng) {
    return '${formatLatitude(lat)}, ${formatLongitude(lng)}';
  }

  /// Formats latitude in DMS format with N/S suffix.
  /// Example: 4.7473 → 4°44'50"N
  static String formatLatitude(double lat) {
    final suffix = lat >= 0 ? 'N' : 'S';
    return '${_toDMS(lat.abs())}$suffix';
  }

  /// Formats longitude in DMS format with E/W suffix.
  /// Example: -74.0890 → 74°5'20"W
  static String formatLongitude(double lng) {
    final suffix = lng >= 0 ? 'E' : 'W';
    return '${_toDMS(lng.abs())}$suffix';
  }

  /// Converts decimal degrees to DMS string.
  static String _toDMS(double decimal) {
    final degrees = decimal.floor();
    final minutesDecimal = (decimal - degrees) * 60;
    final minutes = minutesDecimal.floor();
    final seconds = ((minutesDecimal - minutes) * 60).round();

    // Handle edge case where seconds rounds to 60
    if (seconds == 60) {
      return "$degrees°${minutes + 1}'0\"";
    }

    return '$degrees°$minutes\'$seconds"';
  }

  /// Formats coordinates in a compact decimal format.
  /// Example: 4.7473, -74.0890
  static String formatDecimal(double lat, double lng, {int decimals = 4}) {
    return '${lat.toStringAsFixed(decimals)}, ${lng.toStringAsFixed(decimals)}';
  }
}
