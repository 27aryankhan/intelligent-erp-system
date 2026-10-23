import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// ============================================================================
// CURSOR RING FIELD — REFINED FLUTTER CIRCULAR FORCE FIELD
// - 100% Euclidean circular shape (measured in canvas screen pixels, no oval)
// - Automatic trajectory: Center -> Left -> Center -> Right -> Center
// - Bold, radiant white (#FFFFFF) capsule particles matching Originkit
// - Smooth organic simplex noise turbulence & ambient starfield shimmer
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

double smoothstep(double edge0, double edge1, double x) {
  final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
  return t * t * (3.0 - 2.0 * t);
}

/// Particle representation in relative [0.0, 1.0] unit box
class _Particle {
  final double u; // [0, 1] relative X
  final double v; // [0, 1] relative Y
  double currentX = 0.0;
  double currentY = 0.0;
  double scale = 0.0;
  double energy = 0.0;
  double distFromRing = 999.0;

  _Particle({required this.u, required this.v});
}

/// Originkit-style interactive & automatic Circular Cursor Ring Field Widget
class CursorRingField extends StatefulWidget {
  final Color backgroundColor;
  final Color particleColor;
  final int density;
  final double dotSize;
  final double speed;
  final double autoSpeed;
  final double ringRadius;
  final Widget? child;

  const CursorRingField({
    super.key,
    this.backgroundColor = const Color(0xFF04050A),
    this.particleColor = Colors.white,
    this.density = 480,
    this.dotSize = 100.0,
    this.speed = 5.0,
    this.autoSpeed = 0.85,
    this.ringRadius = 65.0,
    this.child,
  });

  @override
  State<CursorRingField> createState() => _CursorRingFieldState();
}

