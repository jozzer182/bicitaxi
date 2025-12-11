import 'package:flutter/material.dart';
import 'package:liquid_glass_ui_design/liquid_glass_ui.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/routes/app_routes.dart';
import '../../rides/models/ride_status.dart';

/// Home screen for the Bici Taxi Conductor app.
/// Shows driver status toggle and quick actions.
class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final controller = context.rideController;
    final activeRide = controller.activeRide;
    final isOnline = controller.isOnline;

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
              // Active ride banner
              if (activeRide != null && activeRide.status.isActive) ...[
                _buildActiveRideBanner(context),
                const SizedBox(height: 20),
              ],
              _buildStatusSection(context, isOnline),
              const SizedBox(height: 24),
              _buildQuickActions(context),
              const SizedBox(height: 24),
              _buildTodaySummary(context),
              const SizedBox(height: 24),
              _buildRecentRequests(context, isOnline),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveRideBanner(BuildContext context) {
    final ride = context.rideController.activeRide!;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.activeRide),
      child: LiquidCard(
        borderRadius: 20,
        color: AppColors.driverAccent.withValues(alpha: 0.15),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.driverAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.directions_bike_rounded,
                color: AppColors.driverAccent,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Viaje en curso',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ride.status.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.driverAccent,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.driverAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ver',
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.white,
                    size: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, bool isOnline) {
    return LiquidCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: (isOnline ? AppColors.success : AppColors.steelBlue)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  color: isOnline ? AppColors.success : AppColors.steelBlue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOnline ? 'Conectado' : 'Desconectado',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      isOnline
                          ? 'Recibiendo solicitudes de viaje'
                          : 'No estás recibiendo solicitudes',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Online/Offline Toggle
          GestureDetector(
            onTap: () {
              context.rideController.toggleOnlineStatus();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isOnline
                    ? AppColors.success.withValues(alpha: 0.2)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isOnline
                      ? AppColors.success.withValues(alpha: 0.5)
                      : AppColors.surfaceMedium,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isOnline
                        ? Icons.pause_circle_outline_rounded
                        : Icons.play_circle_outline_rounded,
                    color: isOnline
                        ? AppColors.success
                        : AppColors.driverAccent,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isOnline ? 'Tomar descanso' : 'Empezar a trabajar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isOnline
                          ? AppColors.success
                          : AppColors.driverAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: LiquidButton(
            borderRadius: 16,
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.map);
            },
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.map_outlined, color: Colors.black87, size: 28),
                  SizedBox(height: 8),
                  Text(
                    'Ver mapa',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: LiquidButton(
            borderRadius: 16,
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.earnings);
            },
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.insights_rounded, color: Colors.black87, size: 28),
                  SizedBox(height: 8),
                  Text(
                    'Estadísticas',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodaySummary(BuildContext context) {
    return LiquidCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de hoy',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                context,
                icon: Icons.attach_money_rounded,
                value: '\$0',
                label: 'Ganancias',
                color: AppColors.driverAccent,
              ),
              Container(width: 1, height: 50, color: AppColors.surfaceMedium),
              _buildSummaryItem(
                context,
                icon: Icons.directions_bike_rounded,
                value: '0',
                label: 'Viajes',
                color: AppColors.brightBlue,
              ),
              Container(width: 1, height: 50, color: AppColors.surfaceMedium),
              _buildSummaryItem(
                context,
                icon: Icons.timer_outlined,
                value: '0h',
                label: 'Tiempo',
                color: AppColors.electricBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildRecentRequests(BuildContext context, bool isOnline) {
    final pendingRides = context.rideController.pendingRides;

    return LiquidCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Solicitudes cercanas',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (isOnline && pendingRides.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${pendingRides.length}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (isOnline && pendingRides.isNotEmpty) ...[
            ...pendingRides
                .take(2)
                .map(
                  (ride) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRequestItem(
                      context,
                      passengerName: 'Pasajero',
                      distance: '0.5 km',
                      pickup: ride.pickup.displayText,
                      destination: ride.dropoff?.displayText ?? 'Sin destino',
                      fare: '\$5,000',
                    ),
                  ),
                ),
            if (pendingRides.length > 2)
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.map),
                  child: Text(
                    'Ver ${pendingRides.length - 2} más en el mapa',
                    style: TextStyle(
                      color: AppColors.driverAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      isOnline ? Icons.search_rounded : Icons.wifi_off_rounded,
                      size: 48,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isOnline
                          ? 'Buscando solicitudes cercanas...'
                          : 'Conéctate para recibir solicitudes',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRequestItem(
    BuildContext context, {
    required String passengerName,
    required String distance,
    required String pickup,
    required String destination,
    required String fare,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.surfaceMedium,
                child: const Icon(
                  Icons.person_rounded,
                  size: 22,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passengerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'A $distance de ti',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                fare,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
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
                  pickup,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 8),
              Icon(Icons.location_on_rounded, size: 16, color: AppColors.error),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  destination,
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
      ),
    );
  }
}
