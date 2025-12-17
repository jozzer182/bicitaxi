import 'dart:convert';

/// Deterministic geographic cell service for presence/request system.
/// Uses 30 arc-second grid cells with canonical string format.
/// Produces identical results on Flutter and iOS platforms.
class GeoCellService {
  /// Default step size in arc-seconds (30")
  static const int defaultStepSeconds = 30;

  /// Computes the canonical string for a geographic cell.
  /// 
  /// Format: LAT_HEMI + latDeg(2) + "_" + latMin(2) + "_" + latSec(2) + "_" +
  ///         LON_HEMI + lonDeg(3) + "_" + lonMin(2) + "_" + lonSec(2) + "_s" + stepSec(2)
  /// 
  /// Example: N04_44_30_W074_04_30_s30
  static String computeCanonical(double lat, double lng, {int stepSeconds = defaultStepSeconds}) {
    // Determine hemispheres
    final latHemi = lat >= 0 ? 'N' : 'S';
    final lonHemi = lng >= 0 ? 'E' : 'W';

    // Convert to absolute values for DMS breakdown
    final latAbs = lat.abs();
    final lonAbs = lng.abs();

    // Convert to total seconds (integer arithmetic to avoid floating point errors)
    // Multiply by 3600 and floor to get total arc-seconds
    final latTotalSeconds = (latAbs * 3600).floor();
    final lonTotalSeconds = (lonAbs * 3600).floor();

    // Floor to step boundary (aligned to south-west corner)
    final latBucketSeconds = (latTotalSeconds ~/ stepSeconds) * stepSeconds;
    final lonBucketSeconds = (lonTotalSeconds ~/ stepSeconds) * stepSeconds;

    // Convert bucket seconds back to DMS
    final latDeg = latBucketSeconds ~/ 3600;
    final latMin = (latBucketSeconds % 3600) ~/ 60;
    final latSec = latBucketSeconds % 60;

    final lonDeg = lonBucketSeconds ~/ 3600;
    final lonMin = (lonBucketSeconds % 3600) ~/ 60;
    final lonSec = lonBucketSeconds % 60;

    // Format with proper padding
    final latDegStr = latDeg.toString().padLeft(2, '0');
    final latMinStr = latMin.toString().padLeft(2, '0');
    final latSecStr = latSec.toString().padLeft(2, '0');

    final lonDegStr = lonDeg.toString().padLeft(3, '0');
    final lonMinStr = lonMin.toString().padLeft(2, '0');
    final lonSecStr = lonSec.toString().padLeft(2, '0');

    final stepStr = stepSeconds.toString().padLeft(2, '0');

    return '${latHemi}${latDegStr}_${latMinStr}_${latSecStr}_${lonHemi}${lonDegStr}_${lonMinStr}_${lonSecStr}_s$stepStr';
  }

  /// Computes the Base64url-encoded cell ID from a canonical string.
  /// Uses URL-safe Base64 without padding (replaces +/- with -/_, removes =).
  static String computeCellId(String canonical) {
    final bytes = utf8.encode(canonical);
    final base64Str = base64Url.encode(bytes);
    // Remove padding
    return base64Str.replaceAll('=', '');
  }

  /// Computes the cell ID directly from lat/lng coordinates.
  static String computeCellIdFromCoords(double lat, double lng, {int stepSeconds = defaultStepSeconds}) {
    final canonical = computeCanonical(lat, lng, stepSeconds: stepSeconds);
    return computeCellId(canonical);
  }

