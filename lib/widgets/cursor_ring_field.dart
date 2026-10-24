import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// ============================================================================
// CURSOR RING FIELD — REFINED ORIGINKIT CIRCULAR FORCE FIELD
// - Poisson-disk stochastic distribution (guarantees NO particle clumping/blobs)
// - True Euclidean circular geometry in canvas pixel space
// - Aerodynamic, slender rounded micro-capsules matching Originkit reference
// - Automated trajectory: Center -> Left -> Center -> Right -> Center
// ============================================================================

/// 3D Simplex Noise implementation for smooth organic turbulence
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
  final double u;
  final double v;
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
  final int? density;
  final double speed;
  final double autoSpeed;
  final double ringRadius;
  final Widget? child;

  const CursorRingField({
    super.key,
    this.backgroundColor = const Color(0xFF04050A),
    this.particleColor = Colors.white,
    this.density,
    this.speed = 5.0,
    this.autoSpeed = 0.82,
    this.ringRadius = 66.0,
    this.child,
  });

  @override
  State<CursorRingField> createState() => _CursorRingFieldState();
}

class _CursorRingFieldState extends State<CursorRingField>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<_Particle> _particles = [];

  // Physics constants
  static const double cursorLerp = 0.12;
  static const double autoLerp = 0.045;
  static const double handoverLerp = 0.08;

  // Touch & Tracking
  Offset _pointerPx = Offset.zero;
  bool _pointerOver = false;

  // Ring center in screen pixels
  Offset _ringCenterPx = Offset.zero;
  double _follow = 0.0;
  double _simTime = 0.0;
  double _autoTime = 0.0;
  Duration _lastElapsed = Duration.zero;

  Size _lastSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _initPoissonField(const Size(380, 280));
    _ticker = createTicker(_onTick)..start();
  }

  /// Bridson's Poisson Disk Sampling: Guarantees NO particle clumping or overlap
  void _initPoissonField(Size size) {
    _particles.clear();
    final w = math.max(size.width, 240.0);
    final h = math.max(size.height, 200.0);
    const minD = 13.5; // Minimum 13.5px distance between any two particle centers
    final cellSize = minD / math.sqrt(2);
    final gridW = (w / cellSize).ceil() + 1;
    final gridH = (h / cellSize).ceil() + 1;
    final grid = List<int>.filled(gridW * gridH, -1);
    final points = <Offset>[];
    final active = <int>[];

    final rand = math.Random(0x429E37);

    void addPoint(Offset p) {
      final idx = points.length;
      points.add(p);
      active.add(idx);
      final gx = (p.dx / cellSize).floor().clamp(0, gridW - 1);
      final gy = (p.dy / cellSize).floor().clamp(0, gridH - 1);
      grid[gy * gridW + gx] = idx;
    }

    // Seed point near center
    addPoint(Offset(w * 0.5, h * 0.36));

    const minD2 = minD * minD;

    while (active.isNotEmpty && points.length < 420) {
      final randIdx = rand.nextInt(active.length);
      final pointIdx = active[randIdx];
      final basePoint = points[pointIdx];
      bool found = false;

      for (int attempts = 0; attempts < 24; attempts++) {
        final angle = rand.nextDouble() * math.pi * 2.0;
        final dist = minD + rand.nextDouble() * minD;
        final nx = basePoint.dx + math.cos(angle) * dist;
        final ny = basePoint.dy + math.sin(angle) * dist;

        if (nx < 6 || nx > w - 6 || ny < 6 || ny > h - 6) continue;

        final gx = (nx / cellSize).floor();
        final gy = (ny / cellSize).floor();

        bool ok = true;
        for (int dy = -2; dy <= 2 && ok; dy++) {
          for (int dx = -2; dx <= 2 && ok; dx++) {
            final cx = gx + dx;
            final cy = gy + dy;
            if (cx < 0 || cx >= gridW || cy < 0 || cy >= gridH) continue;
            final neighborIdx = grid[cy * gridW + cx];
            if (neighborIdx >= 0) {
              final neighbor = points[neighborIdx];
              final d2 = (neighbor.dx - nx) * (neighbor.dx - nx) +
                         (neighbor.dy - ny) * (neighbor.dy - ny);
              if (d2 < minD2) {
                ok = false;
              }
            }
          }
        }

        if (ok) {
          addPoint(Offset(nx, ny));
          found = true;
          break;
        }
      }

      if (!found) {
        active.removeAt(randIdx);
      }
    }

    for (final pt in points) {
      _particles.add(_Particle(u: pt.dx / w, v: pt.dy / h));
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

    final w = _lastSize.width > 0 ? _lastSize.width : 380.0;
    final h = _lastSize.height > 0 ? _lastSize.height : 280.0;

    // =========================================================================
    // AUTOMATIC TRAJECTORY:
    // Starts at Center (over student avatar at y=0.36) -> Left -> Center -> Right -> Center
    // =========================================================================
    final sweepProgress = -math.sin(_autoTime); // 0 -> -1 (left) -> 0 -> +1 (right) -> 0
    final sweepDistanceX = w * 0.28;
    final autoTargetX = (w * 0.5) + sweepProgress * sweepDistanceX;
    final autoTargetY = (h * 0.36) + math.sin(_autoTime * 2.0) * (h * 0.035);

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

    // True Euclidean circular radius in screen pixels
    final ringRadiusPx = widget.ringRadius +
        math.sin(_simTime * 2.5) * 2.5 +
        math.cos(_simTime * 5.0) * 1.5;

    final ringBandWidthPx = ringRadiusPx * 0.28; // ~18px clean band width
    final halfTime = _simTime * 0.5;

    // Particle field physics in Euclidean screen pixels
    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      final baseX = p.u * w;
      final baseY = p.v * h;

      final dx = baseX - _ringCenterPx.dx;
      final dy = baseY - _ringCenterPx.dy;
      final distPx = math.sqrt(dx * dx + dy * dy);

      p.distFromRing = (distPx - ringRadiusPx).abs();

      // Band intensity
      final t = smoothstep(ringRadiusPx - ringBandWidthPx, ringRadiusPx, distPx) -
                smoothstep(ringRadiusPx, ringRadiusPx + ringBandWidthPx, distPx);
      final tInside = smoothstep(ringRadiusPx + ringBandWidthPx * 0.5, ringRadiusPx, distPx);

      double intensity = math.pow(math.max(t, 0.0), 2.0).toDouble() * 3.5;
      intensity += tInside * 0.3;

      // Ambient baseline shimmer across far field
      final nS = SimplexNoise.noise3D(p.u * 3.0 + 18.49, p.v * 3.0 + 72.97, halfTime);
      intensity += math.pow((nS + 1.5) * 0.5, 2.0) * 0.35;

      // Organic gentle wave drift
      final n1 = SimplexNoise.noise3D(p.u * 4.0 + 88.49, p.v * 4.0 + 32.43, halfTime * 0.6);
      final n2 = SimplexNoise.noise3D(p.u * 4.0 + 50.90, p.v * 4.0 + 120.94, halfTime * 0.6);
      final dispX = n1 * 3.5;
      final dispY = n2 * 3.5;

      p.scale += (intensity - p.scale) * 0.28;
      p.energy = p.energy * 0.65 + p.scale * 0.22;

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
        if (_lastSize != size) {
          _lastSize = size;
          _initPoissonField(size);
        }

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
    final bandThreshold = ringRadius * 0.32;

    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final px = p.currentX;
      final py = p.currentY;

      if (px < -15 || px > w + 15 || py < -15 || py > h + 15) continue;

      final dx = px - ringCenter.dx;
      final dy = py - ringCenter.dy;
      final distFromBand = p.distFromRing;

      final isNearRing = distFromBand < bandThreshold;

      double alpha;
      double capW;
      double capH;

      if (isNearRing) {
        // Luminous, slender aerodynamic capsules tracing the true circle
        final proximity = (1.0 - (distFromBand / bandThreshold)).clamp(0.0, 1.0);
        alpha = (0.78 + proximity * 0.22).clamp(0.0, 1.0);
        capW = 6.8 + proximity * 3.4; // 6.8px to 10.2px slender length
        capH = 1.9 + proximity * 0.6; // 1.9px to 2.5px thickness
      } else {
        // Ambient background stars
        alpha = (0.18 + p.energy.clamp(0.0, 0.35)).clamp(0.12, 0.48);
        capW = 3.2 + (p.energy.clamp(0.0, 0.8)) * 1.5;
        capH = 1.4;
      }

      if (alpha < 0.03) continue;

      // Clean tangential rotation along the circle circumference
      final angle = math.atan2(dy, dx);
      final noiseAngle = SimplexNoise.noise3D(
        (px / w) * 8.0 + 18.49,
        (py / h) * 8.0 + 72.97,
        simTime * 0.7,
      );

      canvas.save();
      canvas.translate(px, py);
      // Rotate by angle + pi/2 so the capsule aligns smoothly along the circular arc
      canvas.rotate((angle + math.pi / 2.0) + (noiseAngle * 0.12));

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