class _CursorRingFieldState extends State<CursorRingField>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<_Particle> _particles = [];

  // Smooth handover and physics
  static const double cursorLerp = 0.12;
  static const double autoLerp = 0.045;
  static const double handoverLerp = 0.08;

  // Touch coordinates in pixels
  Offset _pointerPx = Offset.zero;
  bool _pointerOver = false;

  // Ring center in pixels
  Offset _ringCenterPx = Offset.zero;
  double _follow = 0.0;
  double _simTime = 0.0;
  double _autoTime = 0.0;
  Duration _lastElapsed = Duration.zero;

  Size _lastSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _initParticles();
    _ticker = createTicker(_onTick)..start();
  }

  void _initParticles() {
    _particles.clear();
    final rand = math.Random(0x429E37);
    final count = widget.density.clamp(320, 650);

    // 1. Cluster particles along the central sweep zone for dense ring presence
    final ringClusterCount = (count * 0.45).round();
    for (int i = 0; i < ringClusterCount; i++) {
      // Sweep zone: X from 0.15 to 0.85, Y from 0.10 to 0.70
      final cx = 0.20 + rand.nextDouble() * 0.60;
      final cy = 0.15 + rand.nextDouble() * 0.50;
      final ang = rand.nextDouble() * math.pi * 2.0;
      final rad = (widget.ringRadius * (0.6 + rand.nextDouble() * 0.8)) / 300.0;
      final u = (cx + math.cos(ang) * rad).clamp(0.02, 0.98);
      final v = (cy + math.sin(ang) * rad).clamp(0.02, 0.98);
      _particles.add(_Particle(u: u, v: v));
    }

    // 2. Uniform ambient starfield for the rest of the canvas
    final ambientCount = count - _particles.length;
    final cols = math.sqrt(ambientCount).ceil();
    final rows = (ambientCount / cols).ceil();
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (_particles.length >= count) break;
        final cellW = 1.0 / cols;
        final cellH = 1.0 / rows;
        final jx = (rand.nextDouble() - 0.5) * cellW * 0.85;
        final jy = (rand.nextDouble() - 0.5) * cellH * 0.85;
        final u = ((c + 0.5) * cellW + jx).clamp(0.01, 0.99);
        final v = ((r + 0.5) * cellH + jy).clamp(0.01, 0.99);
        _particles.add(_Particle(u: u, v: v));
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
    _autoTime += dt * widget.autoSpeed;

    // Follow handover
    _follow += ((_pointerOver ? 1.0 : 0.0) - _follow) *
        (1.0 - math.pow(1.0 - handoverLerp, dt * 60.0));

    final w = _lastSize.width > 0 ? _lastSize.width : 360.0;
    final h = _lastSize.height > 0 ? _lastSize.height : 260.0;

    // =========================================================================
    // AUTOMATIC TRAJECTORY:
    // Starts at Center (over student avatar at y=0.36) -> Left -> Center -> Right -> Center
    // =========================================================================
    final sweepProgress = -math.sin(_autoTime); // 0 -> -1 (left) -> 0 -> +1 (right) -> 0
    final sweepDistanceX = w * 0.28;
    final autoTargetX = (w * 0.5) + sweepProgress * sweepDistanceX;
    final autoTargetY = (h * 0.36) + math.sin(_autoTime * 2.0) * (h * 0.04);

    double targetX = autoTargetX;
    double targetY = autoTargetY;

    if (_follow > 0.0001) {
      targetX = autoTargetX + (_pointerPx.dx - autoTargetX) * _follow;
      targetY = autoTargetY + (_pointerPx.dy - autoTargetY) * _follow;
    }

    if (_ringCenterPx == Offset.zero) {
      _ringCenterPx = Offset(w * 0.5, h * 0.36);
    }

    final lerpRate = autoLerp + (cursorLerp - autoLerp) * _follow;
    final rk = 1.0 - math.pow(1.0 - lerpRate, dt * 60.0);
    _ringCenterPx = Offset(
      _ringCenterPx.dx + (targetX - _ringCenterPx.dx) * rk,
      _ringCenterPx.dy + (targetY - _ringCenterPx.dy) * rk,
    );

    // True circular radius in screen pixels
    final ringRadiusPx = widget.ringRadius +
        math.sin(_simTime * 3.0) * 3.5 +
        math.cos(_simTime * 6.0) * 2.0;

    final ringBandWidthPx = ringRadiusPx * 0.32; // ~21px band width
    final ringCoreWidthPx = ringRadiusPx * 0.12; // ~8px hot core
    final halfTime = _simTime * 0.5;

    // Update particles in Euclidean screen pixels for a 100% true circle
    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      final baseX = p.u * w;
      final baseY = p.v * h;

      // Distance in actual canvas pixels ensures a geometrically perfect circle
      final dx = baseX - _ringCenterPx.dx;
      final dy = baseY - _ringCenterPx.dy;
      final distPx = math.sqrt(dx * dx + dy * dy);

      p.distFromRing = (distPx - ringRadiusPx).abs();

      // Ring band intensity
      final t1 = smoothstep(ringRadiusPx - ringBandWidthPx * 1.5, ringRadiusPx, distPx) -
                 smoothstep(ringRadiusPx, ringRadiusPx + ringBandWidthPx, distPx);
      final t2 = smoothstep(ringRadiusPx - ringCoreWidthPx * 1.8, ringRadiusPx, distPx) -
                 smoothstep(ringRadiusPx, ringRadiusPx + ringCoreWidthPx, distPx);
      final t3 = smoothstep(ringRadiusPx + ringCoreWidthPx, ringRadiusPx, distPx);

      double intensity = math.pow(math.max(t1, 0.0), 2.0).toDouble();
      intensity += math.pow(math.max(t2, 0.0), 3.0).toDouble() * 3.0; // hot core
      intensity += t3 * 0.35; // gentle interior halo

      // Ambient baseline simmer
      final nS = SimplexNoise.noise3D(p.u * 3.0 + 18.49, p.v * 3.0 + 72.97, halfTime);
      intensity += math.pow((nS + 1.5) * 0.5, 2.0) * 0.45;

      // Organic drift and turbulence
      final n1 = SimplexNoise.noise3D(p.u * 5.0 + 88.49, p.v * 5.0 + 32.43, halfTime * 0.7);
      final n2 = SimplexNoise.noise3D(p.u * 5.0 + 50.90, p.v * 5.0 + 120.94, halfTime * 0.7);
      final dispX = n1 * 5.0 + math.sin((p.u * 16.0) + (halfTime * 6.0)) * 2.5;
      final dispY = n2 * 5.0 + math.cos((p.v * 16.0) + (halfTime * 5.0)) * 2.5;

      p.scale += (intensity - p.scale) * 0.25;
      p.energy = p.energy * 0.6 + p.scale * 0.25;

      p.currentX = baseX + dispX;
      p.currentY = baseY + dispY;
    }

    setState(() {});
  }

  void _updatePointer(Offset localOffset) {
    _pointerPx = localOffset;
    _pointerOver = true;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _lastSize = size;

        return Container(
          color: widget.backgroundColor,
          child: MouseRegion(
            opaque: false,
            onHover: (e) => _updatePointer(e.localPosition),
            onExit: (_) => setState(() => _pointerOver = false),
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (e) => _updatePointer(e.localPosition),
              onPointerMove: (e) => _updatePointer(e.localPosition),
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
                        ringCenter: _ringCenterPx,
                        ringRadius: widget.ringRadius,
                        particleColor: widget.particleColor,
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
  final Offset ringCenter;
  final double ringRadius;
  final Color particleColor;
  final double simTime;

  final Paint _paint = Paint()..isAntiAlias = true;

  _CursorRingFieldPainter({
    required this.particles,
    required this.ringCenter,
    required this.ringRadius,
    required this.particleColor,
    required this.simTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || particles.isEmpty) return;

    final w = size.width;
    final h = size.height;
    final bandThreshold = ringRadius * 0.38;

    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final px = p.currentX;
      final py = p.currentY;

      if (px < -15 || px > w + 15 || py < -15 || py > h + 15) continue;

      final dx = px - ringCenter.dx;
      final dy = py - ringCenter.dy;
      final distFromBand = p.distFromRing;

      // Distinguish ring particles from ambient background particles
      final isNearRing = distFromBand < bandThreshold;

      double alpha;
      double capW;
      double capH;

      if (isNearRing) {
        // Bright radiant white particles forming the circular ring
        final proximity = (1.0 - (distFromBand / bandThreshold)).clamp(0.0, 1.0);
        alpha = (0.75 + proximity * 0.25).clamp(0.0, 1.0);
        capW = 7.5 + proximity * 6.5; // 7.5px to 14.0px length
        capH = 2.4 + proximity * 1.2; // 2.4px to 3.6px thickness
      } else {
        // Ambient background stars
        alpha = (0.20 + p.energy.clamp(0.0, 0.45)).clamp(0.15, 0.60);
        capW = 3.6 + (p.energy.clamp(0.0, 1.0)) * 2.2;
        capH = 1.6;
      }

      if (alpha < 0.04) continue;

      // Tangential alignment along the circular circumference
      final angle = math.atan2(dy, dx);
      final noiseAngle = SimplexNoise.noise3D(
        (px / w) * 10.0 + 18.49,
        (py / h) * 10.0 + 72.97,
        simTime * 0.85,
      );

      canvas.save();
      canvas.translate(px, py);
      // Rotate by angle + pi/2 so the capsule length aligns along the circumference of the circle
      canvas.rotate((angle + math.pi / 2.0) + (noiseAngle * 0.25));

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
