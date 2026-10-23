import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// ============================================================================
// CURSOR RING FIELD — ORIGINKIT FLUTTER NATIVE PORT
// High-performance particle ring field with interactive cursor & touch dynamics
// Presets: white particles (#FFFFFF), midnight background (#04050A)
// ============================================================================

/// 3D Simplex Noise implementation for organic turbulence and shimmer
class SimplexNoise {
  static final List<int> _p = [
    151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140,
    36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148, 247, 120,
    234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32, 57, 177, 33,
    88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175, 74, 165, 71,
    134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111, 229, 122, 60, 211, 133,
    230, 220, 105, 92, 41, 55, 46, 245, 40, 244, 102, 143, 54, 65, 25, 63, 161,
    1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18, 169, 200, 196, 135, 130,
    116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64, 52, 217, 226, 250,
    124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85, 212, 207, 206, 59, 227,
    47, 16, 58, 17, 182, 189, 28, 42, 223, 183, 170, 213, 119, 248, 152, 2, 44,
    154, 163, 70, 221, 153, 101, 155, 167, 43, 172, 9, 129, 22, 39, 253, 19,
    98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104, 218, 246, 97, 228,
    251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241, 81, 51, 145,
    235, 249, 14, 239, 107, 49, 192, 214, 31, 181, 199, 106, 157, 184, 84,
    204, 176, 115, 121, 50, 45, 127, 4, 150, 254, 138, 236, 205, 93, 222, 114,
    67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180,
  ];

  static final List<int> _perm = List<int>.filled(512, 0);
  static final List<int> _permMod12 = List<int>.filled(512, 0);
  static bool _initialized = false;

  static void _init() {
    if (_initialized) return;
    for (int i = 0; i < 512; i++) {
      _perm[i] = _p[i & 255];
      _permMod12[i] = _perm[i] % 12;
    }
    _initialized = true;
  }

  static double noise3D(double xin, double yin, double zin) {
    _init();
    double n0, n1, n2, n3;
    final s = (xin + yin + zin) * (1.0 / 3.0);
    final i = (xin + s).floor();
    final j = (yin + s).floor();
    final k = (zin + s).floor();
    final t = (i + j + k) * (1.0 / 6.0);
    final x0 = xin - (i - t);
    final y0 = yin - (j - t);
    final z0 = zin - (k - t);

    int i1, j1, k1;
    int i2, j2, k2;
    if (x0 >= y0) {
      if (y0 >= z0) {
        i1 = 1; j1 = 0; k1 = 0; i2 = 1; j2 = 1; k2 = 0;
      } else if (x0 >= z0) {
        i1 = 1; j1 = 0; k1 = 0; i2 = 1; j2 = 0; k2 = 1;
      } else {
        i1 = 0; j1 = 0; k1 = 1; i2 = 1; j2 = 0; k2 = 1;
      }
    } else {
      if (y0 < z0) {
        i1 = 0; j1 = 0; k1 = 1; i2 = 0; j2 = 1; k2 = 1;
      } else if (x0 < z0) {
        i1 = 0; j1 = 1; k1 = 0; i2 = 0; j2 = 1; k2 = 1;
      } else {
        i1 = 0; j1 = 1; k1 = 0; i2 = 1; j2 = 1; k2 = 0;
      }
    }

    final x1 = x0 - i1 + (1.0 / 6.0);
    final y1 = y0 - j1 + (1.0 / 6.0);
    final z1 = z0 - k1 + (1.0 / 6.0);
    final x2 = x0 - i2 + (2.0 / 6.0);
    final y2 = y0 - j2 + (2.0 / 6.0);
    final z2 = z0 - k2 + (2.0 / 6.0);
    final x3 = x0 - 1.0 + (3.0 / 6.0);
    final y3 = y0 - 1.0 + (3.0 / 6.0);
    final z3 = z0 - 1.0 + (3.0 / 6.0);

    final ii = i & 255;
    final jj = j & 255;
    final kk = k & 255;

    final gi0 = _permMod12[ii + _perm[jj + _perm[kk]]];
    final gi1 = _permMod12[ii + i1 + _perm[jj + j1 + _perm[kk + k1]]];
    final gi2 = _permMod12[ii + i2 + _perm[jj + j2 + _perm[kk + k2]]];
    final gi3 = _permMod12[ii + 1 + _perm[jj + 1 + _perm[kk + 1]]];

    double t0 = 0.6 - x0 * x0 - y0 * y0 - z0 * z0;
    if (t0 < 0) {
      n0 = 0.0;
    } else {
      t0 *= t0;
      n0 = t0 * t0 * _grad3(gi0, x0, y0, z0);
    }

    double t1 = 0.6 - x1 * x1 - y1 * y1 - z1 * z1;
    if (t1 < 0) {
      n1 = 0.0;
    } else {
      t1 *= t1;
      n1 = t1 * t1 * _grad3(gi1, x1, y1, z1);
    }

    double t2 = 0.6 - x2 * x2 - y2 * y2 - z2 * z2;
    if (t2 < 0) {
      n2 = 0.0;
    } else {
      t2 *= t2;
      n2 = t2 * t2 * _grad3(gi2, x2, y2, z2);
    }

    double t3 = 0.6 - x3 * x3 - y3 * y3 - z3 * z3;
    if (t3 < 0) {
      n3 = 0.0;
    } else {
      t3 *= t3;
      n3 = t3 * t3 * _grad3(gi3, x3, y3, z3);
    }

    return 32.0 * (n0 + n1 + n2 + n3);
  }

