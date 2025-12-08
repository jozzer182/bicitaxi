import 'package:flutter/material.dart';
import 'package:liquid_glass_ui_design/liquid_glass_ui.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/routes/app_routes.dart';
import '../models/ride.dart';
import '../models/ride_status.dart';
import '../controllers/client_ride_controller.dart';

/// Active ride screen for the Bici Taxi client app.
/// Shows current ride status, origin/destination, and actions.
class ClientActiveRideScreen extends StatefulWidget {
  const ClientActiveRideScreen({super.key});

  @override
  State<ClientActiveRideScreen> createState() => _ClientActiveRideScreenState();
}

class _ClientActiveRideScreenState extends State<ClientActiveRideScreen> {
  @override
  void initState() {
    super.initState();
    // Listen to controller changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.rideController.addListener(_onControllerChange);
    });
  }

  @override
  void dispose() {
    // Remove listener when widget is disposed
    // Note: This may throw if context is no longer valid, so we handle it
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

  @override
  Widget build(BuildContext context) {
    final controller = context.rideController;
    final ride = controller.activeRide;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ride != null
            ? _buildActiveRideContent(context, controller, ride)
            : _buildNoActiveRide(context),
      ),
    );
  }

  Widget _buildNoActiveRide(BuildContext context) {
    final isTablet = ResponsiveUtils.isTabletOrLarger(context);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 48 : 16,
          vertical: 24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 500 : double.infinity,
          ),
          child: LiquidCard(
            borderRadius: 24,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.steelBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.directions_bike_outlined,
                    size: 40,
                    color: AppColors.steelBlue,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Sin viaje activo',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cuando solicites un viaje, podrás ver el estado aquí',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                LiquidButton(
                  borderRadius: 16,
                  color: AppColors.brightBlue,
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.map);
                  },
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 32,
                  ),
                  child: const Text(
                    'Solicitar viaje',
                    style: TextStyle(
                      fontSize: 16,
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
    );
  }

  Widget _buildActiveRideContent(
    BuildContext context,
    ClientRideController controller,
    Ride ride,
  ) {
    final isTablet = ResponsiveUtils.isTabletOrLarger(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 48 : 16,
        vertical: 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 500 : double.infinity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: LiquidCard(
                    borderRadius: 12,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Volver',
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Status card
              LiquidCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Status icon and title
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            ride.status,
                          ).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          _getStatusIcon(ride.status),
                          size: 36,
                          color: _getStatusColor(ride.status),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        ride.status.displayName,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(ride.status),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _getStatusDescription(ride.status),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Route details card
              LiquidCard(
                borderRadius: 20,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Center(
                      child: Text(
                        'Detalles del viaje',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: _buildLocationRow(
                        icon: Icons.trip_origin_rounded,
                        iconColor: AppColors.success,
                        label: 'Recogida',
                        value: ride.pickup.displayText,
                      ),
                    ),
                    if (ride.dropoff != null) ...[
                      Center(
                        child: Container(
                          width: 2,
                          height: 24,
                          color: AppColors.surfaceMedium,
                        ),
                      ),
                      Center(
                        child: _buildLocationRow(
                          icon: Icons.location_on_rounded,
                          iconColor: AppColors.error,
                          label: 'Destino',
                          value: ride.dropoff!.displayText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Driver info (when assigned)
              if (ride.driverId != null) ...[
                LiquidCard(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.surfaceMedium,
                        child: const Icon(
                          Icons.person_rounded,
                          size: 28,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tu conductor',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            Text(
                              'Juan Conductor',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: Colors.amber.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '4.9',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.chat,
                            arguments: ChatRouteArgs(
                              rideId: ride.id,
                              participantName: 'Juan Conductor',
                            ),
                          );
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.brightBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: AppColors.brightBlue,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Action buttons
              if (ride.status.isActive) ...[
                // Simulate progress button (for demo)
                LiquidButton(
                  borderRadius: 16,
                  color: AppColors.electricBlue,
                  onTap: controller.isLoading
                      ? null
                      : () => controller.simulateNextStatus(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (controller.isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      else
                        const Icon(
                          Icons.fast_forward_rounded,
                          color: AppColors.white,
                        ),
                      const SizedBox(width: 8),
                      const Text(
                        'Simular progreso',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Cancel button
                LiquidButton(
                  borderRadius: 16,
                  onTap: controller.isLoading
                      ? null
                      : () => _showCancelDialog(context, controller),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: const Center(
                    child: Text(
                      'Cancelar viaje',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ],

              // Completed message
              if (ride.status == RideStatus.completed)
                LiquidCard(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 48,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '¡Viaje completado!',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      LiquidButton(
                        borderRadius: 12,
                        color: AppColors.brightBlue,
                        onTap: () {
                          controller.clearActiveRide();
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.homeShell,
                            (route) => false,
                          );
                        },
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                        child: const Text(
                          'Volver al inicio',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
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
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(RideStatus status) {
    switch (status) {
      case RideStatus.requested:
      case RideStatus.searchingDriver:
        return AppColors.electricBlue;
      case RideStatus.driverAssigned:
      case RideStatus.driverArriving:
        return AppColors.brightBlue;
      case RideStatus.inProgress:
        return AppColors.success;
      case RideStatus.completed:
        return AppColors.success;
      case RideStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(RideStatus status) {
    switch (status) {
      case RideStatus.requested:
        return Icons.schedule_rounded;
      case RideStatus.searchingDriver:
        return Icons.search_rounded;
      case RideStatus.driverAssigned:
        return Icons.person_pin_rounded;
      case RideStatus.driverArriving:
        return Icons.directions_bike_rounded;
      case RideStatus.inProgress:
        return Icons.directions_rounded;
      case RideStatus.completed:
        return Icons.check_circle_rounded;
      case RideStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  String _getStatusDescription(RideStatus status) {
    switch (status) {
      case RideStatus.requested:
        return 'Tu solicitud ha sido recibida';
      case RideStatus.searchingDriver:
        return 'Buscando un conductor disponible cerca de ti';
      case RideStatus.driverAssigned:
        return 'Un conductor ha aceptado tu viaje';
      case RideStatus.driverArriving:
        return 'Tu conductor está en camino al punto de recogida';
      case RideStatus.inProgress:
        return 'Disfruta tu viaje';
      case RideStatus.completed:
        return '¡Gracias por viajar con Bici Taxi!';
      case RideStatus.cancelled:
        return 'El viaje ha sido cancelado';
    }
  }

  void _showCancelDialog(
    BuildContext context,
    ClientRideController controller,
  ) {
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Cancelar viaje?'),
        content: const Text(
          'Si cancelas, puede que se apliquen cargos según el progreso del viaje.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Volver',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await controller.cancelRide();
              if (mounted) {
                navigator.pushNamedAndRemoveUntil(
                  AppRoutes.homeShell,
                  (route) => false,
                );
              }
            },
            child: Text(
              'Cancelar viaje',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
