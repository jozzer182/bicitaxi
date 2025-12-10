import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// A widget that applies a barrel distortion shader effect to its backdrop.
/// Creates a liquid glass refraction effect where edges distort more than center.
class BarrelDistortionFilter extends StatefulWidget {
  const BarrelDistortionFilter({
    super.key,
    required this.child,
    this.distortionStrength = 1.0,
    this.borderRadius = 40.0,
    this.backgroundColor,
    this.border,
  });

  final Widget child;
  final double distortionStrength;
  final double borderRadius;
  final Color? backgroundColor;
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
        debugPrint('🔮 [BarrelDistortion] Shader cargado correctamente');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadFailed = true);
        debugPrint('⚠️ [BarrelDistortion] Shader error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

        // Debug output
        debugPrint(
          '📐 Widget size: ${size.width.toStringAsFixed(0)}x${size.height.toStringAsFixed(0)}',
        );
        debugPrint(
          '📐 Physical: ${(size.width * devicePixelRatio).toStringAsFixed(0)}x${(size.height * devicePixelRatio).toStringAsFixed(0)}',
        );
        debugPrint('📐 Shader loaded: $_shaderLoaded, failed: $_loadFailed');

        ui.ImageFilter filter;

        if (_shaderLoaded && !_loadFailed && _shader != null) {
          // Configure shader uniforms - índices corresponden al orden en .frag:
          // vec2 uWidgetSize = índices 0, 1
          // float uDistortionStrength = índice 2
          // vec2 uWidgetOffset = índices 3, 4
          _shader!.setFloat(0, size.width); // uWidgetSize.x
          print('📐 uWidgetSize.x: ${size.width}');
          _shader!.setFloat(1, size.height); // uWidgetSize.y
          print('📐 uWidgetSize.y: ${size.height}');
          _shader!.setFloat(
            2,
            widget.distortionStrength,
          ); // uDistortionStrength
          print('📐 uDistortionStrength: ${widget.distortionStrength}');
          _shader!.setFloat(3, 0); // uWidgetOffset.x
          print('📐 uWidgetOffset.x: 0');
          _shader!.setFloat(4, 0); // uWidgetOffset.y
          print('📐 uWidgetOffset.y: 0');

          debugPrint(
            '📐 Shader uniforms: size=(${(size.width * devicePixelRatio).toStringAsFixed(0)}, ${(size.height * devicePixelRatio).toStringAsFixed(0)}), distortion=${widget.distortionStrength}',
          );

          try {
            filter = ui.ImageFilter.shader(_shader!);
            debugPrint('✅ ImageFilter.shader created');
          } catch (e) {
            debugPrint('❌ ImageFilter.shader failed: $e');
            filter = _buildFallbackFilter();
          }
        } else {
          debugPrint('⚠️ Using fallback filter');
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
                        Colors.white.withValues(alpha: 0.06),
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
    return ui.ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5);
  }
}