  /// Represents the origin (south-west corner) of a cell in total arc-seconds.
  static ({int latSeconds, int lonSeconds, String latHemi, String lonHemi}) _getCellOrigin(
    double lat, double lng, {int stepSeconds = defaultStepSeconds}
  ) {
    final latHemi = lat >= 0 ? 'N' : 'S';
    final lonHemi = lng >= 0 ? 'E' : 'W';

    final latAbs = lat.abs();
    final lonAbs = lng.abs();

    final latTotalSeconds = (latAbs * 3600).floor();
    final lonTotalSeconds = (lonAbs * 3600).floor();

    final latBucketSeconds = (latTotalSeconds ~/ stepSeconds) * stepSeconds;
    final lonBucketSeconds = (lonTotalSeconds ~/ stepSeconds) * stepSeconds;

    return (
      latSeconds: latBucketSeconds,
      lonSeconds: lonBucketSeconds,
      latHemi: latHemi,
      lonHemi: lonHemi,
    );
  }

  /// Converts total arc-seconds and hemisphere to canonical format components.
  static String _secondsToCanonical(
    int latSeconds, String latHemi,
    int lonSeconds, String lonHemi,
    int stepSeconds,
  ) {
    final latDeg = latSeconds ~/ 3600;
    final latMin = (latSeconds % 3600) ~/ 60;
    final latSec = latSeconds % 60;

    final lonDeg = lonSeconds ~/ 3600;
    final lonMin = (lonSeconds % 3600) ~/ 60;
    final lonSec = lonSeconds % 60;

    final latDegStr = latDeg.toString().padLeft(2, '0');
    final latMinStr = latMin.toString().padLeft(2, '0');
    final latSecStr = latSec.toString().padLeft(2, '0');

    final lonDegStr = lonDeg.toString().padLeft(3, '0');
    final lonMinStr = lonMin.toString().padLeft(2, '0');
    final lonSecStr = lonSec.toString().padLeft(2, '0');

    final stepStr = stepSeconds.toString().padLeft(2, '0');

    return '${latHemi}${latDegStr}_${latMinStr}_${latSecStr}_${lonHemi}${lonDegStr}_${lonMinStr}_${lonSecStr}_s$stepStr';
  }

  /// Adjusts seconds with hemisphere handling.
  /// Returns new seconds and potentially flipped hemisphere.
  static ({int seconds, String hemi}) _adjustSeconds(
    int seconds, String hemi, int delta, int maxSeconds
  ) {
    var newSeconds = seconds + delta;
    var newHemi = hemi;

    if (newSeconds < 0) {
      // Cross equator/prime meridian
      newSeconds = -newSeconds;
      newHemi = _flipHemi(hemi);
    } else if (newSeconds >= maxSeconds) {
      // Wrap around (shouldn't happen in normal use, but handle it)
      newSeconds = maxSeconds - 1;
    }

    return (seconds: newSeconds, hemi: newHemi);
  }

  static String _flipHemi(String hemi) {
    switch (hemi) {
      case 'N': return 'S';
      case 'S': return 'N';
      case 'E': return 'W';
      case 'W': return 'E';
      default: return hemi;
    }
  }

  /// Computes the 8 neighbor cell IDs for a given location.
  /// Returns a list of canonical strings for the 8 adjacent cells.
  static List<String> computeNeighborCanonicals(
    double lat, double lng, {int stepSeconds = defaultStepSeconds}
  ) {
    final origin = _getCellOrigin(lat, lng, stepSeconds: stepSeconds);
    final neighbors = <String>[];

    // 8 directions: (-step, -step), (-step, 0), (-step, +step),
    //               (0, -step),              (0, +step),
    //               (+step, -step), (+step, 0), (+step, +step)
    final deltas = [
      (-stepSeconds, -stepSeconds),
      (-stepSeconds, 0),
      (-stepSeconds, stepSeconds),
      (0, -stepSeconds),
      (0, stepSeconds),
      (stepSeconds, -stepSeconds),
      (stepSeconds, 0),
      (stepSeconds, stepSeconds),
    ];

    for (final (latDelta, lonDelta) in deltas) {
      final adjustedLat = _adjustSeconds(
        origin.latSeconds, origin.latHemi, latDelta, 90 * 3600
      );
      final adjustedLon = _adjustSeconds(
        origin.lonSeconds, origin.lonHemi, lonDelta, 180 * 3600
      );

      final canonical = _secondsToCanonical(
        adjustedLat.seconds, adjustedLat.hemi,
        adjustedLon.seconds, adjustedLon.hemi,
        stepSeconds,
      );
      neighbors.add(canonical);
    }

    return neighbors;
  }

