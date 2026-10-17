import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// ============================================================================
// 1. LUMINOUS SILK AURORA PAINTER (STUDENT DASHBOARD SIGNATURE BACKDROP)
// ============================================================================
class LuminousSilkAuroraPainter extends CustomPainter {
  const LuminousSilkAuroraPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final w = size.width;
    final h = size.height;

    // 1. Clean, deep One UI midnight obsidian backdrop (#07080B)
    final bgRect = Rect.fromLTWH(0, 0, w, h);
    final bgPaint = Paint()..color = const Color(0xFF07080B);
    canvas.drawRect(bgRect, bgPaint);

    // 2. Subtle One UI calm atmospheric ambient depth (top vignette)
    final ambientRect = Rect.fromLTWH(0, -h * 0.05, w, h * 0.48);
    final ambientPaint = Paint()
      ..color = const Color(0xFF0D1527).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 85);
    canvas.drawOval(ambientRect, ambientPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// 2. GLASS SCAFFOLD (UNIFIED CANVAS FOR ALL STUDENT SCREENS)
// ============================================================================
class GlassScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  const GlassScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: LuminousSilkAuroraPainter(),
              ),
            ),
          ),
          SafeArea(
            child: body,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. FROSTED GLASS APP BAR
// ============================================================================
class FrostedGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;

  const FrostedGlassAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.bottom,
    this.centerTitle = true,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return AppBar(
      backgroundColor: Colors.black.withValues(alpha: 0.55),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: leading ??
          (canPop
              ? Center(
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                        width: 1.0,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.zero,
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                )
              : null),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(color: Colors.black.withValues(alpha: 0.45)),
        ),
      ),
      title: titleWidget ??
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
      actions: actions,
      bottom: bottom,
    );
  }
}

// ============================================================================
// 4. FROSTED APP BAR ACTION BUTTON
// ============================================================================
class FrostedAppBarAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isDestructive;

  const FrostedAppBarAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDestructive
            ? const Color(0xFFEF4444).withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: isDestructive
              ? const Color(0xFFEF4444).withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.28),
          width: 1.0,
        ),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 19,
          color: isDestructive
              ? const Color(0xFFFCA5A5)
              : Colors.white.withValues(alpha: 0.95),
        ),
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

// ============================================================================
// 5. GLASS CONTAINER (SIGNATURE FROSTED CARD)
// ============================================================================
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Border? border;
  final Color? borderColor;
  final Color? color;
  final AlignmentGeometry? alignment;
  final List<Color>? gradientColors;
  final Clip clipBehavior;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 26,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.onTap,
    this.border,
    this.borderColor,
    this.color,
    this.alignment,
    this.gradientColors,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final rradius = BorderRadius.circular(borderRadius);
    final effectiveBorder = border ??
        (borderColor != null
            ? Border.all(color: borderColor!, width: 1.0)
            : Border.all(color: Colors.white.withValues(alpha: 0.10), width: 1.0));

    Widget card = Container(
      width: width,
      height: height,
      alignment: alignment,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? const Color(0xFF161922).withValues(alpha: 0.82),
        borderRadius: rradius,
        border: effectiveBorder,
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D000000), // black 30%
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
          BoxShadow(
            color: Color(0x1A000000), // black 10%
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: rradius,
          splashColor: Colors.white.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.04),
          child: card,
        ),
      );
    }

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    return RepaintBoundary(child: card);
  }
}

// ============================================================================
// 6. GLASS SUB-CARD (INNER LIST ITEM / DETAILS BOX)
// ============================================================================
class GlassSubCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  const GlassSubCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 14,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF1E222C).withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.08),
          width: 1.0,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: card,
      );
    }

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    return card;
  }
}

// ============================================================================
// 7. LIQUID GLASS PILL PAINTER & WIDGET
// Hardware-accelerated liquid glass lens refraction with top specular glare
// arc, 3D cylindrical meniscus, and clean physical optical edge reflection.
// ============================================================================
// 7. LIQUID GLASS PILL PAINTER & WIDGET
// Hardware-accelerated liquid glass lens refraction with top specular glare
// arc, 3D cylindrical meniscus, and clean physical optical edge reflection.
// Supports visual hierarchy: action controls vs subtle metadata tags.
// ============================================================================
class LiquidGlassPillPainter extends CustomPainter {
  final double borderRadius;
  final Color? accentColor;
  final bool isSelected;
  final bool hasTopGlare;
  final bool isSubtle;

