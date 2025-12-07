import 'package:latlong2/latlong.dart';

/// Map-related constants for the Bici Taxi app.
abstract final class MapConstants {
  /// Default center (Mexico City) when location is unavailable.
  static const LatLng defaultCenter = LatLng(19.4326, -99.1332);

  /// Default zoom level for urban areas.
  static const double defaultZoom = 15.0;

  /// Minimum zoom level.
  static const double minZoom = 4.0;

  /// Maximum zoom level.
  static const double maxZoom = 18.0;

  /// OpenStreetMap tile URL template.
  static const String osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// User agent for OSM tile requests.
  static const String userAgent = 'dev.zarabanda.bicitaxi';

  /// Marker sizes.
  static const double markerSize = 48.0;
  static const double markerSizeSmall = 36.0;
}

