import 'dart:math' as math;

import 'package:collection/collection.dart';
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
import '../cards/tactic_style.dart';
import '../cards/trading_card.dart';
import '../collection/owned_card_picker.dart';
import 'combat_session.dart';
import 'combat_text.dart';

/// Carte jouable en combat : un seul combattant, avec une catégorie.
bool isFightCard(CardView v) => v.fighters.length == 1 && v.fighter!.categorie != null && v.tactic == null;

/// Préparation d'un combat rapide : combattant, adversaire, niveau de l'IA,
/// format, catégorie, commandes et cartes Tactique.
class CombatSetupScreen extends ConsumerStatefulWidget {
  const CombatSetupScreen({super.key});

  @override
  ConsumerState<CombatSetupScreen> createState() => _CombatSetupScreenState();
}

class _CombatSetupScreenState extends ConsumerState<CombatSetupScreen> {
  final _rng = math.Random();
  String? _ownedId;
  String? _opponentId;
  final _tactics = <TacticKind>{};

  /// Exemplaires jouables, les meilleurs d'abord (rareté puis note).
  List<CardView> _fightCards() {
    final owned = ref.watch(ownedCardsProvider).value ?? const <OwnedCard>[];
    final views = [for (final o in owned) ?buildCardView(ref, cardId: o.cardId, owned: o)].where(isFightCard).toList();
    views.sort((a, b) {
      final r = b.rarity.index.compareTo(a.rarity.index);
      return r != 0 ? r : (b.overall ?? 0).compareTo(a.overall ?? 0);
    });
    return views;
  }

  /// Meilleure carte Tactique possédée pour chaque effet.
  Map<TacticKind, TacticCard> _tacticCards() {
    final owned = ref.watch(ownedCardsProvider).value ?? const <OwnedCard>[];
    final best = <TacticKind, TacticCard>{};
    for (final o in owned) {
      final t = buildCardView(ref, cardId: o.cardId, owned: o)?.tactic;
      if (t == null) continue;
      final cur = best[t.kind];
      if (cur == null || t.rarity.index > cur.rarity.index) best[t.kind] = t;
    }
    return best;
  }

  Future<void> _pickFighter() async {
    final l = context.l10n;
    final o = await pickOwnedCard(context, title: l.combatPickFighter, where: isFightCard);
    if (o != null) {
      setState(() {
        _ownedId = o.id;
        _opponentId = null;
      });
    }
  }

  Future<void> _chooseOpponent(List<Fighter> pool) async {
    final f = await showModalBottomSheet<Fighter>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
      builder: (_) => _OpponentList(pool: pool),
    );
    if (f != null) setState(() => _opponentId = f.id);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final prefs = ref.watch(combatPrefsProvider);
    final notifier = ref.read(combatPrefsProvider.notifier);
    final cards = _fightCards();
    final mine = cards.firstWhereOrNull((v) => v.owned?.id == _ownedId) ?? cards.firstOrNull;
    final fighters = ref.watch(fightersProvider).value ?? const <Fighter>[];
    final tactics = _tacticCards();

