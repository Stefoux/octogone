import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repositories/content_providers.dart';
import '../../widgets/arena_background.dart';
import '../../widgets/motion_tilt.dart';
import '../../widgets/octagon.dart';
import '../cards/card_backside.dart';
import '../cards/card_view.dart';
import '../cards/effects.dart';
import '../cards/holo_layer.dart';
import '../cards/trading_card.dart';

/// Sélection fixe de prestige autour de l'octogone : (combattant, édition, effet).
/// Une carte absente du cache est simplement remplacée par un dos de carte.
const kPrestigeCards = [
  ('islam-makhachev', 'saison-2026', 'ceinture_or'),
  ('alex-pereira', '2024-topps-chrome-ufc', 'superfractor'),
  ('bo-nickal', 'saison-2026', 'octogone_noir'),
  ('alexander-volkanovski', 'saison-2026', 'ceinture_or'),
  ('ilia-topuria', '2024-topps-chrome-ufc', 'gold-refractor'),
  ('ciryl-gane', 'saison-2026', 'neon'),
];

/// Place de chaque carte autour de l'octogone (en rayons d'octogone),
/// inclinaison au repos et phase du flottement.
const _portraitSlots = [
  (Offset(-1.02, -1.28), -0.20, 0.00),
  (Offset(1.04, -1.22), 0.17, 0.35),
  (Offset(-1.26, 0.06), -0.12, 0.62),
  (Offset(1.27, 0.12), 0.14, 0.18),
  (Offset(-0.96, 1.34), 0.12, 0.81),
  (Offset(1.00, 1.36), -0.16, 0.47),
];
const _landscapeSlots = [
  (Offset(-1.75, -0.62), -0.18, 0.00),
  (Offset(1.78, -0.58), 0.16, 0.35),
  (Offset(-2.45, 0.30), -0.10, 0.62),
  (Offset(2.48, 0.34), 0.12, 0.18),
  (Offset(-1.55, 0.92), 0.10, 0.81),
  (Offset(1.58, 0.95), -0.14, 0.47),
];

/// Écran d'ouverture affiché à chaque lancement, avant l'accueil. Tout l'écran
/// est le bouton d'entrée.
class EntryScreen extends ConsumerStatefulWidget {
  const EntryScreen({super.key, this.onEnter, this.useSensors = true});

  /// Par défaut : aller à l'accueil (la connexion est demandée si besoin).
  final VoidCallback? onEnter;
  final bool useSensors;

