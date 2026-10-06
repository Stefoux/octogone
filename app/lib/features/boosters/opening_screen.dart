import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../core/l10n.dart';
import '../../core/sounds.dart';
import '../../core/theme.dart';
import '../../data/repositories/content_providers.dart';
import '../../domain/models.dart';
import '../../widgets/arena_background.dart';
import '../../widgets/rarity_backdrop.dart';
import '../../widgets/tilt_builder.dart';
import '../cards/card_backside.dart';
import '../cards/card_view.dart';
import '../cards/decorations.dart';
import '../cards/trading_card.dart';
import 'booster_flow.dart';
import 'booster_pack.dart';
import '../defis/defis_service.dart';
import 'booster_service.dart';
import 'swipe_card.dart';

enum _Phase { tear, waiting, reveal, summary }

const _ranks = ['commune', 'peu_commune', 'rare', 'epique', 'legendaire', 'mythique'];
int _rank(String r) => _ranks.indexOf(r);

/// Ouverture d'un booster : on glisse le doigt pour déchirer le sachet, puis
/// les cartes sont révélées une par une (les plus rares en dernier), avec une
/// lueur de la couleur de la rareté juste avant, son et vibration.
class BoosterOpeningScreen extends ConsumerStatefulWidget {
  const BoosterOpeningScreen({super.key, required this.typeId, this.payment = 'gratuit', this.useSensors = true});

  final String typeId;
  final String payment;
  final bool useSensors;

  @override
  ConsumerState<BoosterOpeningScreen> createState() => _BoosterOpeningScreenState();
}

class _BoosterOpeningScreenState extends ConsumerState<BoosterOpeningScreen> with TickerProviderStateMixin {
  _Phase _phase = _Phase.tear;
  double _tear = 0;
  late String _payment = widget.payment;
  late final AnimationController _rip = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final AnimationController _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final AnimationController _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  List<PulledCard> _cards = const [];
  int _index = 0;
  bool _busy = false;
  bool _suspense = false;
  bool _celebrate = false;

  /// Carte du dessus ; nouvelle clé à chaque carte pour repartir de zéro.
  GlobalKey<SwipeCardState> _swipeKey = GlobalKey();

  @override
  void dispose() {
    _rip.dispose();
    _flip.dispose();
    _burst.dispose();
    _pulse.dispose();
    super.dispose();
  }

  BoosterType? get _booster =>
      (ref.read(boosterTypesProvider).value ?? const <BoosterType>[]).firstWhereOrNull((b) => b.id == widget.typeId);

  // --- Déchirure -------------------------------------------------------------

  void _onDrag(DragUpdateDetails d, double width) {
    if (_phase != _Phase.tear || _busy) return;
    setState(() => _tear = (_tear + d.delta.dx.abs() / (width * 0.9)).clamp(0.0, 1.0));
    if (_tear >= 0.8) unawaited(_completeTear());
  }

  void _onDragEnd() {
    if (_phase == _Phase.tear && !_busy && _tear < 0.8) setState(() => _tear = 0);
  }