  const LiquidGlassPillPainter({
    required this.borderRadius,
    this.accentColor,
    this.isSelected = false,
    this.hasTopGlare = true,
    this.isSubtle = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final r = math.min(borderRadius, math.min(size.width, size.height) / 2);
    final rradius = Radius.circular(r);
    final rrect = RRect.fromRectAndRadius(rect, rradius);

    // 1. Internal Liquid Cylindrical Lens Fill (Curved light refraction)
    // Simulates optical liquid light concentration in upper half of the capsule
    final inset = 1.0;
    final innerR = math.max(0.0, r - inset);
    final topLensHeight = math.min(size.height * 0.52, size.height - 2.0);
    if (topLensHeight > 0 && size.width > inset * 2) {
      final topLensRect = Rect.fromLTWH(inset, inset, size.width - inset * 2, topLensHeight);
      final topLensRRect = RRect.fromRectAndCorners(
        topLensRect,
        topLeft: Radius.circular(innerR),
        topRight: Radius.circular(innerR),
        bottomLeft: const Radius.circular(3),
        bottomRight: const Radius.circular(3),
      );
      final lensPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = ui.Gradient.linear(
          Offset(0, inset),
          Offset(0, topLensHeight),
          [
            Colors.white.withValues(alpha: isSelected ? 0.16 : (isSubtle ? 0.06 : 0.12)),
            Colors.white.withValues(alpha: 0.0),
          ],
        );
      canvas.drawRRect(topLensRRect, lensPaint);
    }

    // 2. Outer Optical Glass Perimeter Rim
    // Refined, crystal-clear physical glass rim (no artificial rainbow gradients)
    final strokeRRect = rrect.deflate(0.5);
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.95
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.25, 0),
        Offset(size.width * 0.75, size.height),
        isSelected
            ? [
                Colors.white.withValues(alpha: 0.95), // Crisp luminous top reflection
                Colors.white.withValues(alpha: 0.45), // Clear glass lateral edge
                const Color(0xFF94A3B8).withValues(alpha: 0.22), // Soft slate refraction
                Colors.white.withValues(alpha: 0.25), // Subtle bottom ground bounce
              ]
            : [
                Colors.white.withValues(alpha: isSubtle ? 0.48 : 0.72), // Top light entry
                Colors.white.withValues(alpha: isSubtle ? 0.16 : 0.25), // Clean glass lateral edge
                const Color(0xFF64748B).withValues(alpha: 0.14), // Deep slate reflection
                Colors.white.withValues(alpha: isSubtle ? 0.12 : 0.18), // Bottom ground refraction
              ],
        const [0.0, 0.30, 0.72, 1.0],
      );
    canvas.drawRRect(strokeRRect, rimPaint);

    // 3. Inner Liquid Bevel / Meniscus Ring
    final innerRRect = rrect.deflate(1.4);
    if (innerRRect.width > 0 && innerRRect.height > 0) {
      final innerPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, size.height),
          [
            Colors.white.withValues(alpha: isSelected ? 0.38 : (isSubtle ? 0.16 : 0.26)),
            Colors.white.withValues(alpha: 0.03),
            Colors.white.withValues(alpha: isSubtle ? 0.05 : 0.08),
          ],
          const [0.0, 0.50, 1.0],
        );
      canvas.drawRRect(innerRRect, innerPaint);
    }

    // 4. Top Specular Glare Arc (Curved liquid glass meniscus crowning sheen)
    if (hasTopGlare && size.width > 14) {
      final glarePath = Path();
      final arcInset = 1.8; // Gracefully inset from the outer rim
      final cornerRadius = math.max(1.0, r - arcInset);

      // Tracing top rounded cap smoothly
      final leftCenter = Offset(r, r);
      final rightCenter = Offset(size.width - r, r);
      final leftRect = Rect.fromCircle(center: leftCenter, radius: cornerRadius);
      final rightRect = Rect.fromCircle(center: rightCenter, radius: cornerRadius);

      // Sweep: from upper-left curve through top straight edge to upper-right curve
      glarePath.addArc(leftRect, math.pi * 1.15, math.pi * 0.35);
      glarePath.lineTo(math.max(r, size.width - r), arcInset);
      if (size.width - r > r) {
        glarePath.arcTo(rightRect, -math.pi * 0.5, math.pi * 0.35, false);
      }

      // Pass A: Soft Luminous Sheen Bloom
      final bloomAlpha = isSelected ? 0.38 : (isSubtle ? 0.18 : 0.26);
      final bloomPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(
          Offset(0, arcInset),
          Offset(size.width, arcInset),
          [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: bloomAlpha),
            Colors.white.withValues(alpha: 0.0),
          ],
          const [0.0, 0.5, 1.0],
        );
      canvas.drawPath(glarePath, bloomPaint);

      // Pass B: Crisp Razor Specular Highlight Core
      final coreAlpha = isSelected ? 0.90 : (isSubtle ? 0.45 : 0.78);
      final corePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.85
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(
          Offset(size.width * 0.18, arcInset),
          Offset(size.width * 0.82, arcInset),
          [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: coreAlpha),
            Colors.white.withValues(alpha: 0.0),
          ],
          const [0.0, 0.5, 1.0],
        );
      canvas.drawPath(glarePath, corePaint);
    }

    // 5. Bottom Caustic Ground Bounce
    if (size.width > 16 && size.height > 12) {
      final bottomPath = Path();
      final bottomY = size.height - 1.4;
      final startX = math.max(r * 0.8, size.width * 0.25);
      final endX = math.min(size.width - r * 0.8, size.width * 0.75);
      bottomPath.moveTo(startX, bottomY);
      bottomPath.lineTo(endX, bottomY);

      final causticAlpha = isSelected ? 0.28 : (isSubtle ? 0.08 : 0.15);
      final causticPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.75
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(
          Offset(startX, bottomY),
          Offset(endX, bottomY),
          [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: causticAlpha),
            Colors.white.withValues(alpha: 0.0),
          ],
          const [0.0, 0.5, 1.0],
        );
      canvas.drawPath(bottomPath, causticPaint);
    }
  }

  @override
  bool shouldRepaint(covariant LiquidGlassPillPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.hasTopGlare != hasTopGlare ||
        oldDelegate.isSubtle != isSubtle;
  }
}

