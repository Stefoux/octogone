import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repositories/content_providers.dart';
import '../../domain/models.dart';
import '../../widgets/fighter_widgets.dart';
import '../cards/card_view.dart';
import '../cards/tactic_style.dart';
import '../cards/trading_card.dart';
import 'combat_session.dart';
import 'combat_text.dart';

/// Carte jouable en combat : un seul combattant, avec une catégorie.
bool isFightCard(CardView v) => v.fighters.length == 1 && v.fighter!.categorie != null && v.tactic == null;

/// Mes exemplaires jouables, les meilleurs d'abord (rareté puis note).
List<CardView> fightCards(WidgetRef ref) {
  final owned = ref.watch(ownedCardsProvider).value ?? const <OwnedCard>[];
  final views = [for (final o in owned) ?buildCardView(ref, cardId: o.cardId, owned: o)].where(isFightCard).toList();
  views.sort((a, b) {
    final r = b.rarity.index.compareTo(a.rarity.index);
    return r != 0 ? r : (b.overall ?? 0).compareTo(a.overall ?? 0);
  });
  return views;
}

/// Ma meilleure carte Tactique pour chaque effet.
Map<TacticKind, TacticCard> bestTactics(WidgetRef ref) {
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

/// Choisir un adversaire dans une liste (recherche, meilleurs d'abord).
Future<Fighter?> chooseFighter(BuildContext context, List<Fighter> pool) => showModalBottomSheet<Fighter>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
  builder: (_) => OpponentList(pool: pool),
);

/// Réglages communs : niveau de l'IA, format, catégorie (option), commandes.
class CombatOptions extends ConsumerWidget {
  const CombatOptions({super.key, this.showWeight = false, this.onWeightChanged, this.showFormat = true});
  final bool showWeight;
  final VoidCallback? onWeightChanged;
  final bool showFormat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final prefs = ref.watch(combatPrefsProvider);
    final notifier = ref.read(combatPrefsProvider.notifier);
    return Column(
      children: [
        CombatSection(
          title: l.combatLevel,
          child: SegmentedButton<AiLevel>(
            segments: [for (final a in AiLevel.values) ButtonSegment(value: a, label: Text(levelLabel(l, a)))],
            selected: {prefs.level},
            showSelectedIcon: false,
            onSelectionChanged: (s) => notifier.update((p) => p.copyWith(level: s.first)),
          ),
        ),
        if (showFormat)
          CombatSection(
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
        if (showWeight)
          CombatSection(
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
                onWeightChanged?.call();
              },
            ),
          ),
        CombatSection(
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
      ],
    );
  }
}

/// Choix des cartes Tactique (2 au plus, une par effet).
class TacticChooser extends ConsumerWidget {
  const TacticChooser({super.key, required this.selected, required this.onChanged});
  final Set<TacticKind> selected;
  final ValueChanged<Set<TacticKind>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final tactics = bestTactics(ref);
    return CombatSection(
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
                    selected: selected.contains(t.kind),
                    onSelected: (on) {
                      final next = {...selected};
                      if (!on) {
                        next.remove(t.kind);
                      } else if (next.length < CombatEngine.maxTactics) {
                        next.add(t.kind);
                      }
                      onChanged(next);
                    },
                  ),
              ],
            ),
    );
  }
}

/// Cartes Tactique choisies, telles que jouées en combat.
List<TacticCard> chosenTactics(WidgetRef ref, Set<TacticKind> kinds) {
  final best = bestTactics(ref);
  return [for (final k in kinds) ?best[k]];
}

class Corner extends StatelessWidget {
  const Corner({super.key, required this.label, required this.color, required this.child, required this.footer});
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
class OpponentCard extends StatelessWidget {
  const OpponentCard({super.key, required this.fighter, required this.rarity});
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

class OpponentList extends StatefulWidget {
  const OpponentList({super.key, required this.pool});
  final List<Fighter> pool;

  @override
  State<OpponentList> createState() => _OpponentListState();
}

class _OpponentListState extends State<OpponentList> {
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

class CombatSection extends StatelessWidget {
  const CombatSection({super.key, required this.title, required this.child, this.note});
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
