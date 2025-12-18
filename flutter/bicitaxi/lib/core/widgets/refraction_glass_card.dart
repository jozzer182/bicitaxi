import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// A glass card widget that applies a refraction/distortion shader effect
/// to the background content, creating an iOS 26 "liquid glass" aesthetic.
///
/// This widget must be placed in a Stack above the content you want to show
/// through the glass. Pass a [backgroundKey] pointing to a RepaintBoundary
/// that wraps the background content.
///
/// Falls back to standard BackdropFilter blur if shader fails to load.
class RefractionGlassCard extends StatefulWidget {
  const RefractionGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.refractionStrength = 0.03,
    this.animated = false,
    this.backgroundKey,
  });

  /// Content to display on top of the glass effect
  final Widget child;

  /// Corner radius for the glass card
  final double borderRadius;

  /// Strength of the refraction distortion (0.0 to 0.1)
  /// Higher values = more pronounced lens effect
  final double refractionStrength;

  /// Whether to animate the refraction with subtle waves
  final bool animated;

  /// GlobalKey of the RepaintBoundary wrapping background content.
  /// If null, falls back to blur effect.
  final GlobalKey? backgroundKey;

  @override
  State<RefractionGlassCard> createState() => _RefractionGlassCardState();
}

class _RefractionGlassCardState extends State<RefractionGlassCard>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  ui.Image? _backgroundImage;
  bool _shaderFailed = false;
  Ticker? _ticker;
  double _time = 0.0;
  bool _captureScheduled = false;

  @override
  void initState() {
    super.initState();
    _loadShader();

    if (widget.animated) {
      _ticker = createTicker(_onTick)..start();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _backgroundImage?.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (mounted) {
      setState(() {
        _time = elapsed.inMilliseconds / 1000.0;
      });
      // Schedule capture on next frame after paint
      _scheduleCaptureAfterPaint();
    }
  }

  void _scheduleCaptureAfterPaint() {
    if (_captureScheduled) return;
    _captureScheduled = true;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _captureScheduled = false;
      _captureBackground();
    });
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/refraction_glass.frag',
      );
      if (mounted) {
        setState(() {
          _shader = program.fragmentShader();
        });
        // Schedule first capture after shader loads
        _scheduleCaptureAfterPaint();
      }
    } catch (e) {
      debugPrint('⚠️ RefractionGlassCard: Shader failed to load: $e');
      if (mounted) {
        setState(() => _shaderFailed = true);
      }
    }
  }

  void _captureBackground() {
    if (widget.backgroundKey == null || !mounted) return;

    final boundary =
        widget.backgroundKey!.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;

    if (boundary == null || !boundary.hasSize) return;

    // Check if boundary needs paint - if so, skip this frame
    if (boundary.debugNeedsPaint) {
      debugPrint('⏳ RefractionGlassCard: Waiting for paint to complete');
      return;
    }

    try {
      // Use lower pixel ratio for performance
      final image = boundary.toImageSync(pixelRatio: 0.5);

      // Dispose old image after getting new one
      final oldImage = _backgroundImage;
      _backgroundImage = image;
      oldImage?.dispose();

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('⚠️ RefractionGlassCard: Background capture failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // If shader failed or no background key, use fallback blur
    if (_shaderFailed || widget.backgroundKey == null || _shader == null) {
      return _buildFallback();
    }

    // If no background captured yet, show fallback
    if (_backgroundImage == null) {
      // Schedule capture for when we have a background
      _scheduleCaptureAfterPaint();
      return _buildFallback();
    }

    // Use a LayoutBuilder to get our position and size
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: _ShaderPaintWidget(
            shader: _shader!,
            backgroundImage: _backgroundImage!,
            refractionStrength: widget.refractionStrength,
            time: _time,
            borderRadius: widget.borderRadius,
            backgroundKey: widget.backgroundKey!,
            child: widget.child,
          ),
        );
      },
    );
  }

  /// Fallback to standard backdrop blur when shader unavailable
  Widget _buildFallback() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Separate widget to handle painting - needs its own RenderObject access
class _ShaderPaintWidget extends StatefulWidget {
  const _ShaderPaintWidget({
    required this.shader,
    required this.backgroundImage,
    required this.refractionStrength,
    required this.time,
    required this.borderRadius,
    required this.backgroundKey,
    required this.child,
  });

  final ui.FragmentShader shader;
  final ui.Image backgroundImage;
  final double refractionStrength;
  final double time;
  final double borderRadius;
  final GlobalKey backgroundKey;
  final Widget child;

  @override
  State<_ShaderPaintWidget> createState() => _ShaderPaintWidgetState();
}

class _ShaderPaintWidgetState extends State<_ShaderPaintWidget> {
  final GlobalKey _widgetKey = GlobalKey();
  Offset _widgetPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    // Get position after first frame
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _updatePosition();
    });
  }

  void _updatePosition() {
    final renderBox =
        _widgetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final position = renderBox.localToGlobal(Offset.zero);
      if (mounted && position != _widgetPosition) {
        setState(() {
          _widgetPosition = position;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update position on each build (for scrolling/movement)
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _updatePosition();
    });

    // Get screen size
    final screenSize = MediaQuery.of(context).size;

    return Container(
      key: _widgetKey,
      child: CustomPaint(
        painter: _RefractionPainter(
          shader: widget.shader,
          backgroundImage: widget.backgroundImage,
          refractionStrength: widget.refractionStrength,
          time: widget.time,
          screenSize: screenSize,
          widgetPosition: _widgetPosition,
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _RefractionPainter extends CustomPainter {
  _RefractionPainter({
    required this.shader,
    required this.backgroundImage,
    required this.refractionStrength,
    required this.time,
    required this.screenSize,
    required this.widgetPosition,
  });

  final ui.FragmentShader shader;
  final ui.Image backgroundImage;
  final double refractionStrength;
  final double time;
  final Size screenSize;
  final Offset widgetPosition;

  @override
  void paint(Canvas canvas, Size size) {
    // Use the actual widget position from the RenderBox
    final widgetPosX = widgetPosition.dx;
    final widgetPosY = widgetPosition.dy;

    // Set uniforms
    // Index 0: uSize.x (widget width)
    // Index 1: uSize.y (widget height)
    // Index 2: uScreenSize.x
    // Index 3: uScreenSize.y
    // Index 4: uWidgetPos.x
    // Index 5: uWidgetPos.y
    // Index 6: uRefraction
    // Index 7: uTime
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, screenSize.width);
    shader.setFloat(3, screenSize.height);
    shader.setFloat(4, widgetPosX);
    shader.setFloat(5, widgetPosY);
    shader.setFloat(6, refractionStrength);
    shader.setFloat(7, time);

    // Set sampler (separate index from floats)
    shader.setImageSampler(0, backgroundImage);

    // Draw with shader
    final paint = Paint()..shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_RefractionPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.backgroundImage != backgroundImage ||
        oldDelegate.refractionStrength != refractionStrength ||
        oldDelegate.widgetPosition != widgetPosition;
  }
}