  /// Computes the 8 neighbor cell IDs (Base64url encoded).
  static List<String> computeNeighborCellIds(
    double lat, double lng, {int stepSeconds = defaultStepSeconds}
  ) {
    return computeNeighborCanonicals(lat, lng, stepSeconds: stepSeconds)
        .map(computeCellId)
        .toList();
  }

  /// Gets the current cell and all 8 neighbors (9 total).
  static List<String> computeAllCellIds(
    double lat, double lng, {int stepSeconds = defaultStepSeconds}
  ) {
    final currentCellId = computeCellIdFromCoords(lat, lng, stepSeconds: stepSeconds);
    final neighborIds = computeNeighborCellIds(lat, lng, stepSeconds: stepSeconds);
    return [currentCellId, ...neighborIds];
  }

  /// Gets the current cell canonical and all 8 neighbors (9 total).
  static List<String> computeAllCanonicals(
    double lat, double lng, {int stepSeconds = defaultStepSeconds}
  ) {
    final currentCanonical = computeCanonical(lat, lng, stepSeconds: stepSeconds);
    final neighborCanonicals = computeNeighborCanonicals(lat, lng, stepSeconds: stepSeconds);
    return [currentCanonical, ...neighborCanonicals];
  }

  /// Prints debug information for a location (for testing cross-platform consistency).
  static void debugPrint(double lat, double lng, {int stepSeconds = defaultStepSeconds}) {
    final canonical = computeCanonical(lat, lng, stepSeconds: stepSeconds);
    final cellId = computeCellId(canonical);
    final neighborCanonicals = computeNeighborCanonicals(lat, lng, stepSeconds: stepSeconds);
    final neighborCellIds = neighborCanonicals.map(computeCellId).toList();

    print('=== GeoCellService Debug ===');
    print('Input: lat=$lat, lng=$lng, step=${stepSeconds}s');
    print('Canonical: $canonical');
    print('CellId: $cellId');
    print('Neighbors:');
    for (var i = 0; i < neighborCanonicals.length; i++) {
      print('  [$i] ${neighborCanonicals[i]} -> ${neighborCellIds[i]}');
    }
    print('============================');
  }
}

/// Test vectors for cross-platform verification.
class GeoCellTestVectors {
  /// Test vector: Center of Suba, Bogotá, Colombia
  /// Approximate coordinates: 4.7410, -74.0721
  static const subaCenter = (lat: 4.7410, lng: -74.0721);

  /// Test vector: Near equator and prime meridian
  static const nearEquator = (lat: 0.5, lng: 0.5);

  /// Test vector: Southern hemisphere
  static const southernHemisphere = (lat: -34.6037, lng: -58.3816); // Buenos Aires

  /// Test vector: Eastern hemisphere
  static const easternHemisphere = (lat: 40.4168, lng: -3.7038); // Madrid

  /// Runs all test vectors and prints results.
  static void runAllTests() {
    print('\n🧪 GeoCellService Test Vectors\n');

    print('--- Test 1: Suba Center (Bogotá) ---');
    GeoCellService.debugPrint(subaCenter.lat, subaCenter.lng);

    print('\n--- Test 2: Near Equator ---');
    GeoCellService.debugPrint(nearEquator.lat, nearEquator.lng);

    print('\n--- Test 3: Southern Hemisphere (Buenos Aires) ---');
    GeoCellService.debugPrint(southernHemisphere.lat, southernHemisphere.lng);

    print('\n--- Test 4: Eastern Hemisphere (Madrid) ---');
    GeoCellService.debugPrint(easternHemisphere.lat, easternHemisphere.lng);

    print('\n✅ Test vectors completed. Compare with iOS output.\n');
  }
}
