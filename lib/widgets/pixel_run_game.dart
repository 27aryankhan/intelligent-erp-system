import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Pixel Run Game — Native Flutter implementation of Originkit's pixel-run-game
///
/// Features retro 8-bit runner sprites, animated running/jumping legs,
/// parallax drifting clouds, dashed speed horizon, obstacle blocks with glyphs,
/// autonomous attract mode auto-jumping, and tap-to-jump player control.

const double refW = 1440.0;
const double refH = 512.0;

const double art = 4.8;
const double groundRatio = 393.0 / refH;
const double nearDashRatio = 422.5 / refH;
const double farDashRatio = 448.0 / refH;
const double horizonThick = 4.5;
const double dashThick = 5.0;
const double dashPeriod = 128.0;
const double nearDashOn = 45.0;
const double farDashOn = 23.0;

const double aHorizon = 0.331;
const double aNear = 0.199;
const double aFar = 0.15;
const double aSprite = 0.75; // Enhanced contrast for mobile
const double aCloud = 0.32;
const double blockUnits = 11.0;
const double aHudLabel = 0.40;
const double aHudValue = 0.65;

const List<String> runnerBody = [
  "....########....",
  "..############..",
  ".##############.",
  "################",
  "################",
  "###..######..###",
  "###..######..###",
  "################",
  "################",
  "################",
  "###..........###",
  ".##############.",
  "..############..",
  "....########....",
];

const List<String> runnerLegsA = [
  "...##......##...",
  "..###......###..",
];

const List<String> runnerLegsB = [
  "..###......###..",
  "...##......##...",
];

const List<String> runnerLegsAir = [
  "..###......###..",
  ".###........###.",
];

const List<String> cloudSprite = [
  "....#####.......",
  "..########..##..",
  "################",
  ".##############.",
];

const List<String> blockSprite = [
  "..############..",
  ".##############.",
  "################",
  "################",
  "################",
  "################",
  "################",
  "################",
  "################",
  "################",
  "################",
  "################",
  "################",
  "################",
  ".##############.",
  "..############..",
];

const List<List<String>> glyphSprites = [
  [
    "..####..",
    "..####..",
    "..####..",
    "..####..",
    "...##...",
    ".######.",
    "........",
    "........",
  ],
  [
    "........",
    ".#....#.",
    ".#....#.",
    ".######.",
    ".#....#.",
    ".#....#.",
    "........",
    "........",
  ],
  [
    "........",
    ".######.",
    "....#...",
    "...#....",
    "..#.....",
    ".######.",
    "........",
    "........",
  ],
  [
    "........",
    "..####..",
    ".#....#.",
    ".#....#.",
    ".#....#.",
    "..####..",
    "........",
    "........",
  ],
];

const Map<String, List<String>> fontData = {
  "0": ["###", "#.#", "#.#", "#.#", "###"],
  "1": [".#.", "##.", ".#.", ".#.", "###"],
  "2": ["###", "..#", "###", "#..", "###"],
  "3": ["###", "..#", "###", "..#", "###"],
  "4": ["#.#", "#.#", "###", "..#", "..#"],
  "5": ["###", "#..", "###", "..#", "###"],
  "6": ["###", "#..", "###", "#.#", "###"],
  "7": ["###", "..#", "..#", "..#", "..#"],
  "8": ["###", "#.#", "###", "#.#", "###"],
  "9": ["###", "#.#", "###", "..#", "###"],
  "S": ["###", "#..", "###", "..#", "###"],
  "C": ["###", "#..", "#..", "#..", "###"],
  "O": ["###", "#.#", "#.#", "#.#", "###"],
  "R": ["###", "#.#", "###", "#.#", "#.#"],
  "E": ["###", "#..", "###", "#..", "###"],
  "B": ["##.", "#.#", "##.", "#.#", "##."],
  "T": ["###", ".#.", ".#.", ".#.", ".#."],
  " ": ["...", "...", "...", "...", "..."],
};

class Obstacle {
  double x;
  int stack;
  int glyph;
  Obstacle({required this.x, required this.stack, required this.glyph});
}

