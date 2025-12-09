import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../map/utils/map_constants.dart';
import '../../map/utils/location_service.dart';
import '../../map/utils/retry_tile_provider.dart';

/// A persistent map widget that can be shared across tabs.
/// This widget maintains its own MapController and location state.
class PersistentMapWidget extends StatefulWidget {
  const PersistentMapWidget({
    super.key,
    this.onMapReady,
    this.onPositionChanged,
  });

  /// Called when the map controller is ready.
  final void Function(MapController controller)? onMapReady;

  /// Called when the current position changes.
  final void Function(LatLng position)? onPositionChanged;

  @override
  State<PersistentMapWidget> createState() => PersistentMapWidgetState();
}

class PersistentMapWidgetState extends State<PersistentMapWidget> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();

  LatLng? _currentPosition;
  bool _isLoading = true;
  LocationErrorType? _locationError;

  MapController get mapController => _mapController;
  LatLng? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  LocationErrorType? get locationError => _locationError;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onMapReady?.call(_mapController);
    });
  }

  Future<void> initializeLocation() => _initializeLocation();

  Future<void> _initializeLocation() async {
    setState(() => _isLoading = true);

    final result = await _locationService.getCurrentPosition();

    setState(() {
      _currentPosition = result.position;
      _locationError = result.errorType;
      _isLoading = false;
    });

    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, MapConstants.defaultZoom);
      widget.onPositionChanged?.call(_currentPosition!);
    }
  }

  void centerOnUser() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, MapConstants.defaultZoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentPosition ?? MapConstants.defaultCenter,
        initialZoom: MapConstants.defaultZoom,
        minZoom: MapConstants.minZoom,
        maxZoom: MapConstants.maxZoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: MapConstants.osmTileUrl,
          userAgentPackageName: MapConstants.userAgent,
          tileProvider: RetryTileProvider(),
        ),
      ],
    );
  }
}
