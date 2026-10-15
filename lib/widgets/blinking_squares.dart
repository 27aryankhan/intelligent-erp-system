import 'dart:math' as math;
import 'package:flutter/material.dart';

// ============================================================================
// BLINKING SQUARES — ORIGINKIT FLUTTER IMPLEMENTATION
// Recreated with 1:1 mathematical fidelity to Originkit's BlinkingSquares spec.
// Supports grid calculations, sinusoidal twinkling, radial/directional fade,
// and real-time cursor/touch pointer interaction.
// ============================================================================

class _CellData {
  final double phase;
  final double rate;
  final double tint;

  const _CellData({
    required this.phase,
    required this.rate,
    required this.tint,
  });
}

class BlinkingSquares extends StatefulWidget {
  final double gridSize;
  final double fillPercent;
  final String colorMode; // 'single' or 'multiple'
  final Color squareColor;
  final List<Color> colors;
  final double twinkleSpeed;
  final double opacity;
  final String fadeDirection; // 'right', 'left', 'top', 'bottom', 'radial', 'none'
  final double fadePercent;
  final double fadeIntensity;
  final bool hasCursorInteraction;
  final double cursorRadius;
  final double cursorBoost;
  final Widget? child;
  final double borderRadius;
  final BoxBorder? border;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;

  /// Default matches Originkit's exact preset:
  /// colorMode: "single", squareColor: "#FFFFFF", fadeDirection: "none", hasCursorInteraction: false
  const BlinkingSquares({
    super.key,
    this.gridSize = 40,
    this.fillPercent = 70,
    this.colorMode = 'single',
    this.squareColor = const Color(0xFFFFFFFF),
    this.colors = const [
      Color(0xFFFFFFFF),
    ],
    this.twinkleSpeed = 30,
    this.opacity = 1.0,
    this.fadeDirection = 'none',
    this.fadePercent = 100,
    this.fadeIntensity = 25,
    this.hasCursorInteraction = false,
    this.cursorRadius = 140,
    this.cursorBoost = 60,
    this.child,
    this.borderRadius = 20,
    this.border,
    this.backgroundColor = const Color(0xFF000000),
    this.padding,
  });

  /// Originkit default preset as given in the user's snippet
  factory BlinkingSquares.originkit({
    Key? key,
    Widget? child,
    double gridSize = 40,
    double fillPercent = 70,
    String colorMode = 'single',
    Color squareColor = const Color(0xFFFFFFFF),
    List<Color> colors = const [
      Color(0xFFFFFFFF),
    ],
    double twinkleSpeed = 30,
    double opacity = 1.0,
    String fadeDirection = 'none',
    double fadePercent = 100,
    double fadeIntensity = 25,
    bool hasCursorInteraction = false,
    double cursorRadius = 140,
    double cursorBoost = 60,
    double borderRadius = 20,
    BoxBorder? border,
    Color? backgroundColor = const Color(0xFF000000),
    EdgeInsetsGeometry? padding,
  }) {
    return BlinkingSquares(
      key: key,
      gridSize: gridSize,
      fillPercent: fillPercent,
      colorMode: colorMode,
      squareColor: squareColor,
      colors: colors,
      twinkleSpeed: twinkleSpeed,
      opacity: opacity,
      fadeDirection: fadeDirection,
      fadePercent: fadePercent,
      fadeIntensity: fadeIntensity,
      hasCursorInteraction: hasCursorInteraction,
      cursorRadius: cursorRadius,
      cursorBoost: cursorBoost,
      borderRadius: borderRadius,
      border: border,
      backgroundColor: backgroundColor,
      padding: padding,
      child: child,
    );
  }

  /// HITAM Emerald Theme preset
  factory BlinkingSquares.emerald({
    Key? key,
    Widget? child,
    double gridSize = 36,
    double fillPercent = 70,
    double twinkleSpeed = 30,
    double opacity = 0.85,
    String fadeDirection = 'none',
    double fadePercent = 100,
    double fadeIntensity = 25,
    bool hasCursorInteraction = false,
    double cursorRadius = 140,
    double cursorBoost = 60,
    double borderRadius = 20,
    BoxBorder? border,
    Color? backgroundColor = const Color(0xFF000000),
    EdgeInsetsGeometry? padding,
  }) {
    return BlinkingSquares(
      key: key,
      gridSize: gridSize,
      fillPercent: fillPercent,
      colorMode: 'multiple',
      colors: const [
        Color(0xFF34D399), // Emerald Mint
        Color(0xFF10B981), // Jade
        Color(0xFF38BDF8), // Cyan
        Color(0xFFFFFFFF), // Star White
      ],
      twinkleSpeed: twinkleSpeed,
      opacity: opacity,
      fadeDirection: fadeDirection,
      fadePercent: fadePercent,
      fadeIntensity: fadeIntensity,
      hasCursorInteraction: hasCursorInteraction,
      cursorRadius: cursorRadius,
      cursorBoost: cursorBoost,
      borderRadius: borderRadius,
      border: border ??
          Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.35),
            width: 1.2,
          ),
      backgroundColor: backgroundColor,
      padding: padding,
      child: child,
    );
  }

  /// Displays a dialog with an interactive BlinkingSquares background
  static Future<T?> showBlinkingDialog<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
    double maxWidth = 380,
    double borderRadius = 24,
    BlinkingSquares? backgroundOverride,
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
          child: backgroundOverride ??
              BlinkingSquares.originkit(
                borderRadius: borderRadius,
                padding: const EdgeInsets.all(20),
                child: child,
              ),
        ),
      ),
    );
  }

  @override
  State<BlinkingSquares> createState() => _BlinkingSquaresState();
}

