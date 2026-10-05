import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../domain/models.dart';
import '../../widgets/fighter_widgets.dart';
import 'card_view.dart';
import 'decorations.dart';
import 'effects.dart';
import 'holo_layer.dart';

/// Dimensions logiques d'une carte (format 2,5 × 3,5 pouces). Tout est dessiné
/// dans ce repère puis mis à l'échelle : miniature d'album ou plein écran,
/// la carte est identique.
const kCardWidth = 300.0;
const kCardHeight = 420.0;
const kCardAspect = kCardWidth / kCardHeight;

const _display = 'Oswald';

/// Recto d'une carte.
class TradingCard extends StatelessWidget {
  const TradingCard({super.key, required this.view, this.tilt = Offset.zero, this.animate = true});

  final CardView view;
  final Offset tilt;

  /// false pour les miniatures (album) : effets figés, pas d'animation.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: kCardAspect,
      child: FittedBox(
        child: SizedBox(
          width: kCardWidth,
          height: kCardHeight,
          child: _CardFront(view: view, tilt: tilt, animate: animate),
        ),
      ),
    );
  }
}

class _CardFront extends ConsumerWidget {
  const _CardFront({required this.view, required this.tilt, required this.animate});
  final CardView view;
  final Offset tilt;
  final bool animate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spec = effectFor(view.effect, couleur: view.variant.couleur, frameFamily: view.frameFamily);
    final frame = spec.frame ?? frameColors(view.frameFamily);
    final seed = (view.card?.id ?? view.variant.id).hashCode;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment(-1 + tilt.dx * 0.6, -1),
          end: Alignment(1 + tilt.dx * 0.6, 1),
          colors: frame,
        ),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(9),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF0B0C10)),
            _Photo(view: view, spec: spec, animate: animate),
            if (spec.decoration == Decoration2.cracks) CracksOverlay(seed: seed),
            _BottomInfo(view: view, spec: spec),
            HoloLayer(spec: spec, tilt: tilt, animate: animate),
            if (spec.decoration == Decoration2.confetti) ConfettiOverlay(animate: animate, seed: seed),
            if (spec.decoration == Decoration2.neon) NeonOutline(animate: animate),
            _TopBadges(view: view),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Photo(s)
// -----------------------------------------------------------------------------

class _Photo extends StatelessWidget {
  const _Photo({required this.view, required this.spec, required this.animate});
  final CardView view;
  final EffectSpec spec;
  final bool animate;

  Widget _portrait(Fighter? f) {
    Widget img = FighterPortrait(imageId: f?.imageId, borderRadius: 0, fighterId: f?.id, rarete: view.variant.rarete);
    final filter = photoFilter(spec.photo);
    if (filter != null) img = ColorFiltered(colorFilter: filter, child: img);
    return img;
  }

  @override
  Widget build(BuildContext context) {
    final fighters = view.fighters;
    Widget photo;
    if (view.effect == 'trilogie' && fighters.length >= 2) {
      photo = Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: _portrait(fighters[0])),
        Container(
          width: 46,
          color: const Color(0xFF120E06),
          alignment: Alignment.center,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('III',
                style: TextStyle(fontFamily: _display, fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.gold)),
            Text('${view.rivalry?.nbCombats ?? 3}',
                style: const TextStyle(fontFamily: _display, fontSize: 14, color: AppColors.gold)),
          ]),
        ),
        Expanded(child: _portrait(fighters[1])),
      ]);
    } else if (fighters.length >= 2) {
      photo = Stack(fit: StackFit.expand, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: _portrait(fighters[0])),
          Expanded(child: _portrait(fighters[1])),
        ]),
        Center(
          child: Container(
            margin: const EdgeInsets.only(bottom: 110),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.crimson, width: 1.5),
            ),
            child: const Text('VS',
                style: TextStyle(fontFamily: _display, fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ]);
    } else {
      photo = _portrait(view.fighter);
      if (view.effect == 'main_levee' && animate) photo = _SlowZoom(child: photo);
    }
    return photo;
  }
}

/// Zoom lent sur la photo (Main Levée).
class _SlowZoom extends StatefulWidget {
  const _SlowZoom({required this.child});
  final Widget child;

  @override
  State<_SlowZoom> createState() => _SlowZoomState();
}

class _SlowZoomState extends State<_SlowZoom> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.scale(scale: 1 + 0.08 * Curves.easeInOut.transform(_c.value), child: child),
        child: widget.child,
      );
}

// -----------------------------------------------------------------------------
// Badges du haut : note globale, drapeau, rareté, RC / AUTO
// -----------------------------------------------------------------------------

class _TopBadges extends StatelessWidget {
  const _TopBadges({required this.view});
  final CardView view;

