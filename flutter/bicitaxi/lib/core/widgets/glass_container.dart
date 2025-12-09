import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:liquid_glass_ui_design/liquid_glass_ui.dart';
import '../theme/app_colors.dart';

/// Ultra transparent glass card with customizable blur and opacity.
/// Uses 5% opacity and sigma 5 blur by default per user preference.
class UltraGlassCard extends StatelessWidget {
  const UltraGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24.0,
    this.blurSigma = 5.0,
    this.opacity = 0.05,
    this.borderOpacity = 0.4,
    this.color, // Optional tint color
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blurSigma;
  final double opacity;
  final double borderOpacity;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // Use custom color if provided, otherwise use white with opacity
    final backgroundColor = color ?? Colors.white.withValues(alpha: opacity);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: borderOpacity),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A container widget with liquid glass effect styling.
/// Wraps the Liquid Glass UI design package's components.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24.0,
    this.width,
    this.height,
    this.constraints,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      constraints: constraints,
      child: LiquidCard(
        borderRadius: borderRadius,
        padding: padding != null
            ? EdgeInsets.only(
                left: (padding as EdgeInsets).left,
                right: (padding as EdgeInsets).right,
                top: (padding as EdgeInsets).top,
                bottom: (padding as EdgeInsets).bottom,
              )
            : const EdgeInsets.all(24),
        child: child,
      ),
    );
  }
}

/// A button styled with liquid glass effect.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.width,
    this.height = 56,
    this.borderRadius = 16.0,
    this.isPrimary = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final double? width;
  final double height;
  final double borderRadius;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[icon!, const SizedBox(width: 12)],
        Flexible(child: child),
      ],
    );

    return SizedBox(
      width: width,
      height: height,
      child: LiquidButton(
        borderRadius: borderRadius,
        onTap: onPressed,
        child: buttonChild,
      ),
    );
  }
}

/// A scaffold with liquid glass background.
class GlassScaffold extends StatelessWidget {
  const GlassScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.floatingActionButton,
    this.backgroundGradient,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Gradient? backgroundGradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient:
            backgroundGradient ??
            const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                Color(0xFF1A0A2E),
                AppColors.deepBlue,
              ],
              stops: [0.0, 0.5, 1.0],
            ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        body: child,
      ),
    );
  }
}