    Fighter? opponent;
    List<Fighter> pool = const [];
    if (mine != null) {
      pool = eligibleOpponents(fighters, mine.fighter!, openWeight: prefs.openWeight);
      opponent = pool.firstWhereOrNull((f) => f.id == _opponentId);
      if (opponent == null) {
        opponent = randomOpponent(pool, mine.fighter!, _rng);
        _opponentId = opponent?.id;
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l.combatQuick)),
      body: mine == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l.combatNoFighter,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Corner(
                        label: l.combatYourFighter,
                        color: AppColors.crimson,
                        footer: TextButton.icon(
                          onPressed: _pickFighter,
                          icon: const Icon(Icons.swap_horiz, size: 18),
                          label: Text(l.combatPickFighter, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        child: GestureDetector(
                          key: const Key('combat-pick-fighter'),
                          onTap: _pickFighter,
                          child: TradingCard(view: mine, animate: false),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 110, left: 6, right: 6),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          fontFamily: kDisplayFont,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _Corner(
                        label: l.combatOpponent,
                        color: const Color(0xFF4F8DFF),
                        footer: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              key: const Key('combat-reroll'),
                              tooltip: l.combatReroll,
                              onPressed: pool.length < 2
                                  ? null
                                  : () => setState(() {
                                      final others = pool.where((f) => f.id != _opponentId).toList();
                                      _opponentId = (randomOpponent(others, mine.fighter!, _rng) ?? opponent)?.id;
                                    }),
                              icon: const Icon(Icons.casino_outlined),
                            ),
                            IconButton(
                              tooltip: l.combatChooseOpponent,
                              onPressed: pool.isEmpty ? null : () => _chooseOpponent(pool),
                              icon: const Icon(Icons.list),
                            ),
                          ],
                        ),
                        child: opponent == null
                            ? const AspectRatio(
                                aspectRatio: kCardAspect,
                                child: Center(child: Icon(Icons.help_outline)),
                              )
                            : _OpponentCard(fighter: opponent, rarity: mine.rarity),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _Section(
                  title: l.combatLevel,
                  child: SegmentedButton<AiLevel>(
                    segments: [for (final a in AiLevel.values) ButtonSegment(value: a, label: Text(levelLabel(l, a)))],
                    selected: {prefs.level},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => notifier.update((p) => p.copyWith(level: s.first)),
                  ),
                ),
                _Section(
                  title: l.combatFormat,
                  note: l.combatFormatDetail(3, prefs.format.exchanges),
                  child: SegmentedButton<CombatFormat>(
                    segments: [
                      ButtonSegment(value: CombatFormat.court, label: Text(l.combatFormatCourt)),
                      ButtonSegment(value: CombatFormat.complet, label: Text(l.combatFormatComplet)),
                    ],
                    selected: {prefs.format},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => notifier.update((p) => p.copyWith(format: s.first)),
                  ),
                ),
                _Section(
                  title: l.combatWeight,
                  note: prefs.openWeight ? l.combatOpenWeightNote : null,
                  child: SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(value: false, label: Text(l.combatSameClass)),
                      ButtonSegment(value: true, label: Text(l.combatOpenWeight)),
                    ],
                    selected: {prefs.openWeight},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) {
                      notifier.update((p) => p.copyWith(openWeight: s.first));
                      setState(() => _opponentId = null);
                    },
                  ),
                ),
                _Section(
                  title: l.combatControl,
                  child: SegmentedButton<ControlMode>(
                    segments: [
                      ButtonSegment(
                        value: ControlMode.cartes,
                        icon: const Icon(Icons.style),
                        label: Text(l.combatControlCards),
                      ),
                      ButtonSegment(
                        value: ControlMode.roue,
                        icon: const Icon(Icons.donut_large),
                        label: Text(l.combatControlWheel),
                      ),
                    ],
                    selected: {prefs.control},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => notifier.update((p) => p.copyWith(control: s.first)),
                  ),
                ),
                _Section(
                  title: l.combatTactics,
                  child: tactics.isEmpty
                      ? Text(l.combatNoTactics, style: const TextStyle(color: AppColors.textMuted))
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final t in tactics.values.sortedBy<num>((t) => t.kind.index))
                              FilterChip(
                                key: Key('combat-tactic-${t.kind.key}'),
                                avatar: Icon(tacticIcon(t.kind), size: 18, color: tacticColor(t.kind)),
                                label: Text(tacticName(l, t.kind)),
                                side: BorderSide(color: AppColors.rarity[t.rarity.key] ?? AppColors.outline),
                                selected: _tactics.contains(t.kind),
                                onSelected: (on) => setState(() {
                                  if (!on) {
                                    _tactics.remove(t.kind);
                                  } else if (_tactics.length < CombatEngine.maxTactics) {
                                    _tactics.add(t.kind);
                                  }
                                }),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  key: const Key('combat-enter'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                  icon: const Icon(Icons.sports_mma),
                  label: Text(
                    l.combatEnter.toUpperCase(),
                    style: const TextStyle(fontFamily: kDisplayFont, fontSize: 17, letterSpacing: 1.2),
                  ),
                  onPressed: opponent == null
                      ? null
                      : () {
                          final setup = CombatSetup(
                            player: Contender(
                              fighter: mine.fighter!,
                              rarity: mine.rarity,
                              bonus: mine.variant.bonusStats,
                              owned: mine.owned,
                            ),
                            opponent: Contender(
                              fighter: opponent!,
                              rarity: mine.rarity,
                              bonus: mine.rarity.defaultStatBonus,
                            ),
                            level: prefs.level,
                            format: prefs.format,
                            openWeight: prefs.openWeight,
                            tactics: [for (final k in _tactics) ?tactics[k]],
                            control: prefs.control,
                            timer: prefs.timer,
                            seed: CombatSetup.newSeed(),
                          );
                          context.push('/arene', extra: setup);
                        },
                ),
              ],
            ),
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner({required this.label, required this.color, required this.child, required this.footer});
  final String label;
  final Color color;
  final Widget child;
  final Widget footer;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(fontFamily: kDisplayFont, fontSize: 12, letterSpacing: 1.5, color: color),
        ),
      ),
      child,
      footer,
    ],
  );
}

