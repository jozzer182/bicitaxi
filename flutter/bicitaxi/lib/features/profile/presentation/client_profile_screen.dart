import 'package:flutter/material.dart';
import 'package:liquid_glass_ui_design/liquid_glass_ui.dart';
import '../../../core/providers/app_state.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/demo_mode_service.dart';

/// Profile screen for the Bici Taxi client app.
/// Shows user profile and settings.
class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final DemoModeService _demoModeService = DemoModeService();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _demoModeService.isDemoMode,
      builder: (context, isDemoMode, child) {
        return SingleChildScrollView(
          padding: ResponsiveUtils.getHorizontalPadding(context),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ResponsiveUtils.getContentMaxWidth(context),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildProfileHeader(context, isDemoMode),
                  const SizedBox(height: 24),
                  _buildSettingsSection(context),
                  const SizedBox(height: 24),
                  _buildDemoModeSwitch(context, isDemoMode),
                  const SizedBox(height: 24),
                  _buildLogoutButton(context),
                  const SizedBox(height: 12),
                  _buildDeleteAccountButton(context),
                  const SizedBox(
                    height: 120,
                  ), // Espacio extra para la barra de navegación
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, bool isDemoMode) {
    // Get user from repository
    final user = context.appState.authRepository.currentUser;
    // Show "Usuario Invitado" in demo mode, otherwise show display name or "Usuario"
    final displayName = isDemoMode
        ? 'Usuario Invitado'
        : (user?.displayName ?? 'Usuario');

    return UltraGlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            displayName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          LiquidButton(
            borderRadius: 12,
            onTap: () {
              Navigator.pushNamed(context, '/editProfile');
            },
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: const Text(
              'Editar perfil',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return UltraGlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildSettingsItem(
            context,
            icon: Icons.payment_rounded,
            label: 'Métodos de pago',
            onTap: () => Navigator.pushNamed(context, '/paymentMethods'),
          ),
          _buildDivider(),
          _buildSettingsItem(
            context,
            icon: Icons.info_outline_rounded,
            label: 'Acerca de',
            onTap: () => Navigator.pushNamed(context, '/about'),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoModeSwitch(BuildContext context, bool isDemoMode) {
    return UltraGlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: SwitchListTile(
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.science_outlined,
            color: isDemoMode ? AppColors.electricBlue : Colors.black38,
            size: 22,
          ),
        ),
        title: const Text(
          'Modo Demo',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          isDemoMode ? 'Datos de ejemplo activos' : 'Sin datos de ejemplo',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        value: isDemoMode,
        activeTrackColor: AppColors.electricBlue,
        onChanged: (value) {
          if (value) {
            // Show warning dialog before enabling demo mode
            _showDemoModeWarningDialog(context);
          } else {
            // Disable demo mode immediately
            _demoModeService.setDemoMode(false);
          }
        },
      ),
    );
  }

  void _showDemoModeWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            const Text(
              'Activar Modo Demo',
              style: TextStyle(color: Colors.black87, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          '⚠️ El modo demo muestra datos ficticios de ejemplo.\n\n'
          '• Los viajes mostrados no son reales\n'
          '• El historial será de ejemplo\n'
          '• No afecta tu cuenta real\n\n'
          '¿Deseas activar el modo demo?',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _demoModeService.setDemoMode(true);
            },
            child: Text(
              'Activar',
              style: TextStyle(
                color: AppColors.electricBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.electricBlue, size: 22),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
          color: Colors.black87,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.black38),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(color: AppColors.surfaceMedium, height: 1),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return LiquidButton(
      borderRadius: 16,
      onTap: () {
        _showLogoutDialog(context);
      },
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Text(
            'Cerrar sesión',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAccountButton(BuildContext context) {
    return LiquidButton(
      borderRadius: 16,
      color: AppColors.error.withValues(alpha: 0.1),
      onTap: () {
        _showDeleteAccountDialog(context);
      },
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Text(
            'Eliminar cuenta',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Cerrar sesión?',
          style: TextStyle(color: Colors.black87),
        ),
        content: const Text(
          'Tu sesión actual se cerrará y tendrás que iniciar sesión de nuevo.',
          style: TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.appState.authRepository.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              }
            },
            child: Text(
              'Cerrar sesión',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _DeleteAccountDialog(),
    );
  }
}

/// Dialog with countdown timer for delete account confirmation.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  int _countdown = 8;
  bool _canConfirm = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          _canConfirm = true;
        }
      });

      return _countdown > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
          const SizedBox(width: 8),
          const Text(
            '¿Eliminar cuenta?',
            style: TextStyle(color: Colors.black87),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚠️ Esta acción es IRREVERSIBLE.\n\n'
            '• Se eliminarán todos tus datos\n'
            '• Tu historial de viajes se perderá\n'
            '• No podrás recuperar tu cuenta\n',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          if (!_canConfirm)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Espera $_countdown segundos...',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: TextStyle(color: Colors.black54)),
        ),
        TextButton(
          onPressed: _canConfirm
              ? () async {
                  Navigator.pop(context);
                  try {
                    await context.appState.authRepository.deleteUser();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Cuenta eliminada'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.login,
                        (route) => false,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al eliminar cuenta: $e')),
                      );
                    }
                  }
                }
              : null,
          child: Text(
            'Eliminar cuenta',
            style: TextStyle(
              color: _canConfirm
                  ? AppColors.error
                  : AppColors.error.withValues(alpha: 0.3),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
