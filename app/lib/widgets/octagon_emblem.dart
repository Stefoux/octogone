import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../features/cards/effects.dart';
import '../features/cards/holo_layer.dart';
import 'octagon.dart';

/// Emblème de l'app : octogone noir au motif holographique de l'Octogone
/// Noir, bord doré. [child] s'affiche au centre.
class OctagonEmblem extends StatelessWidget {
  const OctagonEmblem({super.key, required this.size, this.child, this.animate = true});

  final double size;
  final Widget? child;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(fit: StackFit.expand, alignment: Alignment.center, children: [
        ClipPath(
          clipper: const OctagonClipper(),
          child: Stack(fit: StackFit.expand, children: [
            const DecoratedBox(
              decoration: BoxDecoration(gradient: RadialGradient(colors: [Color(0xFF1E1E1E), Color(0xFF070707)])),
            ),
            RepaintBoundary(
              child: HoloLayer(
                spec: const EffectSpec(mode: 9, blend: BlendMode.screen, animated: true, intensity: 0.8),
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

class _RimPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas
      ..drawPath(
        octagonPath(c, r - 1.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF3D38A), AppColors.goldDeep, Color(0xFFF3D38A)],
          ).createShader(Offset.zero & size),
      )
      ..drawPath(
        octagonPath(c, r * 0.84),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = AppColors.gold.withValues(alpha: 0.35),
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
