import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Contour néon qui pulse (Néon Main Event, Face-à-Face).
class NeonOutline extends StatefulWidget {
  const NeonOutline({super.key, this.animate = true, this.radius = 9});
  final bool animate;
  final double radius;

  @override
  State<NeonOutline> createState() => _NeonOutlineState();
}

class _NeonOutlineState extends State<NeonOutline> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _NeonPainter(widget.animate ? _c.value : 0.6, widget.radius),
        ),
      ),
    );
  }
}

class _NeonPainter extends CustomPainter {
  _NeonPainter(this.t, this.radius);
  final double t;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final color = Color.lerp(const Color(0xFFFF2DA6), const Color(0xFF26E7FF), t)!;
    final rect = RRect.fromRectAndRadius((Offset.zero & size).deflate(3), Radius.circular(radius));
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = color.withValues(alpha: 0.35 + 0.35 * t)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = Color.lerp(color, Colors.white, 0.45)!;
    canvas
      ..drawRRect(rect, glow)
      ..drawRRect(rect, line);
  }

  @override
  bool shouldRepaint(covariant _NeonPainter old) => old.t != t;
}

/// Verre fissuré (Cicatrice) : fissures qui partent d'un point d'impact.
/// [seed] rend le motif propre à chaque carte et stable d'un affichage à l'autre.
class CracksOverlay extends StatelessWidget {
  const CracksOverlay({super.key, required this.seed});
  final int seed;

  @override
  Widget build(BuildContext context) =>
      IgnorePointer(child: CustomPaint(size: Size.infinite, painter: _CracksPainter(seed)));
}

class _CracksPainter extends CustomPainter {
  _CracksPainter(this.seed);
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final impact = Offset(size.width * (0.55 + rnd.nextDouble() * 0.2), size.height * (0.22 + rnd.nextDouble() * 0.15));
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..color = Colors.white.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = Colors.white.withValues(alpha: 0.85);
    final maxLen = size.longestSide * 0.9;
    final rings = <double>[22, 48, 85];
    final branches = 9 + rnd.nextInt(4);
    for (var i = 0; i < branches; i++) {
      var angle = (i / branches) * math.pi * 2 + rnd.nextDouble() * 0.4;
      var p = impact;
      final path = Path()..moveTo(p.dx, p.dy);
      final len = maxLen * (0.35 + rnd.nextDouble() * 0.65);
      var travelled = 0.0;
      while (travelled < len) {
        final step = 10 + rnd.nextDouble() * 22;
        angle += (rnd.nextDouble() - 0.5) * 0.5;
        p = p + Offset(math.cos(angle), math.sin(angle)) * step;
        travelled += step;
        path.lineTo(p.dx, p.dy);
        if (rnd.nextDouble() < 0.12) {
          final b = Path()..moveTo(p.dx, p.dy);
          final ba = angle + (rnd.nextBool() ? 0.9 : -0.9);
          b.lineTo(p.dx + math.cos(ba) * 18, p.dy + math.sin(ba) * 18);
          canvas
            ..drawPath(b, glow)
            ..drawPath(b, line);
        }
      }
      canvas
        ..drawPath(path, glow)
        ..drawPath(path, line);
    }
    // Éclats concentriques autour de l'impact
    for (final r in rings) {
      final arcs = Path();
      for (var a = 0.0; a < math.pi * 2; a += 0.55 + rnd.nextDouble() * 0.5) {
        arcs.addArc(Rect.fromCircle(center: impact, radius: r + rnd.nextDouble() * 6), a, 0.25 + rnd.nextDouble() * 0.3);
      }
      canvas.drawPath(arcs, line..color = Colors.white.withValues(alpha: 0.55));
    }
    canvas.drawCircle(impact, 3.5, Paint()..color = Colors.white.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(covariant _CracksPainter old) => old.seed != seed;
}

/// Confettis animés (Main Levée).
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key, this.animate = true, this.seed = 7});
  final bool animate;
  final int seed;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 7));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) =>
              CustomPaint(size: Size.infinite, painter: _ConfettiPainter(widget.animate ? _c.value : 0.35, widget.seed)),
        ),
      );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, this.seed);
  final double t;
  final int seed;
  static const _colors = [Color(0xFFE8B04A), Colors.white, Color(0xFFD7263D), Color(0xFF4F8DFF), Color(0xFFFFF0B8)];

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    for (var i = 0; i < 70; i++) {
      final x0 = rnd.nextDouble();
      final y0 = rnd.nextDouble();
      final speed = 0.6 + rnd.nextDouble() * 0.8;
      final sway = rnd.nextDouble() * 2 * math.pi;
      final y = ((y0 + t * speed) % 1.0) * size.height;
      final x = (x0 * size.width + math.sin(t * 6.28 * 2 + sway) * 8) % size.width;
      final paint = Paint()..color = _colors[i % _colors.length].withValues(alpha: 0.9);
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(t * 12 + sway)
        ..drawRect(Rect.fromCenter(center: Offset.zero, width: 5, height: 2.6), paint)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}

/// Plaque dorée gravée façon ceinture de champion (motif original).
class GoldBeltPlate extends StatelessWidget {
  const GoldBeltPlate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: const LinearGradient(
          colors: [Color(0xFF8C6418), Color(0xFFF5D27A), Color(0xFFB98A2C), Color(0xFFFFF0B8), Color(0xFF8C6418)],
          stops: [0, 0.3, 0.5, 0.72, 1],
        ),
        border: Border.all(color: const Color(0xFF5E420F), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: CustomPaint(painter: _EngravingPainter(), child: child),
    );
  }
}

class _EngravingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFF6B4B12).withValues(alpha: 0.55);
    for (var i = 0; i < 3; i++) {
      final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(-8.0 + i * 4, -4.0 + i * 3, size.width + 16 - i * 8, size.height + 8 - i * 6),
          Radius.circular(30 - i * 6.0));
      canvas.drawRRect(r, p);
    }
    // Rayons gravés de part et d'autre
    for (var i = 0; i < 6; i++) {
      final y = size.height * (0.15 + i * 0.14);
      canvas
        ..drawLine(Offset(-6, y), Offset(6, size.height / 2), p)
        ..drawLine(Offset(size.width + 6, y), Offset(size.width - 6, size.height / 2), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Plaque de musée en laiton (Moment Historique) : vis aux coins, texte gravé.
class MuseumPlaque extends StatelessWidget {
  const MuseumPlaque({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget screw() => Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [Color(0xFFF3E2B6), Color(0xFF6E5428)]),
          ),
        );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C5E2C), Color(0xFFE2C68C), Color(0xFFA9864A), Color(0xFFD9BC80)],
        ),
        border: Border.all(color: const Color(0xFF4A3718), width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Stack(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), child: child),
        Positioned(left: 4, top: 4, child: screw()),
        Positioned(right: 4, top: 4, child: screw()),
        Positioned(left: 4, bottom: 4, child: screw()),
        Positioned(right: 4, bottom: 4, child: screw()),
      ]),
    );
  }
}
