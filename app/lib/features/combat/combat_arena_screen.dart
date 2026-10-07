import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/sounds.dart';
import '../../core/theme.dart';
import '../../widgets/fighter_widgets.dart';
import '../cards/tactic_style.dart';
import 'combat_modes.dart';
import 'combat_service.dart';
import 'combat_session.dart';
import 'combat_text.dart';
import 'submission_game.dart';

/// Délai de chaque temps fort à l'écran (révélation, impacts) : réduit dans
/// les tests.
@visibleForTesting
Duration combatBeat = const Duration(milliseconds: 420);

/// Durée du minuteur (s) quand il est activé dans les réglages.
const kCombatTimerSeconds = 15;

/// L'arène : face-à-face animé, jauges, révélation simultanée des actions,
/// commentaires, mini-jeux de soumission et résultat.
class CombatArenaScreen extends ConsumerStatefulWidget {
  const CombatArenaScreen({super.key, required this.setup});
  final CombatSetup setup;

  @override
  ConsumerState<CombatArenaScreen> createState() => _CombatArenaScreenState();
}

class _Line {
  _Line(this.id, this.text, this.side);
  final int id;
  final String text;
  final int? side;
}

class _CombatArenaScreenState extends ConsumerState<CombatArenaScreen> {
  CombatController? _c;
  bool _busy = false;
  final _lines = <_Line>[];
  var _lineId = 0;
  final _hits = [0, 0];
  final _flash = [0, 0];
  String? _banner;
  var _bannerId = 0;
  (CombatAction, CombatAction)? _reveal;
  Timer? _timer;
  int _left = kCombatTimerSeconds;
  bool _showResult = false;