class Cloud {
  double x;
  double y;
  double scale;
  double depth;
  Cloud({required this.x, required this.y, required this.scale, required this.depth});
}

class PixelWorld {
  double t = 0;
  double dist = 0;
  double speed = 420;
  double playerY = 0;
  double playerV = 0;
  bool grounded = true;
  List<Obstacle> obstacles = [];
  List<Cloud> clouds = [];
  bool dead = false;
  double deadAt = 0;
  double score = 0;
  double best = 0;
  double nextGap = 180;
  int seed = 20260818;
  bool played = false;

  PixelWorld({required this.speed, required this.best, required this.played});
}

double _rng(PixelWorld w) {
  w.seed = (w.seed * 1664525 + 1013904223) & 0xFFFFFFFF;
  return w.seed / 4294967296.0;
}

class PixelRunGameWidget extends StatefulWidget {
  final Color background;
  final Color ink;
  final Color? runnerColor;
  final double startSpeed;
  final double maxSpeed;
  final double gravity;
  final double jump;
  final bool showHud;
  final bool attract;
  final double farDashSpeed;
  final double height;
  final VoidCallback? onJump;

  const PixelRunGameWidget({
    super.key,
    this.background = const Color(0xFF00164C),
    this.ink = Colors.white,
    this.runnerColor,
    this.startSpeed = 420,
    this.maxSpeed = 980,
    this.gravity = 4780,
    this.jump = 1480,
    this.showHud = true,
    this.attract = true,
    this.farDashSpeed = 100,
    this.height = 115,
    this.onJump,
  });

  @override
  State<PixelRunGameWidget> createState() => _PixelRunGameWidgetState();
}

