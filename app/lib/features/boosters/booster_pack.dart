import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../domain/models.dart';
import '../cards/effects.dart';
import '../cards/holo_layer.dart';

/// Repère logique d'un sachet (mis à l'échelle comme les cartes).
const kPackWidth = 300.0;
const kPackHeight = 480.0;
const kPackAspect = kPackWidth / kPackHeight;

/// Hauteur de la bande sertie du haut : la déchirure se fait juste en dessous.
const kTearY = 46.0;

enum PackPart { whole, top, body }

Color _hex(String? s, Color fallback) {
  if (s == null || !s.startsWith('#') || s.length != 7) return fallback;
  return Color(int.parse('FF${s.substring(1)}', radix: 16));
}

/// Booster au visuel graphique original (aucun logo, aucune photo de vrai
/// paquet) : sachet métallisé aux couleurs de la collection, emblème octogone.
class BoosterPack extends StatelessWidget {
  const BoosterPack({
    super.key,
    required this.booster,
    this.tilt = Offset.zero,
    this.part = PackPart.whole,
    this.tearProgress = 0,
    this.animate = true,
  });

  final BoosterType booster;
  final Offset tilt;
  final PackPart part;

  /// 0..1 : avancée de la déchirure (ligne lumineuse le long du haut).
  final double tearProgress;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = [
      for (final c in (booster.visuel['couleurs'] as List? ?? const []).cast<String>()) _hex(c, Colors.black),
    ];
    final palette = colors.length >= 2 ? colors : const [Color(0xFF14161C), Color(0xFF2E3240), Color(0xFFE8B04A)];
    final accent = _hex(booster.visuel['accent'] as String?, const Color(0xFFE8B04A));
    final typeLabel = switch (booster.type) {
      'premium' => l.boosterPremium,
      'evenement' => l.boosterEvent,
      _ => l.boosterStandard,
    };

    Widget pack = SizedBox(
      width: kPackWidth,
      height: kPackHeight,
      child: Stack(children: [
        Positioned.fill(
          child: CustomPaint(painter: _PackPainter(palette, accent, booster.isPremium, tilt)),
        ),
        // Reflet holographique, découpé à la forme du sachet
        Positioned.fill(
          child: ClipPath(
            clipper: _PouchClipper(),
            child: HoloLayer(
              spec: EffectSpec(
                mode: booster.isPremium ? 3 : 0,
                tint: accent,
                tintStrength: 0.45,
                intensity: 0.55,
                blend: BlendMode.screen,
              ),
              tilt: tilt,
              animate: animate,
            ),
          ),
        ),
        Positioned(
          top: 64,
          left: 24,
          right: 24,
          child: Column(children: [
            Text('OCTOGONE',
                style: TextStyle(
                    fontFamily: 'Oswald',
                    fontSize: 13,
                    letterSpacing: 7,
                    color: Colors.white.withValues(alpha: 0.75))),
            const SizedBox(height: 6),
            SizedBox(
              height: 64,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(booster.nom.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Oswald',
                      fontSize: 40,
                      height: 1.0,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 3))],
                    )),
              ),
            ),
          ]),
        ),
        Positioned(
          bottom: 70,
          left: 0,
          right: 0,
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.6), blurRadius: 14)],
              ),
              child: Text(typeLabel.toUpperCase(),
                  style: const TextStyle(
                      fontFamily: 'Oswald', fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 3, color: Colors.black)),
            ),
            const SizedBox(height: 8),
            Text(l.boosterCards(booster.nbCartes).toUpperCase(),
                style: TextStyle(
                    fontFamily: 'Oswald', fontSize: 13, letterSpacing: 3, color: Colors.white.withValues(alpha: 0.8))),
          ]),
        ),
        if (tearProgress > 0) Positioned.fill(child: CustomPaint(painter: _TearPainter(tearProgress))),
      ]),
    );

    if (part != PackPart.whole) {
      pack = ClipRect(
        clipper: _PartClipper(part),
        child: pack,
      );
    }
    return AspectRatio(aspectRatio: kPackAspect, child: FittedBox(child: pack));
  }
}

/// Contour du sachet : corps légèrement arrondi, bandes serties crantées.
Path pouchPath(Size s) {
  const crimp = 30.0;
  const tooth = 10.0;
  final p = Path()..moveTo(8, crimp);
  // bord haut cranté
  for (var x = 8.0; x < s.width - 8; x += tooth) {
    p
      ..lineTo(x + tooth / 2, 4)
      ..lineTo(math.min(x + tooth, s.width - 8), crimp - 22);
  }
  p
    ..lineTo(s.width - 8, crimp)
    ..lineTo(s.width - 4, s.height - crimp)
    ..lineTo(s.width - 8, s.height - crimp + 4);
  // bord bas cranté
  for (var x = s.width - 8; x > 8; x -= tooth) {
    p
      ..lineTo(x - tooth / 2, s.height - 4)
      ..lineTo(math.max(x - tooth, 8), s.height - crimp + 22);
  }
  p
    ..lineTo(8, s.height - crimp + 4)
    ..lineTo(4, s.height - crimp)
    ..close();
  return p;
}

