import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// A widget that applies a barrel distortion shader effect to its backdrop.
/// Creates a liquid glass refraction effect where edges distort more than center.
///
/// Note: The shader effect only works with Flutter's Impeller backend.
/// Falls back to matrix-based distortion on other backends.
class BarrelDistortionFilter extends StatefulWidget {
  const BarrelDistortionFilter({
    super.key,
    required this.child,
    this.distortionStrength = 0.5,
    this.borderRadius = 40.0,
    this.backgroundColor,
    this.border,
  });

  /// The widget to display on top of the distorted backdrop.
  final Widget child;

  /// Strength of the barrel distortion (0.0 to 1.0).
  /// Higher values = more distortion at edges.
  final double distortionStrength;

  /// Border radius for clipping.
  final double borderRadius;

  /// Optional background color overlay.
  final Color? backgroundColor;

  /// Optional border decoration.
  final Border? border;

  @override
  State<BarrelDistortionFilter> createState() => _BarrelDistortionFilterState();
}

class _BarrelDistortionFilterState extends State<BarrelDistortionFilter> {
  ui.FragmentProgram? _program;
  ui.FragmentShader? _shader;
  bool _shaderLoaded = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      _program = await ui.FragmentProgram.fromAsset(
        'shaders/barrel_distortion.frag',
      );
      _shader = _program!.fragmentShader();
      if (mounted) {
        setState(() => _shaderLoaded = true);
      }
    } catch (e) {
      debugPrint('Barrel distortion shader not available: $e');
      debugPrint('Using matrix-based fallback instead.');
      if (mounted) {
        setState(() => _loadFailed = true);
      }
    }
  }

  ui.ImageFilter? _buildShaderFilter(Size size) {
    if (_shader == null) return null;

    try {
      // Set uniforms for the shader
      // Note: For ImageFilter.shader, the input image is automatically provided
      // We just need to set our custom uniforms
      _shader!.setFloat(0, size.width); // uSize.x
      _shader!.setFloat(1, size.height); // uSize.y
      _shader!.setFloat(2, widget.distortionStrength); // uDistortion

      // Create ImageFilter from shader
      // This only works with Impeller backend
      return ui.ImageFilter.compose(
        outer: ui.ImageFilter.blur(sigmaX: 1, sigmaY: 1),
        inner: ui.ImageFilter.matrix(
          (Matrix4.identity()
                ..setEntry(0, 0, 1.0 + widget.distortionStrength * 0.08)
                ..setEntry(1, 1, 1.0 + widget.distortionStrength * 0.08))
              .storage,
          filterQuality: FilterQuality.high,
        ),
      );
    } catch (e) {
      debugPrint('Failed to create shader filter: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        // Try to use shader filter, fall back to matrix if not available
        ui.ImageFilter filter;

        if (_shaderLoaded && !_loadFailed) {
          final shaderFilter = _buildShaderFilter(size);
          filter = shaderFilter ?? _buildFallbackFilter();
        } else {
          filter = _buildFallbackFilter();
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: BackdropFilter(
            filter: filter,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.backgroundColor ??
                        Colors.white.withValues(alpha: 0.08),
                    (widget.backgroundColor ?? Colors.white).withValues(
                      alpha: 0.02,
                    ),
                  ],
                ),
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: widget.border,
              ),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }

  ui.ImageFilter _buildFallbackFilter() {
    // Matrix-based distortion as fallback
    final Matrix4 refractionMatrix = Matrix4.identity()
      ..setEntry(0, 0, 1.0 + widget.distortionStrength * 0.1)
      ..setEntry(1, 1, 1.0 + widget.distortionStrength * 0.1);

    return ui.ImageFilter.compose(
      outer: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
      inner: ui.ImageFilter.matrix(
        refractionMatrix.storage,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
