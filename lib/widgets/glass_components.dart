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
  final Widget? background;

  const GlassScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.background,
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
          Positioned.fill(
            child: RepaintBoundary(
              child: background ??
                  const CustomPaint(
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
// 2B. SMOOTH PAGE ROUTE (FAST 180ms HARDWARE-ACCELERATED, PURE BLACK BARRIER, NO WHITE FLASH)
// ============================================================================
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  SmoothPageRoute({
    required this.child,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.03, 0.0),
                  end: Offset.zero,
                ).animate(curvedAnimation),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 180),
          reverseTransitionDuration: const Duration(milliseconds: 160),
          opaque: true,
          barrierColor: Colors.black,
        );
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
                  child: LiquidGlassPill(
                    borderRadius: 20,
                    enableBlur: true,
                    padding: EdgeInsets.zero,
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(right: 1.5),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Tooltip(
          message: tooltip,
          child: LiquidGlassPill(
            borderRadius: 20,
            enableBlur: true,
            padding: EdgeInsets.zero,
            accentColor: isDestructive ? const Color(0xFFEF4444) : null,
            onTap: onPressed,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: Icon(
                  icon,
                  size: 18,
                  color: isDestructive
                      ? const Color(0xFFFCA5A5)
                      : Colors.white.withValues(alpha: 0.95),
                ),
              ),
            ),
          ),
        ),
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
            : Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.0));

    Widget card = Container(
      width: width,
      height: height,
      alignment: alignment,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? const Color(0xFF141720).withValues(alpha: 0.88),
        borderRadius: rradius,
        border: effectiveBorder,
        boxShadow: const [
          BoxShadow(
            color: Color(0x38000000), // black 22%
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x15000000), // black 8%
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
    final isCompact = size.width <= 34 || size.height <= 34;

    // 1. 3D Volumetric Convex Reflection Dome (Whisper of Upper Glass Highlight)
    final capInsetX = math.max(1.5, r * 0.22);
    final capInsetY = isCompact ? 1.0 : 1.5;
    final capW = size.width - (capInsetX * 2);
    final capH = isCompact
        ? math.min(size.height * 0.32, 6.5)
        : math.min(size.height * 0.38, size.height - 4.0);
    if (capW > 4 && capH > 2) {
      final capR = math.max(1.0, r - capInsetX);
      final capRRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(capInsetX, capInsetY, capW, capH),
        topLeft: Radius.circular(capR),
        topRight: Radius.circular(capR),
        bottomLeft: Radius.circular(math.min(capR, 4.0)),
        bottomRight: Radius.circular(math.min(capR, 4.0)),
      );
      final domeAlpha = isCompact
          ? (isSubtle ? 0.08 : 0.12)
          : (isSelected ? 0.24 : (isSubtle ? 0.12 : 0.16));
      final domePaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = ui.Gradient.linear(
          Offset(0, capInsetY),
          Offset(0, capInsetY + capH),
          [
            Colors.white.withValues(alpha: domeAlpha),
            Colors.white.withValues(alpha: domeAlpha * 0.25),
            Colors.white.withValues(alpha: 0.0),
          ],
          const [0.0, 0.45, 1.0],
        );
      canvas.drawRRect(capRRect, domePaint);
    }

    // 2. 3D Bottom Inner Shadow (Volumetric Glass Thickness & Recessed Optics)
    final bottomShadowRRect = rrect.deflate(1.0);
    if (bottomShadowRRect.width > 0 && bottomShadowRRect.height > 0) {
      final bottomShadowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isCompact ? 0.75 : 1.5
        ..shader = ui.Gradient.linear(
          Offset(0, size.height * 0.50),
          Offset(0, size.height),
          [
            Colors.transparent,
            Colors.black.withValues(alpha: isCompact ? 0.16 : (isSubtle ? 0.20 : 0.28)),
          ],
        );
      canvas.save();
      canvas.clipRRect(rrect);
      canvas.drawRRect(bottomShadowRRect, bottomShadowPaint);
      canvas.restore();
    }

    // 3. Outer Optical Glass Perimeter Rim (Delicate Luminous Hairline Rim)
    final strokeRRect = rrect.deflate(0.5);
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isCompact ? 0.75 : 0.90
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.20, 0),
        Offset(size.width * 0.80, size.height),
        isSelected
            ? [
                Colors.white.withValues(alpha: 0.65),
                Colors.white.withValues(alpha: 0.22),
                const Color(0xFF94A3B8).withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.20),
              ]
            : [
                Colors.white.withValues(
                    alpha: isCompact
                        ? (isSubtle ? 0.38 : 0.45)
                        : (isSubtle ? 0.42 : 0.52)), // Delicate top light rim
                Colors.white.withValues(
                    alpha: isCompact ? 0.08 : (isSubtle ? 0.10 : 0.14)), // Translucent side edge
                const Color(0xFF64748B).withValues(alpha: 0.08), // Gentle refraction
                Colors.white.withValues(
                    alpha: isCompact ? 0.12 : (isSubtle ? 0.14 : 0.18)), // Soft bottom rebound
              ],
        const [0.0, 0.28, 0.70, 1.0],
      );
    canvas.drawRRect(strokeRRect, rimPaint);

    // 4. Inner Liquid Meniscus Ring
    if (!isCompact) {
      final innerRRect = rrect.deflate(1.4);
      if (innerRRect.width > 0 && innerRRect.height > 0) {
        final innerPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.65
          ..shader = ui.Gradient.linear(
            Offset.zero,
            Offset(0, size.height),
            [
              Colors.white.withValues(alpha: isSelected ? 0.22 : (isSubtle ? 0.10 : 0.14)),
              Colors.white.withValues(alpha: 0.02),
              Colors.white.withValues(alpha: isSubtle ? 0.04 : 0.08),
            ],
            const [0.0, 0.50, 1.0],
          );
        canvas.drawRRect(innerRRect, innerPaint);
      }
    }

    // 5. Top Specular Glare Arc (Natural curved liquid meniscus sheen, not metallic chrome)
    if (hasTopGlare && size.width > 14) {
      final glarePath = Path();
      final arcInset = isCompact ? 1.2 : 1.6;
      final cornerRadius = math.max(1.0, r - arcInset);

      final leftCenter = Offset(r, r);
      final rightCenter = Offset(size.width - r, r);
      final leftRect = Rect.fromCircle(center: leftCenter, radius: cornerRadius);
      final rightRect = Rect.fromCircle(center: rightCenter, radius: cornerRadius);

      glarePath.addArc(leftRect, math.pi * 1.15, math.pi * 0.35);
      glarePath.lineTo(math.max(r, size.width - r), arcInset);
      if (size.width - r > r) {
        glarePath.arcTo(rightRect, -math.pi * 0.5, math.pi * 0.35, false);
      }

      // Pass A: Soft Luminous Sheen Bloom
      final bloomAlpha = isCompact
          ? (isSubtle ? 0.08 : 0.12)
          : (isSelected ? 0.22 : (isSubtle ? 0.10 : 0.15));
      final bloomPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isCompact ? 1.0 : 1.8
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

      // Pass B: Subtle Optical Glare Core
      final coreAlpha = isCompact
          ? (isSubtle ? 0.28 : 0.35)
          : (isSelected ? 0.50 : (isSubtle ? 0.32 : 0.40));
      final corePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isCompact ? 0.70 : 0.85
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(
          Offset(size.width * 0.15, arcInset),
          Offset(size.width * 0.85, arcInset),
          [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: coreAlpha * 0.5),
            Colors.white.withValues(alpha: coreAlpha),
            Colors.white.withValues(alpha: coreAlpha * 0.5),
            Colors.white.withValues(alpha: 0.0),
          ],
          const [0.0, 0.25, 0.50, 0.75, 1.0],
        );
      canvas.drawPath(glarePath, corePaint);
    }

    // 6. Bottom Caustic Ground Bounce
    if (!isCompact && size.width > 16 && size.height > 12) {
      final bottomPath = Path();
      final bottomY = size.height - 1.2;
      final startX = math.max(r * 0.7, size.width * 0.20);
      final endX = math.min(size.width - r * 0.7, size.width * 0.80);
      bottomPath.moveTo(startX, bottomY);
      bottomPath.lineTo(endX, bottomY);

      final causticAlpha = isSelected ? 0.20 : (isSubtle ? 0.08 : 0.14);
      final causticPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
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
  final bool enableBlur;
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
    this.enableBlur = false,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rradius = BorderRadius.circular(borderRadius);

    Widget content = Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
      decoration: BoxDecoration(
        borderRadius: rradius,
        gradient: isSelected
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x35FFFFFF), // 21% white top gloss
                  Color(0x12FFFFFF), // soft sheen
                  Color(0x28222A3C), // translucent optical fluid
                  Color(0x3C0B0E16), // deep obsidian core
                  Color(0x5006080D), // shadowed underside
                ],
                stops: [0.0, 0.12, 0.45, 0.82, 1.0],
              )
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isSubtle
                    ? const [
                        Color(0x24FFFFFF), // 14% white top gloss
                        Color(0x0AFFFFFF), // soft falloff
                        Color(0x1A181E2E), // translucent optical fluid (10%)
                        Color(0x280C0F16), // dark obsidian liquid core (16%)
                        Color(0x3606080C), // gentle bottom shadow (21%)
                      ]
                    : const [
                        Color(0x2AFFFFFF), // 16% white top gloss
                        Color(0x0CFFFFFF), // soft roll-off
                        Color(0x221A2234), // translucent optical fluid (13%)
                        Color(0x320B0E15), // deep obsidian liquid core (20%)
                        Color(0x4006080C), // gentle bottom shadow (25%)
                      ],
                stops: const [0.0, 0.12, 0.45, 0.82, 1.0],
              ),
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: rradius,
          splashColor: Colors.white.withValues(alpha: 0.12),
          highlightColor: Colors.white.withValues(alpha: 0.05),
          child: content,
        ),
      );
    }

    Widget glassSurface = CustomPaint(
      foregroundPainter: LiquidGlassPillPainter(
        borderRadius: borderRadius,
        accentColor: accentColor,
        isSelected: isSelected,
        isSubtle: isSubtle,
      ),
      child: content,
    );

    if (enableBlur) {
      glassSurface = BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: glassSurface,
      );
    }

    Widget pill = Container(
      decoration: BoxDecoration(
        borderRadius: rradius,
        boxShadow: isSubtle
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: rradius,
        clipBehavior: Clip.antiAlias,
        child: glassSurface,
      ),
    );

    if (margin != null) {
      pill = Padding(padding: margin!, child: pill);
    }
    return RepaintBoundary(child: pill);
  }
}

