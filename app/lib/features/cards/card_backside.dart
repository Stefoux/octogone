import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'trading_card.dart' show kCardAspect, kCardHeight, kCardWidth;

/// Dos de carte (avant la révélation) : motif d'octogones original.
class CardBackside extends StatelessWidget {
  const CardBackside({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: kCardAspect,
      child: FittedBox(
        child: Container(
          width: kCardWidth,
          height: kCardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8C6418), Color(0xFFF5D27A), Color(0xFFB98A2C)],
            ),
          ),
          padding: const EdgeInsets.all(9),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: CustomPaint(
              painter: _BackPainter(),
              child: const Center(
                child: Text('OCTOGONE',
                    style: TextStyle(
                        fontFamily: 'Oswald',
                        fontSize: 22,
                        letterSpacing: 5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const RadialGradient(colors: [Color(0xFF2A1E10), Color(0xFF0B0A08)])
            .createShader(Offset.zero & size),
    );
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.gold.withValues(alpha: 0.18);
    const r = 26.0;
    for (var y = -r; y < size.height + r; y += r * 1.7) {
      for (var x = -r; x < size.width + r; x += r * 1.7) {
        final c = Offset(x + ((y ~/ (r * 1.7)).isOdd ? r * 0.85 : 0), y);
        final p = Path();
        for (var i = 0; i < 8; i++) {
          final a = math.pi / 8 + i * math.pi / 4;
          final pt = c + Offset(math.cos(a), math.sin(a)) * r * 0.8;
          i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
        }
        canvas.drawPath(p..close(), line);
      }
    }
    final c = size.center(Offset.zero);
    final big = Path();
    for (var i = 0; i < 8; i++) {
      final a = math.pi / 8 + i * math.pi / 4;
      final pt = c + Offset(math.cos(a), math.sin(a)) * 96;
      i == 0 ? big.moveTo(pt.dx, pt.dy) : big.lineTo(pt.dx, pt.dy);
    }
    canvas
      ..drawPath(big..close(), Paint()..color = Colors.black.withValues(alpha: 0.55))
      ..drawPath(
          big,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = AppColors.gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
