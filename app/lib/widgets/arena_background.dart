import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'octagon.dart';

/// Ambiance « soir de combat » derrière les écrans : faisceaux de projecteurs,
/// fumée, poussière en suspension, motif d'octogone et grain.
///
/// Chaque calque est dessiné une seule fois (RepaintBoundary) puis animé
/// uniquement par transform/opacity ; seule la poussière (quelques points)
/// est repeinte à chaque image. Si le téléphone demande de réduire les
/// animations, l'ambiance reste fixe.
class ArenaBackground extends StatefulWidget {
  const ArenaBackground({super.key, this.intensity = 1, this.accent = AppColors.gold, this.child});

  /// 0 (discret, écrans de lecture) à 1 (accueil, écran d'entrée).
  final double intensity;
  final Color accent;
  final Widget? child;

  @override
  State<ArenaBackground> createState() => _ArenaBackgroundState();
}

class _ArenaBackgroundState extends State<ArenaBackground> with SingleTickerProviderStateMixin {
  // Une boucle lente commune : toutes les positions en dérivent (sinus).
  late final AnimationController _t = AnimationController(vsync: this, duration: const Duration(seconds: 40));
  bool _reduce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reduce) {
      _t.stop();
      _t.value = 0.3;
    } else if (!_t.isAnimating) {
      _t.repeat();
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: widget.intensity.clamp(0.0, 1.0)),
      duration: Motion.slow,
      curve: Curves.easeInOut,
      builder: (context, k, child) => Stack(
        fit: StackFit.expand,
        children: [
          const RepaintBoundary(child: _Base()),
          // Motif d'octogone qui glisse très lentement
          _Drift(
            t: _t,
            builder: (v) => Matrix4.translationValues(math.sin(v * 2 * math.pi) * 14, v * 60 - 30, 0),
            child: Opacity(
              opacity: 0.35 + 0.35 * k,
              child: const RepaintBoundary(child: _OctagonPattern()),
            ),
          ),
          // Fumée : trois nappes qui dérivent
          for (final s in _smokes)
            _Drift(
              t: _t,
              builder: (v) {
                final a = (v * s.speed + s.phase) * 2 * math.pi;
                return Matrix4.identity()
                  ..translateByDouble(math.sin(a) * s.dx, math.cos(a * 0.7) * s.dy, 0, 1)
                  ..scaleByDouble(1 + 0.08 * math.sin(a * 1.3), 1 + 0.08 * math.sin(a * 1.3), 1, 1);
              },
              child: Align(
                alignment: s.align,
                child: FractionallySizedBox(
                  widthFactor: s.size,
                  heightFactor: s.size * 0.7,
                  child: Opacity(
                    opacity: (0.10 + 0.14 * k) * s.alpha,
                    child: RepaintBoundary(child: _Blob(color: s.warm ? widget.accent : const Color(0xFF8E8A84))),
                  ),
                ),
              ),
            ),
          // Faisceaux de projecteurs (seulement en ambiance forte)
          if (k > 0.02)
            for (final b in _beams)
              _Drift(
                t: _t,
                builder: (v) => Matrix4.rotationZ(b.angle + math.sin((v * b.speed + b.phase) * 2 * math.pi) * 0.07),
                alignment: b.origin,
                child: Opacity(
                  opacity: k * b.alpha,
                  child: RepaintBoundary(
                    child: _Beam(color: widget.accent, origin: b.origin),
                  ),
                ),
              ),
          // Poussière en suspension dans la lumière
          RepaintBoundary(
            child: CustomPaint(
              painter: _DustPainter(_t, count: (8 + 16 * k).round(), color: widget.accent, strength: 0.5 + 0.5 * k),
            ),
          ),
          const IgnorePointer(child: RepaintBoundary(child: _Vignette())),
          const IgnorePointer(child: RepaintBoundary(child: _Grain())),
          ?child,
        ],
      ),
      child: widget.child,
    );
  }
}

/// Applique une transformation calculée à partir de la boucle commune.
class _Drift extends StatelessWidget {
  const _Drift({required this.t, required this.builder, required this.child, this.alignment = Alignment.center});
  final Animation<double> t;
  final Matrix4 Function(double v) builder;
  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: t,
      child: child,
      builder: (context, child) => Transform(transform: builder(t.value), alignment: alignment, child: child),
    ),
  );
}

class _SmokeSpec {
  const _SmokeSpec(this.align, this.size, this.dx, this.dy, this.speed, this.phase, this.alpha, this.warm);
  final Alignment align;
  final double size, dx, dy, speed, phase, alpha;
  final bool warm;
}

const _smokes = [
  _SmokeSpec(Alignment(-0.9, -0.6), 1.3, 40, 24, 1, 0.0, 1.0, true),
  _SmokeSpec(Alignment(0.9, 0.2), 1.2, 50, 30, 1, 0.33, 0.8, false),
  _SmokeSpec(Alignment(-0.3, 1.0), 1.5, 36, 20, 2, 0.66, 0.7, false),
];

class _BeamSpec {
  const _BeamSpec(this.origin, this.angle, this.speed, this.phase, this.alpha);
  final Alignment origin;
  final double angle, speed, phase, alpha;
}

