import 'package:flutter/material.dart';
import 'package:liquid_glass_ui_design/liquid_glass_ui.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/providers/app_state.dart';
import '../models/ride.dart';

/// Earnings screen for the Bici Taxi driver app.
/// Shows completed rides and earnings from the repository.
class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  List<Ride>? _completedRides;
  bool _isLoading = true;

  // Fake fare per ride for demo
  static const int _farePerRide = 5000;

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    setState(() => _isLoading = true);

    try {
      final rides = await context.rideController.getCompletedRides();
      setState(() {
        _completedRides = rides;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _completedRides = [];
        _isLoading = false;
      });
    }
  }

  int get _totalEarnings =>
      (_completedRides?.length ?? 0) * _farePerRide;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadEarnings,
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

                // Earnings summary card
                _buildEarningsCard(context),

                const SizedBox(height: 24),

                // Completed rides section
                Text(
                  'Viajes completados',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoading
                      ? 'Cargando...'
                      : '${_completedRides?.length ?? 0} viajes',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 16),

                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.driverAccent,
                    ),
                  )
                else if (_completedRides == null || _completedRides!.isEmpty)
                  _buildEmptyState(context)
                else
                  ..._completedRides!.map((ride) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildRideCard(context, ride),
                      )),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsCard(BuildContext context) {
    final isTablet = ResponsiveUtils.isTabletOrLarger(context);

    return LiquidCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
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
              Icons.account_balance_wallet_rounded,
              size: 32,
              color: AppColors.driverAccent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ganancias totales',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${_formatCurrency(_totalEarnings)}',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.driverAccent,
                  fontSize: isTablet ? 48 : 40,
                ),
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatItem(
                icon: Icons.directions_bike_rounded,
                label: 'Viajes',
                value: '${_completedRides?.length ?? 0}',
              ),
              const SizedBox(width: 32),
              _buildStatItem(
                icon: Icons.attach_money_rounded,
                label: 'Promedio',
                value: '\$${_formatCurrency(_farePerRide)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return LiquidCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.steelBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.history_rounded,
              size: 32,
              color: AppColors.steelBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin viajes completados',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Completa tu primer viaje para ver tus ganancias aquí',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(BuildContext context, Ride ride) {
    return LiquidCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with earnings and date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '+\$${_formatCurrency(_farePerRide)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.driverAccent,
                ),
              ),
              Text(
                _formatDate(ride.createdAt),
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Route info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Icon(
                    Icons.trip_origin_rounded,
                    size: 18,
                    color: AppColors.success,
                  ),
                  Container(
                    width: 2,
                    height: 20,
                    color: AppColors.surfaceMedium,
                  ),
                  Icon(
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
                      ride.pickup.displayText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ride.dropoff?.displayText ?? 'Sin destino',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.surfaceMedium, height: 24),
          // Bottom info
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 16,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                _formatTime(ride.createdAt),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Completado',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Hoy';
    } else if (diff.inDays == 1) {
      return 'Ayer';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

