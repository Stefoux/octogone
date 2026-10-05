import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../domain/models.dart';
import '../../widgets/octagon_emblem.dart';
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

    // Visuel photo (combattants réels) si le type de booster en définit un
    final art = booster.visuel['art'] as String?;
    final caption = '${typeLabel.toUpperCase()} · ${l.boosterCards(booster.nbCartes).toUpperCase()}';
    Widget pack = switch (art) {
      'v5' => PhotoPack(
          booster: booster,
          palette: palette,
          accent: accent,
          tilt: tilt,
          tearProgress: tearProgress,
          animate: animate,
          caption: caption,
          champion: false,
        ),
      'champion' => PhotoPack(
          booster: booster,
          palette: palette,
          accent: accent,
          tilt: tilt,
          tearProgress: tearProgress,
          animate: animate,
          caption: caption,
          champion: true,
        ),
      _ => _classic(l, palette, accent, typeLabel),
    };

    if (part != PackPart.whole) {
      pack = ClipRect(
        clipper: _PartClipper(part),
        child: pack,
      );
    }
    return AspectRatio(aspectRatio: kPackAspect, child: FittedBox(child: pack));
  }

  /// Visuel graphique d'origine (sans photo) : repli si aucun visuel photo.
  Widget _classic(AppLocalizations l, List<Color> palette, Color accent, String typeLabel) {
    return SizedBox(
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
  }
}

/// Sachet photo : 5 combattants en V (Standard) ou le combattant phare dans
/// un cadre doré (Premium). Mêmes dimensions et même bande de déchirure que
/// le sachet graphique.
class PhotoPack extends StatelessWidget {
  const PhotoPack({
    super.key,
    required this.booster,
    required this.palette,
    required this.accent,
    required this.tilt,
    required this.tearProgress,
    required this.animate,
    required this.caption,
    required this.champion,
  });

  final BoosterType booster;
  final List<Color> palette;
  final Color accent;
  final Offset tilt;
  final double tearProgress;
  final bool animate;
  final String caption;
  final bool champion;

  static const _gold = [Color(0xFF8C6418), Color(0xFFF5D27A), Color(0xFFB98A2C), Color(0xFFFFF0B8), Color(0xFF8C6418)];