const _beams = [
  _BeamSpec(Alignment(-0.75, -1.05), -0.32, 1, 0.0, 0.55),
  _BeamSpec(Alignment(0.8, -1.05), 0.34, 1, 0.5, 0.45),
  _BeamSpec(Alignment(0.0, -1.1), 0.0, 2, 0.25, 0.3),
];

class _Base extends StatelessWidget {
  const _Base();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(0, -0.35),
        radius: 1.25,
        colors: [Color(0xFF221D16), Color(0xFF13110E), AppColors.background],
        stops: [0, 0.55, 1],
      ),
    ),
  );
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.35), color.withValues(alpha: 0)],
        stops: const [0, 0.45, 1],
      ),
    ),
  );
}

/// Cône de lumière qui part du bord haut.
class _Beam extends StatelessWidget {
  const _Beam({required this.color, required this.origin});
  final Color color;
  final Alignment origin;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _BeamPainter(color, origin), size: Size.infinite);
}

class _BeamPainter extends CustomPainter {
  _BeamPainter(this.color, this.origin);
  final Color color;
  final Alignment origin;

  @override
  void paint(Canvas canvas, Size size) {
    final o = origin.alongSize(size);
    final len = size.height * 1.15;
    final spread = size.width * 0.32;
    final path = Path()
      ..moveTo(o.dx - 6, o.dy)
      ..lineTo(o.dx + 6, o.dy)
      ..lineTo(o.dx + spread, o.dy + len)
      ..lineTo(o.dx - spread, o.dy + len)
      ..close();
    final rect = Rect.fromLTWH(o.dx - spread, o.dy, spread * 2, len);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, Colors.white, 0.6)!.withValues(alpha: 0.22),
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
  }

  @override
  bool shouldRepaint(covariant _BeamPainter old) => old.color != color || old.origin != origin;
}

class _OctagonPattern extends StatelessWidget {
  const _OctagonPattern();

  @override
  Widget build(BuildContext context) => Transform.scale(
    scale: 1.15,
    child: const CustomPaint(painter: _OctagonPatternPainter(), size: Size.infinite),
  );
}

class _OctagonPatternPainter extends CustomPainter {
  const _OctagonPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const r = 46.0;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.gold.withValues(alpha: 0.05);
    for (var y = -r; y < size.height + r; y += r * 1.75) {
      final row = ((y + r) / (r * 1.75)).round();
      for (var x = -r; x < size.width + r; x += r * 1.75) {
        canvas.drawPath(octagonPath(Offset(x + (row.isOdd ? r * 0.875 : 0), y), r * 0.78), line);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DustPainter extends CustomPainter {
  _DustPainter(this.t, {required this.count, required this.color, required this.strength}) : super(repaint: t);
  final Animation<double> t;
  final int count;
  final Color color;
  final double strength;

  static final _seeds = List.generate(32, (i) {
    final r = math.Random(i * 7919 + 13);
    return (r.nextDouble(), r.nextDouble(), 0.6 + r.nextDouble() * 1.8, r.nextDouble(), 1 + r.nextInt(3));
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < count && i < _seeds.length; i++) {
      final (x0, y0, radius, phase, speed) = _seeds[i];
      final v = (t.value * speed + phase) % 1.0;
      final x = (x0 + math.sin((v + phase) * 2 * math.pi) * 0.03) * size.width;
      final y = (y0 - v * 0.35) % 1.0 * size.height;
      final twinkle = 0.5 + 0.5 * math.sin((v * 6 + phase) * 2 * math.pi);
      paint.color = Color.lerp(color, Colors.white, 0.5)!.withValues(alpha: 0.1 + 0.35 * twinkle * strength);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DustPainter old) =>
      old.count != count || old.color != color || old.strength != strength;
}

class _Vignette extends StatelessWidget {
  const _Vignette();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(radius: 1.1, colors: [Colors.transparent, Color(0x99000000)], stops: [0.55, 1]),
    ),
  );
}

/// Grain fixe (dessiné une fois) pour casser l'aspect numérique trop lisse.
class _Grain extends StatelessWidget {
  const _Grain();

  @override
  Widget build(BuildContext context) => const CustomPaint(painter: _GrainPainter(), size: Size.infinite);
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(42);
    final light = Paint()..color = Colors.white.withValues(alpha: 0.035);
    final dark = Paint()..color = Colors.black.withValues(alpha: 0.12);
    final n = (size.width * size.height / 260).clamp(0, 5000).toInt();
    final pts = <Offset>[];
    final pts2 = <Offset>[];
    for (var i = 0; i < n; i++) {
      (i.isEven ? pts : pts2).add(Offset(r.nextDouble() * size.width, r.nextDouble() * size.height));
    }
    canvas
      ..drawRawPoints(_mode, _f(pts), light..strokeWidth = 1.2)
      ..drawRawPoints(_mode, _f(pts2), dark..strokeWidth = 1.2);
  }

  static const _mode = PointMode.points;

  static Float32List _f(List<Offset> pts) {
    final l = Float32List(pts.length * 2);
    for (var i = 0; i < pts.length; i++) {
      l[i * 2] = pts[i].dx;
      l[i * 2 + 1] = pts[i].dy;
    }
    return l;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
