import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'octagon.dart';

/// Fond derrière une carte, propre à sa rareté et de plus en plus
/// spectaculaire : simple dégradé pour une Commune, rayons qui tournent et
/// étincelles pour une Légendaire, aura pulsée et braises pour une Mythique.
/// Ne touche qu'au fond (la carte et la logique de rareté sont inchangées).
class RarityBackdrop extends StatefulWidget {
  const RarityBackdrop({super.key, required this.rarete, this.child});

  final String rarete;
  final Widget? child;

  @override
  State<RarityBackdrop> createState() => _RarityBackdropState();
}

class _RarityBackdropState extends State<RarityBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(vsync: this, duration: const Duration(seconds: 24));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _t
        ..stop()
        ..value = 0.15;
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
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: Motion.slow,
          child: KeyedSubtree(key: ValueKey(widget.rarete), child: _layers(widget.rarete)),
        ),
        ?widget.child,
      ],
    );
  }

  Widget _layers(String r) {
    final c = AppColors.rarity[r] ?? AppColors.steel;
    final rank = const ['commune', 'peu_commune', 'rare', 'epique', 'legendaire', 'mythique'].indexOf(r);
    final deep = switch (r) {
      'mythique' => const Color(0xFF1A0509),
      'legendaire' => const Color(0xFF1A1206),
      'epique' => const Color(0xFF130820),
      'rare' => const Color(0xFF070F22),
      'peu_commune' => const Color(0xFF0B1319),
      _ => AppColors.background,
    };
    return Stack(
      fit: StackFit.expand,
      children: [
        // Dégradé de base à la couleur de la rareté
        RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.15),
                radius: 1.05,
                colors: [
                  Color.lerp(deep, c, 0.16 + 0.04 * rank.clamp(0, 5))!,
                  deep,
                  Color.lerp(deep, Colors.black, 0.5)!,
                ],
                stops: const [0, 0.6, 1],
              ),
            ),
          ),
        ),
        // Peu commune et plus : nappe de lumière qui respire
        if (rank >= 1)
          _Anim(
            t: _t,
            builder: (v, child) => Opacity(opacity: 0.55 + 0.45 * math.sin(v * 2 * math.pi * 3).abs(), child: child),
            child: RepaintBoundary(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.75,
                    colors: [
                      c.withValues(alpha: 0.10 + 0.05 * rank),
                      c.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // Rare et plus : reflet qui balaie l'écran en diagonale
        if (rank >= 2)
          _Anim(
            t: _t,
            builder: (v, child) {
            // Le reflet s'efface aux extrémités : pas de saut quand il repart
            final p = (v * 4) % 1.0;
            return Opacity(
              opacity: math.sin(p * math.pi),
              child: FractionalTranslation(translation: Offset(p * 4 - 2, 0), child: child),
            );
          },
            child: RepaintBoundary(child: _Sweep(color: c)),
          ),
        // Épique et plus : rayons qui tournent lentement
        if (rank >= 3)
          _Anim(
            t: _t,
            builder: (v, child) => Transform.rotate(angle: v * 2 * math.pi, child: child),
            child: RepaintBoundary(
              child: _Rays(color: c, count: rank >= 5 ? 18 : 14, alpha: 0.05 + 0.025 * (rank - 3)),
            ),
          ),
        // Mythique : seconde couronne de rayons en sens inverse, teinte magenta
        if (rank >= 5)
          _Anim(
            t: _t,
            builder: (v, child) => Transform.rotate(angle: -v * 2 * math.pi * 1.5, child: child),
            child: const RepaintBoundary(child: _Rays(color: Color(0xFFFF2DA6), count: 10, alpha: 0.05)),
          ),
        // Légendaire et plus : octogone lumineux qui pulse derrière la carte
        if (rank >= 4)
          _Anim(
            t: _t,
            builder: (v, child) {
              final p = (v * 6) % 1.0;
              return Opacity(
                opacity: math.sin(p * math.pi) * (1 - p * 0.5) * (rank >= 5 ? 0.75 : 0.5),
                child: Transform.scale(scale: 0.7 + p * 0.7, child: child),
              );
            },
            child: RepaintBoundary(child: _OctagonRing(color: c)),
          ),
        // Légendaire et plus : étincelles qui montent
        if (rank >= 4)
          RepaintBoundary(
            child: CustomPaint(
              painter: _SparksPainter(_t, color: c, count: rank >= 5 ? 26 : 16, embers: rank >= 5),
            ),
          ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(radius: 1.15, colors: [Colors.transparent, Color(0xAA000000)], stops: [0.5, 1]),
            ),
          ),
        ),
      ],
    );
  }
}

