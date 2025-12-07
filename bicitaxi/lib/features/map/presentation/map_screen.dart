import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:liquid_glass_ui_design/liquid_glass_ui.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/routes/app_routes.dart';
import '../../rides/models/ride_location_point.dart';
import '../utils/map_constants.dart';
import '../utils/location_service.dart';

/// Map screen for the Bici Taxi client app.
/// Allows users to select pickup and dropoff locations.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();

  LatLng? _currentPosition;
  LatLng? _pickupPosition;
  LatLng? _dropoffPosition;
  bool _isLoading = true;
  bool _isRequesting = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    setState(() => _isLoading = true);

    final result = await _locationService.getCurrentPosition();

    setState(() {
      _currentPosition = result.position;
      _isLoading = false;
      if (!result.isReal) {
        _locationError = result.errorMessage;
      }
    });

    // Move map to current position
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, MapConstants.defaultZoom);
    }
  }

  void _handleMapTap(TapPosition tapPosition, LatLng position) {
    setState(() {
      if (_pickupPosition == null) {
        // First tap: set pickup
        _pickupPosition = position;
      } else if (_dropoffPosition == null) {
        // Second tap: set dropoff
        _dropoffPosition = position;
      } else {
        // Both exist: update dropoff (simpler behavior)
        _dropoffPosition = position;
      }
    });
  }

  void _clearSelections() {
    setState(() {
      _pickupPosition = null;
      _dropoffPosition = null;
    });
  }

  Future<void> _confirmLocations() async {
    if (_pickupPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor selecciona un punto de recogida'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isRequesting = true);

    try {
      // Create ride location points
      final pickup = RideLocationPoint(
        lat: _pickupPosition!.latitude,
        lng: _pickupPosition!.longitude,
      );

      final dropoff = _dropoffPosition != null
          ? RideLocationPoint(
              lat: _dropoffPosition!.latitude,
              lng: _dropoffPosition!.longitude,
            )
          : null;

      // Request the ride through the controller
      await context.rideController.requestRide(pickup, dropoff);

      if (mounted) {
        // Navigate to active ride screen
        Navigator.pushReplacementNamed(context, AppRoutes.activeRide);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al solicitar viaje: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  void _centerOnUser() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, MapConstants.defaultZoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Map
          _buildMap(context),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(context),
          ),

          // Bottom overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomOverlay(context),
          ),

          // Loading indicator
          if (_isLoading || _isRequesting)
            Container(
              color: AppColors.primary.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.electricBlue,
                    ),
                    if (_isRequesting) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Solicitando viaje...',
                        style: TextStyle(color: AppColors.white),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentPosition ?? MapConstants.defaultCenter,
        initialZoom: MapConstants.defaultZoom,
        minZoom: MapConstants.minZoom,
        maxZoom: MapConstants.maxZoom,
        onTap: _handleMapTap,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // Tile layer
        TileLayer(
          urlTemplate: MapConstants.osmTileUrl,
          userAgentPackageName: MapConstants.userAgent,
          tileBuilder: (context, widget, tile) {
            // Darken tiles to match app theme
            return ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                0.7, 0, 0, 0, 0,
                0, 0.7, 0, 0, 0,
                0, 0, 0.8, 0, 0,
                0, 0, 0, 1, 0,
              ]),
              child: widget,
            );
          },
        ),

        // Markers layer
        MarkerLayer(
          markers: _buildMarkers(),
        ),
      ],
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Current position marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: _currentPosition!,
          width: MapConstants.markerSize,
          height: MapConstants.markerSize,
          child: _buildCurrentPositionMarker(),
        ),
      );
    }

    // Pickup marker
    if (_pickupPosition != null) {
      markers.add(
        Marker(
          point: _pickupPosition!,
          width: MapConstants.markerSize,
          height: MapConstants.markerSize,
          child: _buildPickupMarker(),
        ),
      );
    }

    // Dropoff marker
    if (_dropoffPosition != null) {
      markers.add(
        Marker(
          point: _dropoffPosition!,
          width: MapConstants.markerSize,
          height: MapConstants.markerSize,
          child: _buildDropoffMarker(),
        ),
      );
    }

    return markers;
  }

  Widget _buildCurrentPositionMarker() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.brightBlue.withValues(alpha: 0.3),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.brightBlue, width: 3),
      ),
      child: const Center(
        child: Icon(
          Icons.my_location_rounded,
          color: AppColors.brightBlue,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildPickupMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.trip_origin_rounded,
            color: AppColors.white,
            size: 20,
          ),
        ),
        Container(
          width: 3,
          height: 8,
          color: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildDropoffMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: AppColors.white,
            size: 20,
          ),
        ),
        Container(
          width: 3,
          height: 8,
          color: AppColors.error,
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Back button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: LiquidCard(
                borderRadius: 12,
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.white,
                  size: 24,
                ),
              ),
            ),
            const Spacer(),
            // Center on user button
            GestureDetector(
              onTap: _centerOnUser,
              child: LiquidCard(
                borderRadius: 12,
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: AppColors.electricBlue,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomOverlay(BuildContext context) {
    final isTablet = ResponsiveUtils.isTabletOrLarger(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 48 : 16,
          vertical: 16,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 500 : double.infinity,
            ),
            child: LiquidCard(
              borderRadius: 20,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Location error warning
                  if (_locationError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _locationError!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Pickup info
                  _buildLocationInfo(
                    icon: Icons.trip_origin_rounded,
                    iconColor: AppColors.success,
                    label: 'Punto de recogida',
                    value: _pickupPosition != null
                        ? '${_pickupPosition!.latitude.toStringAsFixed(4)}, ${_pickupPosition!.longitude.toStringAsFixed(4)}'
                        : 'Toca el mapa para seleccionar',
                    isSelected: _pickupPosition != null,
                  ),

                  const SizedBox(height: 12),

                  // Dropoff info
                  _buildLocationInfo(
                    icon: Icons.location_on_rounded,
                    iconColor: AppColors.error,
                    label: 'Destino',
                    value: _dropoffPosition != null
                        ? '${_dropoffPosition!.latitude.toStringAsFixed(4)}, ${_dropoffPosition!.longitude.toStringAsFixed(4)}'
                        : _pickupPosition != null
                            ? 'Toca de nuevo para seleccionar destino'
                            : 'Selecciona primero el punto de recogida',
                    isSelected: _dropoffPosition != null,
                  ),

                  const SizedBox(height: 16),

                  // Buttons
                  Row(
                    children: [
                      // Clear button
                      Expanded(
                        child: LiquidButton(
                          borderRadius: 12,
                          onTap: _clearSelections,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: const Text(
                            'Limpiar',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Confirm button
                      Expanded(
                        flex: 2,
                        child: LiquidButton(
                          borderRadius: 12,
                          color: _pickupPosition != null
                              ? AppColors.brightBlue
                              : AppColors.surfaceMedium,
                          onTap: _pickupPosition != null ? _confirmLocations : null,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            'Solicitar viaje',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _pickupPosition != null
                                  ? AppColors.white
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInfo({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isSelected,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  color: isSelected ? AppColors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (isSelected)
          Icon(
            Icons.check_circle_rounded,
            color: iconColor,
            size: 20,
          ),
      ],
    );
  }
}