  static double _grad3(int hash, double x, double y, double z) {
    final h = hash & 15;
    final u = h < 8 ? x : y;
    final v = h < 4 ? y : (h == 12 || h == 14 ? x : z);
    return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v);
  }
}

/// 1D Value noise for organic idle wandering
double valueNoise1D(double x, double seed) {
  final i = x.floor();
  final f = x - i;
  double h(int n) {
    final s = math.sin((n + seed) * 127.1) * 43758.5453;
    return s - s.floor();
  }
  final u = f * f * (3.0 - 2.0 * f);
  return h(i) * (1.0 - u) + h(i + 1) * u;
}

double smoothstep(double edge0, double edge1, double x) {
  final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
  return t * t * (3.0 - 2.0 * t);
}

/// Individual Particle state in normalized [-1, 1] coordinate field
class _Particle {
  final double refX;
  final double refY;
  double currentX;
  double currentY;
  double memX = 0.0;
  double memY = 0.0;
  double scale = 0.0;
  double energy = 0.0;

  _Particle({
    required this.refX,
    required this.refY,
  })  : currentX = refX,
        currentY = refY;
}

/// Originkit-style interactive Cursor Ring Field Widget
class CursorRingField extends StatefulWidget {
  final Color backgroundColor;
  final Color particleColor;
  final int density;
  final double dotSize;
  final double speed;
  final double cameraDistance;
  final double ringRadius;
  final double ringWidth;
  final double ringPush;
  final double turbulence;
  final Widget? child;

  const CursorRingField({
    super.key,
    this.backgroundColor = const Color(0xFF04050A),
    this.particleColor = Colors.white,
    this.density = 300,
    this.dotSize = 120.0,
    this.speed = 6.0,
    this.cameraDistance = 160.0,
    this.ringRadius = 12.0,
    this.ringWidth = 9.0,
    this.ringPush = 50.0,
    this.turbulence = 100.0,
    this.child,
  });

  @override
  State<CursorRingField> createState() => _CursorRingFieldState();
}