class _PouchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => pouchPath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _PartClipper extends CustomClipper<Rect> {
  _PartClipper(this.part);
  final PackPart part;

  @override
  Rect getClip(Size size) =>
      part == PackPart.top ? Rect.fromLTWH(0, 0, size.width, kTearY) : Rect.fromLTWH(0, kTearY, size.width, size.height);

  @override
  bool shouldReclip(covariant _PartClipper old) => old.part != part;
}

class _PackPainter extends CustomPainter {
  _PackPainter(this.palette, this.accent, this.premium, this.tilt);
  final List<Color> palette;
  final Color accent;
  final bool premium;
  final Offset tilt;

  @override
  void paint(Canvas canvas, Size size) {
    final path = pouchPath(size);
    final rect = Offset.zero & size;

    // Ombre portée
    canvas.drawShadow(path, Colors.black, 14, false);

    // Corps : dégradé de la collection
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(-0.3 + tilt.dx * 0.3, -1),
          end: Alignment(0.3 + tilt.dx * 0.3, 1),
          colors: palette,
        ).createShader(rect),
    );

    canvas.save();
    canvas.clipPath(path);

    // Rayures diagonales discrètes
    final stripe = Paint()
      ..color = accent.withValues(alpha: 0.07)
      ..strokeWidth = 14;
    for (var x = -size.height; x < size.width + size.height; x += 46) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height * 0.7, 0), stripe);
    }

    // Bandes serties (haut et bas) : métal strié
    final band = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withValues(alpha: 0.32), Colors.white.withValues(alpha: 0.08), Colors.white.withValues(alpha: 0.28)],
      ).createShader(rect);
    canvas
      ..drawRect(Rect.fromLTWH(0, 0, size.width, 34), band)
      ..drawRect(Rect.fromLTWH(0, size.height - 34, size.width, 34), band);
    final ridge = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    for (var x = 6.0; x < size.width; x += 5) {
      canvas
        ..drawLine(Offset(x, 4), Offset(x, 34), ridge)
        ..drawLine(Offset(x, size.height - 34), Offset(x, size.height - 4), ridge);
    }

    // Emblème octogone
    final c = Offset(size.width / 2, size.height * 0.5);
    canvas.drawCircle(
      c,
      120,
      Paint()
        ..shader = RadialGradient(colors: [accent.withValues(alpha: 0.38), accent.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: c, radius: 120)),
    );
    Path octagon(double r) {
      final p = Path();
      for (var i = 0; i < 8; i++) {
        final a = math.pi / 8 + i * math.pi / 4;
        final pt = c + Offset(math.cos(a), math.sin(a)) * r;
        i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
      }
      return p..close();
    }

    canvas
      ..drawPath(octagon(78), Paint()..color = Colors.black.withValues(alpha: 0.35))
      ..drawPath(
          octagon(78),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..color = accent)
      ..drawPath(
          octagon(62),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = Colors.white.withValues(alpha: 0.45));
    final diamond = Path()
      ..moveTo(c.dx, c.dy - 30)
      ..lineTo(c.dx + 24, c.dy)
      ..lineTo(c.dx, c.dy + 30)
      ..lineTo(c.dx - 24, c.dy)
      ..close();
    canvas
      ..drawPath(
          diamond,
          Paint()
            ..shader = LinearGradient(colors: [Colors.white, accent, accent.withValues(alpha: 0.7)])
                .createShader(diamond.getBounds()))
      ..drawPath(
          diamond,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = Colors.white.withValues(alpha: 0.8));

    // Double filet sous l'emblème
    final rule = Paint()
      ..color = accent.withValues(alpha: 0.8)
      ..strokeWidth = 2;
    canvas
      ..drawLine(Offset(60, size.height * 0.5 + 100), Offset(size.width - 60, size.height * 0.5 + 100), rule)
      ..drawLine(Offset(84, size.height * 0.5 + 107), Offset(size.width - 84, size.height * 0.5 + 107),
          rule..strokeWidth = 1);

    if (premium) {
      // Liseré supplémentaire pour le Premium
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..color = accent.withValues(alpha: 0.55));
    }
    canvas.restore();

    // Contour
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.35));
  }

  @override
  bool shouldRepaint(covariant _PackPainter old) => old.tilt != tilt || old.palette != palette || old.accent != accent;
}

/// Ligne de déchirure : pointillés le long du haut, partie déjà déchirée lumineuse.
class _TearPainter extends CustomPainter {
  _TearPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 2;
    for (var x = 10.0; x < size.width - 10; x += 12) {
      canvas.drawLine(Offset(x, kTearY), Offset(x + 6, kTearY), dash);
    }
    final end = 10 + (size.width - 20) * progress.clamp(0.0, 1.0);
    final torn = Path()..moveTo(10, kTearY);
    final rnd = math.Random(5);
    for (var x = 10.0; x < end; x += 6) {
      torn.lineTo(x, kTearY + (rnd.nextDouble() - 0.5) * 6);
    }
    canvas
      ..drawPath(
          torn,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7
            ..color = const Color(0xFFFFF0B8).withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6))
      ..drawPath(
          torn,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _TearPainter old) => old.progress != progress;
}