  @override
  ConsumerState<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends ConsumerState<EntryScreen> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(seconds: 9));
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 90));
  late final AnimationController _exit = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
  bool _reduce = false;
  bool _started = false;
  bool _leaving = false;
  bool _focused = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_started) return;
    _started = true;
    if (_reduce) {
      _intro.value = 1;
    } else {
      _intro.forward().whenComplete(() {
        if (mounted && !_leaving) _spin.repeat();
      });
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    _spin.dispose();
    _exit.dispose();
    super.dispose();
  }

  Future<void> _enter() async {
    if (_leaving) return;
    _leaving = true;
    unawaited(HapticFeedback.mediumImpact());
    if (!_reduce) await _exit.forward();
    if (!mounted) return;
    if (widget.onEnter != null) {
      widget.onEnter!();
    } else {
      context.go('/accueil');
    }
  }

  /// Interval [a, b] de l'intro ramené à 0..1.
  double _iv(double a, double b, [Curve curve = Curves.easeOutCubic]) =>
      curve.transform(((_intro.value - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final views = _prestigeViews();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Semantics(
        button: true,
        label: l.entryCta,
        child: InkWell(
          key: const Key('entry-enter'),
          autofocus: true,
          onTap: _enter,
          onFocusChange: (f) => setState(() => _focused = f),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ArenaBackground(intensity: 1),
              MotionTiltBuilder(
                useSensors: widget.useSensors && !_reduce,
                builder: (context, tilt) => LayoutBuilder(
                  builder: (context, c) {
                    final landscape = c.maxWidth > c.maxHeight * 1.05;
                    final r = landscape
                        ? math.min(c.maxHeight * 0.27, c.maxWidth * 0.17)
                        : math.min(c.maxWidth * 0.36, c.maxHeight * 0.2);
                    final center = Offset(c.maxWidth / 2, c.maxHeight * (landscape ? 0.44 : 0.42));
                    final slots = landscape ? _landscapeSlots : _portraitSlots;
                    final cardW = landscape ? r * 0.72 : math.min(c.maxWidth * 0.27, r * 0.78);
                    // Construits une fois par inclinaison, hors de la boucle d'animation :
                    // à chaque image seules les transformations changent.
                    final faces = [
                      for (var i = 0; i < slots.length; i++)
                        RepaintBoundary(
                          child: views.elementAtOrNull(i) == null
                              ? const CardBackside()
                              : TradingCard(view: views[i]!, tilt: tilt, animate: false),
                        ),
                    ];
                    final holo = RepaintBoundary(
                      child: HoloLayer(
                        spec: const EffectSpec(mode: 9, blend: BlendMode.screen, animated: true, intensity: 0.85),
                        tilt: tilt,
                        animate: !_reduce,
                      ),
                    );
                    return AnimatedBuilder(
                      animation: Listenable.merge([_intro, _loop, _spin, _exit]),
                      builder: (context, _) {
                        final e = Curves.easeInCubic.transform(_exit.value);
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (var i = 0; i < slots.length; i++)
                              _card(i, slots[i], faces[i], center, r, cardW, tilt, e),
                            _octagon(center, r, holo, e),
                            _title(center, r, e),
                            _cta(l, c, e),
                            if (e > 0.55)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: ColoredBox(
                                    color: Colors.black.withValues(alpha: ((e - 0.55) / 0.45).clamp(0.0, 1.0)),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<CardView?> _prestigeViews() {
    final cards = ref.watch(allCardsProvider).value;
    final series = ref.watch(allSeriesProvider).value;
    if (cards == null || series == null) return const [];
    return [
      for (final (fighter, edition, effet) in kPrestigeCards)
        () {
          final card = cards.values.firstWhereOrNull(
            (c) =>
                c.editionId == edition &&
                c.fighterIds.length == 1 &&
                c.fighterIds.first == fighter &&
                series[c.seriesId]?.type == 'base',
          );
          if (card == null) return null;
          return buildCardView(ref, cardId: card.id, variantId: '${card.seriesId}:$effet');
        }(),
    ];
  }

  Widget _card(
    int i,
    (Offset, double, double) slot,
    Widget face,
    Offset center,
    double r,
    double w,
    Offset tilt,
    double e,
  ) {
    final (pos, rot, phase) = slot;
    final appear = _iv(0.42 + i * 0.05, 0.70 + i * 0.05, Curves.easeOutBack);
    final opacity = (_iv(0.42 + i * 0.05, 0.62 + i * 0.05) * (1 - e)).clamp(0.0, 1.0);
    final v = (_loop.value + phase) * 2 * math.pi;
    final float = _reduce ? Offset.zero : Offset(math.cos(v) * 3, math.sin(v) * 7);
    // Glisse depuis le centre à l'apparition, s'écarte à la sortie
    final spread = (0.55 + 0.45 * appear) * (1 + e * 1.6);
    final c = center + pos * r * spread + float + tilt * 10 * (1 + i % 2 * 0.6);
    final h = w / kCardAspect;
    final max = 0.23; // ≈ 13° d'inclinaison au maximum
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..rotateX(-tilt.dy * max)
      ..rotateY(tilt.dx * max)
      ..rotateZ(rot + (_reduce ? 0 : math.sin(v * 0.5) * 0.025))
      ..scaleByDouble(0.85 + 0.15 * appear, 0.85 + 0.15 * appear, 1, 1);
    return Positioned(
      left: c.dx - w / 2,
      top: c.dy - h / 2,
      width: w,
      height: h,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Transform(
            alignment: Alignment.center,
            transform: transform,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(w * 0.05),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 18, offset: const Offset(0, 10)),
                ],
              ),
              child: face,
            ),
          ),
        ),
      ),
    );
  }

  Widget _octagon(Offset center, double r, Widget holo, double e) {
    final trace = _iv(0.0, 0.42, Curves.easeInOutCubic);
    final fill = _iv(0.30, 0.60);
    final angle = _spin.value * 2 * math.pi + (1 - _iv(0.0, 0.6)) * -0.6;
    final s = r * 2;
    return Positioned(
      left: center.dx - r,
      top: center.dy - r,
      width: s,
      height: s,
      child: IgnorePointer(
        child: Opacity(
          opacity: (1 - e * 1.3).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 1 + e * e * 5,
            child: Transform.rotate(
              angle: angle,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  // Halo doré
                  Opacity(
                    opacity: fill * (0.7 + 0.3 * math.sin(_loop.value * 2 * math.pi * 2)),
                    child: Transform.scale(
                      scale: 1.45,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              AppColors.gold.withValues(alpha: 0.28),
                              AppColors.gold.withValues(alpha: 0.06),
                              Colors.transparent,
                            ],
                            stops: const [0.35, 0.6, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Octogone noir, motif holographique de l'Octogone Noir
                  Opacity(
                    opacity: fill,
                    child: ClipPath(
                      clipper: const OctagonClipper(),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(colors: [Color(0xFF1E1E1E), Color(0xFF070707)]),
                            ),
                          ),
                          holo,
                        ],
                      ),
                    ),
                  ),
                  // Cadre noir métal + tracé doré
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: _OctagonFramePainter(trace: trace, fill: fill),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _title(Offset center, double r, double e) {
    final letters = _iv(0.42, 0.80, Curves.linear);
    final sheen = _reduce ? -1.0 : ((_loop.value * 2) % 1.0) * 1.8 - 0.4;
    final size = r * 0.36;
    return Positioned(
      left: 0,
      right: 0,
      top: center.dy - size * 0.75,
      child: IgnorePointer(
        child: Opacity(
          opacity: (1 - e * 2).clamp(0.0, 1.0),
          child: Column(
            children: [
              // Le titre reste à l'intérieur de l'octogone quelle que soit la police
              SizedBox(
                width: r * 1.72,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _MetalTitle(text: 'OCTOGONE', size: size, progress: letters, sheen: sheen),
                ),
              ),
              SizedBox(height: size * 0.12),
              Opacity(
                opacity: _iv(0.72, 0.95),
                child: SizedBox(
                width: r * 1.45,
                child: FittedBox(fit: BoxFit.scaleDown, child: Text(
                  context.l10n.authTagline.toUpperCase(),
                  style: TextStyle(
                    fontSize: math.max(10, size * 0.2),
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                )),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cta(AppLocalizations l, BoxConstraints c, double e) {
    final appear = _iv(0.82, 1.0);
    final pulse = _reduce ? 1.0 : 0.6 + 0.4 * (0.5 + 0.5 * math.sin(_loop.value * 2 * math.pi * 3));
    return Positioned(
      left: 24,
      right: 24,
      bottom: c.maxHeight * 0.07 + MediaQuery.paddingOf(context).bottom,
      child: IgnorePointer(
        child: Opacity(
          opacity: (appear * (1 - e * 2)).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - appear) * 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Line(width: 34 + 12 * pulse),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        l.entryCta,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: kDisplayFont,
                          fontSize: 16,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w600,
                          color: Color.lerp(
                            AppColors.gold,
                            Colors.white,
                            _focused ? 0.6 : 0.15,
                          )!.withValues(alpha: _focused ? 1 : pulse),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _Line(width: 34 + 12 * pulse, flip: true),
                  ],
                ),
                const SizedBox(height: 10),
                Icon(Icons.keyboard_double_arrow_down, size: 18, color: AppColors.gold.withValues(alpha: 0.4 * pulse)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.width, this.flip = false});
  final double width;
  final bool flip;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 1.2,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: flip
            ? [AppColors.gold.withValues(alpha: 0.8), Colors.transparent]
            : [Colors.transparent, AppColors.gold.withValues(alpha: 0.8)],
      ),
    ),
  );
}

/// « OCTOGONE » : lettres qui apparaissent une à une, puis reflet métallique.
class _MetalTitle extends StatelessWidget {
  const _MetalTitle({required this.text, required this.size, required this.progress, required this.sheen});
  final String text;
  final double size;

  /// 0..1 : avancée de l'apparition lettre par lettre.
  final double progress;

  /// Position du reflet (-0.4..1.4, hors champ en dehors de 0..1).
  final double sheen;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: kDisplayFont,
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: size * 0.08,
      height: 1,
      color: Colors.white,
      shadows: const [Shadow(color: Colors.black, blurRadius: 14)],
    );
    final n = text.length;
    final letters = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < n; i++)
          Builder(
            builder: (context) {
              final t = ((progress * (n + 2)) - i).clamp(0.0, 1.0);
              final eased = Curves.easeOutCubic.transform(t);
              return Opacity(
                opacity: eased,
                child: Transform.translate(
                  offset: Offset(0, (1 - eased) * size * 0.35),
                  child: Transform.scale(
                    scale: 0.8 + 0.2 * eased,
                    child: Text(text[i], style: style),
                  ),
                ),
              );
            },
          ),
      ],
    );
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) {
        final p = sheen;
        List<double> clampStops(List<double> s) => [for (final x in s) x.clamp(0.0, 1.0)];
        return LinearGradient(
          begin: const Alignment(-1, -0.4),
          end: const Alignment(1, 0.4),
          colors: const [AppColors.goldDeep, AppColors.gold, Color(0xFFFFF4D6), AppColors.gold, Color(0xFFB7862F)],
          stops: clampStops([0, p - 0.12, p, p + 0.12, 1]),
        ).createShader(rect);
      },
      child: letters,
    );
  }
}

/// Cadre de l'octogone : bord noir métallisé (comme l'Octogone Noir) et
/// liseré doré qui se trace au lancement.
class _OctagonFramePainter extends CustomPainter {
  _OctagonFramePainter({required this.trace, required this.fill});
  final double trace;
  final double fill;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final outer = octagonPath(c, r);
    if (fill > 0) {
      canvas.drawPath(
        outer,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.07
          ..shader = SweepGradient(
            colors: [
              const Color(0xFF050505),
              const Color(0xFF3A3A3A),
              const Color(0xFF0A0A0A),
              const Color(0xFF4A4A4A),
              const Color(0xFF050505),
            ].map((c) => c.withValues(alpha: fill)).toList(),
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
      canvas.drawPath(
        octagonPath(c, r * 0.86),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = AppColors.gold.withValues(alpha: 0.35 * fill),
      );
    }
    if (trace > 0) {
      final metric = outer.computeMetrics().first;
      final part = metric.extractPath(0, metric.length * trace);
      canvas
        ..drawPath(
          part,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..color = AppColors.gold.withValues(alpha: 0.45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        )
        ..drawPath(
          part,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..strokeJoin = StrokeJoin.miter
            ..color = const Color(0xFFF3D38A),
        );
      if (trace < 1) {
        // Étincelle en tête du tracé
        final tip = metric.getTangentForOffset(metric.length * trace)?.position;
        if (tip != null) {
          canvas
            ..drawCircle(
              tip,
              7,
              Paint()
                ..color = Colors.white.withValues(alpha: 0.35)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
            )
            ..drawCircle(tip, 2.5, Paint()..color = Colors.white);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OctagonFramePainter old) => old.trace != trace || old.fill != fill;
}
