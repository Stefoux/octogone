import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../features/cards/effects.dart';
import '../features/cards/holo_layer.dart';
import 'octagon.dart';

/// Logo de l'app (celui de l'écran d'entrée) : octogone noir au motif
/// holographique multicolore, cadre en métal noir et liseré doré.
/// [child] s'affiche au centre ; [glow] ajoute le halo doré.
class OctagonEmblem extends StatelessWidget {
  const OctagonEmblem({super.key, required this.size, this.child, this.animate = true, this.glow = false});

  final double size;
  final Widget? child;
  final bool animate;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(fit: StackFit.expand, alignment: Alignment.center, clipBehavior: Clip.none, children: [
        if (glow)
          Transform.scale(
            scale: 1.5,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0x47E2B04F), Color(0x0FE2B04F), Colors.transparent],
                  stops: [0.35, 0.6, 1],
                ),
              ),
            ),
          ),
        ClipPath(
          clipper: const OctagonClipper(),
          child: Stack(fit: StackFit.expand, children: [
            const DecoratedBox(
              decoration: BoxDecoration(gradient: RadialGradient(colors: [Color(0xFF1E1E1E), Color(0xFF070707)])),
            ),
            RepaintBoundary(
              child: HoloLayer(
                spec: const EffectSpec(mode: 14, blend: BlendMode.screen, animated: true, intensity: 0.8),
                tilt: Offset.zero,
                animate: animate && !(MediaQuery.maybeDisableAnimationsOf(context) ?? false),
              ),
            ),
          ]),
        ),
        CustomPaint(painter: _RimPainter()),
        if (child != null) Center(child: child),
      ]),
    );
  }
}

/// Cadre identique à celui de l'écran d'entrée : bord en métal noir,
/// liseré doré extérieur légèrement lumineux, filet doré intérieur.
class _RimPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawPath(
      octagonPath(c, r * 0.965),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.07
        ..shader = const SweepGradient(
          colors: [Color(0xFF050505), Color(0xFF3A3A3A), Color(0xFF0A0A0A), Color(0xFF4A4A4A), Color(0xFF050505)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawPath(
      octagonPath(c, r * 0.86),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.gold.withValues(alpha: 0.35),
    );
    final edge = octagonPath(c, r - 1.2);
    canvas
      ..drawPath(
        edge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = AppColors.gold.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      )
      ..drawPath(
        edge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = const Color(0xFFF3D38A),
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
