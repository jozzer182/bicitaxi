import 'package:flutter/material.dart';
import 'package:liquid_glass_ui_design/liquid_glass_ui.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_layout.dart';
import 'driver_home_screen.dart';
import '../../rides/presentation/driver_active_ride_screen.dart';
import '../../rides/presentation/driver_earnings_screen.dart';
import '../../profile/presentation/driver_profile_screen.dart';

/// Main shell for the Bici Taxi Conductor app.
/// Contains navigation (bottom nav on phones, side rail on tablets).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  final List<_NavDestination> _destinations = const [
    _NavDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Inicio',
    ),
    _NavDestination(
      icon: Icons.directions_bike_outlined,
      selectedIcon: Icons.directions_bike_rounded,
      label: 'Viaje',
    ),
    _NavDestination(
      icon: Icons.attach_money_rounded,
      selectedIcon: Icons.attach_money_rounded,
      label: 'Ganancias',
    ),
    _NavDestination(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Perfil',
    ),
  ];

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const DriverHomeScreen();
      case 1:
        return const DriverActiveRideScreen();
      case 2:
        return const DriverEarningsScreen();
      case 3:
        return const DriverProfileScreen();
      default:
        return const DriverHomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = ResponsiveUtils.isTabletOrLarger(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: isWideScreen
            ? _buildWideLayout(context)
            : _buildNarrowLayout(context),
      ),
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _getScreen(_selectedIndex),
        ),
        _buildBottomNavBar(context),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      children: [
        _buildNavigationRail(context),
        Expanded(
          child: _getScreen(_selectedIndex),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return LiquidCard(
      borderRadius: 0,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_destinations.length, (index) {
            final dest = _destinations[index];
            final isSelected = _selectedIndex == index;
            return _NavBarItem(
              icon: isSelected ? dest.selectedIcon : dest.icon,
              label: dest.label,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedIndex = index),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildNavigationRail(BuildContext context) {
    return LiquidCard(
      borderRadius: 0,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            const SizedBox(height: 24),
            // App logo
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.driverAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.pedal_bike_rounded,
                color: AppColors.driverAccent,
                size: 28,
              ),
            ),
            const SizedBox(height: 32),
            // Navigation items
            Expanded(
              child: Column(
                children: List.generate(_destinations.length, (index) {
                  final dest = _destinations[index];
                  final isSelected = _selectedIndex == index;
                  return _NavRailItem(
                    icon: isSelected ? dest.selectedIcon : dest.icon,
                    label: dest.label,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedIndex = index),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavDestination {
  const _NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.driverAccent : AppColors.textTertiary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.driverAccent : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavRailItem extends StatelessWidget {
  const _NavRailItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.driverAccent.withValues(alpha: 0.1),
                border: Border(
                  left: BorderSide(
                    color: AppColors.driverAccent,
                    width: 3,
                  ),
                ),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.driverAccent : AppColors.textTertiary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.driverAccent : AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