class _PixelRunGameWidgetState extends State<PixelRunGameWidget>
    with SingleTickerProviderStateMixin {
  late PixelWorld _world;
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  Size _lastSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _world = PixelWorld(
      speed: widget.startSpeed,
      best: 0,
      played: false,
    );

    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    if (_lastSize.width > 0 && _lastSize.height > 0) {
      _step(math.min(0.05, dt), _lastSize.width, _lastSize.height);
      if (mounted) setState(() {});
    }
  }

  void _seedWorld(double w, double h) {
    final s = _calcScale(w, h);
    final px = art * s;

    _world.clouds = [
      Cloud(x: w * 0.17, y: 0.18, scale: 1.15, depth: 0.2),
      Cloud(x: w * 0.44, y: 0.11, scale: 0.85, depth: 0.7),
      Cloud(x: w * 0.78, y: 0.26, scale: 1.35, depth: 0.45),
    ];

    final sp = widget.startSpeed * s;
    _world.obstacles = [];
    final initConfigs = [
      (0.68, 1, 0),
      (1.22, 2, 2),
    ];

    for (final cfg in initConfigs) {
      final at = cfg.$1;
      int stack = cfg.$2;
      final glyph = cfg.$3;

      while (stack > 0 && !_jumpWindow(stack, sp, s).ok) {
        stack--;
      }
      if (stack > 0) {
        _world.obstacles.add(Obstacle(x: w * at, stack: stack, glyph: glyph));
      }
    }

    _world.dist = 40.0 * px;
  }

  double _calcScale(double w, double h) {
    // Mobile responsive scale calculation
    return math.max(0.30, math.min(w / refW * 2.2, h / refH * 2.0));
  }

  ({bool ok, double lead}) _jumpWindow(int stack, double sp, double s) {
    final px = art * s;
    final v = widget.jump * s;
    final g = widget.gravity * s;
    final top = stack * blockUnits * px;
    final disc = v * v - 2.0 * g * top;

    final tX = (10.0 * px + blockUnits * px * 0.76) / sp;
    if (disc <= 0) return (ok: false, lead: 0.22);
    final root = math.sqrt(disc);
    final t1 = (v - root) / g;
    final t2 = (v + root) / g;

    final clearWindow = t2 - t1;
    final ok = clearWindow > tX * 1.1;
    final lead = t1 + (clearWindow - tX) / 2.0;

    return (
      ok: ok,
      lead: lead > 0 ? lead : 0.22,
    );
  }

  void _doJump() {
    if (_world.dead || !_world.grounded) return;
    final s = _calcScale(
      _lastSize.width > 0 ? _lastSize.width : 360,
      _lastSize.height > 0 ? _lastSize.height : widget.height,
    );
    _world.playerV = widget.jump * s;
    _world.grounded = false;
    _world.played = true;
    widget.onJump?.call();
  }

  void _step(double dt, double w, double h) {
    final s = _calcScale(w, h);
    final px = art * s;
    final groundY = h * groundRatio;
    final playerX = w * 0.08;

    _world.t += dt;

    if (_world.dead) {
      if (_world.t - _world.deadAt > 0.5) {
        final best = math.max(_world.best, _world.score);
        final played = _world.played;
        _world = PixelWorld(
          speed: widget.startSpeed,
          best: best,
          played: played,
        );
        _seedWorld(w, h);
      }
      return;
    }

    final base = widget.startSpeed;
    final cap = math.max(base, widget.maxSpeed);
    final sp = math.min(cap, base + _world.dist / 260.0) * s;
    _world.speed = sp;
    _world.dist += sp * dt;
    _world.score = _world.dist / 24.0;

    if (!_world.grounded) {
      _world.playerV -= widget.gravity * s * dt;
      _world.playerY += _world.playerV * dt;
      if (_world.playerY <= 0) {
        _world.playerY = 0;
        _world.playerV = 0;
        _world.grounded = true;
      }
    }

    // Move obstacles
    for (final ob in _world.obstacles) {
      ob.x -= sp * dt;
    }
    _world.obstacles.removeWhere((o) => o.x < -20.0 * px);

    final lastX = _world.obstacles.isNotEmpty
        ? _world.obstacles.map((o) => o.x).reduce(math.max)
        : -double.infinity;

    final flight = 2.0 * widget.jump / widget.gravity;
    final clearDist = (sp / s) * flight + (blockUnits + 20.0) * art;
    if (lastX < w - (clearDist + _world.nextGap) * s) {
      final r = _rng(_world);
      int stack = r < 0.60 ? 1 : 2;

      while (stack > 0 && !_jumpWindow(stack, sp, s).ok) {
        stack--;
      }
      if (stack > 0) {
        _world.obstacles.add(
          Obstacle(
            x: w + 8.0 * px,
            stack: stack,
            glyph: ( _rng(_world) * glyphSprites.length).floor() % glyphSprites.length,
          ),
        );
      }
      _world.nextGap = 160.0 + _rng(_world) * 320.0;
    }

    // Move clouds
    for (final cl in _world.clouds) {
      cl.x -= sp * dt * (0.12 + 0.22 * cl.depth);
    }
    _world.clouds.removeWhere((c) => c.x < -30.0 * px);
    if (_world.clouds.length < 5 && _rng(_world) < 0.012) {
      _world.clouds.add(
        Cloud(
          x: w + 10.0 * px,
          y: 0.10 + _rng(_world) * 0.42,
          scale: 0.75 + _rng(_world) * 0.90,
          depth: _rng(_world),
        ),
      );
    }

    // Autonomous attract mode (auto-jumps so game stays alive and plays automatically)
    final auto = widget.attract;
    if (auto && _world.grounded) {
      final bu = blockUnits * px;
      final plFront = playerX + 13.0 * px;
      Obstacle? nextOb;
      double gap = double.infinity;
      for (final ob in _world.obstacles) {
        final left = ob.x + bu * 0.12;
        if (left + bu * 0.76 <= plFront) continue;
        if (left - plFront < gap) {
          gap = left - plFront;
          nextOb = ob;
        }
      }

      if (nextOb != null) {
        final win = _jumpWindow(nextOb.stack, sp, s);
        final leadTime = win.lead;
        final triggerDist = sp * leadTime;
        if (gap <= triggerDist && gap > -5.0 * px) {
          _doJump();
        }
      }
    }

    // Collision detection
    final plBox = Rect.fromLTWH(
      playerX + 5.0 * px,
      groundY - _world.playerY - 14.0 * px,
      6.0 * px,
      12.0 * px,
    );

    for (final ob in _world.obstacles) {
      final bu = blockUnits * px;
      final obBox = Rect.fromLTWH(
        ob.x + bu * 0.18,
        groundY - ob.stack * bu,
        bu * 0.64,
        ob.stack * bu,
      );

      if (plBox.overlaps(obBox)) {
        _world.dead = true;
        _world.deadAt = _world.t;
        _world.best = math.max(_world.best, _world.score);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _doJump();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth > 0 ? constraints.maxWidth : 360.0;
          final h = widget.height > 0 ? widget.height : 115.0;

          if (_lastSize != Size(w, h)) {
            _lastSize = Size(w, h);
            if (_world.obstacles.isEmpty) {
              _seedWorld(w, h);
            }
          }

          return CustomPaint(
            size: Size(w, h),
            painter: _PixelRunPainter(
              world: _world,
              background: widget.background,
              ink: widget.ink,
              runnerColor: widget.runnerColor ?? Colors.cyanAccent.shade200,
              showHud: widget.showHud,
              farDashSpeed: widget.farDashSpeed,
              scale: _calcScale(w, h),
            ),
          );
        },
      ),
    );
  }
}