  Future<void> _completeTear() async {
    if (_busy) return;
    _busy = true;
    final fx = ref.read(soundFxProvider);
    unawaited(HapticFeedback.heavyImpact());
    unawaited(fx.play('rip'));
    setState(() => _tear = 1);
    final pending = ref.read(boosterServiceProvider).open(widget.typeId, payment: _payment);
    await _rip.forward(from: 0);
    if (!mounted) return;
    setState(() => _phase = _Phase.waiting);
    try {
      final cards = await pending;
      if (!mounted) return;
      // Photos téléchargées pendant la révélation (la première est attendue un instant)
      final photos = _precachePhotos(cards);
      if (photos.isNotEmpty) {
        await photos.first.timeout(const Duration(milliseconds: 1500), onTimeout: () {});
      }
      if (!mounted) return;
      ref
        ..invalidate(boosterStatusProvider)
        ..invalidate(walletProvider)
        ..invalidate(defisProvider);
      setState(() {
        _cards = cards;
        _index = 0;
        _phase = _Phase.reveal;
      });
      _flip.reset();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(boosterErrorMessage(context.l10n, e))));
      _rip.reset();
      setState(() {
        _phase = _Phase.tear;
        _tear = 0;
      });
    } finally {
      _busy = false;
    }
  }

  List<Future<void>> _precachePhotos(List<PulledCard> cards) {
    final images = ref.read(imagesProvider).value ?? const <String, ImageRef>{};
    final futures = <Future<void>>[];
    for (final c in cards) {
      final view = buildCardView(ref, cardId: c.cardId, owned: c.toOwned());
      for (final f in view?.fighters ?? const <Fighter>[]) {
        final img = images[f.imageId];
        if (img == null) continue;
        futures.add(precacheImage(CachedNetworkImageProvider(AppConfig.publicImageUrl(img.storagePath)), context));
      }
    }
    return futures;
  }

  // --- Révélation ------------------------------------------------------------

  bool get _revealed => _flip.value >= 0.5;

  /// Toucher : révèle la carte, ou la fait passer si elle est déjà révélée.
  Future<void> _onTapCard() async {
    if (_phase != _Phase.reveal || _busy) return;
    if (!_revealed) {
      await _revealCurrent();
    } else {
      await _swipeKey.currentState?.fling(AxisDirection.left);
    }
  }

  Future<void> _revealCurrent() async {
    if (_busy || _revealed) return;
    _busy = true;
    try {
      await _reveal();
    } finally {
      _busy = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _reveal() async {
    final card = _cards[_index];
    final fx = ref.read(soundFxProvider);
    if (_rank(card.rarete) >= _rank('legendaire')) {
      // Suspense : la lueur s'intensifie avant la révélation
      setState(() => _suspense = true);
      for (var i = 0; i < 3; i++) {
        unawaited(HapticFeedback.mediumImpact());
        await Future<void>.delayed(const Duration(milliseconds: 260));
      }
      if (!mounted) return;
      setState(() => _suspense = false);
    }
    unawaited(fx.play('flip', volume: 0.6));
    await _flip.animateTo(0.5, curve: Curves.easeIn);
    if (!mounted) return;
    unawaited(fx.reveal(card.rarete));
    if (_rank(card.rarete) >= _rank('rare')) unawaited(_burst.forward(from: 0));
    if (_rank(card.rarete) >= _rank('legendaire')) setState(() => _celebrate = true);
    await _flip.animateTo(1, curve: Curves.easeOut);
  }

  /// La carte du dessus s'est envolée : on passe à la suivante.
  void _advance() {
    if (!mounted) return;
    setState(() {
      _celebrate = false;
      _swipeKey = GlobalKey();
      if (_index + 1 < _cards.length) {
        _index++;
      } else {
        _phase = _Phase.summary;
      }
    });
    _flip.reset();
    _burst.reset();
  }

  void _onFlingStart(AxisDirection dir) {
    unawaited(HapticFeedback.selectionClick());
    unawaited(ref.read(soundFxProvider).swipe(dir));
  }

  void _revealAll() {
    setState(() {
      _celebrate = false;
      _phase = _Phase.summary;
    });
  }

  Future<void> _openAnother() async {
    final b = _booster;
    if (b == null) return;
    final payment = await choosePayment(context, ref, b);
    if (payment == null || !mounted) return;
    _rip.reset();
    _flip.reset();
    setState(() {
      _payment = payment;
      _phase = _Phase.tear;
      _tear = 0;
      _cards = const [];
      _index = 0;
    });
  }

  // --- Interface -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final booster = ref.watch(boosterTypesProvider).value?.firstWhereOrNull((b) => b.id == widget.typeId);
    final accent = _accentOf(booster);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(fit: StackFit.expand, children: [
        // Fond : ambiance aux couleurs du booster, puis fond de la rareté de
        // la carte une fois révélée
        if (_phase == _Phase.reveal && _cards.isNotEmpty)
          AnimatedBuilder(
            animation: _flip,
            builder: (context, _) => RarityBackdrop(rarete: _revealed ? _cards[_index].rarete : 'commune'),
          )
        else
          ArenaBackground(intensity: 0.8, accent: accent),
        SafeArea(
          child: Stack(children: [
            Column(children: [
              _TopBar(
                phase: _phase,
                progress: _phase == _Phase.reveal ? '${_index + 1}/${_cards.length}' : null,
                onClose: () => context.pop(),
                onRevealAll: _revealAll,
              ),
              Expanded(
                child: switch (_phase) {
                  _Phase.tear || _Phase.waiting => booster == null
                      ? const Center(child: CircularProgressIndicator())
                      : _buildTear(context, booster),
                  _Phase.reveal => _buildReveal(context),
                  _Phase.summary => _buildSummary(context),
                },
              ),
            ]),
            if (_celebrate) const Positioned.fill(child: ConfettiOverlay()),
          ]),
        ),
      ]),
      bottomNavigationBar: _phase == _Phase.summary
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _openAnother,
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                      child: Text(l.boosterOpenAnother),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => context.pop(),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                      child: Text(l.boosterDone),
                    ),
                  ),
                ]),
              ),
            )
          : null,
    );
  }

  Color _accentOf(BoosterType? b) {
    final s = b?.visuel['accent'] as String?;
    if (s == null || s.length != 7) return AppColors.gold;
    return Color(int.parse('FF${s.substring(1)}', radix: 16));
  }

  Widget _buildTear(BuildContext context, BoosterType booster) {
    final l = context.l10n;
    return LayoutBuilder(builder: (context, c) {
      final packW = math.min(c.maxWidth * 0.72, (c.maxHeight - 90) * kPackAspect);
      return TiltBuilder(
        useSensors: widget.useSensors,
        builder: (context, tilt) => Column(children: [
          Expanded(
            child: Center(
              child: GestureDetector(
                key: const Key('booster-tear'),
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (d) => _onDrag(d, packW),
                onHorizontalDragEnd: (_) => _onDragEnd(),
                child: AnimatedBuilder(
                  animation: _rip,
                  builder: (context, _) {
                    final t = Curves.easeOutCubic.transform(_rip.value);
                    return SizedBox(
                      width: packW,
                      child: Stack(clipBehavior: Clip.none, children: [
                        Transform.translate(
                          offset: Offset(0, t * c.maxHeight * 0.9),
                          child: Opacity(
                            opacity: (1 - t * 0.9).clamp(0.0, 1.0),
                            child: BoosterPack(booster: booster, tilt: tilt, part: PackPart.body),
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(t * packW * 0.6, -t * c.maxHeight * 0.4),
                          child: Transform.rotate(
                            angle: -0.6 * t,
                            alignment: Alignment.topRight,
                            child: Opacity(
                              opacity: (1 - t).clamp(0.0, 1.0),
                              child: BoosterPack(
                                booster: booster,
                                tilt: tilt,
                                part: PackPart.top,
                                tearProgress: _tear,
                              ),
                            ),
                          ),
                        ),
                      ]),
                    );
                  },
                ),
              ),
            ),
          ),
          SizedBox(
            height: 70,
            child: _phase == _Phase.waiting
                ? Center(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 10),
                      Text(l.boosterOpening),
                    ]),
                  )
                : Column(children: [
                    const Icon(Icons.swipe_right_alt, color: AppColors.gold, size: 30)
                        .animate(onPlay: (c) => c.repeat())
                        .moveX(begin: -18, end: 18, duration: 1100.ms, curve: Curves.easeInOut)
                        .fadeIn(duration: 300.ms),
                    Text(l.boosterTearHint, style: const TextStyle(color: AppColors.textMuted)),
                  ]),
          ),
        ]),
      );
    });
  }

  Widget _buildReveal(BuildContext context) {
    final l = context.l10n;
    final card = _cards[_index];
    final rarityColor = AppColors.rarity[card.rarete] ?? Colors.white;
    final view = buildCardView(ref, cardId: card.cardId, owned: card.toOwned());
    final remaining = _cards.length - _index - 1;
    return LayoutBuilder(builder: (context, c) {
      final w = math.min(c.maxWidth * 0.74, (c.maxHeight - 120) * kCardAspect);
      final size = Size(w, w / kCardAspect);
      final face = AnimatedBuilder(
        animation: _flip,
        builder: (context, _) {
          final v = _flip.value;
          final showFront = v >= 0.5;
          final angle = showFront ? (v - 1) * math.pi : v * math.pi;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle),
            child: showFront && view != null
                ? TradingCard(view: view)
                : (_suspense
                    ? const CardBackside()
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .shake(hz: 6, rotation: 0.02, duration: 400.ms)
                    : const CardBackside()),
          );
        },
      );
      return Column(children: [
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              Center(
                child: SizedBox.fromSize(
                  size: size,
                  child: Stack(clipBehavior: Clip.none, children: [
                    // Pile des cartes restantes
                    for (var i = math.min(remaining, 3); i >= 1; i--)
                      Transform.translate(
                        offset: Offset(i * 5.0, i * 6.0),
                        child: const Opacity(opacity: 0.85, child: CardBackside()),
                      ),
                    // Lueur de rareté (avant et pendant la révélation)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_flip, _burst, _pulse]),
                        builder: (context, _) => CustomPaint(
                          painter: _GlowPainter(
                            color: rarityColor,
                            strength: _suspense
                                ? 1.0
                                : switch (_rank(card.rarete)) {
                                    <= 0 => 0.0,
                                    1 => 0.3,
                                    _ => 0.45 + 0.25 * _pulse.value,
                                  },
                            burst: _burst.value,
                            rank: _rank(card.rarete),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              // Carte du dessus : glisser dans n'importe quel sens ou toucher
              AnimatedBuilder(
                animation: _flip,
                builder: (context, _) => SwipeCard(
                  key: _swipeKey,
                  cardSize: size,
                  canFling: _revealed && !_busy,
                  onTap: _onTapCard,
                  onBlocked: (_) => _revealCurrent(),
                  onFlingStart: _onFlingStart,
                  onSwiped: (_) => _advance(),
                  child: KeyedSubtree(key: const Key('booster-reveal'), child: face),
                ),
              ),
            ]),
          ),
          SizedBox(
            height: 92,
            child: AnimatedBuilder(
              animation: _flip,
              builder: (context, _) => _revealed && view != null
                  ? _CardInfo(view: view, card: card)
                  : Center(
                      child: Text(l.boosterTapToReveal, style: const TextStyle(color: AppColors.textMuted)),
                    ),
            ),
          ),
        ]);
    });
  }

  Widget _buildSummary(BuildContext context) {
    final l = context.l10n;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: kCardAspect * 0.9,
      ),
      itemCount: _cards.length,
      itemBuilder: (context, i) {
        final c = _cards[i];
        final view = buildCardView(ref, cardId: c.cardId, owned: c.toOwned());
        return Column(children: [
          Expanded(
            child: Stack(clipBehavior: Clip.none, children: [
              if (view != null)
                GestureDetector(
                  onTap: () => context.push('/carte/${Uri.encodeComponent(c.cardId)}?owned=${c.ownedId}'),
                  child: TradingCard(view: view, animate: false),
                ),
              if (c.isNew)
                Positioned(
                  top: -6,
                  left: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.crimson, borderRadius: BorderRadius.circular(6)),
                    child: Text(l.boosterNew, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900)),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 4),
          Text(rarityLabel(l, c.rarete),
              style: TextStyle(fontSize: 11, color: AppColors.rarity[c.rarete], fontWeight: FontWeight.w700)),
        ]).animate(delay: (60 * i).ms).fadeIn(duration: 250.ms).slideY(begin: 0.15, end: 0);
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.phase, required this.progress, required this.onClose, required this.onRevealAll});
  final _Phase phase;
  final String? progress;
  final VoidCallback onClose;
  final VoidCallback onRevealAll;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SizedBox(
      height: 52,
      child: Row(children: [
        if (phase == _Phase.tear)
          IconButton(icon: const Icon(Icons.close), onPressed: onClose)
        else
          const SizedBox(width: 48),
        Expanded(
          child: Center(
            child: progress == null
                ? const SizedBox()
                : Text(progress!, style: const TextStyle(fontFamily: 'Oswald', fontSize: 18, color: AppColors.textMuted)),
          ),
        ),
        if (phase == _Phase.reveal)
          TextButton(key: const Key('booster-reveal-all'), onPressed: onRevealAll, child: Text(l.boosterRevealAll))
        else
          const SizedBox(width: 48),
      ]),
    );
  }
}

