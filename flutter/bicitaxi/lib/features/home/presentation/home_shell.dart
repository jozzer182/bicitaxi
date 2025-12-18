import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/glass_container.dart';
import 'map_home_screen.dart';
import '../../rides/presentation/client_history_screen.dart';
import '../../profile/presentation/client_profile_screen.dart';
import 'persistent_map_widget.dart';

/// Main shell for the Bici Taxi client app.
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
      icon: Icons.map_outlined,
      selectedIcon: Icons.map_rounded,
      label: 'Mapa',
    ),
    _NavDestination(
      icon: Icons.history_outlined,
      selectedIcon: Icons.history_rounded,
      label: 'Historial',
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
    // Index 0 = Mapa (handled by MapHomeScreen)
    // Index 1 = Historial
    // Index 2 = Perfil
    switch (index) {
      case 1:
        return const ClientHistoryScreen();
      case 2:
        return const ClientProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = ResponsiveUtils.isTabletOrLarger(context);

    return Scaffold(
      backgroundColor: Colors.white,
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
        // When on home tab (0), use MapHomeScreen with its own map
        // When on other tabs, show the persistent map with blur
        if (_selectedIndex == 0)
          const Positioned.fill(child: MapHomeScreen())
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
              // When on home tab (0), use MapHomeScreen with its own map
              // When on other tabs, show the persistent map with blur
              if (_selectedIndex == 0)
                const Positioned.fill(child: MapHomeScreen())
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
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: SizedBox(
          height: 75, // Fixed height for nav bar
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              // Blur 5% = sigma ~2.5 para un efecto sutil
              filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
              child: Container(
                decoration: BoxDecoration(
                  // Tinte blanco 5% de opacidad
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationRail(BuildContext context) {
    return UltraGlassCard(
      borderRadius: 0,
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
                color: AppColors.electricBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.directions_bike_rounded,
                color: AppColors.electricBlue,
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
                  ? AppColors.electricBlue
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
                    ? AppColors.electricBlue
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
                color: AppColors.electricBlue.withValues(alpha: 0.1),
                border: Border(
                  left: BorderSide(color: AppColors.electricBlue, width: 3),
                ),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.electricBlue
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
                    ? AppColors.electricBlue
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
