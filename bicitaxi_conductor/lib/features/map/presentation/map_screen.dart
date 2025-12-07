import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:liquid_glass_ui_design/liquid_glass_ui.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/routes/app_routes.dart';
import '../../rides/models/ride.dart';
import '../utils/map_constants.dart';
import '../utils/location_service.dart';

/// Map screen for the Bici Taxi driver app.
/// Shows driver's location and nearby ride requests.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();

  LatLng? _currentPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    // Listen to controller changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.rideController.addListener(_onControllerChange);
    });
  }

  @override
  void dispose() {
    try {
      context.rideController.removeListener(_onControllerChange);
    } catch (_) {}
    super.dispose();
  }

  void _onControllerChange() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeLocation() async {
    setState(() => _isLoading = true);

    final result = await _locationService.getCurrentPosition();

    setState(() {
      _currentPosition = result.position;
      _isLoading = false;
    });

    // Move map to current position
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, MapConstants.defaultZoom);
    }
  }

  void _centerOnUser() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, MapConstants.defaultZoom);
    }
  }

  void _toggleOnlineStatus() {
    context.rideController.toggleOnlineStatus();
    final isOnline = context.rideController.isOnline;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isOnline ? 'Estás en línea' : 'Estás desconectado'),
        backgroundColor: isOnline ? AppColors.success : AppColors.steelBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _acceptRide(Ride ride) async {
    await context.rideController.acceptRide(ride);
    if (mounted && context.rideController.activeRide != null) {
      Navigator.pushNamed(context, AppRoutes.activeRide);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.rideController;
    final pendingRides = controller.pendingRides;
    final isOnline = controller.isOnline;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Map
          _buildMap(context, pendingRides),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(context, isOnline),
          ),

          // Bottom overlay with ride requests
          if (isOnline)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomOverlay(context, pendingRides),
            ),

          // Offline message
          if (!isOnline)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildOfflineMessage(context),
            ),

          // Loading indicator
          if (_isLoading)
            Container(
              color: AppColors.primary.withValues(alpha: 0.7),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.driverAccent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap(BuildContext context, List<Ride> pendingRides) {
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
          markers: _buildMarkers(pendingRides),
        ),
      ],
    );
  }

  List<Marker> _buildMarkers(List<Ride> pendingRides) {
    final markers = <Marker>[];

    // Driver's current position marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: _currentPosition!,
          width: MapConstants.markerSize,
          height: MapConstants.markerSize,
          child: _buildDriverMarker(),
        ),
      );
    }

    // Pending ride request markers
    for (final ride in pendingRides) {
      markers.add(
        Marker(
          point: LatLng(ride.pickup.lat, ride.pickup.lng),
          width: MapConstants.markerSize,
          height: MapConstants.markerSize,
          child: _buildRideRequestMarker(),
        ),
      );
    }

    return markers;
  }

  Widget _buildDriverMarker() {
    final isOnline = context.rideController.isOnline;

    return Container(
      decoration: BoxDecoration(
        color: isOnline
            ? AppColors.driverAccent.withValues(alpha: 0.3)
            : AppColors.steelBlue.withValues(alpha: 0.3),
        shape: BoxShape.circle,
        border: Border.all(
          color: isOnline ? AppColors.driverAccent : AppColors.steelBlue,
          width: 3,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.directions_bike_rounded,
          color: isOnline ? AppColors.driverAccent : AppColors.steelBlue,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildRideRequestMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.brightBlue,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.brightBlue.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_pin_circle_rounded,
            color: AppColors.white,
            size: 20,
          ),
        ),
        Container(
          width: 3,
          height: 8,
          color: AppColors.brightBlue,
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, bool isOnline) {
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
            const SizedBox(width: 12),
            // Online/Offline toggle
            Expanded(
              child: GestureDetector(
                onTap: _toggleOnlineStatus,
                child: LiquidCard(
                  borderRadius: 12,
                  color: isOnline
                      ? AppColors.success.withValues(alpha: 0.2)
                      : AppColors.steelBlue.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isOnline ? AppColors.success : AppColors.steelBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isOnline ? 'En línea' : 'Desconectado',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isOnline ? AppColors.success : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Center on user button
            GestureDetector(
              onTap: _centerOnUser,
              child: LiquidCard(
                borderRadius: 12,
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: AppColors.driverAccent,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineMessage(BuildContext context) {
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
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 40,
                    color: AppColors.steelBlue,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Estás desconectado',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Activa tu estado para recibir solicitudes',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LiquidButton(
                    borderRadius: 12,
                    color: AppColors.driverAccent,
                    onTap: _toggleOnlineStatus,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    child: const Text(
                      'Conectarse',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomOverlay(BuildContext context, List<Ride> pendingRides) {
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Solicitudes cercanas',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.brightBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${pendingRides.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.brightBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (pendingRides.isEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'No hay solicitudes en este momento',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    // Show first pending ride
                    _buildRideRequestCard(context, pendingRides.first),
                    if (pendingRides.length > 1) ...[
                      const SizedBox(height: 8),
                      Text(
                        'y ${pendingRides.length - 1} más',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRideRequestCard(BuildContext context, Ride ride) {
    // Calculate estimated distance from driver
    double? distance;
    if (_currentPosition != null) {
      distance = _locationService.calculateDistance(
        _currentPosition!,
        LatLng(ride.pickup.lat, ride.pickup.lng),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brightBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.brightBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pasajero',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (distance != null)
                      Text(
                        '${(distance / 1000).toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '\$5,000',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.driverAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.trip_origin_rounded,
                size: 16,
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ride.pickup.displayText,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (ride.dropoff != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: AppColors.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ride.dropoff!.displayText,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          LiquidButton(
            borderRadius: 12,
            color: AppColors.driverAccent,
            onTap: () => _acceptRide(ride),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Text(
              'Aceptar viaje',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