class _Anim extends StatelessWidget {
  const _Anim({required this.t, required this.builder, required this.child});
  final Animation<double> t;
  final Widget Function(double v, Widget child) builder;
  final Widget child;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(animation: t, child: child, builder: (context, child) => builder(t.value, child!)),
  );
}

class _Sweep extends StatelessWidget {
  const _Sweep({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: -0.5,
    child: FractionallySizedBox(
      widthFactor: 0.45,
      heightFactor: 2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0),
              Color.lerp(color, Colors.white, 0.5)!.withValues(alpha: 0.10),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Rays extends StatelessWidget {
  const _Rays({required this.color, required this.count, required this.alpha});
  final Color color;
  final int count;
  final double alpha;

  @override
  Widget build(BuildContext context) => OverflowBox(
    maxWidth: double.infinity,
    maxHeight: double.infinity,
    child: LayoutBuilder(
      builder: (context, _) {
        final s = MediaQuery.sizeOf(context).longestSide * 1.6;
        return SizedBox(
          width: s,
          height: s,
          child: CustomPaint(painter: _RaysPainter(color, count, alpha)),
        );
      },
    ),
  );
}

class _RaysPainter extends CustomPainter {
  _RaysPainter(this.color, this.count, this.alpha);
  final Color color;
  final int count;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: alpha * 3),
          color.withValues(alpha: alpha),
          color.withValues(alpha: 0),
        ],
        stops: const [0, 0.35, 1],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    final w = math.pi / count * 0.55;
    for (var i = 0; i < count; i++) {
      final a = i * 2 * math.pi / count;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + math.cos(a - w) * r, c.dy + math.sin(a - w) * r)
        ..lineTo(c.dx + math.cos(a + w) * r, c.dy + math.sin(a + w) * r)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RaysPainter old) => old.color != color || old.count != count || old.alpha != alpha;
}

class _OctagonRing extends StatelessWidget {
  const _OctagonRing({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _RingPainter(color), size: Size.infinite);
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = octagonPath(size.center(Offset.zero), size.shortestSide * 0.48);
    canvas
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..color = color.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      )
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = Color.lerp(color, Colors.white, 0.4)!.withValues(alpha: 0.8),
      );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.color != color;
}

class _SparksPainter extends CustomPainter {
  _SparksPainter(this.t, {required this.color, required this.count, required this.embers}) : super(repaint: t);
  final Animation<double> t;
  final Color color;
  final int count;
  final bool embers;

  static final _seeds = List.generate(32, (i) {
    final r = math.Random(i * 104729 + 7);
    return (r.nextDouble(), r.nextDouble(), 1.0 + r.nextDouble() * 2.2, 2 + r.nextInt(4));
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (var i = 0; i < count; i++) {
      final (x0, phase, radius, speed) = _seeds[i];
      final v = (t.value * speed + phase) % 1.0;
      final x = (x0 + math.sin((v * 2 + phase) * 2 * math.pi) * 0.025) * size.width;
      final y = size.height * (1.05 - v * 1.15);
      final fade = math.sin(v * math.pi);
      final col = embers && i.isOdd ? const Color(0xFFFF8A3D) : Color.lerp(color, Colors.white, 0.35)!;
      p.color = col.withValues(alpha: 0.75 * fade);
      canvas.drawCircle(Offset(x, y), radius, p);
    }
  }

  @override
  bool shouldRepaint(covariant _SparksPainter old) => old.color != color || old.count != count || old.embers != embers;
}
