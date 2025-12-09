import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:liquid_glass_ui_design/liquid_glass_ui.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/barrel_distortion_filter.dart';
import '../../../core/widgets/responsive_layout.dart';
import 'driver_map_home_screen.dart';
import '../../rides/presentation/driver_active_ride_screen.dart';
import '../../rides/presentation/driver_earnings_screen.dart';
import '../../profile/presentation/driver_profile_screen.dart';
import 'persistent_map_widget.dart';

/// Main shell for the Bici Taxi Conductor app.
/// Contains navigation (bottom nav on phones, side rail on tablets).
/// The map is rendered persistently in the background with blur effect
/// when navigating to other tabs for a liquid glass experience.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  // Key for persistent map widget
  final GlobalKey<PersistentMapWidgetState> _mapKey = GlobalKey();

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

  void _onTabChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _getOverlayScreen(int index) {
    // Return the screen content for non-map tabs
    switch (index) {
      case 1:
        return const DriverActiveRideScreen();
      case 2:
        return const DriverEarningsScreen();
      case 3:
        return const DriverProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = ResponsiveUtils.isTabletOrLarger(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true, // Allow body to extend behind bottom nav
      body: SafeArea(
        bottom: false, // Don't add padding for bottom nav
        child: isWideScreen
            ? _buildWideLayout(context)
            : _buildNarrowLayout(context),
      ),
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return Stack(
      children: [
        // When on home tab (0), use DriverMapHomeScreen with its own map
        // When on other tabs, show the persistent map with blur
        if (_selectedIndex == 0)
          const Positioned.fill(child: DriverMapHomeScreen())
        else ...[
          // Persistent map in background for blur effect
          Positioned.fill(child: PersistentMapWidget(key: _mapKey)),

          // Blur overlay (no dark tint, just blur)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.transparent),
            ),
          ),

          // The actual screen content
          Positioned.fill(child: _getOverlayScreen(_selectedIndex)),
        ],

        // Bottom nav bar overlays with transparency
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBottomNavBar(context),
        ),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      children: [
        _buildNavigationRail(context),
        Expanded(
          child: Stack(
            children: [
              // When on home tab (0), use DriverMapHomeScreen with its own map
              // When on other tabs, show the persistent map with blur
              if (_selectedIndex == 0)
                const Positioned.fill(child: DriverMapHomeScreen())
              else ...[
                // Persistent map in background for blur effect
                Positioned.fill(child: PersistentMapWidget(key: _mapKey)),

                // Blur overlay (no dark tint, just blur)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(color: Colors.transparent),
                  ),
                ),

                // The actual screen content
                Positioned.fill(child: _getOverlayScreen(_selectedIndex)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: BarrelDistortionFilter(
          distortionStrength: 0.7,
          borderRadius: 40,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_destinations.length, (index) {
              final dest = _destinations[index];
              final isSelected = _selectedIndex == index;
              return _NavBarItem(
                icon: isSelected ? dest.selectedIcon : dest.icon,
                label: dest.label,
                isSelected: isSelected,
                onTap: () => _onTabChanged(index),
              );
            }),
          ),
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
                    onTap: () => _onTabChanged(index),
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
              color: isSelected
                  ? AppColors.driverAccent
                  : AppColors.textDarkSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.driverAccent
                    : AppColors.textDarkSecondary,
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
                  left: BorderSide(color: AppColors.driverAccent, width: 3),
                ),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.driverAccent
                  : AppColors.textDarkSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.driverAccent
                    : AppColors.textDarkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