class _CardInfo extends StatelessWidget {
  const _CardInfo({required this.view, required this.card});
  final CardView view;
  final PulledCard card;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final color = AppColors.rarity[card.rarete] ?? Colors.white;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
        if (card.isNew)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.crimson, borderRadius: BorderRadius.circular(6)),
            child: Text(l.boosterNew, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        Text(rarityLabel(l, card.rarete).toUpperCase(),
            style: TextStyle(fontFamily: 'Oswald', fontSize: 16, letterSpacing: 2, color: color, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 2),
      Text(
        [
          if (view.tactic != null)
            l.tacticLabel
          else if (view.effect != 'base')
            variantLabel(l, view.effect, view.variant.nom),
          if (card.numeroSerie != null && card.tirage != null) l.cardSerial(card.numeroSerie!, card.tirage!),
        ].join(' · '),
        style: const TextStyle(color: AppColors.textMuted),
      ),
      const SizedBox(height: 6),
      Text(l.boosterTapForNext, style: const TextStyle(color: Colors.white38, fontSize: 12)),
    ]).animate().fadeIn(duration: 250.ms);
  }
}

/// Halo de couleur de la rareté derrière la carte, et gerbe de rayons à la
/// révélation des cartes rares et au-delà.
class _GlowPainter extends CustomPainter {
  _GlowPainter({required this.color, required this.strength, required this.burst, required this.rank});
  final Color color;
  final double strength;
  final double burst;
  final int rank;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    if (strength > 0) {
      final r = size.longestSide * (0.7 + 0.12 * strength);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: 0.75 * strength), color.withValues(alpha: 0.35 * strength), color.withValues(alpha: 0)],
            stops: const [0.45, 0.7, 1],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }
    if (burst > 0 && burst < 1) {
      final rays = 10 + rank * 4;
      final len = size.longestSide * (0.4 + burst * 0.7);
      final paint = Paint()
        ..color = color.withValues(alpha: (1 - burst) * 0.8)
        ..strokeWidth = 3 + rank.toDouble()
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < rays; i++) {
        final a = i * 2 * math.pi / rays + burst * 0.4;
        final dir = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(c + dir * len * 0.55, c + dir * len, paint);
      }
      if (rank >= 4) {
        // Flash blanc pour les légendaires et mythiques
        canvas.drawRect(
          Rect.fromCenter(center: c, width: size.width * 6, height: size.height * 6),
          Paint()..color = Colors.white.withValues(alpha: (1 - burst * 3).clamp(0.0, 1.0) * 0.6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GlowPainter old) =>
      old.burst != burst || old.strength != strength || old.color != color || old.rank != rank;
}
