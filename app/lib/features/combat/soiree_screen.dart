import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repositories/content_providers.dart';
import '../../domain/models.dart';
import '../../widgets/fighter_widgets.dart';
import '../cards/card_view.dart';
import '../cards/trading_card.dart';
import '../collection/owned_card_picker.dart';
import 'combat_modes.dart';
import 'combat_service.dart';
import 'combat_session.dart';
import 'combat_text.dart';
import 'combat_widgets.dart';

/// Soirée : 5 de mes combattants, un combat chacun contre un adversaire de sa
/// catégorie ; le 5e est le main event (5 rounds).
class SoireeScreen extends ConsumerStatefulWidget {
  const SoireeScreen({super.key});

  @override
  ConsumerState<SoireeScreen> createState() => _SoireeScreenState();
}

class _SoireeScreenState extends ConsumerState<SoireeScreen> {
  SoireeState? _state;
  bool _loaded = false;
  final _picks = List<String?>.filled(SoireeState.bouts, null);
  final _tactics = <TacticKind>{};

  @override
  void initState() {
    super.initState();
    ModeStore.load(SoireeState.key).then((j) {
      if (mounted) {
        setState(() {
          _state = SoireeState.fromJson(j);
          _loaded = true;
        });
      }
    });
  }

  Future<void> _save(SoireeState? s) async {
    setState(() => _state = s);
    await ModeStore.save(SoireeState.key, s?.toJson());
  }

  Future<void> _pick(int i) async {
    final l = context.l10n;
    final o = await pickOwnedCard(
      context,
      title: l.combatPickFighter,
      where: isFightCard,
      exclude: {
        for (final (j, p) in _picks.indexed)
          if (j != i && p != null) p,
      },
    );
    if (o != null) setState(() => _picks[i] = o.id);
  }

  void _start(Map<String, CardView> cards, List<Fighter> fighters) {
    final rng = math.Random();
    final opponents = <String>[];
    for (final id in _picks) {
      final me = cards[id]!.fighter!;
      final pool = eligibleOpponents(fighters, me, openWeight: false);
      final f = randomOpponent(pool, me, rng);
      if (f == null) return;
      opponents.add(f.id);
    }
    _save(SoireeState(owned: [for (final p in _picks) p!], opponents: opponents));
  }

  Future<void> _fight(Map<String, CardView> cards, Map<String, Fighter> fighters) async {
    final s = _state!;
    final i = s.next;
    final mine = cards[s.owned[i]];
    final opp = fighters[s.opponents[i]];
    if (mine == null || opp == null) return;
    final prefs = ref.read(combatPrefsProvider);
    final setup = CombatSetup(
      player: Contender(fighter: mine.fighter!, rarity: mine.rarity, bonus: mine.variant.bonusStats, owned: mine.owned),
      opponent: Contender(fighter: opp, rarity: mine.rarity, bonus: mine.rarity.defaultStatBonus),
      level: prefs.level,
      format: prefs.format,
      titleFight: i == SoireeState.bouts - 1,
      tactics: chosenTactics(ref, _tactics),
      control: prefs.control,
      timer: prefs.timer,
      seed: CombatSetup.newSeed(),
      modeLabel: context.l10n.soireeLabel(i + 1),
      allowRematch: false,
      mode: 'soiree',
    );
    final ready = await ref.read(combatServiceProvider).prepare(setup);
    if (!mounted) return;
    final outcome = await context.push<CombatOutcome>('/arene', extra: ready);
    if (outcome == null || !mounted) return;
    await _save(s.record(outcome));
  }