  @override
  Widget build(BuildContext context) {
    final rarityColor = AppColors.rarity[view.variant.rarete] ?? AppColors.steel;
    return Positioned(
      left: 10,
      right: 10,
      top: 10,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (view.overall != null && !view.isDuel)
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.72),
                border: Border.all(color: AppColors.gold, width: 2),
              ),
              child: Text('${view.overall}',
                  style: const TextStyle(fontFamily: _display, fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          const Spacer(),
          if (view.isRookie) const _Pill(text: 'RC', color: AppColors.crimson),
          if (view.isAutograph) const _Pill(text: 'AUTO', color: AppColors.gold, dark: true),
          if (!view.isDuel && view.fighter?.pays != null)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(6)),
              child: Text(flagEmoji(view.fighter!.pays), style: const TextStyle(fontSize: 20)),
            ),
          const SizedBox(width: 6),
          Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: rarityColor,
                border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.2),
                boxShadow: [BoxShadow(color: rarityColor.withValues(alpha: 0.8), blurRadius: 8)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color, this.dark = false});
  final String text;
  final Color color;
  final bool dark;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(left: 6, top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        child: Text(text,
            style: TextStyle(
                fontFamily: _display,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: dark ? Colors.black : Colors.white)),
      );
}

// -----------------------------------------------------------------------------
// Bas de carte : plaque du nom (ou plaque dorée / plaque de musée), pied de carte
// -----------------------------------------------------------------------------

class _BottomInfo extends StatelessWidget {
  const _BottomInfo({required this.view, required this.spec});
  final CardView view;
  final EffectSpec spec;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = view.fighter;
    final nameStyle = TextStyle(
      fontFamily: _display,
      fontSize: 27,
      height: 1.05,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      color: spec.decoration == Decoration2.goldPlate ? const Color(0xFF3A2606) : Colors.white,
      shadows: spec.decoration == Decoration2.goldPlate
          ? null
          : const [Shadow(color: Colors.black, blurRadius: 6, offset: Offset(0, 2))],
    );

    Widget nameBlock;
    if (view.isDuel) {
      final a = view.fighters[0], b = view.fighters[1];
      nameBlock = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text('${_last(a.nom)}  vs  ${_last(b.nom)}'.toUpperCase(), style: nameStyle),
        ),
        if (view.rivalry != null)
          Text('${view.rivalry!.nbCombats} × · ${view.rivalry!.scoreFor(a.id)}',
              style: const TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w600)),
      ]);
    } else {
      nameBlock = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text((f?.nom ?? view.card?.nomImprime ?? '').toUpperCase(), style: nameStyle),
        ),
        if (f?.surnom != null || view.card?.sousTitre != null)
          Text('« ${view.card?.sousTitre ?? f!.surnom} »',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: spec.decoration == Decoration2.goldPlate ? const Color(0xFF5E420F) : AppColors.gold,
                  fontStyle: FontStyle.italic,
                  fontSize: 13)),
        Text(weightClassLabel(l, f?.categorie).toUpperCase(),
            style: TextStyle(
                fontFamily: _display,
                fontSize: 11,
                letterSpacing: 1.6,
                color: spec.decoration == Decoration2.goldPlate ? const Color(0xFF5E420F) : Colors.white70)),
      ]);
    }

    Widget plate;
    switch (spec.decoration) {
      case Decoration2.goldPlate:
        plate = GoldBeltPlate(child: nameBlock);
      case Decoration2.museumPlaque:
        final ev = view.event;
        String? date;
        if (ev?.date != null) {
          final d = DateTime.tryParse(ev!.date!);
          if (d != null) date = DateFormat.yMMMMd(Localizations.localeOf(context).toLanguageTag()).format(d);
        }
        plate = MuseumPlaque(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text((ev?.nom ?? l.effectMoment).toUpperCase(),
                style: const TextStyle(
                    fontFamily: _display, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: Color(0xFF3B2A10))),
            if (date != null)
              Text(date.toUpperCase(),
                  style: const TextStyle(fontFamily: _display, fontSize: 11, letterSpacing: 1.6, color: Color(0xFF4A3718))),
            const SizedBox(height: 4),
            Text((f?.nom ?? '').toUpperCase(),
                style: const TextStyle(fontFamily: _display, fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF2A1D08))),
          ]),
        );
      default:
        plate = Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: nameBlock);
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00000000), Color(0xCC000000), Color(0xF2000000)],
            stops: [0, 0.45, 1],
          ),
        ),
        padding: const EdgeInsets.only(top: 46),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            plate,
            const SizedBox(height: 8),
            _Footer(view: view),
          ],
        ),
      ),
    );
  }

  static String _last(String name) => name.split(' ').last;
}

class _Footer extends StatelessWidget {
  const _Footer({required this.view});
  final CardView view;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final edition = view.edition;
    final variantName =
        view.effect == 'base' ? null : variantLabel(l, view.effect, view.variant.nom);
    final serial = view.serial != null && view.printRun != null
        ? l.cardSerial(view.serial!, view.printRun!)
        : (view.printRun != null ? '/${view.printRun}' : null);
    const small = TextStyle(fontFamily: _display, fontSize: 10.5, letterSpacing: 1.3, color: Colors.white70);
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text((edition?.nom ?? '').toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: small),
              if (variantName != null)
                Text(variantName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: small.copyWith(color: AppColors.rarity[view.variant.rarete], fontWeight: FontWeight.w600)),
            ]),
          ),
          if (serial != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(colors: [Color(0xFFB98A2C), Color(0xFFFFF0B8), Color(0xFFB98A2C)]),
              ),
              child: Text(serial,
                  style: const TextStyle(fontFamily: _display, fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black)),
            ),
          if (view.numberLabel != null)
            Text(view.numberLabel!, style: small.copyWith(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