  @override
  Widget build(BuildContext context) {
    final body = champion ? const [Color(0xFF050505), Color(0xFF15100A), Color(0xFF070707)] : palette;
    return SizedBox(
      width: kPackWidth,
      height: kPackHeight,
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _PhotoPouchPainter(body, champion ? const Color(0xFFE2B04F) : accent, champion))),
        Positioned.fill(
          child: ClipPath(
            clipper: _PouchClipper(),
            child: Stack(fit: StackFit.expand, children: [
              if (champion) ..._championLayers() else ..._v5Layers(),
              // Reflet qui suit l'inclinaison : doré et pailleté pour le Premium
              HoloLayer(
                spec: champion
                    ? const EffectSpec(mode: 10, tint: Color(0xFFE2B04F), tintStrength: 0.5, intensity: 0.5, blend: BlendMode.screen)
                    : const EffectSpec(mode: 11, intensity: 0.55, blend: BlendMode.screen),
                tilt: tilt,
                animate: animate,
              ),
            ]),
          ),
        ),
        // Nom de la collection
        Positioned(
          top: 54,
          left: 18,
          right: 18,
          child: Column(children: [
            SizedBox(
              height: 58,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _goldOrWhite(
                  Text(
                    booster.nom.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: kDisplayFont,
                      fontSize: 44,
                      height: 1.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black87, blurRadius: 12, offset: Offset(0, 3))],
                    ),
                  ),
                ),
              ),
            ),
            if (!champion) ...[
              const SizedBox(height: 4),
              Text(caption,
                  style: TextStyle(
                      fontFamily: kDisplayFont,
                      fontSize: 12.5,
                      letterSpacing: 2.5,
                      color: Colors.white.withValues(alpha: 0.8),
                      shadows: const [Shadow(color: Colors.black, blurRadius: 6)])),
            ],
          ]),
        ),
        if (champion)
          Positioned(
            left: 0,
            right: 0,
            top: 414,
            child: Center(child: _plate()),
          ),
        if (tearProgress > 0) Positioned.fill(child: CustomPaint(painter: _TearPainter(tearProgress))),
      ]),
    );
  }

  Widget _goldOrWhite(Widget text) => champion
      ? ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (r) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF0B8), Color(0xFFE2B04F), Color(0xFF9C7224)],
          ).createShader(r),
          child: text,
        )
      : text;

  /// Disposition en V : 1 au centre (plus grand, plus bas, devant), 2 et 4
  /// de part et d'autre un peu plus haut, 3 et 5 encore plus haut, derrière.
  /// Chacun cache environ un tiers de la largeur de celui qui est derrière.
  List<Widget> _v5Layers() {
    const s = 108.0; // largeur des combattants 2 à 5
    const s1 = s * 1.2;
    const aspect = 0.8; // largeur / hauteur des bustes
    const cx = kPackWidth / 2;
    // Les bustes ont des marges transparentes de chaque côté : un recouvrement
    // de la moitié de la boîte cache environ un tiers de la silhouette.
    const hide = s * 0.5;
    const d12 = s1 / 2 + s / 2 - hide;
    const d23 = s - hide;
    const bottom1 = 446.0;
    const step = 68.0;
    Widget bust(int n, double centerX, double width, double bottom, double light) {
      final h = width / aspect;
      return Positioned(
        left: centerX - width / 2,
        top: bottom - h,
        width: width,
        height: h,
        child: ColorFiltered(
          // Les combattants du fond sont un peu plus sombres (profondeur)
          colorFilter: ColorFilter.matrix([
            light, 0, 0, 0, 0, //
            0, light, 0, 0, 0,
            0, 0, light, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: Image.asset('assets/boosters/combattant-$n.png', fit: BoxFit.cover, filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) => const SizedBox()),
        ),
      );
    }

    return [
      // Halo de projecteur derrière le groupe
      Positioned(
        left: -40,
        right: -40,
        top: 160,
        height: 320,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, 0.15),
              radius: 0.75,
              colors: [accent.withValues(alpha: 0.45), accent.withValues(alpha: 0.12), Colors.transparent],
              stops: const [0, 0.5, 1],
            ),
          ),
        ),
      ),
      // Logo de l'app au centre du V, derrière les combattants
      Positioned(
        left: cx - 64,
        top: 150,
        width: 128,
        height: 128,
        child: OctagonEmblem(size: 128, animate: animate, glow: true),
      ),
      bust(3, cx - d12 - d23, s, bottom1 - 2 * step, 0.7),
      bust(5, cx + d12 + d23, s, bottom1 - 2 * step, 0.7),
      bust(2, cx - d12, s, bottom1 - step, 0.86),
      bust(4, cx + d12, s, bottom1 - step, 0.86),
      bust(1, cx, s1, bottom1, 1.0),
      // Fondu vers la bande sertie du bas
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        height: 90,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, palette.first.withValues(alpha: 0.85)],
            ),
          ),
        ),
      ),
    ];
  }

  /// Premium : photo du champion dans un cadre doré gravé, fond noir.
  List<Widget> _championLayers() {
    const left = 26.0;
    const top = 120.0;
    const width = kPackWidth - 2 * left;
    const height = 302.0;
    return [
      // Lueur dorée derrière le cadre
      const Positioned(
        left: -20,
        right: -20,
        top: 90,
        height: 360,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 0.7,
              colors: [Color(0x55E2B04F), Color(0x11E2B04F), Colors.transparent],
              stops: [0, 0.55, 1],
            ),
          ),
        ),
      ),
      Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _gold),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.7), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Stack(fit: StackFit.expand, children: [
            Container(
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFF3A2A0E), width: 1.5)),
              child: Image.asset('assets/boosters/champion.jpg',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.35),
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, _, _) => const ColoredBox(color: Colors.black)),
            ),
            // Vignettage et bas assombri pour la plaque
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(radius: 0.95, colors: [Colors.transparent, Color(0x99000000)], stops: [0.6, 1]),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                  stops: [0.7, 1],
                ),
              ),
            ),
            // Filet doré intérieur gravé
            IgnorePointer(
              child: Container(
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(border: Border.all(color: const Color(0xAAF5D27A), width: 0.8)),
              ),
            ),
          ]),
        ),
      ),
      // Ornements dorés aux coins du cadre
      for (final (x, y) in const [(left, top), (left + width, top), (left, top + height), (left + width, top + height)])
        Positioned(
          left: x - 9,
          top: y - 9,
          width: 18,
          height: 18,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFF0B8), Color(0xFFB98A2C)]),
                border: Border.all(color: const Color(0xFF5A4012), width: 1),
              ),
            ),
          ),
        ),
    ];
  }

  Widget _plate() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _gold),
          border: Border.all(color: const Color(0xFF5A4012)),
          boxShadow: [BoxShadow(color: const Color(0xFFE2B04F).withValues(alpha: 0.45), blurRadius: 14)],
        ),
        child: Text(caption,
            style: const TextStyle(
                fontFamily: kDisplayFont, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2.5, color: Color(0xFF1A1206))),
      );
}

/// Corps du sachet photo : dégradé, bandes serties métal, contour.
class _PhotoPouchPainter extends CustomPainter {
  _PhotoPouchPainter(this.colors, this.accent, this.champion);
  final List<Color> colors;
  final Color accent;
  final bool champion;

  @override
  void paint(Canvas canvas, Size size) {
    final path = pouchPath(size);
    final rect = Offset.zero & size;
    canvas
      ..drawShadow(path, Colors.black, 14, false)
      ..drawPath(
          path,
          Paint()
            ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors)
                .createShader(rect));
    canvas
      ..save()
      ..clipPath(path);
    final band = Paint()
      ..shader = LinearGradient(
        colors: champion
            ? const [Color(0xFF8C6418), Color(0xFFF5D27A), Color(0xFFB98A2C), Color(0xFFFFF0B8), Color(0xFF8C6418)]
            : [Colors.white.withValues(alpha: 0.32), Colors.white.withValues(alpha: 0.08), Colors.white.withValues(alpha: 0.28)],
      ).createShader(rect);
    canvas
      ..drawRect(Rect.fromLTWH(0, 0, size.width, 34), band)
      ..drawRect(Rect.fromLTWH(0, size.height - 34, size.width, 34), band);
    final ridge = Paint()
      ..color = Colors.black.withValues(alpha: champion ? 0.35 : 0.25)
      ..strokeWidth = 1;
    for (var x = 6.0; x < size.width; x += 5) {
      canvas
        ..drawLine(Offset(x, 4), Offset(x, 34), ridge)
        ..drawLine(Offset(x, size.height - 34), Offset(x, size.height - 4), ridge);
    }
    canvas.restore();
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = champion ? 3 : 2
          ..color = champion ? accent.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.35));
  }

  @override
  bool shouldRepaint(covariant _PhotoPouchPainter old) => old.colors != colors || old.accent != accent;
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