class _BlinkingSquaresState extends State<BlinkingSquares>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Offset? _pointerPos;
  bool _isPointerActive = false;
  final DateTime _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerMove(Offset localPosition) {
    if (!widget.hasCursorInteraction) return;
    setState(() {
      _pointerPos = localPosition;
      _isPointerActive = true;
    });
  }

  void _onPointerLeave() {
    if (!widget.hasCursorInteraction) return;
    setState(() {
      _isPointerActive = false;
      _pointerPos = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = BorderRadius.circular(widget.borderRadius);
    final hasChild = widget.child != null;

    final backgroundPainter = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final elapsed =
            DateTime.now().difference(_startTime).inMicroseconds / 1000000.0;

        return CustomPaint(
          size: hasChild ? Size.zero : Size.infinite,
          painter: _BlinkingSquaresPainter(
            time: elapsed,
            gridSize: widget.gridSize,
            fillPercent: widget.fillPercent,
            colorMode: widget.colorMode,
            squareColor: widget.squareColor,
            colors: widget.colors,
            twinkleSpeed: widget.twinkleSpeed,
            opacity: widget.opacity,
            fadeDirection: widget.fadeDirection,
            fadePercent: widget.fadePercent,
            fadeIntensity: widget.fadeIntensity,
            hasCursorInteraction:
                widget.hasCursorInteraction && _isPointerActive,
            pointerPos: _pointerPos,
            cursorRadius: widget.cursorRadius,
            cursorBoost: widget.cursorBoost,
          ),
        );
      },
    );

    Widget content;
    if (hasChild) {
      content = Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(child: backgroundPainter),
          Padding(
            padding: widget.padding ?? EdgeInsets.zero,
            child: widget.child!,
          ),
        ],
      );
    } else {
      content = backgroundPainter;
    }

    final container = Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? const Color(0xFF000000),
        borderRadius: effectiveBorderRadius,
        border: widget.border ??
            Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 1.0,
            ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.50),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );

    if (!widget.hasCursorInteraction) {
      return container;
    }

    return MouseRegion(
      onHover: (event) => _onPointerMove(event.localPosition),
      onExit: (_) => _onPointerLeave(),
      child: Listener(
        onPointerDown: (event) => _onPointerMove(event.localPosition),
        onPointerMove: (event) => _onPointerMove(event.localPosition),
        onPointerUp: (_) => _onPointerLeave(),
        onPointerCancel: (_) => _onPointerLeave(),
        child: container,
      ),
    );
  }
}

class _BlinkingSquaresPainter extends CustomPainter {
  final double time;
  final double gridSize;
  final double fillPercent;
  final String colorMode;
  final Color squareColor;
  final List<Color> colors;
  final double twinkleSpeed;
  final double opacity;
  final String fadeDirection;
  final double fadePercent;
  final double fadeIntensity;
  final bool hasCursorInteraction;
  final Offset? pointerPos;
  final double cursorRadius;
  final double cursorBoost;

  static final Map<String, List<_CellData>> _cellCache = {};

  _BlinkingSquaresPainter({
    required this.time,
    required this.gridSize,
    required this.fillPercent,
    required this.colorMode,
    required this.squareColor,
    required this.colors,
    required this.twinkleSpeed,
    required this.opacity,
    required this.fadeDirection,
    required this.fadePercent,
    required this.fadeIntensity,
    required this.hasCursorInteraction,
    required this.pointerPos,
    required this.cursorRadius,
    required this.cursorBoost,
  });