// ============================================================================
// 8. LIQUID GLASS CIRCLE BUTTON (MINIMAL TRANSLUCENT OPTICAL GLASS LENS)
// High-fidelity visionOS translucent circular lens button for chevrons & actions.
// Features genuine backdrop refraction, subtle luminous rim, and natural highlights.
// ============================================================================
class LiquidGlassCircleButton extends StatelessWidget {
  final double size;
  final Widget? child;
  final IconData? icon;
  final double iconSize;
  final Color iconColor;
  final VoidCallback? onTap;
  final String? tooltip;

  const LiquidGlassCircleButton({
    super.key,
    this.size = 28,
    this.child,
    this.icon,
    this.iconSize = 11,
    this.iconColor = Colors.white,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final rradius = BorderRadius.circular(size / 2);

    Widget buttonContent = SizedBox(
      width: size,
      height: size,
      child: Center(
        child: child ??
            (icon != null
                ? Padding(
                    padding: icon == Icons.arrow_forward_ios_rounded
                        ? const EdgeInsets.only(left: 1.5)
                        : EdgeInsets.zero,
                    child: Icon(
                      icon,
                      size: iconSize,
                      color: iconColor,
                    ),
                  )
                : null),
      ),
    );

    if (tooltip != null) {
      buttonContent = Tooltip(message: tooltip!, child: buttonContent);
    }

    Widget glassLens = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Lighter, luminous optical glass surface that pops forward on dark cards
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x48FFFFFF), // 28% white crystal highlight entry
            Color(0x22FFFFFF), // 13% clear optical fluid body
            Color(0x181F2B3E), // translucent blue-slate tint
            Color(0x350D131F), // soft depth tone
          ],
          stops: [0.0, 0.35, 0.70, 1.0],
        ),
        // Brighter, distinct optical glass rim so users immediately recognize it as interactive
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.34),
          width: 0.95,
        ),
      ),
      child: buttonContent,
    );

    if (onTap != null) {
      glassLens = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: rradius,
          splashColor: Colors.white.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: glassLens,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          // Crisp grounding shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 8,
            offset: const Offset(0, 2.5),
          ),
          // Ambient floor bounce
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, -0.5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: rradius,
        clipBehavior: Clip.antiAlias,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: glassLens,
        ),
      ),
    );
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
  final bool enableBlur;
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
    this.isSubtle = false,
    this.enableBlur = false,
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
      enableBlur: enableBlur,
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
  final bool enableBlur;

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
    this.enableBlur = false,
  }) : text = text ?? label ?? '';

  @override
  Widget build(BuildContext context) {
    final finalTextColor = textColor ?? Colors.white;

    return LiquidGlassPill(
      borderRadius: 18,
      enableBlur: enableBlur,
      isSubtle: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5.5),
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
              fontSize: 11.5,
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
