import 'dart:ui';
import 'package:flutter/material.dart';

// ============================================================================
// 1. LUMINOUS SILK AURORA PAINTER (STUDENT DASHBOARD SIGNATURE BACKDROP)
// ============================================================================
class LuminousSilkAuroraPainter extends CustomPainter {
  const LuminousSilkAuroraPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Pure cosmic black canvas (#000000 -> #030508)
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF000000),
          Color(0xFF030508),
          Color(0xFF000000),
        ],
        stops: [0.0, 0.50, 1.0],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // 2. Faint Top-Left Ambient Starlight Glow (faint slate/silver starlight)
    final lightRayRect = Rect.fromLTWH(
      -size.width * 0.25,
      -size.height * 0.12,
      size.width * 0.90,
      size.height * 0.65,
    );
    final lightRayPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.04),
          const Color(0xFF1E293B).withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(lightRayRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 65);
    canvas.drawOval(lightRayRect, lightRayPaint);

    // 3. Faint Right-Side Deep Indigo/Slate Atmosphere (no green)
    final silkRightRect = Rect.fromLTWH(
      size.width * 0.38,
      -40,
      size.width * 0.68,
      size.height * 0.82,
    );
    final silkRightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF1E1B4B).withValues(alpha: 0.08),
          const Color(0xFF0F172A).withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(silkRightRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 55);
    canvas.drawOval(silkRightRect, silkRightPaint);
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
            child: CustomPaint(
              painter: LuminousSilkAuroraPainter(),
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
      backgroundColor: Colors.black.withValues(alpha: 0.70),
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
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
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
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(color: Colors.transparent),
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
            ? const Color(0xFFEF4444).withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.08),
        shape: BoxShape.circle,
        border: Border.all(
          color: isDestructive
              ? const Color(0xFFEF4444).withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.18),
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
    this.borderRadius = 20,
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
    final effectiveBorder = border ??
        Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.18),
          width: 1.0,
        );

    final cardInterior = Container(
      alignment: alignment,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        gradient: color != null
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors ?? [
                  Colors.white.withValues(alpha: 0.09),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: effectiveBorder,
      ),
      child: child,
    );

    Widget result = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: onTap != null
              ? Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(borderRadius),
                    splashColor: Colors.white.withValues(alpha: 0.08),
                    highlightColor: Colors.white.withValues(alpha: 0.04),
                    child: cardInterior,
                  ),
                )
              : cardInterior,
        ),
      ),
    );

    if (margin != null) {
      result = Padding(padding: margin!, child: result);
    }
    return result;
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
        color: backgroundColor ?? Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.13),
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
// 7. GLASS CAPSULE PILL
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
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ?? color ?? Colors.white;
    final effectiveBorderColor = borderColor ??
        (color != null
            ? color!.withValues(alpha: 0.40)
            : Colors.white.withValues(alpha: 0.28));

    Widget content = child ??
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: fontSize + 2, color: color ?? effectiveTextColor),
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

    final pillBox = Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: backgroundColor != null
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (color != null
                      ? color!.withValues(alpha: 0.22)
                      : Colors.white.withValues(alpha: 0.16)),
                  (color != null
                      ? color!.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.04)),
                ],
                stops: const [0.0, 1.0],
              ),
        color: backgroundColor,
        border: Border.all(
          color: effectiveBorderColor,
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.06),
            blurRadius: 1,
            spreadRadius: 0.5,
            offset: const Offset(0, -0.5),
          ),
        ],
      ),
      child: content,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: onTap != null
            ? Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(borderRadius),
                  splashColor: Colors.white.withValues(alpha: 0.12),
                  child: pillBox,
                ),
              )
            : pillBox,
      ),
    );
  }
}

// ============================================================================
// 8. GLASS STATUS PILL (SAFE, WARNING, CRITICAL, INFO)
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
    Color bg;
    Color border;
    Color fg;

    if (color != null) {
      bg = color!.withValues(alpha: 0.20);
      border = color!.withValues(alpha: 0.50);
      fg = color!;
    } else if (isSuccess == true) {
      bg = const Color(0xFF10B981).withValues(alpha: 0.22);
      border = const Color(0xFF34D399).withValues(alpha: 0.65);
      fg = Colors.white;
    } else if (isWarning == true) {
      bg = const Color(0xFFF59E0B).withValues(alpha: 0.22);
      border = const Color(0xFFFBBF24).withValues(alpha: 0.65);
      fg = Colors.white;
    } else if (isError == true) {
      bg = const Color(0xFFEF4444).withValues(alpha: 0.22);
      border = const Color(0xFFF87171).withValues(alpha: 0.65);
      fg = Colors.white;
    } else {
      switch (status) {
        case GlassPillStatus.safe:
          bg = const Color(0xFF10B981).withValues(alpha: 0.22);
          border = const Color(0xFF34D399).withValues(alpha: 0.65);
          fg = Colors.white;
          break;
        case GlassPillStatus.warning:
          bg = const Color(0xFFF59E0B).withValues(alpha: 0.22);
          border = const Color(0xFFFBBF24).withValues(alpha: 0.65);
          fg = Colors.white;
          break;
        case GlassPillStatus.critical:
          bg = const Color(0xFFEF4444).withValues(alpha: 0.22);
          border = const Color(0xFFF87171).withValues(alpha: 0.65);
          fg = Colors.white;
          break;
        case GlassPillStatus.info:
          bg = const Color(0xFF3B82F6).withValues(alpha: 0.22);
          border = const Color(0xFF60A5FA).withValues(alpha: 0.65);
          fg = Colors.white;
          break;
        case GlassPillStatus.neutral:
          bg = Colors.white.withValues(alpha: 0.12);
          border = Colors.white.withValues(alpha: 0.30);
          fg = Colors.white;
          break;
      }
    }

    final finalTextColor = textColor ?? fg;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 1.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
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
        ),
      ),
    );
  }
}
