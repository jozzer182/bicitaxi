import 'package:flutter/material.dart';
import 'package:liquid_glass_ui_design/liquid_glass_ui.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_layout.dart';

/// Earnings screen for the Bici Taxi Conductor app.
/// Shows earnings summary and history.
class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({super.key});

  // Fake earnings data
  static final List<_EarningsDay> _weeklyEarnings = [
    _EarningsDay(day: 'Lun', amount: 85.00, trips: 4),
    _EarningsDay(day: 'Mar', amount: 120.50, trips: 6),
    _EarningsDay(day: 'Mié', amount: 95.00, trips: 5),
    _EarningsDay(day: 'Jue', amount: 150.00, trips: 7),
    _EarningsDay(day: 'Vie', amount: 180.00, trips: 9),
    _EarningsDay(day: 'Sáb', amount: 200.00, trips: 10),
    _EarningsDay(day: 'Dom', amount: 125.50, trips: 5),
  ];

  static final List<_TripEarning> _recentTrips = [
    _TripEarning(
      time: '14:30',
      origin: 'Centro',
      destination: 'Universidad',
      amount: 35.00,
    ),
    _TripEarning(
      time: '13:15',
      origin: 'Plaza Norte',
      destination: 'Hospital',
      amount: 28.00,
    ),
    _TripEarning(
      time: '11:45',
      origin: 'Estación',
      destination: 'Centro Comercial',
      amount: 42.00,
    ),
    _TripEarning(
      time: '10:20',
      origin: 'Residencial',
      destination: 'Oficinas',
      amount: 20.50,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveUtils.getHorizontalPadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveUtils.getContentMaxWidth(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              _buildTotalEarnings(context),
              const SizedBox(height: 24),
              _buildWeeklyChart(context),
              const SizedBox(height: 24),
              _buildStats(context),
              const SizedBox(height: 24),
              _buildRecentTrips(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalEarnings(BuildContext context) {
    final totalWeek = _weeklyEarnings.fold<double>(
      0,
      (sum, day) => sum + day.amount,
    );

    return LiquidCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Ganancias esta semana',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${totalWeek.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.driverAccent,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMiniStat(
                context,
                icon: Icons.trending_up_rounded,
                value: '+12%',
                label: 'vs semana pasada',
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(BuildContext context) {
    final maxAmount = _weeklyEarnings
        .map((e) => e.amount)
        .reduce((a, b) => a > b ? a : b);

    return LiquidCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ganancias por día',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _weeklyEarnings.map((day) {
                final heightPercent = day.amount / maxAmount;
                final isToday = day.day == 'Dom'; // Simulating today

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '\$${day.amount.toInt()}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isToday
                            ? AppColors.driverAccent
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 32,
                      height: 100 * heightPercent,
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.driverAccent
                            : AppColors.steelBlue.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      day.day,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                        color: isToday
                            ? AppColors.driverAccent
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    final totalTrips = _weeklyEarnings.fold<int>(
      0,
      (sum, day) => sum + day.trips,
    );
    final avgPerTrip = _weeklyEarnings.fold<double>(
          0,
          (sum, day) => sum + day.amount,
        ) /
        totalTrips;

    return Row(
      children: [
        Expanded(
          child: LiquidCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.directions_bike_rounded,
                  color: AppColors.brightBlue,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  totalTrips.toString(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Viajes',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: LiquidCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.electricBlue,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${avgPerTrip.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Promedio/viaje',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: LiquidCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.star_rounded,
                  color: Colors.amber.shade600,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  '4.9',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Calificación',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTrips(BuildContext context) {
    return LiquidCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Viajes de hoy',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          ..._recentTrips.map((trip) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTripItem(context, trip),
              )),
        ],
      ),
    );
  }

  Widget _buildTripItem(BuildContext context, _TripEarning trip) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.driverAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.directions_bike_rounded,
              color: AppColors.driverAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${trip.origin} → ${trip.destination}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  trip.time,
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+\$${trip.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.driverAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsDay {
  const _EarningsDay({
    required this.day,
    required this.amount,
    required this.trips,
  });

  final String day;
  final double amount;
  final int trips;
}

class _TripEarning {
  const _TripEarning({
    required this.time,
    required this.origin,
    required this.destination,
    required this.amount,
  });

  final String time;
  final String origin;
  final String destination;
  final double amount;
}

