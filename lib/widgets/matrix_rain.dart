import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Character set: Katakana half-width + Digits as specified in MatrixRain component
const String _matrixCharacters =
    'ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ1234567890';

/// High-performance Flutter implementation of the Componentry Matrix Rain component.
/// Displays falling digital rain consisting of Katakana glyphs and numbers with glowing
/// trail heads and smooth authentic matrix animations.
class MatrixRain extends StatefulWidget {
  final double fontSize;
  final int speed; // milliseconds per tick (default 50)
  final String variant; // 'default' (green), 'cyan', 'rainbow'
  final Color? fixedColor;
  final bool transparent;
  final double width;
  final double height;

  const MatrixRain({
    super.key,
    this.fontSize = 15.0,
    this.speed = 50,
    this.variant = 'default',
    this.fixedColor,
    this.transparent = false,
    this.width = double.infinity,
    this.height = double.infinity,
  });

  @override
  State<MatrixRain> createState() => _MatrixRainState();
}

class _MatrixColumn {
  double x;
  double dropRow;
  double speed;
  int trailLength;
  List<String> chars;

  _MatrixColumn({
    required this.x,
    required this.dropRow,
    required this.speed,
    required this.trailLength,
    required this.chars,
  });
}

class _MatrixRainState extends State<MatrixRain> {
  Timer? _timer;
  final math.Random _random = math.Random();
  final List<_MatrixColumn> _columns = [];
  double _lastWidth = 0;
  double _lastHeight = 0;
  int _tickCount = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(MatrixRain oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speed != widget.speed) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: widget.speed), (_) {
      if (!mounted) return;
      _updateDrops();
      setState(() {
        _tickCount++;
      });
    });
  }

  void _initColumns(double width, double height) {
    _columns.clear();
    final double colWidth = widget.fontSize * 1.15;
    final int columnCount = (width / colWidth).ceil() + 1;
    final int maxRows = (height / (widget.fontSize * 1.15)).ceil() + 1;

    for (int i = 0; i < columnCount; i++) {
      final trailLen = _random.nextInt(16) + 12; // 12 to 28 characters
      // Stagger drops across the screen so rain is active immediately
      final dropRow = _random.nextDouble() * (maxRows + trailLen) - trailLen;
      final speed = _random.nextDouble() * 0.7 + 0.75; // 0.75 to 1.45 rows per tick

      final chars = List.generate(
        maxRows + trailLen + 10,
        (_) => _matrixCharacters[_random.nextInt(_matrixCharacters.length)],
      );

      _columns.add(
        _MatrixColumn(
          x: i * colWidth,
          dropRow: dropRow,
          speed: speed,
          trailLength: trailLen,
          chars: chars,
        ),
      );
    }
  }

  void _updateDrops() {
    if (_columns.isEmpty || _lastHeight <= 0) return;
    final double rowHeight = widget.fontSize * 1.15;
    final int maxRows = (_lastHeight / rowHeight).ceil() + 1;

    for (var col in _columns) {
      col.dropRow += col.speed;

      // Periodically shimmer/mutate random character in trail
      if (_random.nextDouble() < 0.15 && col.chars.isNotEmpty) {
        final mutateIdx = _random.nextInt(col.chars.length);
        col.chars[mutateIdx] =
            _matrixCharacters[_random.nextInt(_matrixCharacters.length)];
      }

      // Reset when drop leaves screen
      if ((col.dropRow - col.trailLength) > maxRows) {
        if (_random.nextDouble() > 0.03) {
          col.dropRow = -(_random.nextInt(12) + 2).toDouble();
          col.speed = _random.nextDouble() * 0.7 + 0.75;
          col.trailLength = _random.nextInt(16) + 12;
        }
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = widget.width.isFinite ? widget.width : constraints.maxWidth;
        final h =
            widget.height.isFinite ? widget.height : constraints.maxHeight;

        if (w > 0 && h > 0 && (w != _lastWidth || h != _lastHeight)) {
          _lastWidth = w;
          _lastHeight = h;
          _initColumns(w, h);
        }

        return SizedBox(
          width: w,
          height: h,
          child: CustomPaint(
            painter: _MatrixRainPainter(
              columns: _columns,
              fontSize: widget.fontSize,
              variant: widget.variant,
              fixedColor: widget.fixedColor,
              transparent: widget.transparent,
              tickCount: _tickCount,
            ),
          ),
        );
      },
    );
  }
}