class _PixelRunPainter extends CustomPainter {
  final PixelWorld world;
  final Color background;
  final Color ink;
  final Color runnerColor;
  final bool showHud;
  final double farDashSpeed;
  final double scale;

  _PixelRunPainter({
    required this.world,
    required this.background,
    required this.ink,
    required this.runnerColor,
    required this.showHud,
    required this.farDashSpeed,
    required this.scale,
  });

  void _stamp(
    Canvas canvas,
    List<String> rows,
    double ox,
    double oy,
    double unit,
    Paint paint,
  ) {
    for (int r = 0; r < rows.length; r++) {
      final y0 = (oy + r * unit).roundToDouble();
      final y1 = (oy + (r + 1) * unit).roundToDouble();
      int c = 0;
      final row = rows[r];
      while (c < row.length) {
        if (row[c] != '#') {
          c++;
          continue;
        }
        int e = c;
        while (e < row.length && row[e] == '#') {
          e++;
        }
        final x0 = (ox + c * unit).roundToDouble();
        final x1 = (ox + e * unit).roundToDouble();
        canvas.drawRect(Rect.fromLTRB(x0, y0, x1, y1), paint);
        c = e;
      }
    }
  }

  void _blit(
    Canvas canvas,
    List<String> rows,
    double ox,
    double oy,
    double unit,
    Color color, {
    List<String>? knock,
    Color? knockColor,
  }) {
    final paint = Paint()..color = color;
    _stamp(canvas, rows, ox, oy, unit, paint);
    if (knock != null && knockColor != null) {
      final knockPaint = Paint()..color = knockColor;
      final kx = ox + ((rows[0].length - knock[0].length) / 2.0) * unit;
      final ky = oy + ((rows.length - knock.length) / 2.0) * unit;
      _stamp(canvas, knock, kx, ky, unit, knockPaint);
    }
  }

