import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:liquid_glass_ui_design/liquid_glass_ui.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/refraction_glass_card.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/request_service.dart';
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
  final RequestService _requestService = RequestService();

  // Key for background capture (used by refraction shader)
  final GlobalKey _mapBackgroundKey = GlobalKey();

  LatLng? _currentPosition;
  bool _isLoading = true;
  LocationErrorType? _locationError;

  // Firebase requests subscription
  StreamSubscription<List<RideRequest>>? _requestsSubscription;
  List<RideRequest> _firebaseRequests = [];

  // Active ride state
  RideRequest? _activeFirebaseRequest;
  StreamSubscription<RideRequest?>? _activeRequestSubscription;
  Timer? _driverLocationTimer;
  bool _isRideInfoCollapsed = false;
  List<LatLng> _routePoints = [];

  // Status bar collapse state
  bool _isStatusCollapsed = false;
  Timer? _collapseTimer;

  @override
  void initState() {
    super.initState();
    _initializeLocation();

    // Start collapse timer for initial state
    _collapseTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _isStatusCollapsed = true);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.rideController.addListener(_onControllerChange);
    });
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    _driverLocationTimer?.cancel();
    _activeRequestSubscription?.cancel();
    try {
      context.rideController.removeListener(_onControllerChange);
    } catch (_) {}
    _requestsSubscription?.cancel();
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
      // Start watching Firebase requests for this location
      _startWatchingRequests();
    }
  }

  /// Subscribes to Firebase requests in driver's geo cells
  void _startWatchingRequests() {
    if (_currentPosition == null) return;

    _requestsSubscription?.cancel();
    _requestsSubscription = _requestService
        .watchOpenRequests(
          lat: _currentPosition!.latitude,
          lng: _currentPosition!.longitude,
          includeNeighbors: true, // Immediately watch 9 cells
        )
        .listen((requests) {
          if (mounted) {
            // Filter to only show fresh requests (heartbeat within 3 minutes)
            final freshRequests = requests.where((r) => r.isFresh).toList();
            setState(() => _firebaseRequests = freshRequests);
            print(
              '📬 Received ${requests.length} requests, ${freshRequests.length} fresh',
            );
          }
        });
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

  Future<void> _toggleOnlineStatus() async {
    await context.rideController.toggleOnlineStatus();
    final isOnline = context.rideController.isOnline;

    // Handle collapse timer - start timer for both online and offline states
    setState(() => _isStatusCollapsed = false);
    _collapseTimer?.cancel();
    _collapseTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _isStatusCollapsed = true);
      }
    });

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
        // Full-screen map (wrapped for shader capture)
        RepaintBoundary(
          key: _mapBackgroundKey,
          child: _buildMap(context, pendingRides),
        ),

        // Status bar background overlay
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: MediaQuery.of(context).padding.top,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),

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
          bottom: isOnline ? 380 : 260,
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
            color: Colors.white.withValues(alpha: 0.85),
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
        // Route polyline (when active ride)
        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                color: AppColors.electricBlue,
                strokeWidth: 4.0,
              ),
            ],
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

    // Active ride markers (client pickup and destination)
    if (_activeFirebaseRequest != null) {
      // Client pickup marker (green)
      markers.add(
        Marker(
          point: LatLng(
            _activeFirebaseRequest!.pickup.lat,
            _activeFirebaseRequest!.pickup.lng,
          ),
          width: MapConstants.markerSize,
          height: MapConstants.markerSize,
          child: _buildClientPickupMarker(),
        ),
      );

      // Destination marker (purple) if available
      if (_activeFirebaseRequest!.dropoff != null) {
        markers.add(
          Marker(
            point: LatLng(
              _activeFirebaseRequest!.dropoff!.lat,
              _activeFirebaseRequest!.dropoff!.lng,
            ),
            width: MapConstants.markerSize,
            height: MapConstants.markerSize,
            child: _buildDestinationMarker(),
          ),
        );
      }
    } else {
      // Show pending ride request markers only when no active ride
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
    }

    return markers;
  }

  /// Green marker for client pickup location
  Widget _buildClientPickupMarker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.3),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.green, width: 3),
      ),
      child: const Center(
        child: Icon(Icons.person, color: Colors.green, size: 24),
      ),
    );
  }

  /// Purple marker for destination
  Widget _buildDestinationMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.flag, color: Colors.white, size: 20),
        ),
        Container(width: 3, height: 8, color: Colors.purple),
      ],
    );
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status bar background
        Container(
          height: MediaQuery.of(context).padding.top,
          color: Colors.white.withValues(alpha: 0.92),
        ),
        // Content below status bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Active ride banner
              if (hasActiveRide)
                GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.activeRide),
                  child: UltraGlassCard(
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
                            color: AppColors.driverAccent.withValues(
                              alpha: 0.2,
                            ),
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
              else if (_isStatusCollapsed)
                // Collapsed status button (shown after 5 seconds)
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: _toggleOnlineStatus,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          isOnline
                              ? Icons.wifi_rounded
                              : Icons.wifi_off_rounded,
                          color: isOnline
                              ? AppColors.success
                              : AppColors.steelBlue,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                )
              else
                // Status toggle bar (expanded view)
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
      ],
    );
  }

  Widget _buildLocationFab() {
    return GestureDetector(
      onTap: _centerOnUser,
      child: UltraGlassCard(
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

    return UltraGlassCard(
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
    // Height for compact ride request items (approx 70px per item, show ~4)
    const maxListHeight = 300.0;

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
            child: RefractionGlassCard(
              borderRadius: 24,
              refractionStrength: 0.02,
              animated: true,
              backgroundKey: _mapBackgroundKey,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Connection button or ride requests
                    if (!isOnline)
                      LiquidButton(
                        borderRadius: 14,
                        color: AppColors.driverAccent.withValues(alpha: 0.3),
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
                    // Show active ride panel
                    else if (_activeFirebaseRequest != null)
                      _buildActiveRidePanel()
                    else ...[
                      // Nearby requests section header
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
                              color: AppColors.brightBlue.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_firebaseRequests.length}',
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
                      if (_firebaseRequests.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_rounded,
                                color: AppColors.textTertiary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Buscando solicitudes...',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        // Scrollable list of Firebase ride requests
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: maxListHeight,
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _firebaseRequests.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              return _buildFirebaseRequestItem(
                                context,
                                _firebaseRequests[index],
                              );
                            },
                          ),
                        ),
                    ],
                  ],
                ),
              ), // End Padding (inner)
            ), // End RefractionGlassCard
          ), // End ConstrainedBox
        ), // End Center
      ), // End Padding (outer)
    ); // End SafeArea
  }

  /// Builds the active ride panel (collapsible)
  Widget _buildActiveRidePanel() {
    final request = _activeFirebaseRequest!;
    final clientName = request.clientName ?? 'Cliente';

    if (_isRideInfoCollapsed) {
      // Collapsed view - minimal info
      return GestureDetector(
        onTap: () => setState(() => _isRideInfoCollapsed = false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.directions_bike_rounded,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pasajero: $clientName',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      'Toca para ver detalles',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.expand_more, color: AppColors.textSecondary),
            ],
          ),
        ),
      );
    }

    // Expanded view - full ride info
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with collapse button
        Row(
          children: [
            Icon(Icons.directions_bike_rounded, color: Colors.green, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pasajero: $clientName',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Colors.green, size: 8),
                  SizedBox(width: 4),
                  Text(
                    'ACTIVO',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() => _isRideInfoCollapsed = true);
                _zoomToRoute();
              },
              child: const Icon(
                Icons.expand_less,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Pickup location
        Row(
          children: [
            Icon(Icons.location_on, color: Colors.green, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                request.pickup.address ?? 'Ubicación del pasajero',
                style: const TextStyle(fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        // Destination if available
        if (request.dropoff != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.flag, color: Colors.purple, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  request.dropoff!.address ?? 'Destino',
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        // Action buttons
        Row(
          children: [
            // Cancel button
            Expanded(
              child: LiquidButton(
                borderRadius: 12,
                color: AppColors.error.withValues(alpha: 0.15),
                onTap: _cancelRide,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.close, color: AppColors.error, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Cancelar',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Complete button
            Expanded(
              flex: 2,
              child: LiquidButton(
                borderRadius: 12,
                color: Colors.green,
                onTap: _completeRide,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Pasajero Recogido',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds a compact item for a Firebase RideRequest
  Widget _buildFirebaseRequestItem(BuildContext context, RideRequest request) {
    // Calculate distance from driver to pickup
    double? distanceToPickup;
    if (_currentPosition != null) {
      distanceToPickup = _locationService.calculateDistance(
        _currentPosition!,
        LatLng(request.pickup.lat, request.pickup.lng),
      );
    }

    // Calculate trip distance (pickup to dropoff) if dropoff exists
    double? tripDistance;
    if (request.dropoff != null) {
      tripDistance = _calculateDistance(
        LatLng(request.pickup.lat, request.pickup.lng),
        LatLng(request.dropoff!.lat, request.dropoff!.lng),
      );
    }

    // Format distance to pickup: m for < 1km, km otherwise
    String distanceText;
    if (distanceToPickup != null) {
      if (distanceToPickup < 1000) {
        distanceText = '${distanceToPickup.round()} m';
      } else {
        distanceText = '${(distanceToPickup / 1000).toStringAsFixed(1)} km';
      }
    } else {
      distanceText = '-- m';
    }

    // Format trip distance
    String tripDistanceText = '--';
    if (tripDistance != null) {
      if (tripDistance < 1000) {
        tripDistanceText = '${tripDistance.round()} m';
      } else {
        tripDistanceText = '${(tripDistance / 1000).toStringAsFixed(1)} km';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: Time + Client Name + Distance to pickup + Accept button
          Row(
            children: [
              // Time
              Text(
                request.ageString,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppColors.electricBlue,
                ),
              ),
              const SizedBox(width: 8),
              // Client name if available
              if (request.clientName != null) ...[
                Icon(Icons.person, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  request.clientName!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Distance to pickup
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brightBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  distanceText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.brightBlue,
                  ),
                ),
              ),
              const Spacer(),
              // Accept button
              GestureDetector(
                onTap: () => _acceptFirebaseRequest(request),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        color: AppColors.success,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Aceptar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Destination only - with geocoded name if available
          if (request.dropoff != null) ...[
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: AppColors.deepBlue),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Geocoded name (primary)
                      Text(
                        request.dropoff!.address ?? 'Destino',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Compact DMS (secondary)
                      _buildCompactDmsText(
                        request.dropoff!.lat,
                        request.dropoff!.lng,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Trip distance row
            Row(
              children: [
                Icon(Icons.route, size: 14, color: AppColors.driverAccent),
                const SizedBox(width: 6),
                Text(
                  'Distancia: ',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  tripDistanceText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.driverAccent,
                  ),
                ),
              ],
            ),
          ] else ...[
            // No dropoff - show pickup DMS only
            Row(
              children: [
                Icon(
                  Icons.circle_outlined,
                  size: 14,
                  color: AppColors.brightBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  'Recogida: ',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                _buildCompactDmsText(request.pickup.lat, request.pickup.lng),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Builds compact DMS text with minutes in lighter color and seconds in darker
  Widget _buildCompactDmsText(double lat, double lng) {
    final latDms = _toDmsComponents(lat.abs());
    final lngDms = _toDmsComponents(lng.abs());
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';

    const minuteColor = Color(0x99000000); // Black 60%
    const secondColor = Color(0xCC000000); // Black 80%

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
        children: [
          TextSpan(
            text: "${latDms['minutes']}'",
            style: TextStyle(color: minuteColor),
          ),
          TextSpan(
            text: '${latDms['seconds']}"$latDir',
            style: TextStyle(color: secondColor, fontWeight: FontWeight.w500),
          ),
          TextSpan(
            text: ', ',
            style: TextStyle(color: minuteColor),
          ),
          TextSpan(
            text: "${lngDms['minutes']}'",
            style: TextStyle(color: minuteColor),
          ),
          TextSpan(
            text: '${lngDms['seconds']}"$lngDir',
            style: TextStyle(color: secondColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// Converts decimal degrees to DMS components
  Map<String, String> _toDmsComponents(double decimal) {
    final degrees = decimal.floor();
    final minutesDecimal = (decimal - degrees) * 60;
    final minutes = minutesDecimal.floor();
    final seconds = ((minutesDecimal - minutes) * 60);

    return {
      'degrees': degrees.toString(),
      'minutes': minutes.toString().padLeft(2, '0'),
      'seconds': seconds.toStringAsFixed(1),
    };
  }

  /// Calculates distance between two points in meters (Haversine)
  double _calculateDistance(LatLng p1, LatLng p2) {
    const earthRadius = 6371000.0; // meters
    final lat1Rad = p1.latitude * math.pi / 180;
    final lat2Rad = p2.latitude * math.pi / 180;
    final dLat = (p2.latitude - p1.latitude) * math.pi / 180;
    final dLng = (p2.longitude - p1.longitude) * math.pi / 180;

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Accept a Firebase request
  Future<void> _acceptFirebaseRequest(RideRequest request) async {
    final uid = _requestService.currentUserId;
    if (uid == null) return;

    try {
      await _requestService.assignDriver(
        request.cellId,
        request.requestId,
        uid,
      );
      print('✅ Accepted request: ${request.requestId}');

      // Set active request and start tracking
      if (mounted) {
        setState(() {
          _activeFirebaseRequest = request;
          _isRideInfoCollapsed = false;
        });

        // Start watching the request for updates
        _activeRequestSubscription = _requestService
            .watchRequest(request.cellId, request.requestId)
            .listen((updatedRequest) {
              if (mounted && updatedRequest != null) {
                setState(() => _activeFirebaseRequest = updatedRequest);
              }
            });

        // Start periodic driver location updates
        _startDriverLocationUpdates(request);

        // Calculate route from current position to pickup
        _calculateRoute(request);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '¡Viaje aceptado! Pasajero: ${request.clientName ?? "Cliente"}',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error accepting request: $e');
    }
  }

  /// Start periodic driver location updates
  void _startDriverLocationUpdates(RideRequest request) {
    _driverLocationTimer?.cancel();
    _driverLocationTimer = Timer.periodic(const Duration(seconds: 5), (
      _,
    ) async {
      if (_currentPosition != null && _activeFirebaseRequest != null) {
        await _requestService.updateDriverLocation(
          request.cellId,
          request.requestId,
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
      }
    });
  }

  /// Calculate route from driver to pickup (simple straight line for now)
  void _calculateRoute(RideRequest request) {
    if (_currentPosition == null) return;

    final pickupLatLng = LatLng(request.pickup.lat, request.pickup.lng);

    // Simple straight line route (for visual representation)
    // In production, use OSRM or similar routing service
    setState(() {
      _routePoints = [_currentPosition!, pickupLatLng];
    });

    // Zoom to show route
    _zoomToRoute();
  }

  /// Zoom map to show the full route
  void _zoomToRoute() {
    if (_routePoints.isEmpty || _currentPosition == null) return;
    if (_activeFirebaseRequest == null) return;

    final pickup = LatLng(
      _activeFirebaseRequest!.pickup.lat,
      _activeFirebaseRequest!.pickup.lng,
    );

    // Calculate bounds
    final minLat = _currentPosition!.latitude < pickup.latitude
        ? _currentPosition!.latitude
        : pickup.latitude;
    final maxLat = _currentPosition!.latitude > pickup.latitude
        ? _currentPosition!.latitude
        : pickup.latitude;
    final minLng = _currentPosition!.longitude < pickup.longitude
        ? _currentPosition!.longitude
        : pickup.longitude;
    final maxLng = _currentPosition!.longitude > pickup.longitude
        ? _currentPosition!.longitude
        : pickup.longitude;

    // Add padding
    final latPadding = (maxLat - minLat) * 0.3;
    final lngPadding = (maxLng - minLng) * 0.3;

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(minLat - latPadding, minLng - lngPadding),
          LatLng(maxLat + latPadding, maxLng + lngPadding),
        ),
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  /// Complete the ride (confirm pickup)
  Future<void> _completeRide() async {
    if (_activeFirebaseRequest == null) return;

    try {
      await _requestService.completeRequest(
        _activeFirebaseRequest!.cellId,
        _activeFirebaseRequest!.requestId,
      );

      // Show confirmation dialog
      if (mounted) {
        _showPickupConfirmedDialog('conductor');
      }
    } catch (e) {
      print('❌ Error completing ride: $e');
    }
  }

  /// Cancel the ride
  Future<void> _cancelRide() async {
    if (_activeFirebaseRequest == null) return;

    try {
      await _requestService.cancelRequest(
        _activeFirebaseRequest!.cellId,
        _activeFirebaseRequest!.requestId,
      );

      _clearActiveRide();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Viaje cancelado'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error canceling ride: $e');
    }
  }

  /// Clear active ride state
  void _clearActiveRide() {
    _driverLocationTimer?.cancel();
    _activeRequestSubscription?.cancel();
    setState(() {
      _activeFirebaseRequest = null;
      _routePoints = [];
      _isRideInfoCollapsed = false;
    });
  }

  /// Show pickup confirmed dialog
  void _showPickupConfirmedDialog(String confirmedBy) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            SizedBox(width: 12),
            Flexible(child: Text('¡Recogida Confirmada!')),
          ],
        ),
        content: Text(
          'La recogida ha sido confirmada por el $confirmedBy.\n\n¡Buen viaje! Puedes cerrar la app.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearActiveRide();
            },
            child: const Text('¡Buen Viaje!'),
          ),
        ],
      ),
    );
  }
}
