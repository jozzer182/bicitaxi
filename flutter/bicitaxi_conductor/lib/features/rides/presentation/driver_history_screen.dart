import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/services/history_service.dart';

/// History screen for the Bici Taxi Conductor app.
/// Shows list of past rides from Firebase history collection.
class DriverHistoryScreen extends StatefulWidget {
  const DriverHistoryScreen({super.key});

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  final HistoryService _historyService = HistoryService();
  List<RideHistoryEntry>? _rides;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _rides = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final rides = await _historyService.getHistory(uid);
      setState(() {
        _rides = rides;
        _isLoading = false;
      });
    } catch (e) {
      print('⚠️ Error loading history: $e');
      setState(() {
        _rides = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: AppColors.driverAccent,
      backgroundColor: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: ResponsiveUtils.getHorizontalPadding(context),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveUtils.getContentMaxWidth(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Historial de viajes',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoading
                      ? 'Cargando...'
                      : '${_rides?.length ?? 0} viajes completados',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.driverAccent,
                    ),
                  )
                else if (_rides == null || _rides!.isEmpty)
                  _buildEmptyState(context)
                else
                  ..._rides!.map(
                    (ride) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildRideCard(context, ride),
                    ),
                  ),
                const SizedBox(height: 100), // Space for bottom nav
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return UltraGlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.driverAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.history_rounded,
              size: 32,
              color: AppColors.driverAccent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin viajes aún',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cuando completes viajes, aparecerán aquí',
            style: TextStyle(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(BuildContext context, RideHistoryEntry ride) {
    final isCompleted = ride.status == 'completed';
    final isCancelled = ride.status == 'cancelled';

    return UltraGlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status and date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      (isCompleted
                              ? AppColors.success
                              : isCancelled
                              ? AppColors.error
                              : AppColors.driverAccent)
                          .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ride.statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? AppColors.success
                        : isCancelled
                        ? AppColors.error
                        : AppColors.driverAccent,
                  ),
                ),
              ),
              Text(
                ride.dateString,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Client info
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.driverAccent.withValues(alpha: 0.2),
                child: const Icon(
                  Icons.person_rounded,
                  size: 18,
                  color: AppColors.driverAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.clientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Pasajero',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Route info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Icon(
                    Icons.trip_origin_rounded,
                    size: 18,
                    color: AppColors.success,
                  ),
                  Container(
                    width: 2,
                    height: 24,
                    color: AppColors.surfaceMedium,
                  ),
                  const Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: AppColors.error,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.pickupAddress ?? 'Punto de recogida',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      ride.dropoffAddress ?? 'Sin destino',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.surfaceMedium, height: 32),
          // Bottom row with time
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                _formatTime(ride.createdAt),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              if (ride.completedAt != null) ...[
                const SizedBox(width: 16),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  'Completado ${_formatTime(ride.completedAt!)}',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