  void _drawPixelText(
    Canvas canvas,
    String text,
    double rightX,
    double y,
    Color color,
    double fpx,
  ) {
    final cw = 4.0 * fpx;
    final total = text.length * cw - fpx;
    double x = rightX - total;
    final paint = Paint()..color = color;

    for (int i = 0; i < text.length; i++) {
      final ch = text[i];
      final glyph = fontData[ch] ?? fontData[' ']!;
      for (int r = 0; r < 5; r++) {
        for (int c = 0; c < 3; c++) {
          if (glyph[r][c] == '#') {
            final x0 = (x + c * fpx).roundToDouble();
            final y0 = (y + r * fpx).roundToDouble();
            final x1 = (x + (c + 1) * fpx).roundToDouble();
            final y1 = (y + (r + 1) * fpx).roundToDouble();
            canvas.drawRect(Rect.fromLTRB(x0, y0, x1, y1), paint);
          }
        }
      }
      x += cw;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final s = scale;
    final px = art * s;
    final groundY = h * groundRatio;
    final playerX = w * 0.08;

    // 1. Clear background
    final bgPaint = Paint()..color = background;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // 2. Parallax clouds
    for (final cl in world.clouds) {
      final cloudAlpha = (aCloud * (0.7 + 0.3 * cl.depth)).clamp(0.0, 1.0);
      _blit(
        canvas,
        cloudSprite,
        cl.x,
        cl.y * h,
        px * cl.scale,
        ink.withValues(alpha: cloudAlpha),
      );
    }

    // 3. Ground Horizon Line
    final horizonPaint = Paint()
      ..color = ink.withValues(alpha: aHorizon);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        groundY.roundToDouble(),
        w,
        math.max(1.0, (horizonThick * s).roundToDouble()),
      ),
      horizonPaint,
    );

    // 4. Dashed speed lines
    void drawDashRow(double ratio, double onDash, double alpha, double phase) {
      final period = dashPeriod * s;
      final len = onDash * s;
      final y = (h * ratio).roundToDouble();
      final th = math.max(1.0, (dashThick * s).roundToDouble());
      final paint = Paint()..color = ink.withValues(alpha: alpha);
      final start = -((phase % period) + period) % period;
      for (double x = start; x < w; x += period) {
        canvas.drawRect(
          Rect.fromLTWH(x.roundToDouble(), y, len.roundToDouble(), th),
          paint,
        );
      }
    }

    drawDashRow(nearDashRatio, nearDashOn, aNear, world.dist);
    final farMul = farDashSpeed / 100.0;
    drawDashRow(farDashRatio, farDashOn, aFar, world.dist * farMul);

    // 5. Obstacles
    final bu = blockUnits * px;
    for (final ob in world.obstacles) {
      for (int i = 0; i < ob.stack; i++) {
        _blit(
          canvas,
          blockSprite,
          ob.x,
          groundY - (i + 1) * bu,
          bu / 16.0,
          ink.withValues(alpha: aSprite),
          knock: glyphSprites[(ob.glyph + i) % glyphSprites.length],
          knockColor: background,
        );
      }
    }

    // 6. Pixel Runner
    final bodyH = runnerBody.length * px;
    final feet = groundY - world.playerY;

    // Body
    _blit(
      canvas,
      runnerBody,
      playerX,
      feet - bodyH - 2.0 * px,
      px,
      runnerColor,
    );

    // Legs animation
    final legs = !world.grounded
        ? runnerLegsAir
        : ((world.dist / (28.0 * s)).floor() % 2 == 1
            ? runnerLegsA
            : runnerLegsB);

    _blit(
      canvas,
      legs,
      playerX,
      feet - 2.0 * px,
      px,
      runnerColor,
    );

    // 7. Retro Score & Best HUD
    if (showHud) {
      final fpx = 2.4 * s;
      final padScore = world.score.floor().toString().padLeft(5, '0');
      final padBest = world.best.floor().toString().padLeft(5, '0');

      final rightBest = w - 16.0 * s;
      final rightScore = rightBest - 95.0 * s;
      final labelY = h * 0.08;
      final valueY = h * 0.18;

      _drawPixelText(canvas, "SCORE", rightScore, labelY, ink.withValues(alpha: aHudLabel), fpx);
      _drawPixelText(canvas, padScore, rightScore, valueY, ink.withValues(alpha: aHudValue), fpx);
      _drawPixelText(canvas, "BEST", rightBest, labelY, ink.withValues(alpha: aHudLabel), fpx);
      _drawPixelText(canvas, padBest, rightBest, valueY, ink.withValues(alpha: aHudValue), fpx);
    }
  }

  @override
  bool shouldRepaint(covariant _PixelRunPainter oldDelegate) => true;
}
