import 'package:flutter/material.dart';
import 'package:liquid_glass_ui_design/liquid_glass_ui.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/routes/app_routes.dart';
import '../models/ride.dart';
import '../models/ride_status.dart';
import '../controllers/driver_ride_controller.dart';

/// Active ride screen for the Bici Taxi driver app.
/// Shows current ride status, passenger info, and actions.
class DriverActiveRideScreen extends StatefulWidget {
  const DriverActiveRideScreen({super.key});

  @override
  State<DriverActiveRideScreen> createState() => _DriverActiveRideScreenState();
}

class _DriverActiveRideScreenState extends State<DriverActiveRideScreen> {
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
                    color: AppColors.driverAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.directions_bike_rounded,
                    size: 40,
                    color: AppColors.driverAccent,
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
                  'Acepta una solicitud para comenzar un viaje',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                LiquidButton(
                  borderRadius: 16,
                  color: AppColors.driverAccent,
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.map);
                  },
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 32,
                  ),
                  child: const Text(
                    'Ver solicitudes',
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
    DriverRideController controller,
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
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.white,
                      size: 24,
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
                    Container(
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
                    const SizedBox(height: 16),
                    Text(
                      ride.status.displayName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(ride.status),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getStatusDescription(ride.status),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Passenger info card
              LiquidCard(
                borderRadius: 20,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.brightBlue.withValues(
                        alpha: 0.2,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 28,
                        color: AppColors.brightBlue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pasajero',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          Text(
                            'María Cliente',
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
                                '4.8',
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
                            participantName: 'María Cliente',
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

              // Route details card
              LiquidCard(
                borderRadius: 20,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ruta del viaje',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLocationRow(
                      icon: Icons.trip_origin_rounded,
                      iconColor: AppColors.success,
                      label: 'Recogida',
                      value: ride.pickup.dmsCoords,
                      address: ride.pickup.address,
                    ),
                    if (ride.dropoff != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 11),
                        child: Container(
                          width: 2,
                          height: 24,
                          color: AppColors.surfaceMedium,
                        ),
                      ),
                      _buildLocationRow(
                        icon: Icons.location_on_rounded,
                        iconColor: AppColors.error,
                        label: 'Destino',
                        value: ride.dropoff!.dmsCoords,
                        address: ride.dropoff!.address,
                      ),
                    ],
                    const Divider(color: AppColors.surfaceMedium, height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tarifa estimada',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        Text(
                          '\$5,000',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.driverAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons based on status
              _buildActionButtons(context, controller, ride),
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
    String? address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (address != null && address.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    DriverRideController controller,
    Ride ride,
  ) {
    final status = ride.status;

    if (status == RideStatus.driverAssigned) {
      return _buildDriverAssignedActions(context, controller);
    } else if (status == RideStatus.driverArriving) {
      return _buildDriverArrivingActions(context, controller);
    } else if (status == RideStatus.inProgress) {
      return _buildInProgressActions(context, controller);
    }

    return const SizedBox.shrink();
  }

  Widget _buildDriverAssignedActions(
    BuildContext context,
    DriverRideController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LiquidButton(
          borderRadius: 16,
          color: AppColors.driverAccent,
          onTap: controller.isLoading ? null : () => controller.markArriving(),
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
                const Icon(Icons.navigation_rounded, color: AppColors.white),
              const SizedBox(width: 8),
              const Text(
                'Ir a recoger',
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
        _buildCancelButton(context, controller),
      ],
    );
  }

  Widget _buildDriverArrivingActions(
    BuildContext context,
    DriverRideController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LiquidButton(
          borderRadius: 16,
          color: AppColors.success,
          onTap: controller.isLoading ? null : () => controller.startRide(),
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
                const Icon(Icons.play_arrow_rounded, color: AppColors.white),
              const SizedBox(width: 8),
              const Text(
                'Iniciar viaje',
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
        _buildCancelButton(context, controller),
      ],
    );
  }

  Widget _buildInProgressActions(
    BuildContext context,
    DriverRideController controller,
  ) {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LiquidButton(
          borderRadius: 16,
          color: AppColors.driverAccent,
          onTap: controller.isLoading
              ? null
              : () async {
                  await controller.finishRide();
                  if (mounted) {
                    navigator.pushNamedAndRemoveUntil(
                      AppRoutes.homeShell,
                      (route) => false,
                    );
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: const Text('¡Viaje completado! +\$5,000'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                },
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
                const Icon(Icons.check_circle_rounded, color: AppColors.white),
              const SizedBox(width: 8),
              const Text(
                'Finalizar viaje',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCancelButton(
    BuildContext context,
    DriverRideController controller,
  ) {
    return LiquidButton(
      borderRadius: 16,
      onTap: controller.isLoading
          ? null
          : () => _showCancelDialog(context, controller),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: const Text(
        'Cancelar viaje',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.error,
        ),
      ),
    );
  }

  Color _getStatusColor(RideStatus status) {
    switch (status) {
      case RideStatus.driverAssigned:
        return AppColors.brightBlue;
      case RideStatus.driverArriving:
        return AppColors.electricBlue;
      case RideStatus.inProgress:
        return AppColors.success;
      case RideStatus.completed:
        return AppColors.success;
      case RideStatus.cancelled:
        return AppColors.error;
      default:
        return AppColors.steelBlue;
    }
  }

  IconData _getStatusIcon(RideStatus status) {
    switch (status) {
      case RideStatus.driverAssigned:
        return Icons.check_circle_outline_rounded;
      case RideStatus.driverArriving:
        return Icons.directions_bike_rounded;
      case RideStatus.inProgress:
        return Icons.directions_rounded;
      case RideStatus.completed:
        return Icons.check_circle_rounded;
      case RideStatus.cancelled:
        return Icons.cancel_rounded;
      default:
        return Icons.pending_rounded;
    }
  }

  String _getStatusDescription(RideStatus status) {
    switch (status) {
      case RideStatus.driverAssigned:
        return 'Has aceptado este viaje. Dirígete al punto de recogida.';
      case RideStatus.driverArriving:
        return 'Estás en camino. El pasajero ha sido notificado.';
      case RideStatus.inProgress:
        return 'Viaje en curso. Lleva al pasajero a su destino.';
      case RideStatus.completed:
        return '¡Viaje completado! Gracias por tu servicio.';
      case RideStatus.cancelled:
        return 'Este viaje ha sido cancelado.';
      default:
        return 'Estado del viaje';
    }
  }

  void _showCancelDialog(
    BuildContext context,
    DriverRideController controller,
  ) {
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Cancelar viaje?'),
        content: const Text(
          'Si cancelas después de aceptar, puede afectar tu calificación.',
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
              await controller.cancelActiveRide();
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
