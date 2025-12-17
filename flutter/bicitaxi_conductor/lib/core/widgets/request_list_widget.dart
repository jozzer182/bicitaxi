import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/request_service.dart';
import 'glass_container.dart';

/// Widget that displays incoming ride requests for drivers.
/// Shows requests in the current cell and expands to neighbors after 20 seconds.
class RequestListWidget extends StatefulWidget {
  final double lat;
  final double lng;
  final RequestService? requestService;
  final Function(RideRequest)? onRequestTap;

  const RequestListWidget({
    super.key,
    required this.lat,
    required this.lng,
    this.requestService,
    this.onRequestTap,
  });

  @override
  State<RequestListWidget> createState() => _RequestListWidgetState();
}

class _RequestListWidgetState extends State<RequestListWidget> {
  late RequestService _requestService;
  StreamSubscription<List<RideRequest>>? _requestsSubscription;
  List<RideRequest> _requests = [];
  bool _isLoading = true;
  bool _isExpanded = false;
  Timer? _expansionTimer;

  @override
  void initState() {
    super.initState();
    _requestService = widget.requestService ?? RequestService();
    _startWatching();
  }

  @override
  void didUpdateWidget(RequestListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If location changed significantly, restart watching
    if ((oldWidget.lat - widget.lat).abs() > 0.001 ||
        (oldWidget.lng - widget.lng).abs() > 0.001) {
      _startWatching();
    }
  }

  void _startWatching() {
    _requestsSubscription?.cancel();
    _expansionTimer?.cancel();
    setState(() {
      _isLoading = true;
      _isExpanded = false;
    });

    // Start with current cell only
    _requestsSubscription = _requestService
        .watchOpenRequests(lat: widget.lat, lng: widget.lng, includeNeighbors: false)
        .listen((requests) {
          if (mounted) {
            setState(() {
              _requests = requests;
              _isLoading = false;
            });
          }
        }, onError: (error) {
          print('❌ Error watching requests: $error');
          if (mounted) {
            setState(() => _isLoading = false);
          }
        });

    // Set timer to expand to neighbors after 20 seconds
    _expansionTimer = Timer(const Duration(seconds: 20), () {
      if (mounted && !_isExpanded) {
        _expandToNeighbors();
      }
    });
  }

  void _expandToNeighbors() {
    _requestsSubscription?.cancel();
    setState(() => _isExpanded = true);

    _requestsSubscription = _requestService
        .watchOpenRequests(lat: widget.lat, lng: widget.lng, includeNeighbors: true)
        .listen((requests) {
          if (mounted) {
            setState(() => _requests = requests);
          }
        });

    print('🔄 Expanded to watch 9 cells for requests');
  }

  @override
  void dispose() {
    _requestsSubscription?.cancel();
    _expansionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        _buildHeader(),
        const SizedBox(height: 12),
        // Request list
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: AppColors.electricBlue,
              ),
            ),
          )
        else if (_requests.isEmpty)
          _buildEmptyState()
        else
          ..._requests.map((request) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildRequestCard(request),
          )),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.electricBlue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.notifications_active_rounded,
            color: AppColors.electricBlue,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Solicitudes cercanas',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              Row(
                children: [
                  Text(
                    _isExpanded ? '9 celdas' : '1 celda',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textDarkSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textDarkTertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_requests.length} ${_requests.length == 1 ? 'solicitud' : 'solicitudes'}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textDarkSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Live indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'EN VIVO',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return UltraGlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            color: AppColors.textDarkTertiary,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'Sin solicitudes',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textDarkSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isExpanded
                ? 'No hay clientes buscando viaje en tu zona'
                : 'Expandiendo búsqueda en 20s...',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textDarkTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(RideRequest request) {
    return GestureDetector(
      onTap: () => widget.onRequestTap?.call(request),
      child: UltraGlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with age and status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.electricBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.ageString,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.electricBlue,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textDarkTertiary,
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Pickup location
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.electricBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.trip_origin_rounded,
                    color: AppColors.electricBlue,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Punto de recogida',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textDarkTertiary,
                        ),
                      ),
                      Text(
                        '${request.pickup.lat.toStringAsFixed(5)}, ${request.pickup.lng.toStringAsFixed(5)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Dropoff location (if available)
            if (request.dropoff != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.deepBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.deepBlue,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Destino',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textDarkTertiary,
                          ),
                        ),
                        Text(
                          '${request.dropoff!.lat.toStringAsFixed(5)}, ${request.dropoff!.lng.toStringAsFixed(5)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