  Future<void> _quit() async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l.soireeQuitConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.combatBack)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.soireeQuit)),
        ],
      ),
    );
    if (ok == true) await _save(null);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cards = {for (final v in fightCards(ref)) v.owned!.id: v};
    final fighters = ref.watch(fightersProvider).value ?? const <Fighter>[];
    final byId = {for (final f in fighters) f.id: f};
    final s = _state;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l.combatEvening)),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: s == null ? _compose(l, cards, fighters) : _active(l, s, cards, byId),
            ),
    );
  }

  List<Widget> _compose(AppLocalizations l, Map<String, CardView> cards, List<Fighter> fighters) {
    final ready = _picks.every((p) => p != null && cards.containsKey(p));
    return [
      Text(l.soireeCompose, style: const TextStyle(color: AppColors.textMuted)),
      const SizedBox(height: 12),
      for (var i = 0; i < SoireeState.bouts; i++)
        _BoutRow(
          key: Key('soiree-slot-$i'),
          label: i == SoireeState.bouts - 1 ? l.soireeMainEvent : l.soireeBout(i + 1),
          mine: cards[_picks[i]],
          onTap: () => _pick(i),
        ),
      const SizedBox(height: 8),
      const CombatOptions(),
      TacticChooser(
        selected: _tactics,
        onChanged: (k) => setState(
          () => _tactics
            ..clear()
            ..addAll(k),
        ),
      ),
      FilledButton.icon(
        key: const Key('soiree-start'),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        icon: const Icon(Icons.nightlife),
        label: Text(l.soireeStart),
        onPressed: ready ? () => _start(cards, fighters) : null,
      ),
    ];
  }

  List<Widget> _active(AppLocalizations l, SoireeState s, Map<String, CardView> cards, Map<String, Fighter> byId) {
    return [
      for (var i = 0; i < SoireeState.bouts; i++)
        _BoutRow(
          key: Key('soiree-bout-$i'),
          label: i == SoireeState.bouts - 1 ? l.soireeMainEvent : l.soireeBout(i + 1),
          mine: cards[s.owned[i]],
          opponent: byId[s.opponents[i]],
          outcome: i < s.results.length ? s.results[i] : null,
          current: i == s.next,
        ),
      const SizedBox(height: 12),
      if (s.done) ...[
        Text(
          l.soireeSummary(s.wins).toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: kDisplayFont, fontSize: 26, color: AppColors.gold),
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('soiree-new'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: () => _save(null),
          child: Text(l.soireeNew),
        ),
      ] else ...[
        TacticChooser(
          selected: _tactics,
          onChanged: (k) => setState(
            () => _tactics
              ..clear()
              ..addAll(k),
          ),
        ),
        FilledButton.icon(
          key: const Key('soiree-next'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          icon: const Icon(Icons.sports_mma),
          label: Text(s.next == SoireeState.bouts - 1 ? l.soireeMainEvent : l.soireeNext),
          onPressed: () => _fight(cards, byId),
        ),
        TextButton(onPressed: _quit, child: Text(l.soireeQuit)),
      ],
    ];
  }
}

/// Une ligne de la soirée : ma carte, l'adversaire, le résultat.
class _BoutRow extends StatelessWidget {
  const _BoutRow({
    super.key,
    required this.label,
    this.mine,
    this.opponent,
    this.outcome,
    this.current = false,
    this.onTap,
  });
  final String label;
  final CardView? mine;
  final Fighter? opponent;
  final CombatOutcome? outcome;
  final bool current;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final o = outcome;
    final status = o == null
        ? (current ? null : l.modeUpcoming)
        : [
            o.won == null ? l.combatDraw : (o.won! ? l.combatWin : l.combatLoss),
            if (o.method != null) methodLabel(l, o.method!),
          ].join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: current ? AppColors.gold : Colors.transparent),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 54,
                child: mine == null
                    ? AspectRatio(
                        aspectRatio: kCardAspect,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.outline),
                          ),
                          child: const Icon(Icons.add, color: AppColors.gold),
                        ),
                      )
                    : TradingCard(view: mine!, animate: false),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: const TextStyle(fontSize: 11, letterSpacing: 1.3, color: AppColors.gold),
                    ),
                    Text(
                      [mine?.fighter?.nom ?? '—', ?opponent?.nom].join('  vs  '),
                      maxLines: 2,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (status != null)
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: o == null
                              ? AppColors.textMuted
                              : (o.won == true
                                    ? AppColors.success
                                    : (o.won == false ? AppColors.crimson : AppColors.steel)),
                        ),
                      ),
                  ],
                ),
              ),
              if (opponent != null)
                SizedBox(width: 46, height: 46, child: FighterPortrait(imageId: opponent!.imageId, borderRadius: 23)),
            ],
          ),
        ),
      ),
    );
  }
}