  /// Récompense validée par le serveur (null pendant l'envoi).
  CombatReward? _reward;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final habits = widget.setup.level == AiLevel.difficile ? await HabitStore.load() : null;
    if (!mounted) return;
    setState(() => _c = CombatController(widget.setup, habits: habits));
    _say(_c!.lastEvents);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c?.dispose();
    super.dispose();
  }

  SoundFx get _fx => ref.read(soundFxProvider);

  /// Résultat rendu au mode qui a lancé le combat.
  CombatOutcome? get _outcome {
    final c = _c;
    if (c == null || !c.finished) return null;
    return CombatOutcome(
      won: c.playerWon,
      method: c.result?.method,
      round: c.result?.round ?? c.engine.round,
      gaveUp: c.gaveUp,
    );
  }

  // --- Minuteur ---------------------------------------------------------------

  void _startTimer() {
    _timer?.cancel();
    if (!widget.setup.timer || _c == null || _c!.finished) return;
    setState(() => _left = kCombatTimerSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _busy) return;
      setState(() => _left--);
      if (_left <= 0) {
        t.cancel();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(context.l10n.combatTimeUp), duration: const Duration(seconds: 1)));
        _onAction(CombatAction.garde);
      }
    });
  }

  // --- Actions du joueur --------------------------------------------------------

  Future<void> _onAction(CombatAction a) async {
    final c = _c;
    if (c == null || _busy || c.finished || !c.options.contains(a)) return;
    _timer?.cancel();
    setState(() => _busy = true);
    unawaited(HapticFeedback.selectionClick());
    c.play(a);
    setState(() => _reveal = (a, c.lastAi!));
    await _pause(1.6);
    if (!mounted) return;
    setState(() => _reveal = null);
    await _play(c.lastEvents);
    while (c.pending != null) {
      if (!mounted) return;
      final skill = await showSubmissionGame(context, attacking: c.pending!.attacker == 0, seed: c.serial * 31 + 7);
      if (!mounted) return;
      c.resolveSubmission(skill);
      await _play(c.lastEvents);
    }
    if (!mounted) return;
    if (c.finished) {
      await _end();
    } else {
      setState(() => _busy = false);
      _startTimer();
    }
  }

  Future<void> _onTactic(TacticCard t) async {
    final c = _c;
    if (c == null || _busy || !c.canUse(t)) return;
    unawaited(HapticFeedback.mediumImpact());
    c.useTactic(t);
    await _play(c.lastEvents);
  }

  Future<void> _quit() async {
    final l = context.l10n;
    final c = _c;
    if (c == null || c.finished) {
      context.pop(_outcome);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l.combatQuitConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.combatBack)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.combatQuit)),
        ],
      ),
    );
    if (ok == true && mounted) {
      _timer?.cancel();
      c.giveUp();
      final id = widget.setup.combatId;
      if (id != null) unawaited(ref.read(combatServiceProvider).abandon(id));
      setState(() => _showResult = true);
    }
  }

  Future<void> _end() async {
    _timer?.cancel();
    final c = _c!;
    if (widget.setup.level == AiLevel.difficile) unawaited(HabitStore.save(c.driver.ai.habits));
    unawaited(
      ref.read(combatServiceProvider).finish(widget.setup, c).then((r) {
        if (mounted) setState(() => _reward = r);
      }),
    );
    await _pause(2.5);
    if (mounted) setState(() => _showResult = true);
  }

  Future<void> _rematch() async {
    final next = await ref.read(combatServiceProvider).prepare(widget.setup.rematch());
    if (mounted) context.pushReplacement('/arene', extra: next);
  }

  Future<void> _pause(double beats) =>
      Future.delayed(Duration(microseconds: (combatBeat.inMicroseconds * beats).round()));

  // --- Retour visuel, sonore et haptique des événements --------------------------

  void _say(List<CombatEvent> events) {
    final l = context.l10n;
    for (final e in events) {
      final t = eventText(l, e, _c!.names);
      if (t == null) continue;
      _lines.add(_Line(_lineId++, t, e.side));
    }
    while (_lines.length > 4) {
      _lines.removeAt(0);
    }
  }

  Future<void> _play(List<CombatEvent> events) async {
    for (final e in events) {
      if (!mounted) return;
      final l = context.l10n;
      final text = eventText(l, e, _c!.names);
      final side = e.side;
      final pan = side == null ? 0.0 : (side == 0 ? 0.5 : -0.5);
      var wait = text == null ? 0.0 : 0.9;
      switch (e.type) {
        case 'touche' || 'contre':
          final target = 1 - side!;
          final heavy = e.type == 'contre' || (e.action?.heavy ?? false);
          unawaited(_fx.play(heavy ? 'coup_lourd' : 'coup_leger', balance: pan));
          unawaited(heavy ? HapticFeedback.heavyImpact() : HapticFeedback.lightImpact());
          _hits[target]++;
          _flash[target]++;
        case 'bloque':
          unawaited(_fx.play('bloque', balance: -pan));
          unawaited(HapticFeedback.selectionClick());
        case 'rate' || 'takedown_rate' || 'esquive':
          unawaited(_fx.play('rate', volume: 0.6));
        case 'knockdown':
          unawaited(_fx.play('chute'));
          unawaited(_fx.play('foule', volume: 0.7));
          unawaited(HapticFeedback.vibrate());
          _hits[1 - side!]++;
          _banner = 'KNOCKDOWN';
          _bannerId++;
          wait = 1.6;
        case 'takedown':
          unawaited(_fx.play('chute', volume: 0.8));
          unawaited(HapticFeedback.mediumImpact());
        case 'signature':
          unawaited(_fx.play('foule', volume: 0.6));
          _banner = l.actSignature.toUpperCase();
          _bannerId++;
        case 'soumission_tentee':
          unawaited(HapticFeedback.mediumImpact());
        case 'fin_round' || 'decision':
          unawaited(_fx.play('cloche'));
          wait = 1.2;
        case 'ko' || 'tko' || 'fin_soumission':
          unawaited(_fx.play('victoire'));
          unawaited(HapticFeedback.heavyImpact());
          _banner = switch (e.type) {
            'ko' => 'KO',
            'tko' => l.methodTko.toUpperCase(),
            _ => l.methodSoumission.toUpperCase(),
          };
          _bannerId++;
          wait = 1.6;
      }
      setState(() => _say([e]));
      if (wait > 0) await _pause(wait);
    }
    if (mounted) setState(() => _banner = null);
  }

  // --- Affichage -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return ListenableBuilder(
      listenable: c,
      // Retour système pendant le combat : comme un abandon (avec confirmation)
      builder: (context, _) => PopScope(
        canPop: c.finished && _showResult,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _quit();
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _TopBar(c: c, onQuit: _quit, timerLeft: widget.setup.timer && !_busy && !c.finished ? _left : null),
                    _FaceOff(c: c, hits: _hits, flash: _flash),
                    Expanded(
                      child: _Center(c: c, lines: _lines, reveal: _reveal),
                    ),
                    if (widget.setup.tactics.isNotEmpty)
                      _TacticBar(c: c, tactics: widget.setup.tactics, enabled: !_busy, onUse: _onTactic),
                    _Controls(c: c, mode: widget.setup.control, enabled: !_busy && !c.finished, onAction: _onAction),
                  ],
                ),
                if (_banner != null)
                  Center(
                    key: ValueKey('banner-$_bannerId'),
                    child:
                        Text(
                              _banner!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: kDisplayFont,
                                fontSize: 58,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3,
                                color: AppColors.gold,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 18),
                                  Shadow(color: AppColors.crimson, blurRadius: 30),
                                ],
                              ),
                            )
                            .animate()
                            .scaleXY(begin: 2.2, end: 1, duration: 380.ms, curve: Curves.easeOutBack)
                            .fadeIn(duration: 200.ms),
                  ),
                if (_showResult)
                  Positioned.fill(
                    child: _ResultPanel(
                      c: c,
                      reward: c.gaveUp ? null : _reward,
                      sending: !c.gaveUp && _reward == null,
                      onRematch: widget.setup.allowRematch ? _rematch : null,
                      onBack: () => context.pop(_outcome),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Haut de l'écran : abandon, round, échange, minuteur
// -----------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({required this.c, required this.onQuit, this.timerLeft});
  final CombatController c;
  final VoidCallback onQuit;
  final int? timerLeft;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final e = c.engine;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
      child: Row(
        children: [
          IconButton(key: const Key('combat-quit'), onPressed: onQuit, icon: const Icon(Icons.close)),
          Expanded(
            child: Column(
              children: [
                Text(
                  l.combatRound(e.round).toUpperCase(),
                  style: const TextStyle(
                    fontFamily: kDisplayFont,
                    fontSize: 20,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (c.setup.modeLabel != null)
                  Text(
                    c.setup.modeLabel!.toUpperCase(),
                    style: const TextStyle(fontSize: 11, letterSpacing: 1.4, color: AppColors.gold),
                  ),
                Text(
                  '${l.combatExchange(math.min(e.exchange, c.setup.config.exchangesPerRound), c.setup.config.exchangesPerRound)}'
                  ' · ${stanceLabel(l, e.stanceOf(0))}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 40,
            height: 40,
            child: timerLeft == null
                ? null
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: timerLeft! / kCombatTimerSeconds,
                        strokeWidth: 3,
                        color: timerLeft! <= 5 ? AppColors.crimson : AppColors.gold,
                      ),
                      Text('$timerLeft', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Face-à-face : photos, noms, jauges
// -----------------------------------------------------------------------------

class _FaceOff extends StatelessWidget {
  const _FaceOff({required this.c, required this.hits, required this.flash});
  final CombatController c;
  final List<int> hits;
  final List<int> flash;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return SizedBox(
      height: (h * 0.3).clamp(190.0, 300.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Expanded(
              child: _FighterPanel(c: c, side: 0, hits: hits[0], flash: flash[0]),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FighterPanel(c: c, side: 1, hits: hits[1], flash: flash[1]),
            ),
          ],
        ),
      ),
    );
  }
}

class _FighterPanel extends StatelessWidget {
  const _FighterPanel({required this.c, required this.side, required this.hits, required this.flash});
  final CombatController c;
  final int side;
  final int hits;
  final int flash;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final contender = side == 0 ? c.setup.player : c.setup.opponent;
    final s = c.engine.sides[side];
    final corner = side == 0 ? AppColors.crimson : const Color(0xFF4F8DFF);
    final rarity = AppColors.rarity[contender.rarity.key] ?? AppColors.steel;
    final down = c.engine.stanceOf(side) == Stance.dessous;
    final ready = c.engine.signatureReady(side);

    Widget photo = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rarity, width: 2),
        boxShadow: [BoxShadow(color: corner.withValues(alpha: 0.35), blurRadius: 14)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FighterPortrait(
            imageId: contender.fighter.imageId,
            borderRadius: 0,
            fighterId: contender.fighter.id,
            rarete: contender.rarity.key,
          ),
          if (flash > 0)
            ColoredBox(color: AppColors.crimson.withValues(alpha: 0.55))
                .animate(key: ValueKey('flash-$side-$flash'))
                .fadeOut(duration: 450.ms),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xE6000000)],
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: side == 0 ? Alignment.centerLeft : Alignment.centerRight,
                child: Text(
                  contender.fighter.nom.toUpperCase(),
                  style: const TextStyle(fontFamily: kDisplayFont, fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            left: side == 0 ? 6 : null,
            right: side == 1 ? 6 : null,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.black.withValues(alpha: 0.7),
              child: Text(
                '${contender.overall}',
                style: const TextStyle(
                  fontFamily: kDisplayFont,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    photo = AnimatedRotation(
      turns: down ? (side == 0 ? -0.012 : 0.012) : 0,
      duration: Motion.medium,
      child: AnimatedScale(scale: down ? 0.94 : 1, duration: Motion.medium, child: photo),
    );
    if (hits > 0) {
      photo = photo.animate(key: ValueKey('hit-$side-$hits')).shakeX(hz: 7, amount: 7, duration: 380.ms);
    }

    return Column(
      crossAxisAlignment: side == 0 ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Expanded(child: photo),
        const SizedBox(height: 6),
        _Gauge(
          key: Key('health-$side'),
          label: l.combatHealth,
          value: s.health,
          max: s.maxHealth,
          color: AppColors.crimson,
          side: side,
        ),
        _Gauge(label: l.combatStamina, value: s.stamina, max: 100, color: const Color(0xFF3FB6E8), side: side),
        _Gauge(
          label: ready ? l.combatSignatureReady : l.combatMomentum,
          value: s.momentum,
          max: 100,
          color: AppColors.gold,
          side: side,
          glow: ready,
        ),
      ],
    );
  }
}

class _Gauge extends StatelessWidget {
  const _Gauge({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.side,
    this.glow = false,
  });
  final String label;
  final int value;
  final int max;
  final Color color;
  final int side;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final f = max == 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Column(
        crossAxisAlignment: side == 0 ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Text(
            '$label · $value',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: glow ? AppColors.gold : AppColors.textMuted, letterSpacing: 0.4),
          ),
          const SizedBox(height: 1),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(3),
              boxShadow: glow ? [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 8)] : null,
            ),
            child: Align(
              alignment: side == 0 ? Alignment.centerLeft : Alignment.centerRight,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: f),
                duration: Motion.slow,
                curve: Motion.curve,
                builder: (context, v, _) => FractionallySizedBox(
                  widthFactor: v,
                  child: Container(
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Centre : révélation simultanée des actions, commentaires
// -----------------------------------------------------------------------------

class _Center extends StatelessWidget {
  const _Center({required this.c, required this.lines, required this.reveal});
  final CombatController c;
  final List<_Line> lines;
  final (CombatAction, CombatAction)? reveal;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (final line in lines)
                  Padding(
                    key: ValueKey('line-${line.id}'),
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      line.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: line == lines.last ? 15.5 : 13,
                        fontWeight: line == lines.last ? FontWeight.w700 : FontWeight.w500,
                        color: switch (line.side) {
                          0 => const Color(0xFFFF8A94),
                          1 => const Color(0xFF8DB4FF),
                          _ => AppColors.gold,
                        }.withValues(alpha: line == lines.last ? 1 : 0.6),
                      ),
                    ),
                  ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.4, end: 0),
              ],
            ),
          ),
        ),
        if (reveal != null)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.55),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                        width: 110,
                        height: 162,
                        child: _ActionCard(action: reveal!.$1, stance: c.engine.stanceOf(0), big: true),
                      )
                      .animate()
                      .slideX(begin: -1.2, end: 0, duration: 300.ms, curve: Curves.easeOutCubic)
                      .flipH(begin: -0.5, end: 0, duration: 300.ms),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: const Text(
                      'VS',
                      style: TextStyle(
                        fontFamily: kDisplayFont,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    ).animate().scaleXY(begin: 0.3, end: 1, duration: 260.ms, curve: Curves.easeOutBack),
                  ),
                  SizedBox(
                        width: 110,
                        height: 162,
                        child: _ActionCard(action: reveal!.$2, stance: c.engine.stanceOf(1), big: true, opponent: true),
                      )
                      .animate()
                      .slideX(begin: 1.2, end: 0, duration: 300.ms, curve: Curves.easeOutCubic)
                      .flipH(begin: 0.5, end: 0, duration: 300.ms),
                ],
              ),
            ).animate().fadeIn(duration: 150.ms),
          ),
        if (reveal == null && lines.isEmpty)
          Center(
            child: Text(l.combatYourMove, style: const TextStyle(color: AppColors.textMuted)),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Cartes Tactique et commandes (cartes ou roue)
// -----------------------------------------------------------------------------

class _TacticBar extends StatelessWidget {
  const _TacticBar({required this.c, required this.tactics, required this.enabled, required this.onUse});
  final CombatController c;
  final List<TacticCard> tactics;
  final bool enabled;
  final ValueChanged<TacticCard> onUse;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Row(
        children: [
          for (final t in tactics)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Opacity(
                  opacity: c.canUse(t) ? 1 : 0.35,
                  child: OutlinedButton.icon(
                    key: Key('use-tactic-${t.kind.key}'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: tacticColor(t.kind)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    onPressed: enabled && c.canUse(t) ? () => onUse(t) : null,
                    icon: Icon(tacticIcon(t.kind), size: 18, color: tacticColor(t.kind)),
                    label: Text(tacticName(l, t.kind), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.c, required this.mode, required this.enabled, required this.onAction});
  final CombatController c;
  final ControlMode mode;
  final bool enabled;
  final ValueChanged<CombatAction> onAction;

  @override
  Widget build(BuildContext context) {
    final options = c.finished ? const <CombatAction>[] : c.hand;
    final stance = c.engine.stanceOf(0);
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.45,
      duration: Motion.fast,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
        child: mode == ControlMode.roue
            ? Center(
                child: _ActionWheel(options: options, stance: stance, onAction: enabled ? onAction : null),
              )
            : SizedBox(
                height: 118,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final (i, a) in options.indexed)
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: GestureDetector(
                            key: Key('action-$i-${a.key}'),
                            onTap: enabled ? () => onAction(a) : null,
                            child: _ActionCard(action: a, stance: stance),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Carte d'action : pictogramme, nom, coût en endurance.
class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action, required this.stance, this.big = false, this.opponent = false});
  final CombatAction action;
  final Stance stance;
  final bool big;
  final bool opponent;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final color = actionColor(action);
    final sig = action == CombatAction.signature;
    return AspectRatio(
      aspectRatio: 0.68,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(color, Colors.black, 0.35)!, const Color(0xFF111319)],
          ),
          border: Border.all(color: opponent ? const Color(0xFF4F8DFF) : color, width: sig ? 2.5 : 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: sig ? 0.8 : 0.3),
              blurRadius: sig ? 16 : 6,
            ),
          ],
        ),
        padding: const EdgeInsets.all(5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(actionIcon(action), size: big ? 40 : 26, color: Colors.white),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                actionName(l, action, stance),
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: kDisplayFont, fontSize: big ? 15 : 11.5, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              action.cost > 0 ? '−${action.cost}' : (action.cost < 0 ? '+${-action.cost}' : '0'),
              style: TextStyle(fontSize: big ? 12 : 10, color: const Color(0xFF8FD3F0)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Roue d'action : la même main, disposée en cercle.
class _ActionWheel extends StatelessWidget {
  const _ActionWheel({required this.options, required this.stance, required this.onAction});
  final List<CombatAction> options;
  final Stance stance;
  final ValueChanged<CombatAction>? onAction;

  static const size = 230.0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final n = options.length;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          for (var i = 0; i < n; i++)
            () {
              final a = options[i];
              final angle = -math.pi / 2 + 2 * math.pi * i / n;
              const r = size / 2 - 40;
              return Positioned(
                left: size / 2 + r * math.cos(angle) - 36,
                top: size / 2 + r * math.sin(angle) - 36,
                child: GestureDetector(
                  key: Key('action-$i-${a.key}'),
                  onTap: onAction == null ? null : () => onAction!(a),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.lerp(actionColor(a), Colors.black, 0.45),
                      border: Border.all(color: actionColor(a), width: a == CombatAction.signature ? 3 : 1.5),
                      boxShadow: [BoxShadow(color: actionColor(a).withValues(alpha: 0.4), blurRadius: 10)],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(actionIcon(a), size: 22),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            actionName(l, a, stance),
                            style: const TextStyle(
                              fontFamily: kDisplayFont,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }(),
          Center(
            child: Container(
              width: 74,
              height: 74,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.6),
                border: Border.all(color: AppColors.outline),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  stanceLabel(l, stance),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Résultat : vainqueur, méthode, cartes des 3 juges
// -----------------------------------------------------------------------------

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.c,
    required this.onRematch,
    required this.onBack,
    this.reward,
    this.sending = false,
  });
  final CombatController c;
  final CombatReward? reward;
  final bool sending;

  /// Revanche (combat rapide) ; null dans un mode, où « Continuer » rend le résultat.
  final VoidCallback? onRematch;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final won = c.playerWon;
    final r = c.result;
    final title = won == null ? l.combatDraw : (won ? l.combatWin : l.combatLoss);
    final color = won == null ? AppColors.steel : (won ? AppColors.gold : AppColors.crimson);
    final method = c.gaveUp ? l.combatQuit : (r == null ? '' : l.combatResultLine(methodLabel(l, r.method), r.round));
    return ColoredBox(
      key: const Key('combat-result'),
      color: Colors.black.withValues(alpha: 0.94),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
          children: [
            Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kDisplayFont,
                fontSize: 54,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: color,
              ),
            ).animate().scaleXY(begin: 1.8, end: 1, duration: 420.ms, curve: Curves.easeOutBack).fadeIn(),
            const SizedBox(height: 6),
            Text(
              method,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${c.names[0]}  vs  ${c.names[1]}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            _RewardLine(reward: reward, sending: sending),
            if (r != null && r.scorecards.isNotEmpty && r.scorecards.first.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                l.combatJudges.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: kDisplayFont,
                  fontSize: 14,
                  letterSpacing: 1.6,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 8),
              _Scorecards(result: r),
            ],
            const SizedBox(height: 28),
            if (onRematch != null) ...[
              FilledButton.icon(
                key: const Key('combat-rematch'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                onPressed: onRematch,
                icon: const Icon(Icons.replay),
                label: Text(l.combatRematch),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                key: const Key('combat-back'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: onBack,
                child: Text(l.combatBack),
              ),
            ] else
              FilledButton(
                key: const Key('combat-continue'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                onPressed: onBack,
                child: Text(l.modeContinue),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _Scorecards extends StatelessWidget {
  const _Scorecards({required this.result});
  final CombatResult result;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final rounds = result.scorecards.first.length;
    const head = TextStyle(fontSize: 12, color: AppColors.textMuted);
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {0: FlexColumnWidth(1.6)},
      children: [
        TableRow(
          children: [
            const SizedBox(),
            for (var i = 0; i < rounds; i++) Center(child: Text('R${i + 1}', style: head)),
            const Center(child: Text('Total', style: head)),
          ],
        ),
        for (var j = 0; j < result.scorecards.length; j++)
          TableRow(
            children: [
              Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(l.combatJudge(j + 1))),
              for (final (a, b) in result.scorecards[j])
                Center(
                  child: Text(
                    '$a-$b',
                    style: TextStyle(color: a > b ? const Color(0xFFFF8A94) : (b > a ? const Color(0xFF8DB4FF) : null)),
                  ),
                ),
              Center(
                child: Text(
                  '${result.judgeTotal(j).$1}-${result.judgeTotal(j).$2}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Récompense du combat (pièces) ou état de la vérification serveur.
class _RewardLine extends StatelessWidget {
  const _RewardLine({required this.reward, required this.sending});
  final CombatReward? reward;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = reward;
    if (r == null) {
      if (!sending) return const SizedBox.shrink();
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 8),
          Text(l.rewardChecking, style: const TextStyle(color: AppColors.textMuted)),
        ],
      );
    }
    if (r.status == 'valide') {
      return Column(
        key: const Key('combat-reward'),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.toll, color: AppColors.gold),
              const SizedBox(width: 6),
              Text(
                l.rewardCoins(r.coins),
                style: const TextStyle(fontFamily: kDisplayFont, fontSize: 24, color: AppColors.gold),
              ),
            ],
          ).animate().scaleXY(begin: 0.6, end: 1, curve: Curves.easeOutBack, duration: 400.ms),
          if (r.capped) Text(l.rewardCapped, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      );
    }
    final text = switch (r.status) {
      'attente' => l.rewardPending,
      'horsligne' => l.rewardOffline,
      _ => l.rewardRefused,
    };
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppColors.textMuted),
    );
  }
}