/// Adversaire : photo de la rareté jouée, nom, note, catégorie.
class _OpponentCard extends StatelessWidget {
  const _OpponentCard({required this.fighter, required this.rarity});
  final Fighter fighter;
  final Rarity rarity;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final color = AppColors.rarity[rarity.key] ?? AppColors.steel;
    return AspectRatio(
      aspectRatio: kCardAspect,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 2),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12)],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FighterPortrait(imageId: fighter.imageId, borderRadius: 0, fighterId: fighter.id, rarete: rarity.key),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 18, 8, 6),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xE6000000)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        fighter.nom.toUpperCase(),
                        style: const TextStyle(fontFamily: kDisplayFont, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      weightClassLabel(l, fighter.categorie),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 6,
              top: 6,
              child: CircleAvatar(
                radius: 15,
                backgroundColor: Colors.black.withValues(alpha: 0.7),
                child: Text(
                  '${fighter.stats.withBonus(rarity.defaultStatBonus).overall}',
                  style: const TextStyle(
                    fontFamily: kDisplayFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpponentList extends StatefulWidget {
  const _OpponentList({required this.pool});
  final List<Fighter> pool;

  @override
  State<_OpponentList> createState() => _OpponentListState();
}

class _OpponentListState extends State<_OpponentList> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final q = _q.trim().toLowerCase();
    final list = widget.pool.where((f) => q.isEmpty || f.nom.toLowerCase().contains(q)).toList()
      ..sort((a, b) => b.stats.overall.compareTo(a.stats.overall));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.combatChooseOpponent, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.searchFighters),
            onChanged: (v) => setState(() => _q = v),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, i) {
                final f = list[i];
                return ListTile(
                  leading: SizedBox(
                    width: 44,
                    height: 44,
                    child: FighterPortrait(imageId: f.imageId, borderRadius: 22),
                  ),
                  title: Text(f.nom),
                  subtitle: Text(weightClassLabel(l, f.categorie)),
                  trailing: Text(
                    '${f.stats.overall}',
                    style: const TextStyle(fontFamily: kDisplayFont, fontSize: 18, color: AppColors.gold),
                  ),
                  onTap: () => Navigator.pop(context, f),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.note});
  final String title;
  final String? note;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(fontFamily: kDisplayFont, fontSize: 13, letterSpacing: 1.4, color: AppColors.gold),
        ),
        const SizedBox(height: 6),
        SizedBox(width: double.infinity, child: child),
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(note!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
          ),
      ],
    ),
  );
}
