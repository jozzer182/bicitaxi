import 'package:flutter/material.dart';

/// Breakpoints for responsive design.
abstract final class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Utility class for responsive sizing and layout.
abstract final class ResponsiveUtils {
  /// Returns true if the screen is considered mobile-sized.
  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < Breakpoints.mobile;
  }

  /// Returns true if the screen is considered tablet-sized.
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= Breakpoints.mobile && width < Breakpoints.tablet;
  }

  /// Returns true if the screen is phone-sized (mobile or small tablet).
  static bool isPhone(BuildContext context) {
    return MediaQuery.sizeOf(context).width < Breakpoints.tablet;
  }

  /// Returns true if the screen is tablet or larger.
  static bool isTabletOrLarger(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= Breakpoints.mobile;
  }

  /// Returns the appropriate content max width for the current screen size.
  static double getContentMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < Breakpoints.mobile) {
      return double.infinity; // Full width on mobile
    } else if (width < Breakpoints.tablet) {
      return 500; // Constrained on tablet
    } else {
      return 600; // More constrained on desktop
    }
  }

  /// Returns responsive horizontal padding based on screen size.
  static EdgeInsets getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < Breakpoints.mobile) {
      return const EdgeInsets.symmetric(horizontal: 24);
    } else if (width < Breakpoints.tablet) {
      return const EdgeInsets.symmetric(horizontal: 48);
    } else {
      return const EdgeInsets.symmetric(horizontal: 64);
    }
  }
}

/// A widget that renders different layouts based on screen size.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.desktop) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= Breakpoints.mobile) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}

