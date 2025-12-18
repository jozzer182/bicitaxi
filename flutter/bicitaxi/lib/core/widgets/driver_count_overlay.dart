import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/presence_service.dart';
import 'glass_container.dart';

/// Overlay widget that shows the count of nearby drivers in real-time.
/// Displays "X conductores en tu zona" on the map.
class DriverCountOverlay extends StatefulWidget {
  final double lat;
  final double lng;
  final PresenceService? presenceService;

  const DriverCountOverlay({
    super.key,
    required this.lat,
    required this.lng,
    this.presenceService,
  });

  @override
  State<DriverCountOverlay> createState() => _DriverCountOverlayState();
}

class _DriverCountOverlayState extends State<DriverCountOverlay> {
  late PresenceService _presenceService;
  DriverCountWatcher? _watcher;
  StreamSubscription<int>? _countSubscription;
  Timer? _refreshTimer;
  int _driverCount = 0;
  bool _isLoading = true;

  /// Refresh interval - re-evaluates stale drivers locally (no new reads)
  static const Duration _refreshInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _presenceService =
        widget.presenceService ??
        PresenceService(appName: 'bicitaxi', role: PresenceRole.client);
    _createWatcher();

    // Periodic refresh - just re-evaluates cached data locally, no new Firestore reads!
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (mounted) {
        _watcher?.refresh(); // Local re-evaluation only
      }
    });
  }

  @override
  void didUpdateWidget(DriverCountOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If location changed significantly, recreate watcher with new cells
    if ((oldWidget.lat - widget.lat).abs() > 0.001 ||
        (oldWidget.lng - widget.lng).abs() > 0.001) {
      _disposeWatcher();
      _createWatcher();
    }
  }

  void _createWatcher() {
    _watcher = _presenceService.createDriverCountWatcher(
      widget.lat,
      widget.lng,
    );

    _countSubscription = _watcher!.countStream.listen(
      (count) {
        if (mounted) {
          setState(() {
            _driverCount = count;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        print('❌ Error watching driver count: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
  }

  void _disposeWatcher() {
    _countSubscription?.cancel();
    _countSubscription = null;
    _watcher?.dispose();
    _watcher = null;
  }

  @override
  void dispose() {
    _disposeWatcher();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UltraGlassCard(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _driverCount > 0
                  ? AppColors.success.withValues(alpha: 0.2)
                  : AppColors.textSecondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.directions_bike_rounded,
              color: _driverCount > 0
                  ? AppColors.success
                  : AppColors.textSecondary,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          if (_isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.electricBlue,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_driverCount ${_driverCount == 1 ? 'conductor' : 'conductores'}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _driverCount > 0
                        ? AppColors.textDark
                        : AppColors.textDarkSecondary,
                  ),
                ),
                Text(
                  'en tu zona',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textDarkTertiary,
                  ),
                ),
              ],
            ),
          if (_driverCount > 0) ...[
            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