class _MatrixRainPainter extends CustomPainter {
  final List<_MatrixColumn> columns;
  final double fontSize;
  final String variant;
  final Color? fixedColor;
  final bool transparent;
  final int tickCount;

  _MatrixRainPainter({
    required this.columns,
    required this.fontSize,
    required this.variant,
    required this.fixedColor,
    required this.transparent,
    required this.tickCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Background
    if (!transparent) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF030712), // Deep Cyber Matrix black
      );
    }

    final double rowHeight = fontSize * 1.15;
    final int maxRows = (size.height / rowHeight).ceil() + 1;

    // 2. Render each active digital rain column
    for (int colIdx = 0; colIdx < columns.length; colIdx++) {
      final col = columns[colIdx];
      final headRow = col.dropRow.floor();
      final startTrailRow = headRow - col.trailLength + 1;

      // Skip columns completely off screen
      if (startTrailRow > maxRows || headRow < -1) continue;

      final paragraphBuilder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: TextAlign.center,
          fontSize: fontSize,
          height: 1.15,
        ),
      );

      bool hasText = false;

      for (int k = 0; k < col.trailLength; k++) {
        final currentRow = startTrailRow + k;
        if (currentRow < 0 || currentRow > maxRows) continue;

        final isHead = (k == col.trailLength - 1);
        final isNearHead = (k == col.trailLength - 2);

        // Color computation
        Color charColor;
        List<ui.Shadow>? shadows;

        if (variant == 'rainbow' && fixedColor == null) {
          final hue = (tickCount * 4 + colIdx * 12 + k * 8) % 360;
          charColor = HSLColor.fromAHSL(1.0, hue.toDouble(), 1.0, 0.50).toColor();
          if (isHead) {
            charColor = Colors.white;
            shadows = [
              ui.Shadow(
                color: HSLColor.fromAHSL(1.0, hue.toDouble(), 1.0, 0.7).toColor(),
                blurRadius: 10,
              ),
            ];
          }
        } else if (fixedColor != null) {
          final alpha = (k / col.trailLength).clamp(0.10, 1.0);
          charColor = isHead ? Colors.white : fixedColor!.withValues(alpha: alpha);
          if (isHead) {
            shadows = [ui.Shadow(color: fixedColor!, blurRadius: 10)];
          }
        } else if (variant == 'cyan') {
          final alpha = (k / col.trailLength).clamp(0.08, 0.95);
          charColor = isHead
              ? const Color(0xFFE0FFFF)
              : const Color(0xFF00E5FF).withValues(alpha: alpha);
          if (isHead) {
            shadows = const [
              ui.Shadow(color: Color(0xFF00E5FF), blurRadius: 10),
            ];
          }
        } else {
          // Default iconic Matrix Green
          final alpha = (k / col.trailLength).clamp(0.08, 0.95);
          if (isHead) {
            charColor = const Color(0xFFE8FFF0); // Bright white-green core
            shadows = const [
              ui.Shadow(color: Color(0xFF00FF66), blurRadius: 12),
              ui.Shadow(color: Color(0xFF00FF41), blurRadius: 4),
            ];
          } else if (isNearHead) {
            charColor = const Color(0xFF00FF66);
            shadows = const [
              ui.Shadow(color: Color(0xFF00FF41), blurRadius: 6),
            ];
          } else {
            charColor = const Color(0xFF00FF41).withValues(alpha: alpha);
          }
        }

        final charIndex = (currentRow.abs()) % col.chars.length;
        final charText = col.chars[charIndex];

        paragraphBuilder.pushStyle(
          ui.TextStyle(
            color: charColor,
            fontSize: fontSize,
            fontFamily: 'monospace',
            fontWeight: isHead ? FontWeight.w900 : FontWeight.w600,
            shadows: shadows,
          ),
        );
        paragraphBuilder.addText(charText + (k < col.trailLength - 1 ? '\n' : ''));
        paragraphBuilder.pop();
        hasText = true;
      }

      if (hasText) {
        final paragraph = paragraphBuilder.build()
          ..layout(ui.ParagraphConstraints(width: fontSize * 1.15));

        // Calculate Y position of start of trail
        final drawY = math.max(0.0, startTrailRow * rowHeight);
        canvas.drawParagraph(paragraph, Offset(col.x, drawY));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MatrixRainPainter oldDelegate) => true;
}
