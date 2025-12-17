import 'dart:convert';

/// Simple test script to verify GeoCellService outputs.
/// This file can be run standalone with: dart run test/geo_cell_test.dart

// Copied from geo_cell_service.dart for standalone execution
class GeoCellService {
  static const int defaultStepSeconds = 30;

  static String computeCanonical(
    double lat,
    double lng, {
    int stepSeconds = defaultStepSeconds,
  }) {
    final latHemi = lat >= 0 ? 'N' : 'S';
    final lonHemi = lng >= 0 ? 'E' : 'W';

    final latAbs = lat.abs();
    final lonAbs = lng.abs();

    final latTotalSeconds = (latAbs * 3600).floor();
    final lonTotalSeconds = (lonAbs * 3600).floor();

    final latBucketSeconds = (latTotalSeconds ~/ stepSeconds) * stepSeconds;
    final lonBucketSeconds = (lonTotalSeconds ~/ stepSeconds) * stepSeconds;

    final latDeg = latBucketSeconds ~/ 3600;
    final latMin = (latBucketSeconds % 3600) ~/ 60;
    final latSec = latBucketSeconds % 60;

    final lonDeg = lonBucketSeconds ~/ 3600;
    final lonMin = (lonBucketSeconds % 3600) ~/ 60;
    final lonSec = lonBucketSeconds % 60;

    final latDegStr = latDeg.toString().padLeft(2, '0');
    final latMinStr = latMin.toString().padLeft(2, '0');
    final latSecStr = latSec.toString().padLeft(2, '0');

    final lonDegStr = lonDeg.toString().padLeft(3, '0');
    final lonMinStr = lonMin.toString().padLeft(2, '0');
    final lonSecStr = lonSec.toString().padLeft(2, '0');

    final stepStr = stepSeconds.toString().padLeft(2, '0');

    return '${latHemi}${latDegStr}_${latMinStr}_${latSecStr}_${lonHemi}${lonDegStr}_${lonMinStr}_${lonSecStr}_s$stepStr';
  }

  static String computeCellId(String canonical) {
    final bytes = utf8.encode(canonical);
    final base64Str = base64Url.encode(bytes);
    return base64Str.replaceAll('=', '');
  }
}

void main() {
  print('\n======================================');
  print('  GeoCellService Cross-Platform Test');
  print('======================================\n');

  final testCases = [
    {'name': 'Suba Center (Bogotá)', 'lat': 4.7410, 'lng': -74.0721},
    {'name': 'Near Equator', 'lat': 0.5, 'lng': 0.5},
    {'name': 'Buenos Aires (S hemisphere)', 'lat': -34.6037, 'lng': -58.3816},
    {'name': 'Madrid (E hemisphere)', 'lat': 40.4168, 'lng': -3.7038},
  ];

  for (final tc in testCases) {
    final lat = tc['lat'] as double;
    final lng = tc['lng'] as double;
    final name = tc['name'] as String;

    final canonical = GeoCellService.computeCanonical(lat, lng);
    final cellId = GeoCellService.computeCellId(canonical);

    print('Test: $name');
    print('  Coords: lat=$lat, lng=$lng');
    print('  Canonical: $canonical');
    print('  CellId: $cellId');
    print('');
  }

  // Verify URL-safety
  final testCanonical = GeoCellService.computeCanonical(4.7410, -74.0721);
  final testCellId = GeoCellService.computeCellId(testCanonical);

  print('URL-Safety Check:');
  print('  Contains "/": ${testCellId.contains("/")}');
  print('  Contains "+": ${testCellId.contains("+")}');
  print('  Contains "=": ${testCellId.contains("=")}');
  print(
    '  URL-safe: ${!testCellId.contains("/") && !testCellId.contains("+") && !testCellId.contains("=")}',
  );

  print('\n✅ Test complete. Compare with iOS output.\n');
}