class _CursorRingFieldState extends State<CursorRingField>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<_Particle> _particles = [];

  // Pointer & Physics Constants (OriginKit standard values)
  static const double cursorReach = 0.45;
  static const double cursorLerp = 0.12;
  static const double wanderLerp = 0.01;
  static const double handoverLerp = 0.08;
  static const double cursorJitter = 0.01;
  static const double ringEdge = 0.04;

  // Normalized Coordinates [-1, 1]
  double _pointerX = 0.0;
  double _pointerY = 0.0;
  bool _pointerOver = false;

  double _ringPosX = 0.0;
  double _ringPosY = 0.0;
  double _follow = 0.0;
  double _simTime = 0.0;
  double _wander = 0.0;
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initParticles();
    _ticker = createTicker(_onTick)..start();
  }

  void _initParticles() {
    _particles.clear();
    // Deterministic pseudo-random generation with Poisson-like stratification
    final count = (widget.density * 1.25).clamp(200, 480).toInt();
    final cols = math.sqrt(count).ceil();
    final rows = (count / cols).ceil();

    final rand = math.Random(0x9E3779B9);
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (_particles.length >= count) break;
        final cellW = 2.0 / cols;
        final cellH = 2.0 / rows;
        final jx = (rand.nextDouble() - 0.5) * cellW * 0.75;
        final jy = (rand.nextDouble() - 0.5) * cellH * 0.75;
        final x = (-1.0 + (c + 0.5) * cellW + jx).clamp(-1.0, 1.0);
        final y = (-1.0 + (r + 0.5) * cellH + jy).clamp(-1.0, 1.0);
        _particles.add(_Particle(refX: x, refY: y));
      }
    }
  }

  @override
  void didUpdateWidget(covariant CursorRingField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.density != widget.density) {
      _initParticles();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final dtRaw = _lastElapsed == Duration.zero
        ? 1.0 / 60.0
        : (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    final dt = dtRaw.clamp(0.001, 1.0 / 20.0);

    final speedNorm = widget.speed / 50.0;
    _simTime = (_simTime + dt * speedNorm) % 3600.0;
    _wander += dt * speedNorm;

    // Follow handover
    _follow += ((_pointerOver ? 1.0 : 0.0) - _follow) *
        (1.0 - math.pow(1.0 - handoverLerp, dt * 60.0));

    final wx = (valueNoise1D(_wander * 0.66, 94.234) - 0.5) * 2.0;
    final wy = (valueNoise1D(_wander * 0.75, 21.028) - 0.5) * 2.0;
    final wanderX = wx * 0.2;
    final wanderY = wy * 0.1;

    double targetX = wanderX;
    double targetY = wanderY;
    if (_follow > 0.0001) {
      final cx = _pointerX * cursorReach + wx * cursorJitter;
      final cy = _pointerY * cursorReach + wy * cursorJitter;
      targetX = wanderX + (cx - wanderX) * _follow;
      targetY = wanderY + (cy - wanderY) * _follow;
    }

    final lerpRate = wanderLerp + (cursorLerp - wanderLerp) * _follow;
    final rk = 1.0 - math.pow(1.0 - lerpRate, dt * 60.0);
    _ringPosX += (targetX - _ringPosX) * rk;
    _ringPosY += (targetY - _ringPosY) * rk;

    final normRadius = widget.ringRadius / 100.0;
    final radius = normRadius +
        math.sin(_simTime * 3.0) * 0.025 +
        math.cos(_simTime * 6.0) * 0.015;

    final normWidth = math.max(widget.ringWidth, 1.0) / 100.0;
    final normPush = widget.ringPush / 100.0;
    final normTurb = widget.turbulence / 100.0;
    final halfTime = _simTime * 0.5;

    // Particle field updates
    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      final rx = p.refX;
      final ry = p.refY;

      final dx = rx - _ringPosX;
      final dy = ry - _ringPosY;
      final dist = math.sqrt(dx * dx + dy * dy);

      // Edge noise deformation
      final n0 = SimplexNoise.noise3D(rx * 0.2 + 18.4924, ry * 0.2 + 72.9744, halfTime);
      final dist1 = math.sqrt(
        math.pow(rx + (n0 * 0.005) - _ringPosX, 2) +
        math.pow(ry + (n0 * 0.005) - _ringPosY, 2),
      );

      double t = smoothstep(radius - (normWidth * 2.0), radius, dist) -
                 smoothstep(radius, radius + normWidth, dist1);
      double t2 = smoothstep(radius - (ringEdge * 2.0), radius, dist) -
                  smoothstep(radius, radius + ringEdge, dist1);
      final t3 = smoothstep(radius + ringEdge, radius, dist);

      t = math.pow(math.max(t, 0.0), 2.0).toDouble();
      t2 = math.pow(math.max(t2, 0.0), 3.0).toDouble();

      t += t2 * 3.0; // hot core
      t += t3 * 0.4; // interior lift
      t += SimplexNoise.noise3D(rx * 30.0 + 11.4924, ry * 30.0 + 12.9744, halfTime) * t3 * 0.5;

      // Ambient baseline simmer
      final nS = SimplexNoise.noise3D(rx * 2.0 + 18.4924, ry * 2.0 + 72.9744, halfTime);
      t += math.pow((nS + 1.5) * 0.5, 2.0) * 0.6;

      // Drift & wave turbulence
      final n1 = SimplexNoise.noise3D(rx * 4.0 + 88.494, ry * 4.0 + 32.4397, halfTime * 0.7);
      final n2 = SimplexNoise.noise3D(rx * 4.0 + 50.904, ry * 4.0 + 120.947, halfTime * 0.7);
      final n3 = SimplexNoise.noise3D(rx * 20.0 + 18.4924, ry * 20.0 + 72.9744, halfTime);
      final n4 = SimplexNoise.noise3D(rx * 20.0 + 50.904, ry * 20.0 + 120.947, halfTime);

      double dispX = (n1 * 0.03 + n3 * 0.005) * normTurb;
      double dispY = (n2 * 0.03 + n4 * 0.005) * normTurb;
      final clampedDist = dist.clamp(0.0, 1.0);
      dispX += math.sin((rx * 20.0) + (halfTime * 8.0)) * 0.02 * clampedDist * normTurb;
      dispY += math.cos((ry * 20.0) + (halfTime * 6.0)) * 0.02 * clampedDist * normTurb;

      // Elastic push memory
      final pushFactor = math.pow(math.max(t2, 0.0), 0.75) * normPush;
      p.memX = (p.memX * 0.8) - (_ringPosX - (rx + dispX)) * pushFactor;
      p.memY = (p.memY * 0.8) - (_ringPosY - (ry + dispY)) * pushFactor;

      p.scale += (t - p.scale) * 0.2;
      p.energy = p.energy * 0.5 + p.scale * 0.25;

      p.currentX = rx + dispX + (p.memX * 0.25);
      p.currentY = ry + dispY + (p.memY * 0.25);
    }

    setState(() {});
  }

  void _updatePointer(Offset localOffset, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    _pointerX = (localOffset.dx / size.width) * 2.0 - 1.0;
    _pointerY = (localOffset.dy / size.height) * 2.0 - 1.0;
    _pointerOver = true;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Container(
          color: widget.backgroundColor,
          child: MouseRegion(
            opaque: false,
            onHover: (e) => _updatePointer(e.localPosition, size),
            onExit: (_) => setState(() => _pointerOver = false),
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (e) => _updatePointer(e.localPosition, size),
              onPointerMove: (e) => _updatePointer(e.localPosition, size),
              onPointerUp: (_) => setState(() => _pointerOver = false),
              onPointerCancel: (_) => setState(() => _pointerOver = false),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RepaintBoundary(
                    child: CustomPaint(
                      size: size,
                      painter: _CursorRingFieldPainter(
                        particles: _particles,
                        ringPosX: _ringPosX,
                        ringPosY: _ringPosY,
                        particleColor: widget.particleColor,
                        dotSize: widget.dotSize,
                        simTime: _simTime,
                      ),
                    ),
                  ),
                  if (widget.child != null) widget.child!,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CursorRingFieldPainter extends CustomPainter {
  final List<_Particle> particles;
  final double ringPosX;
  final double ringPosY;
  final Color particleColor;
  final double dotSize;
  final double simTime;

  final Paint _paint = Paint()..isAntiAlias = true;

  _CursorRingFieldPainter({
    required this.particles,
    required this.ringPosX,
    required this.ringPosY,
    required this.particleColor,
    required this.dotSize,
    required this.simTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || particles.isEmpty) return;

    final w = size.width;
    final h = size.height;
    final baseScale = (w / 650.0).clamp(0.65, 1.35) * (dotSize / 100.0);
    final dotW = 6.8 * baseScale;
    final dotH = 2.4 * baseScale;

    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final scale = p.scale;
      if (scale < 0.04) continue;

      // Coordinate mapping from normalized [-1, 1] to canvas screen space
      final px = (p.currentX * 0.5 + 0.5) * w;
      final py = (p.currentY * 0.5 + 0.5) * h;

      if (px < -20 || px > w + 20 || py < -20 || py > h + 20) continue;

      // Tangential vector orientation relative to cursor ring
      final angle = math.atan2(p.currentY - ringPosY, p.currentX - ringPosX);
      final noiseAngle = SimplexNoise.noise3D(
        p.currentX * 10.0 + 18.4924,
        p.currentY * 10.0 + 72.9744,
        simTime * 0.85,
      );

      final alpha = (smoothstep(0.1, 0.22, scale) * p.energy.clamp(0.0, 1.0))
          .clamp(0.0, 1.0);
      if (alpha < 0.02) continue;

      final capW = math.max(dotW * scale, 2.2);
      final capH = math.max(dotH * scale, 1.2);

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(-angle + (noiseAngle * 0.45));

      _paint.color = particleColor.withValues(alpha: alpha);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: capW, height: capH),
        Radius.circular(capH * 0.5),
      );
      canvas.drawRRect(rrect, _paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CursorRingFieldPainter oldDelegate) => true;
}
