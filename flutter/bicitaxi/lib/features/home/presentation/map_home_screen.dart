import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:liquid_glass_ui_design/liquid_glass_ui.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/routes/app_routes.dart';
import '../../map/utils/map_constants.dart';
import '../../map/utils/location_service.dart';
import '../../map/utils/retry_tile_provider.dart';
import '../../map/utils/geocoding_service.dart';
import '../../rides/models/ride_location_point.dart';
import '../../rides/models/ride_status.dart';

/// Map-first home screen for the Bici Taxi client app.
/// Shows the map as the primary view with overlay controls.
class MapHomeScreen extends StatefulWidget {
  const MapHomeScreen({super.key});

  @override
  State<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends State<MapHomeScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final GeocodingService _geocodingService = GeocodingService();

  LatLng? _currentPosition;
  LatLng? _pickupPosition;
  LatLng? _dropoffPosition;
  String? _pickupAddress;
  String? _dropoffAddress;
  bool _isLoadingPickupAddress = false;
  bool _isLoadingDropoffAddress = false;
  bool _isLoading = true;
  bool _isRequesting = false;
  LocationErrorType? _locationError;

  // Breathing animation controller
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize breathing animation
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _breathingAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
    _breathingController.repeat(reverse: true);

    _initializeLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.rideController.addListener(_onControllerChange);
    });
  }

  @override
  void dispose() {
    _breathingController.dispose();
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

      // Automatically set pickup location to current GPS position after a short delay
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted && _pickupPosition == null && _currentPosition != null) {
        _setPickupToCurrentLocation();
      }
    }
  }

  /// Sets the pickup location to the current GPS position and geocodes the address.
  void _setPickupToCurrentLocation() {
    if (_currentPosition == null) return;

    setState(() {
      _pickupPosition = _currentPosition;
      _pickupAddress = null;
      _isLoadingPickupAddress = true;
    });

    // Geocode the current position to get the address
    _geocodingService.reverseGeocode(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      onResult: (address) {
        if (mounted) {
          setState(() {
            _pickupAddress = address;
            _isLoadingPickupAddress = false;
          });
        }
      },
    );
  }

  Future<void> _openSettings() async {
    if (_locationError == LocationErrorType.serviceDisabled) {
      await _locationService.openLocationSettings();
    } else {
      await _locationService.openAppSettings();
    }
    // Retry after returning from settings
    _initializeLocation();
  }

  void _handleMapTap(TapPosition tapPosition, LatLng position) {
    setState(() {
      if (_pickupPosition == null) {
        _pickupPosition = position;
        _pickupAddress = null;
        _isLoadingPickupAddress = true;
      } else if (_dropoffPosition == null) {
        _dropoffPosition = position;
        _dropoffAddress = null;
        _isLoadingDropoffAddress = true;
      } else {
        _dropoffPosition = position;
        _dropoffAddress = null;
        _isLoadingDropoffAddress = true;
      }
    });

    // Geocode the selected position
    if (_pickupPosition != null &&
        _pickupAddress == null &&
        _isLoadingPickupAddress) {
      _geocodingService.reverseGeocode(
        position.latitude,
        position.longitude,
        onResult: (address) {
          if (mounted) {
            setState(() {
              _pickupAddress = address;
              _isLoadingPickupAddress = false;
            });
          }
        },
      );
    } else if (_dropoffPosition != null &&
        _dropoffAddress == null &&
        _isLoadingDropoffAddress) {
      _geocodingService.reverseGeocode(
        position.latitude,
        position.longitude,
        onResult: (address) {
          if (mounted) {
            setState(() {
              _dropoffAddress = address;
              _isLoadingDropoffAddress = false;
            });
          }
        },
      );
    }
  }

  void _clearSelections() {
    _geocodingService.cancel();
    setState(() {
      _pickupPosition = null;
      _dropoffPosition = null;
      _pickupAddress = null;
      _dropoffAddress = null;
      _isLoadingPickupAddress = false;
      _isLoadingDropoffAddress = false;
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
      final pickup = RideLocationPoint(
        lat: _pickupPosition!.latitude,
        lng: _pickupPosition!.longitude,
        address: _pickupAddress,
      );

      final dropoff = _dropoffPosition != null
          ? RideLocationPoint(
              lat: _dropoffPosition!.latitude,
              lng: _dropoffPosition!.longitude,
              address: _dropoffAddress,
            )
          : null;

      await context.rideController.requestRide(pickup, dropoff);

      if (mounted) {
        Navigator.pushNamed(context, AppRoutes.activeRide);
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
    final activeRide = context.rideController.activeRide;
    final hasActiveRide = activeRide != null && activeRide.status.isActive;

    return Stack(
      children: [
        // Full-screen map
        _buildMap(context),

        // Top welcome bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildTopBar(context, hasActiveRide),
        ),

        // GPS error banner
        if (_locationError != null && !_isLoading)
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 16,
            right: 16,
            child: _buildGpsErrorBanner(),
          ),

        // Center on user FAB
        Positioned(right: 16, bottom: 280, child: _buildLocationFab()),

        // Bottom panel
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildBottomPanel(context, hasActiveRide),
        ),

        // Loading overlay
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
        TileLayer(
          urlTemplate: MapConstants.osmTileUrl,
          userAgentPackageName: MapConstants.userAgent,
          tileProvider: RetryTileProvider(),
          tileBuilder: (context, widget, tile) {
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
        // Arc line between pickup and dropoff with breathing animation
        if (_pickupPosition != null && _dropoffPosition != null)
          AnimatedBuilder(
            animation: _breathingAnimation,
            builder: (context, child) {
              return PolylineLayer(
                polylines: _buildArcPolylines(_breathingAnimation.value),
              );
            },
          ),
        MarkerLayer(markers: _buildMarkers()),
      ],
    );
  }

  /// Builds arc polylines with gradient effect between pickup and dropoff.
  /// [opacity] controls the breathing animation effect (0.0 to 1.0).
  List<Polyline> _buildArcPolylines(double opacity) {
    if (_pickupPosition == null || _dropoffPosition == null) {
      return [];
    }

    final arcPoints = _generateArcPoints(
      _pickupPosition!,
      _dropoffPosition!,
      segments: 30,
      arcHeight: 0.3, // Height of arc as fraction of distance
    );

    // Create multiple polyline segments to simulate gradient
    final polylines = <Polyline>[];
    final segmentCount = arcPoints.length - 1;

    for (int i = 0; i < segmentCount; i++) {
      final t = i / segmentCount;
      final baseColor = Color.lerp(
        AppColors.electricBlue,
        AppColors.deepBlue,
        t,
      )!;
      // Apply breathing opacity to the color
      final color = baseColor.withValues(alpha: opacity);

      polylines.add(
        Polyline(
          points: [arcPoints[i], arcPoints[i + 1]],
          color: color,
          strokeWidth: 4.0,
          strokeCap: StrokeCap.round,
        ),
      );
    }

    return polylines;
  }

  /// Generates points along a quadratic Bézier curve (arc) between two points.
  /// The arc curves to the side (perpendicular to the line), like a thrown ball trajectory.
  List<LatLng> _generateArcPoints(
    LatLng start,
    LatLng end, {
    int segments = 30,
    double arcHeight = 0.3,
  }) {
    final points = <LatLng>[];

    // Calculate the midpoint
    final midLat = (start.latitude + end.latitude) / 2;
    final midLng = (start.longitude + end.longitude) / 2;

    // Calculate the direction vector from start to end
    final deltaLat = end.latitude - start.latitude;
    final deltaLng = end.longitude - start.longitude;

    // Calculate the distance between points
    final distance = sqrt(deltaLat * deltaLat + deltaLng * deltaLng);

    // Calculate perpendicular vector (rotate 90 degrees to the left)
    // This creates the bulge to the side
    final perpLat = -deltaLng;
    final perpLng = deltaLat;

    // Normalize and scale by arc height
    final arcOffset = distance * arcHeight;
    final controlLat = midLat + (perpLat / distance) * arcOffset;
    final controlLng = midLng + (perpLng / distance) * arcOffset;

    // Generate points along the quadratic Bézier curve
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final lat = _quadraticBezier(start.latitude, controlLat, end.latitude, t);
      final lng = _quadraticBezier(
        start.longitude,
        controlLng,
        end.longitude,
        t,
      );
      points.add(LatLng(lat, lng));
    }

    return points;
  }

  /// Quadratic Bézier curve interpolation.
  double _quadraticBezier(double p0, double p1, double p2, double t) {
    final mt = 1 - t;
    return mt * mt * p0 + 2 * mt * t * p1 + t * t * p2;
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

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
            color: AppColors.electricBlue,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.electricBlue.withValues(alpha: 0.4),
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
        Container(width: 3, height: 8, color: AppColors.electricBlue),
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
            color: AppColors.deepBlue,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.deepBlue.withValues(alpha: 0.4),
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
        Container(width: 3, height: 8, color: AppColors.deepBlue),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, bool hasActiveRide) {
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
                  color: AppColors.brightBlue.withValues(alpha: 0.2),
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
                          color: AppColors.brightBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.directions_bike_rounded,
                          color: AppColors.brightBlue,
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
                        color: AppColors.brightBlue,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              )
            else
              // Welcome card
              LiquidCard(
                borderRadius: 16,
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
                        color: AppColors.electricBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.waving_hand_rounded,
                        color: AppColors.electricBlue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Hola!',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '¿A dónde quieres ir hoy?',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
          color: AppColors.electricBlue,
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

  Widget _buildBottomPanel(BuildContext context, bool hasActiveRide) {
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
            child: LiquidCard(
              borderRadius: 24,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Location selection info
                  _buildLocationRow(
                    icon: Icons.trip_origin_rounded,
                    iconColor: AppColors.electricBlue,
                    label: 'Punto de recogida',
                    value: _pickupPosition != null
                        ? (_isLoadingPickupAddress
                              ? 'Buscando dirección...'
                              : (_pickupAddress ?? 'Ubicación seleccionada'))
                        : 'Toca el mapa para seleccionar',
                    isSelected: _pickupPosition != null,
                    isLoading: _isLoadingPickupAddress,
                    coordinates: _pickupPosition,
                  ),
                  const SizedBox(height: 12),
                  _buildLocationRow(
                    icon: Icons.location_on_rounded,
                    iconColor: AppColors.deepBlue,
                    label: 'Destino',
                    value: _dropoffPosition != null
                        ? (_isLoadingDropoffAddress
                              ? 'Buscando dirección...'
                              : (_dropoffAddress ?? 'Destino seleccionado'))
                        : _pickupPosition != null
                        ? 'Toca para seleccionar destino'
                        : 'Primero selecciona recogida',
                    isSelected: _dropoffPosition != null,
                    isLoading: _isLoadingDropoffAddress,
                    coordinates: _dropoffPosition,
                  ),
                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    children: [
                      if (_pickupPosition != null || _dropoffPosition != null)
                        Expanded(
                          child: LiquidButton(
                            borderRadius: 12,
                            onTap: _clearSelections,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: const Center(
                              child: Text(
                                'Limpiar',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_pickupPosition != null || _dropoffPosition != null)
                        const SizedBox(width: 12),
                      Expanded(
                        flex: _pickupPosition != null ? 2 : 1,
                        child: LiquidButton(
                          borderRadius: 12,
                          color: _pickupPosition != null
                              ? AppColors.brightBlue
                              : AppColors.surfaceMedium,
                          onTap: _pickupPosition != null
                              ? _confirmLocations
                              : null,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Center(
                            child: Text(
                              'Solicitar viaje',
                              textAlign: TextAlign.center,
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

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isSelected,
    bool isLoading = false,
    LatLng? coordinates,
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // Show coordinates in DMS format (only minutes and seconds)
              if (coordinates != null && isSelected)
                _buildDmsCoordinates(coordinates),
            ],
          ),
        ),
        if (isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.electricBlue,
            ),
          )
        else if (isSelected)
          Icon(Icons.check_circle_rounded, color: iconColor, size: 20),
      ],
    );
  }

  /// Builds DMS coordinates showing only minutes and seconds.
  /// Minutes are displayed in a more subtle color than seconds.
  Widget _buildDmsCoordinates(LatLng coordinates) {
    final lat = _toDms(coordinates.latitude.abs());
    final lng = _toDms(coordinates.longitude.abs());
    final latDir = coordinates.latitude >= 0 ? 'N' : 'S';
    final lngDir = coordinates.longitude >= 0 ? 'E' : 'W';

    // Colors for different parts
    const minuteColor = AppColors.textTertiary;
    final secondColor = AppColors.textSecondary.withValues(alpha: 0.8);

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
        children: [
          // Latitude: minutes (subtle) + seconds (visible)
          TextSpan(
            text: "${lat['minutes']}'",
            style: TextStyle(color: minuteColor),
          ),
          TextSpan(
            text: '${lat['seconds']}"$latDir',
            style: TextStyle(color: secondColor, fontWeight: FontWeight.w500),
          ),
          TextSpan(
            text: ', ',
            style: TextStyle(color: minuteColor),
          ),
          // Longitude: minutes (subtle) + seconds (visible)
          TextSpan(
            text: "${lng['minutes']}'",
            style: TextStyle(color: minuteColor),
          ),
          TextSpan(
            text: '${lng['seconds']}"$lngDir',
            style: TextStyle(color: secondColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// Converts decimal degrees to DMS components.
  Map<String, String> _toDms(double decimal) {
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
}
