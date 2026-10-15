import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// ============================================================================
// ANIMATED RAYS — VENGEANCE UI FLUTTER IMPLEMENTATION
// 1:1 authentic Skia implementation of VengeanceUI's AnimatedRays component.
// Recreates the exact mathematical moiré beat frequency between 16% stripes
// and 20% rainbow linear gradients at 100 degrees, composited with Skia blur,
// difference blend overlay, and top-right radial mask.
// ============================================================================

class AnimatedRays extends StatefulWidget {
  final Widget? child;
  final dynamic borderRadius;
  final BoxBorder? border;
  final Color backgroundColor;
  final EdgeInsetsGeometry? padding;
  final double opacity;
  final double speedSeconds;
  final bool isDark;
  final List<Color>? rayColors;
  final BoxShadow? glowShadow;

  const AnimatedRays({
    super.key,
    this.child,
    this.borderRadius,
    this.border,
    this.backgroundColor = const Color(0xFF04060A),
    this.padding,
    this.opacity = 0.85,
    this.speedSeconds = 25.0,
    this.isDark = true,
    this.rayColors,
    this.glowShadow,
  });

  /// Displays any widget within a modal dialog with AnimatedRays background
  static Future<T?> showRaysDialog<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
    double maxWidth = 380,
    dynamic borderRadius,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: AnimatedRays(
            borderRadius: borderRadius ?? BorderRadius.circular(24),
            padding: const EdgeInsets.all(22),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  State<AnimatedRays> createState() => _AnimatedRaysState();
}

class _AnimatedRaysState extends State<AnimatedRays>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (widget.speedSeconds * 1000).toInt().clamp(5000, 120000),
      ),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadius effectiveBorderRadius;
    if (widget.borderRadius is BorderRadius) {
      effectiveBorderRadius = widget.borderRadius as BorderRadius;
    } else if (widget.borderRadius is BorderRadiusGeometry) {
      effectiveBorderRadius =
          (widget.borderRadius as BorderRadiusGeometry).resolve(TextDirection.ltr);
    } else if (widget.borderRadius is num) {
      effectiveBorderRadius =
          BorderRadius.circular((widget.borderRadius as num).toDouble());
    } else {
      effectiveBorderRadius = BorderRadius.circular(22);
    }
    final hasChild = widget.child != null;

    final backgroundPainter = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: hasChild ? Size.zero : Size.infinite,
          painter: AnimatedRaysPainter(
            progress: _controller.value,
            opacity: widget.opacity,
            isDark: widget.isDark,
            customColors: widget.rayColors,
          ),
        );
      },
    );

    final effectiveShadows = widget.glowShadow != null
        ? [widget.glowShadow!]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.65),
              blurRadius: 32,
              offset: const Offset(0, 10),
            ),
          ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        boxShadow: effectiveShadows,
      ),
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            // 1. Deep cosmic dark base canvas & frosted diffusion
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(color: widget.backgroundColor),
              ),
            ),
            // 2. Flowing Animated Aurora Rays Layer
            Positioned.fill(child: backgroundPainter),
            // 3. Child content
            if (hasChild)
              Padding(
                padding: widget.padding ?? EdgeInsets.zero,
                child: widget.child!,
              ),
            // 4. Polished Specular Glass Border & Corner Rim Highlight
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: SpecularGlassBorderPainter(
                    borderRadius: effectiveBorderRadius,
                    customBorder: widget.border,
                    defaultBorderWidth: 1.15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SPECULAR GLASS BORDER PAINTER
// Hardware-accelerated visionOS glass border with directional specular lighting
// and subtle inner corner bevel highlight for flawless, continuous curvature.
// ============================================================================
class SpecularGlassBorderPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final BoxBorder? customBorder;
  final double defaultBorderWidth;

  const SpecularGlassBorderPainter({
    required this.borderRadius,
    this.customBorder,
    this.defaultBorderWidth = 1.15,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = borderRadius.toRRect(rect);

    Color? baseColor;
    double strokeWidth = defaultBorderWidth;

    if (customBorder is Border) {
      final b = customBorder as Border;
      if (b.isUniform) {
        baseColor = b.top.color;
        strokeWidth = b.top.width;
      }
    }

    // 1. Primary Specular Rim Gradient (Top-left light source across all 4 corners)
    final strokeRRect = rrect.deflate(strokeWidth / 2.0);
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        [
          baseColor?.withValues(alpha: (baseColor.a * 1.35).clamp(0.0, 1.0)) ??
              Colors.white.withValues(alpha: 0.38),
          baseColor?.withValues(alpha: (baseColor.a * 0.85).clamp(0.0, 1.0)) ??
              Colors.white.withValues(alpha: 0.22),
          baseColor?.withValues(alpha: (baseColor.a * 0.50).clamp(0.0, 1.0)) ??
              Colors.white.withValues(alpha: 0.14),
          baseColor?.withValues(alpha: (baseColor.a * 0.25).clamp(0.0, 1.0)) ??
              Colors.white.withValues(alpha: 0.07),
        ],
        const [0.0, 0.35, 0.70, 1.0],
      );
    canvas.drawRRect(strokeRRect, borderPaint);

    // 2. Subtle Inner Corner Bevel (Frosted lens highlight along top curves)
    final innerRRect = rrect.deflate(strokeWidth + 0.6);
    if (innerRRect.width > 0 && innerRRect.height > 0) {
      final innerPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.65
        ..shader = ui.Gradient.linear(
          Offset(size.width * 0.15, 0),
          Offset(size.width * 0.85, size.height * 0.50),
          [
            Colors.white.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.04),
            Colors.transparent,
          ],
          const [0.0, 0.45, 1.0],
        );
      canvas.drawRRect(innerRRect, innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SpecularGlassBorderPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.customBorder != customBorder ||
        oldDelegate.defaultBorderWidth != defaultBorderWidth;
  }
}


class AnimatedRaysPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final double opacity;
  final bool isDark;
  final List<Color>? customColors;

  AnimatedRaysPainter({
    required this.progress,
    required this.opacity,
    required this.isDark,
    this.customColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final bounds = Rect.fromLTWH(0, 0, w, h);

    // 1. Deep cosmic dark base canvas
    final baseColor = isDark ? const Color(0xFF04060A) : const Color(0xFFF8FAFC);
    canvas.drawRect(bounds, Paint()..color = baseColor);

    // 2. Aurora Layer (composited on top of background, masked with radial vignette)
    canvas.saveLayer(bounds, Paint());

    // 2a. Blur filter matching CSS filter: blur(10px)
    canvas.saveLayer(
      bounds,
      Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
    );

    // 100 degrees angle vector matching CSS 100deg (sin 100°, -cos 100°)
    final double rad100 = 100.0 * (math.pi / 180.0);
    final double gdx = math.sin(rad100); // 0.9848
    final double gdy = -math.cos(rad100); // 0.1736

    // VengeanceUI rainbow palette: #60a5fa 10%, #e879f9 15%, #60a5fa 20%, #5eead4 25%, #60a5fa 30%
    final rainbowColors = customColors ??
        (isDark
            ? const [
                Color(0xFF60A5FA), // Light Blue
                Color(0xFFE879F9), // Fuchsia / Magenta
                Color(0xFF60A5FA), // Light Blue
                Color(0xFF5EEAD4), // Teal / Cyan
                Color(0xFF60A5FA), // Light Blue
              ]
            : const [
                Color(0xFF3B82F6),
                Color(0xFFD946EF),
                Color(0xFF3B82F6),
                Color(0xFF0D9488),
                Color(0xFF3B82F6),
              ]);
    const rainbowStops = [0.0, 0.25, 0.50, 0.75, 1.0];

    // Stripes palette: 0..7% black, 10..12% transparent, 16% black
    final stripeBlack = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    final stripeColors = [
      stripeBlack,
      stripeBlack,
      Colors.transparent,
      Colors.transparent,
      stripeBlack,
    ];
    const stripeStops = [0.0, 0.42, 0.58, 0.75, 1.0];

    // LAYER 1: Base aurora (backgroundSize: 300% 200%)
    final double rainbowPeriod1 = math.max(180.0, w * 0.55);
    final double r1Shift = progress * (2.0 * rainbowPeriod1);
    final r1From = Offset(-gdx * r1Shift, -gdy * r1Shift);
    final r1To = Offset(r1From.dx + gdx * rainbowPeriod1, r1From.dy + gdy * rainbowPeriod1);

    canvas.drawRect(
      bounds,
      Paint()
        ..shader = ui.Gradient.linear(
          r1From,
          r1To,
          rainbowColors,
          rainbowStops,
          TileMode.repeated,
        ),
    );

    final double stripePeriod1 = rainbowPeriod1 * 0.80; // 16% vs 20%
    final double s1Shift = progress * (2.0 * stripePeriod1);
    final s1From = Offset(-gdx * s1Shift, -gdy * s1Shift);
    final s1To = Offset(s1From.dx + gdx * stripePeriod1, s1From.dy + gdy * stripePeriod1);

    canvas.drawRect(
      bounds,
      Paint()
        ..shader = ui.Gradient.linear(
          s1From,
          s1To,
          stripeColors,
          stripeStops,
          TileMode.repeated,
        ),
    );

    // LAYER 2: Overlay with BlendMode.difference (matching CSS mix-blend-mode: difference)
    final double rainbowPeriod2 = rainbowPeriod1 * 0.75;
    final double r2Shift = progress * (3.0 * rainbowPeriod2);
    final r2From = Offset(-gdx * r2Shift, -gdy * r2Shift);
    final r2To = Offset(r2From.dx + gdx * rainbowPeriod2, r2From.dy + gdy * rainbowPeriod2);

    canvas.drawRect(
      bounds,
      Paint()
        ..blendMode = BlendMode.difference
        ..shader = ui.Gradient.linear(
          r2From,
          r2To,
          rainbowColors,
          rainbowStops,
          TileMode.repeated,
        ),
    );

    final double stripePeriod2 = stripePeriod1 * 0.75;
    final double s2Shift = progress * (3.0 * stripePeriod2);
    final s2From = Offset(-gdx * s2Shift, -gdy * s2Shift);
    final s2To = Offset(s2From.dx + gdx * stripePeriod2, s2From.dy + gdy * stripePeriod2);

    canvas.drawRect(
      bounds,
      Paint()
        ..blendMode = BlendMode.difference
        ..shader = ui.Gradient.linear(
          s2From,
          s2To,
          stripeColors,
          stripeStops,
          TileMode.repeated,
        ),
    );

    // End blur layer
    canvas.restore();

    // 2b. Radial Mask: maskImage: radial-gradient(ellipse at 100% 0%, black 40%, transparent 70%)
    final maskPaint = Paint()
      ..blendMode = BlendMode.dstIn
      ..shader = ui.Gradient.radial(
        Offset(w * 1.0, 0.0), // Top right corner (100% 0%)
        w * 1.15,
        [
          Colors.white.withValues(alpha: opacity),
          Colors.white.withValues(alpha: opacity * 0.90),
          Colors.white.withValues(alpha: opacity * 0.30),
          Colors.transparent,
        ],
        const [0.0, 0.40, 0.70, 0.95],
      );
    canvas.drawRect(bounds, maskPaint);

    // End aurora layer
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AnimatedRaysPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.opacity != opacity ||
        oldDelegate.isDark != isDark ||
        oldDelegate.customColors != customColors;
  }
}


