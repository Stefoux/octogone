import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n.dart';
import '../../core/sounds.dart';
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
import 'combat_widgets.dart';

/// Route vers la ceinture : les vrais classés de la catégorie (n°15, n°10,
/// n°5, n°3, n°1), puis le champion en 5 rounds. Une défaite renvoie au début.
class RouteScreen extends ConsumerStatefulWidget {
  const RouteScreen({super.key});

  @override
  ConsumerState<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends ConsumerState<RouteScreen> {
  RouteState? _route;
  bool _loaded = false;
  String? _ownedId;
  final _tactics = <TacticKind>{};

  @override
  void initState() {
    super.initState();
    ModeStore.load(RouteState.key).then((j) {
      if (mounted) {
        setState(() {
          _route = RouteState.fromJson(j);
          _loaded = true;
        });
      }
    });
  }

  Future<void> _save(RouteState? r) async {
    setState(() => _route = r);
    await ModeStore.save(RouteState.key, r?.toJson());
  }

  Future<void> _fight(CardView mine, List<Fighter> ladder) async {
    final r = _route!;
    final l = context.l10n;
    final step = r.step;
    final rarity = r.rarities[step];
    final prefs = ref.read(combatPrefsProvider);
    final setup = CombatSetup(
      player: Contender(fighter: mine.fighter!, rarity: mine.rarity, bonus: mine.variant.bonusStats, owned: mine.owned),
      opponent: Contender(fighter: ladder[step], rarity: rarity, bonus: rarity.defaultStatBonus),
      level: r.level,
      format: r.format,
      titleFight: step == r.ladder.length - 1,
      tactics: chosenTactics(ref, _tactics),
      control: prefs.control,
      timer: prefs.timer,
      seed: CombatSetup.newSeed(),
      modeLabel: l.routeLabel(step + 1),
      allowRematch: false,
      mode: 'route',
    );
    final ready = await ref.read(combatServiceProvider).prepare(setup);
    if (!mounted) return;
    final outcome = await context.push<CombatOutcome>('/arene', extra: ready);
    if (outcome == null || !mounted) return;
    final next = r.after(outcome);
    await _save(next);
    if (!mounted) return;
    if (next.champion) {
      unawaited(ref.read(soundFxProvider).play('victoire'));
    } else if (next.lastLost) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.routeLost)));
    }
  }

  Future<void> _quit() async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l.routeQuitConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.combatBack)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.routeQuit)),
        ],
      ),
    );
    if (ok == true) await _save(null);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cards = fightCards(ref);
    final fighters = ref.watch(fightersProvider).value ?? const <Fighter>[];
    final byId = {for (final f in fighters) f.id: f};
    final r = _route;
    final mine = r == null
        ? (cards.firstWhereOrNull((v) => v.owned!.id == _ownedId) ??
              cards.firstWhereOrNull((v) => buildRoute(fighters, v.fighter!, v.rarity).isNotEmpty) ??
              cards.firstOrNull)
        : cards.firstWhereOrNull((v) => v.owned!.id == r.owned);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l.combatRoad)),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : mine == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l.combatNoFighter, textAlign: TextAlign.center),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: r == null ? _setup(l, mine, fighters) : _active(l, r, mine, byId),
            ),
    );
  }

  String? _sourceLine(AppLocalizations l, List<Fighter> ladder) {
    final date = ladder.map(rankingOf).nonNulls.map((r) => r.date).nonNulls.firstOrNull;
    if (date == null) return null;
    final d = DateTime.tryParse(date);
    return l.routeSource(
      d == null ? date : DateFormat.yMMMMd(Localizations.localeOf(context).toLanguageTag()).format(d),
    );
  }

  List<Widget> _setup(AppLocalizations l, CardView mine, List<Fighter> fighters) {
    final rungs = buildRoute(fighters, mine.fighter!, mine.rarity);
    final champion = rankingOf(mine.fighter!)?.rang == 0;
    final source = _sourceLine(l, [for (final x in rungs) x.fighter]);
    return [
      Text(l.routeIntro, style: const TextStyle(color: AppColors.textMuted)),
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: GestureDetector(
              key: const Key('route-pick'),
              onTap: () async {
                final o = await pickOwnedCard(context, title: l.combatPickFighter, where: isFightCard);
                if (o != null) setState(() => _ownedId = o.id);
              },
              child: TradingCard(view: mine, animate: false),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: rungs.isEmpty
                ? Text(l.routeNoRanking, style: const TextStyle(color: AppColors.crimson))
                : Column(
                    children: [
                      for (final (i, rung) in rungs.indexed.toList().reversed)
                        _RungTile(rung: rung, index: i, champion: champion, compact: true),
                    ],
                  ),
          ),
        ],
      ),
      if (source != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(source, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
        ),
      const SizedBox(height: 12),
      const CombatOptions(),
      FilledButton.icon(
        key: const Key('route-start'),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        icon: const Icon(Icons.emoji_events),
        label: Text(l.routeStart),
        onPressed: rungs.isEmpty
            ? null
            : () {
                final prefs = ref.read(combatPrefsProvider);
                _save(
                  RouteState(
                    owned: mine.owned!.id,
                    ladder: [for (final x in rungs) x.fighter.id],
                    rarities: [for (final x in rungs) x.rarity],
                    level: prefs.level,
                    format: prefs.format,
                  ),
                );
              },
      ),
    ];
  }

  List<Widget> _active(AppLocalizations l, RouteState r, CardView mine, Map<String, Fighter> byId) {
    final ladder = [for (final id in r.ladder) byId[id]];
    if (ladder.any((f) => f == null)) return [Text(l.routeNoRanking)];
    final fighters = ladder.nonNulls.toList();
    final champion = rankingOf(mine.fighter!)?.rang == 0;
    return [
      Row(
        children: [
          SizedBox(width: 64, child: TradingCard(view: mine, animate: false)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mine.fighter!.nom.toUpperCase(), style: const TextStyle(fontFamily: kDisplayFont, fontSize: 20)),
                Text(
                  r.champion ? l.routeChampion : l.routeLabel(r.step + 1),
                  style: const TextStyle(color: AppColors.gold),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (r.champion)
        Column(
          children: [
            const Icon(
              Icons.emoji_events,
              size: 72,
              color: AppColors.gold,
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1, end: 1.12, duration: 900.ms),
            Text(
              l.routeWon,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: kDisplayFont, fontSize: 22, color: AppColors.gold),
            ),
            const SizedBox(height: 12),
          ],
        ),
      for (var i = fighters.length - 1; i >= 0; i--)
        _RungTile(
          rung: RouteRung(
            fighter: fighters[i],
            rank: rankingOf(fighters[i])?.rang ?? routeTargets[i],
            rarity: r.rarities[i],
            title: i == fighters.length - 1,
          ),
          index: i,
          champion: champion,
          done: i < r.step,
          current: i == r.step,
        ),
      const SizedBox(height: 8),
      if (r.champion)
        FilledButton(
          key: const Key('route-new'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: () => _save(null),
          child: Text(l.routeNew),
        )
      else ...[
        TacticChooser(
          selected: _tactics,
          onChanged: (k) => setState(
            () => _tactics
              ..clear()
              ..addAll(k),
          ),
        ),
        FilledButton.icon(
          key: const Key('route-fight'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          icon: const Icon(Icons.sports_mma),
          label: Text(
            r.step == fighters.length - 1 ? (champion ? l.routeTitleDefense : l.routeTitleFight) : l.routeFight,
          ),
          onPressed: () => _fight(mine, fighters),
        ),
        TextButton(onPressed: _quit, child: Text(l.routeQuit)),
      ],
    ];
  }
}

class _RungTile extends StatelessWidget {
  const _RungTile({
    required this.rung,
    required this.index,
    required this.champion,
    this.done = false,
    this.current = false,
    this.compact = false,
  });
  final RouteRung rung;
  final int index;

  /// Le joueur est lui-même champion : le dernier combat est une défense du titre.
  final bool champion;
  final bool done;
  final bool current;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final color = AppColors.rarity[rung.rarity.key] ?? AppColors.steel;
    final rank = rung.rank == 0 ? l.routeChampion : l.routeRank(rung.rank);
    final size = compact ? 30.0 : 44.0;
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 4 : 8),
      padding: EdgeInsets.all(compact ? 4 : 8),
      decoration: BoxDecoration(
        color: current ? AppColors.gold.withValues(alpha: 0.12) : AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: current ? AppColors.gold : AppColors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: FighterPortrait(
              imageId: rung.fighter.imageId,
              borderRadius: size / 2,
              fighterId: rung.fighter.id,
              rarete: rung.rarity.key,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rung.title ? '$rank · ${champion ? l.routeTitleDefense : l.routeTitleFight}' : rank,
                  style: TextStyle(fontSize: compact ? 10.5 : 11.5, letterSpacing: 1, color: AppColors.gold),
                ),
                Text(
                  rung.fighter.nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: compact ? 13 : 15),
                ),
              ],
            ),
          ),
          if (!compact)
            Icon(
              done ? Icons.check_circle : (current ? Icons.play_circle_fill : Icons.lock_outline),
              color: done ? AppColors.success : (current ? AppColors.gold : AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}
