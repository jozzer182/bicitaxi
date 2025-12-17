import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:liquid_glass_ui_design/liquid_glass_ui.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/request_service.dart';
import '../utils/map_constants.dart';
import '../utils/location_service.dart';

/// Tracking state for the map screen.
enum TrackingState {
  /// Selecting pickup/dropoff locations
  selecting,

  /// Searching for a driver
  searching,

  /// Driver assigned, tracking their location
  tracking,

  /// Driver has arrived (<50m from pickup)
  driverArrived,

  /// Trip started - show completion message
  tripStarted,
}

/// Map screen for the Bici Taxi client app.
/// Allows users to select pickup and dropoff locations.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final RequestService _requestService = RequestService();

  LatLng? _currentPosition;
  LatLng? _pickupPosition;
  LatLng? _dropoffPosition;
  bool _isLoading = true;
  bool _isRequesting = false;
  String? _locationError;

  // Tracking state
  TrackingState _trackingState = TrackingState.selecting;
  RideRequest? _activeRequest;
  StreamSubscription<RideRequest?>? _requestSubscription;
  LatLng? _driverPosition;
  bool _arrivedNotified = false;

  // Animation for searching state
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeLocation();

    // Setup pulse animation for searching state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _requestSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
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
    // Only allow location selection in selecting state
    if (_trackingState != TrackingState.selecting) return;

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isRequesting = true);

    try {
      // Create request via RequestService (Firebase)
      final request = await _requestService.createRequest(
        pickupLat: _pickupPosition!.latitude,
        pickupLng: _pickupPosition!.longitude,
        dropoffLat: _dropoffPosition?.latitude,
        dropoffLng: _dropoffPosition?.longitude,
      );

      if (request != null && mounted) {
        // Transition to searching state
        setState(() {
          _trackingState = TrackingState.searching;
          _activeRequest = request;
          _isRequesting = false;
        });

        // Subscribe to request updates for real-time tracking
        _requestSubscription = _requestService
            .watchRequest(request.cellId, request.requestId)
            .listen(_onRequestUpdate);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al solicitar viaje: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        setState(() => _isRequesting = false);
      }
    }
  }

  /// Handles real-time request updates from Firebase.
  void _onRequestUpdate(RideRequest? request) {
    if (!mounted || request == null) return;

    setState(() {
      _activeRequest = request;

      // Update driver position if available
      if (request.driverLat != null && request.driverLng != null) {
        _driverPosition = LatLng(request.driverLat!, request.driverLng!);

        // Check proximity for arrival notification
        _checkDriverProximity();
      }

      // Update tracking state based on request status
      switch (request.status) {
        case RequestStatus.open:
          _trackingState = TrackingState.searching;
          break;
        case RequestStatus.assigned:
          _trackingState = TrackingState.tracking;
          break;
        case RequestStatus.completed:
          _trackingState = TrackingState.tripStarted;
          // Show completion message and clean up after delay
          Future.delayed(const Duration(seconds: 3), _finishTrip);
          break;
        case RequestStatus.cancelled:
          _cancelTracking();
          break;
      }
    });
  }

  /// Check if driver is within 50m of pickup and notify.
  void _checkDriverProximity() {
    if (_driverPosition == null ||
        _pickupPosition == null ||
        _arrivedNotified ||
        _trackingState != TrackingState.tracking) {
      return;
    }

    final distance = _calculateDistance(
      _pickupPosition!.latitude,
      _pickupPosition!.longitude,
      _driverPosition!.latitude,
      _driverPosition!.longitude,
    );

    if (distance < 50) {
      setState(() {
        _trackingState = TrackingState.driverArrived;
        _arrivedNotified = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('¡Tu conductor ha llegado!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  /// Calculates distance in meters between two coordinates.
  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371000.0; // meters
    final dLat = (lat2 - lat1) * (pi / 180);
    final dLng = (lng2 - lng1) * (pi / 180);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Cancels the current request and returns to selecting state.
  Future<void> _cancelRequest() async {
    if (_activeRequest == null) return;

    try {
      await _requestService.cancelRequest(
        _activeRequest!.cellId,
        _activeRequest!.requestId,
      );
    } catch (e) {
      print('Error cancelling request: $e');
    }

    _cancelTracking();
  }

  /// Cleans up tracking state.
  void _cancelTracking() {
    _requestSubscription?.cancel();
    _requestSubscription = null;

    if (mounted) {
      setState(() {
        _trackingState = TrackingState.selecting;
        _activeRequest = null;
        _driverPosition = null;
        _arrivedNotified = false;
      });
    }
  }

  /// Called when trip is complete.
  void _finishTrip() {
    _requestSubscription?.cancel();
    _requestSubscription = null;

    if (mounted) {
      // Return to home screen with success message
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.homeShell,
        (route) => false,
      );
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
          Positioned(top: 0, left: 0, right: 0, child: _buildTopBar(context)),

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
                0.7,
                0,
                0,
                0,
                0,
                0,
                0.7,
                0,
                0,
                0,
                0,
                0,
                0.8,
                0,
                0,
                0,
                0,
                0,
                1,
                0,
              ]),
              child: widget,
            );
          },
        ),

        // Markers layer
        MarkerLayer(markers: _buildMarkers()),
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

    // Driver marker (when tracking)
    if (_driverPosition != null &&
        (_trackingState == TrackingState.tracking ||
            _trackingState == TrackingState.driverArrived)) {
      markers.add(
        Marker(
          point: _driverPosition!,
          width: 50,
          height: 50,
          child: _buildDriverMarker(),
        ),
      );
    }

    return markers;
  }

  Widget _buildDriverMarker() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _trackingState == TrackingState.driverArrived
              ? 1.0
              : _pulseAnimation.value * 0.9,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.electricBlue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.electricBlue.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.directions_bike_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        );
      },
    );
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
        Container(width: 3, height: 8, color: AppColors.success),
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
        Container(width: 3, height: 8, color: AppColors.error),
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
              child: UltraGlassCard(
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
              child: UltraGlassCard(
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
            child: UltraGlassCard(
              borderRadius: 20,
              padding: const EdgeInsets.all(20),
              child: _buildOverlayContent(),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds overlay content based on current tracking state
  Widget _buildOverlayContent() {
    switch (_trackingState) {
      case TrackingState.selecting:
        return _buildSelectionUI();
      case TrackingState.searching:
        return _buildSearchingUI();
      case TrackingState.tracking:
        return _buildTrackingUI();
      case TrackingState.driverArrived:
        return _buildDriverArrivedUI();
      case TrackingState.tripStarted:
        return _buildTripStartedUI();
    }
  }

  /// UI for selecting pickup/dropoff locations
  Widget _buildSelectionUI() {
    return Column(
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
                    style: TextStyle(fontSize: 12, color: AppColors.warning),
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
                onTap: _isRequesting
                    ? null
                    : (_pickupPosition != null ? _confirmLocations : null),
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: _isRequesting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Text(
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
    );
  }

  /// UI for searching for a driver
  Widget _buildSearchingUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated searching indicator
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.electricBlue.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.directions_bike_rounded,
                    color: AppColors.electricBlue,
                    size: 30,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        const Text(
          'Buscando conductor...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tu solicitud ha sido enviada',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        // Cancel button
        LiquidButton(
          borderRadius: 12,
          color: AppColors.error.withValues(alpha: 0.2),
          onTap: _cancelRequest,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          child: const Text(
            'Cancelar solicitud',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }

  /// UI for tracking driver location
  Widget _buildTrackingUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.electricBlue,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.directions_bike_rounded,
              color: AppColors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 12),

        const Text(
          '¡Conductor en camino!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tu conductor se dirige al punto de recogida',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Cancel button
        LiquidButton(
          borderRadius: 12,
          color: AppColors.error.withValues(alpha: 0.2),
          onTap: _cancelRequest,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          child: const Text(
            'Cancelar viaje',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }

  /// UI when driver has arrived
  Widget _buildDriverArrivedUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.check_rounded, color: AppColors.white, size: 35),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          '¡Tu conductor ha llegado!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Dirígete al punto de recogida',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  /// UI when trip has started
  Widget _buildTripStartedUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.electricBlue, AppColors.brightBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.celebration_rounded,
              color: AppColors.white,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          '¡Buen viaje!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Disfruta tu viaje en Bici Taxi',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
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
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
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
          Icon(Icons.check_circle_rounded, color: iconColor, size: 20),
      ],
    );
  }
}
