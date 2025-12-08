import 'package:latlong2/latlong.dart';

/// Map-related constants for the Bici Taxi app.
abstract final class MapConstants {
  /// Default center (Bogotá, Colombia) when location is unavailable.
  static const LatLng defaultCenter = LatLng(4.6097, -74.0817);

  /// Default zoom level for urban areas.
  static const double defaultZoom = 15.0;

  /// Minimum zoom level.
  static const double minZoom = 4.0;

  /// Maximum zoom level.
  static const double maxZoom = 18.0;

  /// CartoDB Voyager tile URL template (colorful with soft blue roads).
  static const String osmTileUrl =
      'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png';

  /// User agent for OSM tile requests.
  static const String userAgent = 'dev.zarabanda.bicitaxi';

  /// Marker sizes.
  static const double markerSize = 48.0;
  static const double markerSizeSmall = 36.0;
}
