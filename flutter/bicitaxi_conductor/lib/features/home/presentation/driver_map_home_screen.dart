import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:liquid_glass_ui_design/liquid_glass_ui.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/routes/app_routes.dart';
import '../../map/utils/map_constants.dart';
import '../../map/utils/location_service.dart';
import '../../map/utils/retry_tile_provider.dart';
import '../../rides/models/ride.dart';
import '../../rides/models/ride_status.dart';

/// Map-first home screen for the Bici Taxi driver app.
/// Shows the map as the primary view with driver status overlay.
class DriverMapHomeScreen extends StatefulWidget {
  const DriverMapHomeScreen({super.key});

  @override
  State<DriverMapHomeScreen> createState() => _DriverMapHomeScreenState();
}

class _DriverMapHomeScreenState extends State<DriverMapHomeScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();

  LatLng? _currentPosition;
  bool _isLoading = true;
  LocationErrorType? _locationError;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
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
    if (mounted) setState(() {});
  }

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
    }
  }

  Future<void> _openSettings() async {
    if (_locationError == LocationErrorType.serviceDisabled) {
      await _locationService.openLocationSettings();
    } else {
      await _locationService.openAppSettings();
    }
    _initializeLocation();
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
    final isOnline = controller.isOnline;
    final pendingRides = controller.pendingRides;
    final activeRide = controller.activeRide;
    final hasActiveRide = activeRide != null && activeRide.status.isActive;

    return Stack(
      children: [
        // Full-screen map
        _buildMap(context, pendingRides),

        // Top status bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildTopBar(context, isOnline, hasActiveRide),
        ),

        // Center on user FAB
        Positioned(
          right: 16,
          bottom: isOnline ? 320 : 200,
          child: _buildLocationFab(),
        ),

        // GPS error banner
        if (_locationError != null && !_isLoading)
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 16,
            right: 16,
            child: _buildGpsErrorBanner(),
          ),

        // Bottom panel
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildBottomPanel(context, isOnline, pendingRides),
        ),

        // Loading overlay
        if (_isLoading)
          Container(
            color: AppColors.primary.withValues(alpha: 0.7),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.driverAccent),
            ),
          ),
      ],
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
        TileLayer(
          urlTemplate: MapConstants.osmTileUrl,
          userAgentPackageName: MapConstants.userAgent,
          tileProvider: RetryTileProvider(),
        ),
        MarkerLayer(markers: _buildMarkers(pendingRides)),
      ],
    );
  }

  List<Marker> _buildMarkers(List<Ride> pendingRides) {
    final markers = <Marker>[];
    final isOnline = context.rideController.isOnline;

    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: _currentPosition!,
          width: MapConstants.markerSize,
          height: MapConstants.markerSize,
          child: _buildDriverMarker(isOnline),
        ),
      );
    }

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

  Widget _buildDriverMarker(bool isOnline) {
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
        Container(width: 3, height: 8, color: AppColors.brightBlue),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, bool isOnline, bool hasActiveRide) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Active ride banner
            if (hasActiveRide)
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.activeRide),
                child: LiquidCard(
                  borderRadius: 16,
                  color: AppColors.driverAccent.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.driverAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.directions_bike_rounded,
                          color: AppColors.driverAccent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Viaje en curso',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Toca para ver detalles',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.driverAccent,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              )
            else
              // Status toggle bar
              GestureDetector(
                onTap: _toggleOnlineStatus,
                child: UltraGlassCard(
                  borderRadius: 16,
                  color: isOnline
                      ? AppColors.success.withValues(alpha: 0.15)
                      : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color:
                              (isOnline
                                      ? AppColors.success
                                      : AppColors.steelBlue)
                                  .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isOnline
                              ? Icons.wifi_rounded
                              : Icons.wifi_off_rounded,
                          color: isOnline
                              ? AppColors.success
                              : AppColors.steelBlue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOnline ? 'Conectado' : 'Desconectado',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isOnline
                                    ? AppColors.success
                                    : AppColors.textDark,
                              ),
                            ),
                            Text(
                              isOnline
                                  ? 'Recibiendo solicitudes'
                                  : 'Toca para conectarte',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textDarkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isOnline
                              ? AppColors.success
                              : AppColors.steelBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationFab() {
    return GestureDetector(
      onTap: _centerOnUser,
      child: LiquidCard(
        borderRadius: 14,
        padding: const EdgeInsets.all(14),
        child: const Icon(
          Icons.my_location_rounded,
          color: AppColors.driverAccent,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildGpsErrorBanner() {
    final isGpsDisabled = _locationError == LocationErrorType.serviceDisabled;
    final message = isGpsDisabled
        ? 'GPS desactivado'
        : 'Permiso de ubicación requerido';
    final buttonText = isGpsDisabled ? 'Activar GPS' : 'Dar permiso';

    return LiquidCard(
      borderRadius: 14,
      color: AppColors.warning.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isGpsDisabled
                  ? Icons.location_off_rounded
                  : Icons.lock_outline_rounded,
              color: AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.warning,
                  ),
                ),
                const Text(
                  'Mostrando ubicación predeterminada',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _openSettings,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(
    BuildContext context,
    bool isOnline,
    List<Ride> pendingRides,
  ) {
    final isTablet = ResponsiveUtils.isTabletOrLarger(context);
    // Extra bottom padding to account for the transparent navigation bar
    const navBarHeight = 80.0;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: isTablet ? 48 : 16,
          right: isTablet ? 48 : 16,
          top: 8,
          bottom: navBarHeight + 8, // Add space for nav bar
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 500 : double.infinity,
            ),
            child: UltraGlassCard(
              borderRadius: 24,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Today's summary
                  _buildTodaySummary(context),

                  const SizedBox(height: 16),

                  // Connection button or ride requests
                  if (!isOnline)
                    LiquidButton(
                      borderRadius: 14,
                      color: Colors.white.withValues(alpha: 0.3),
                      onTap: _toggleOnlineStatus,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.play_circle_outline_rounded,
                            color: AppColors.textDark,
                            size: 22,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Empezar a trabajar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Nearby requests section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Solicitudes cercanas',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brightBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${pendingRides.length}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.brightBlue,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (pendingRides.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: AppColors.textDarkTertiary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Buscando solicitudes...',
                              style: TextStyle(
                                color: AppColors.textDarkSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      _buildRideRequestCard(context, pendingRides.first),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodaySummary(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildSummaryItem(
          icon: Icons.attach_money_rounded,
          value: '\$0',
          label: 'Ganancias',
          color: AppColors.driverAccent,
        ),
        Container(width: 1, height: 40, color: AppColors.surfaceMedium),
        _buildSummaryItem(
          icon: Icons.directions_bike_rounded,
          value: '0',
          label: 'Viajes',
          color: AppColors.brightBlue,
        ),
        Container(width: 1, height: 40, color: AppColors.surfaceMedium),
        _buildSummaryItem(
          icon: Icons.timer_outlined,
          value: '0h',
          label: 'Tiempo',
          color: AppColors.electricBlue,
        ),
      ],
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
        ),
      ],
    );
  }

  Widget _buildRideRequestCard(BuildContext context, Ride ride) {
    double? distance;
    if (_currentPosition != null) {
      distance = _locationService.calculateDistance(
        _currentPosition!,
        LatLng(ride.pickup.lat, ride.pickup.lng),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.brightBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.brightBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pasajero',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.driverAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.trip_origin_rounded,
                size: 14,
                color: AppColors.success,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ride.pickup.displayText,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LiquidButton(
            borderRadius: 10,
            color: AppColors.driverAccent,
            onTap: () => _acceptRide(ride),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: const Text(
              'Aceptar viaje',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