class LiquidGlassPill extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color? color;
  final Color? accentColor;
  final bool isSelected;
  final bool isSubtle;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const LiquidGlassPill({
    super.key,
    required this.child,
    this.borderRadius = 22,
    this.color,
    this.accentColor,
    this.isSelected = false,
    this.isSubtle = false,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rradius = BorderRadius.circular(borderRadius);

    final content = Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
      decoration: BoxDecoration(
        borderRadius: rradius,
        gradient: isSelected
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x35FFFFFF), // brighter 21% white top gloss
                  Color(0x80252C3E), // translucent optical fluid
                  Color(0xBA12151D), // dark obsidian liquid depth
                ],
                stops: [0.0, 0.45, 1.0],
              )
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isSubtle
                    ? const [
                        Color(0x18FFFFFF), // 9% white top
                        Color(0x551E2330), // translucent slate
                        Color(0x8812151D), // soft dark obsidian
                      ]
                    : const [
                        Color(0x28FFFFFF), // 16% white top gloss
                        Color(0x771E2330), // translucent optical fluid
                        Color(0xAA12151D), // obsidian liquid depth
                      ],
                stops: const [0.0, 0.45, 1.0],
              ),
      ),
      child: child,
    );

    Widget pill = Container(
      decoration: BoxDecoration(
        borderRadius: rradius,
        boxShadow: [
          // Ambient drop shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: isSubtle ? 0.20 : 0.35),
            blurRadius: isSubtle ? 6 : 10,
            offset: const Offset(0, 3),
          ),
          // Subtle luminous white optical bounce when selected
          if (isSelected)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: rradius,
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(
          foregroundPainter: LiquidGlassPillPainter(
            borderRadius: borderRadius,
            accentColor: accentColor,
            isSelected: isSelected,
            isSubtle: isSubtle,
          ),
          child: onTap != null
              ? Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: rradius,
                    splashColor: Colors.white.withValues(alpha: 0.12),
                    highlightColor: Colors.white.withValues(alpha: 0.05),
                    child: content,
                  ),
                )
              : content,
        ),
      ),
    );

    if (margin != null) {
      pill = Padding(padding: margin!, child: pill);
    }
    return RepaintBoundary(child: pill);
  }
}

// ============================================================================
// 8. GLASS CAPSULE PILL
// ============================================================================
class GlassCapsulePill extends StatelessWidget {
  final String? label;
  final Widget? child;
  final IconData? icon;
  final Color? textColor;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;
  final double fontSize;
  final double borderRadius;
  final bool isSubtle;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const GlassCapsulePill({
    super.key,
    this.label,
    this.child,
    this.icon,
    this.textColor,
    this.color,
    this.backgroundColor,
    this.borderColor,
    this.fontSize = 12,
    this.borderRadius = 22,
    this.isSubtle = true,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ?? Colors.white;

    Widget content = child ??
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: fontSize + 2, color: effectiveTextColor),
              const SizedBox(width: 5),
            ],
            if (label != null)
              Text(
                label!,
                style: TextStyle(
                  color: effectiveTextColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        );

    return LiquidGlassPill(
      borderRadius: borderRadius,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 5.5),
      isSubtle: isSubtle,
      onTap: onTap,
      child: content,
    );
  }
}

// ============================================================================
// 9. GLASS STATUS PILL (SAFE, WARNING, CRITICAL, INFO)
// ============================================================================
enum GlassPillStatus { safe, warning, critical, info, neutral }

class GlassStatusPill extends StatelessWidget {
  final String text;
  final GlassPillStatus status;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final bool? isSuccess;
  final bool? isWarning;
  final bool? isError;

  const GlassStatusPill({
    super.key,
    String? text,
    String? label,
    this.status = GlassPillStatus.safe,
    this.icon,
    this.color,
    this.textColor,
    this.isSuccess,
    this.isWarning,
    this.isError,
  }) : text = text ?? label ?? '';

  @override
  Widget build(BuildContext context) {
    final finalTextColor = textColor ?? Colors.white;

    return LiquidGlassPill(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: finalTextColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: finalTextColor,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