  List<_CellData> _ensureCells(int cols, int rows) {
    final key = '${cols}x$rows';
    final cached = _cellCache[key];
    if (cached != null && cached.length == cols * rows) {
      return cached;
    }

    final total = cols * rows;
    final list = List<_CellData>.generate(total, (i) {
      // Originkit pseudo-random generation function
      final s = math.sin(i * 12.9898 + 78.233) * 43758.5453;
      final r1 = s - s.floorToDouble();
      final s2 = math.sin(i * 7.137 + 33.71) * 12345.6789;
      final r2 = s2 - s2.floorToDouble();
      final s3 = math.sin(i * 3.51 + 5.91) * 9876.54321;
      final r3 = s3 - s3.floorToDouble();

      return _CellData(
        phase: r1 * math.pi * 2,
        rate: 0.6 + r2 * 0.8,
        tint: r3,
      );
    });

    _cellCache[key] = list;
    return list;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final cells = math.max(2, gridSize.floor());
    final longSide = math.max(w, h);
    final cellSize = longSide / cells;
    final cols = math.max(1, (w / cellSize).ceil());
    final rows = math.max(1, (h / cellSize).ceil());

    final cellList = _ensureCells(cols, rows);

    final palette = (colorMode == 'multiple' && colors.isNotEmpty)
        ? colors
        : [squareColor];

    final speed = math.max(0.0, twinkleSpeed) * 0.05;
    const strength = 1.0;
    final masterOpacity = opacity.clamp(0.0, 1.0);

    final fill = (fillPercent / 100.0).clamp(0.1, 1.0);
    final inset = (1.0 - fill) * 0.5;

    final f = (fadePercent / 100.0).clamp(0.0, 1.0);
    final fStart = 1.0 - f;
    const fEnd = 1.0;
    final noFade = f <= 0;

    final falloff = 0.2 + (fadeIntensity.clamp(0.0, 100.0) / 100.0) * 5.8;

    final hasCursor = hasCursorInteraction && pointerPos != null;
    final cr = math.max(1.0, cursorRadius);
    final cb = math.max(0.0, cursorBoost) / 100.0;
    final cr2 = cr * cr;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final i = y * cols + x;
        if (i >= cellList.length) continue;
        final cell = cellList[i];

        double u;
        switch (fadeDirection) {
          case 'left':
            u = 1.0 - (x / math.max(1, cols - 1));
            break;
          case 'top':
            u = 1.0 - (y / math.max(1, rows - 1));
            break;
          case 'bottom':
            u = y / math.max(1, rows - 1);
            break;
          case 'radial':
            final dx = (x - (cols - 1) / 2.0) / math.max(1.0, (cols - 1) / 2.0);
            final dy = (y - (rows - 1) / 2.0) / math.max(1.0, (rows - 1) / 2.0);
            u = math.sqrt(dx * dx + dy * dy).clamp(0.0, 1.0);
            break;
          case 'none':
            u = 0.0;
            break;
          case 'right':
          default:
            u = x / math.max(1, cols - 1);
        }

        double envelope;
        if (fadeDirection == 'none' || noFade) {
          envelope = 1.0;
        } else if (u <= fStart) {
          envelope = 1.0;
        } else if (u >= fEnd) {
          envelope = 0.0;
        } else {
          final k = (u - fStart) / math.max(0.0001, fEnd - fStart);
          envelope = math.pow(1.0 - k, falloff).toDouble();
        }

        final cx = x * cellSize;
        final cy = y * cellSize;

        double reveal = 0.0;
        if (hasCursor) {
          final dx = cx + cellSize * 0.5 - pointerPos!.dx;
          final dy = cy + cellSize * 0.5 - pointerPos!.dy;
          final d2 = dx * dx + dy * dy;
          if (d2 < cr2) {
            final k = 1.0 - (d2 / cr2);
            reveal = k * k * cb;
          }
        }

        // Originkit sinusoidal twinkling formula
        final osc = 0.5 +
            0.5 *
                math.sin(
                    time * speed * cell.rate * math.pi * 2 + cell.phase);
        final twinkle = 1.0 - strength + strength * osc;

        final env2 = (envelope + reveal).clamp(0.0, 1.0);
        final finalAlpha = (env2 * twinkle * masterOpacity).clamp(0.0, 1.0);
        if (finalAlpha <= 0.002) continue;

        final sx = cx + cellSize * inset;
        final sy = cy + cellSize * inset;
        final sw = cellSize * fill;
        final sh = cellSize * fill;

        final ci = palette.length > 1
            ? (cell.tint * palette.length).floor().clamp(0, palette.length - 1)
            : 0;
        final c = palette[ci];

        paint.color = c.withValues(alpha: finalAlpha * c.opacity);

        // Draw pixel square matching Originkit ctx.fillRect
        canvas.drawRect(Rect.fromLTWH(sx, sy, sw, sh), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BlinkingSquaresPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.pointerPos != pointerPos ||
        oldDelegate.gridSize != gridSize ||
        oldDelegate.opacity != opacity ||
        oldDelegate.twinkleSpeed != twinkleSpeed;
  }
}
