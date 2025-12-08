import 'package:flutter/material.dart';
import 'package:liquid_glass_ui_design/liquid_glass_ui.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/routes/app_routes.dart';

/// Login screen for Bici Taxi Conductor.
/// Displays authentication options with a liquid glass aesthetic.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;
    final isTablet = ResponsiveUtils.isTabletOrLarger(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: ResponsiveUtils.getHorizontalPadding(context),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ResponsiveUtils.getContentMaxWidth(context),
              ),
              child: isLandscape && isTablet
                  ? _buildLandscapeLayout(context)
                  : _buildPortraitLayout(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 48),
        _buildHeader(context),
        const SizedBox(height: 48),
        _buildLoginCard(context),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _buildHeader(context)),
        const SizedBox(width: 48),
        Expanded(child: _buildLoginCard(context)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isTablet = ResponsiveUtils.isTabletOrLarger(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // App icon/logo placeholder
        Container(
          width: isTablet ? 120 : 100,
          height: isTablet ? 120 : 100,
          decoration: BoxDecoration(
            color: AppColors.surfaceMedium,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.driverAccent.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.pedal_bike_rounded,
            size: isTablet ? 60 : 50,
            color: AppColors.driverAccent,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Bici Taxi',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'Conductor',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.driverAccent,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Conecta con pasajeros y genera ingresos',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return LiquidCard(
      borderRadius: 28,
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Inicia sesión',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Elige cómo quieres continuar',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Google Sign In Button
          _AuthButton(
            onPressed: () {
              // TODO: Implement Google Sign In with Firebase Auth
              _navigateToHome(context);
            },
            icon: _buildGoogleIcon(),
            label: 'Continuar con Google',
          ),
          const SizedBox(height: 16),

          // Apple Sign In Button
          _AuthButton(
            onPressed: () {
              // TODO: Implement Apple Sign In with Firebase Auth
              _navigateToHome(context);
            },
            icon: const Icon(
              Icons.apple_rounded,
              size: 24,
              color: AppColors.white,
            ),
            label: 'Continuar con Apple',
          ),
          const SizedBox(height: 24),

          // Divider with text
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.surfaceMedium)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('o', style: Theme.of(context).textTheme.bodySmall),
              ),
              const Expanded(child: Divider(color: AppColors.surfaceMedium)),
            ],
          ),
          const SizedBox(height: 24),

          // Guest Button
          LiquidButton(
            borderRadius: 16,
            color: AppColors.driverAccent,
            onTap: () {
              // TODO: Implement guest mode with anonymous Firebase Auth
              _navigateToHome(context);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Continuar como invitado',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Terms text
          Text(
            'Al continuar, aceptas nuestros Términos de Servicio y Política de Privacidad',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Colors.blue.shade700,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    Navigator.pushReplacementNamed(context, AppRoutes.homeShell);
  }
}

/// Custom auth button with glass effect.
class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return LiquidButton(
      borderRadius: 16,
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
