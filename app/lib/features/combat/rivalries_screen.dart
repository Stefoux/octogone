import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n.dart';
import '../../core/techniques.dart';
import '../../core/theme.dart';
import '../../data/repositories/content_providers.dart';
import '../../domain/models.dart';
import '../../widgets/fighter_widgets.dart';
import '../cards/card_view.dart';
import 'combat_modes.dart';
import 'combat_service.dart';
import 'combat_session.dart';
import 'combat_widgets.dart';

/// Scénarios : les vraies rivalités de la base (2 combats ou plus entre les
/// mêmes combattants), à rejouer avec l'un ou l'autre, vrai bilan affiché.
class RivalriesScreen extends ConsumerWidget {
  const RivalriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final rivalries = ref.watch(rivalriesProvider).value ?? const <Rivalry>[];
    final fighters = ref.watch(fightersByIdProvider);
    final progress = ref.watch(rivalryProgressProvider);
    // Ma meilleure carte de chaque combattant
    final best = <String, CardView>{};
    for (final v in fightCards(ref)) {
      best.putIfAbsent(v.fighter!.id, () => v);
    }
    final list = [
      for (final r in rivalries)
        if (fighters[r.fighterA] != null && fighters[r.fighterB] != null) r,
    ];
    list.sort((a, b) {
      final pa = best.containsKey(a.fighterA) || best.containsKey(a.fighterB) ? 0 : 1;
      final pb = best.containsKey(b.fighterA) || best.containsKey(b.fighterB) ? 0 : 1;
      if (pa != pb) return pa.compareTo(pb);
      return b.nbCombats.compareTo(a.nbCombats);
    });
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l.combatScenarios)),
      body: list.isEmpty
          ? Center(child: Text(l.rivalryEmpty))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: list.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(l.rivalriesIntro, style: const TextStyle(color: AppColors.textMuted)),
                  );
                }
                final r = list[i - 1];
                final a = fighters[r.fighterA]!, b = fighters[r.fighterB]!;
                final playable = best.containsKey(a.id) || best.containsKey(b.id);
                final won = progress[r.id] ?? const <String>{};
                return Card(
                  key: Key('rivalry-${r.id}'),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: _Pair(a: a, b: b),
                    title: Text('${a.nom}  vs  ${b.nom}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '${l.rivalryFights(r.nbCombats)} · ${_lastName(a.nom)} ${r.scoreFor(a.id)} ${_lastName(b.nom)}',
                    ),
                    trailing: !playable
                        ? const Icon(Icons.lock_outline, color: AppColors.textMuted)
                        : (won.isNotEmpty
                              ? Icon(Icons.verified, color: won.length == 2 ? AppColors.gold : AppColors.success)
                              : const Icon(Icons.chevron_right)),
                    onTap: () => _open(context, ref, r, a, b, best),
                  ),
                );
              },
            ),
    );
  }

  static String _lastName(String n) => n.split(' ').last;

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    Rivalry r,
    Fighter a,
    Fighter b,
    Map<String, CardView> best,
  ) async {
    final side = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      builder: (_) => _RivalrySheet(rivalry: r, a: a, b: b, playable: {...best.keys}),
    );
    if (side == null || !context.mounted) return;
    final mine = best[side]!;
    final opp = side == a.id ? b : a;
    final prefs = ref.read(combatPrefsProvider);
    final setup = CombatSetup(
      player: Contender(fighter: mine.fighter!, rarity: mine.rarity, bonus: mine.variant.bonusStats, owned: mine.owned),
      opponent: Contender(fighter: opp, rarity: mine.rarity, bonus: mine.rarity.defaultStatBonus),
      level: prefs.level,
      format: prefs.format,
      // Rivalité entre catégories différentes (changement de catégorie) : poids libre
      openWeight: mine.fighter!.categorie != opp.categorie,
      control: prefs.control,
      timer: prefs.timer,
      seed: CombatSetup.newSeed(),
      modeLabel: context.l10n.rivalryLabel,
      allowRematch: false,
      mode: 'rivalite',
    );
    final ready = await ref.read(combatServiceProvider).prepare(setup);
    if (!context.mounted) return;
    final outcome = await context.push<CombatOutcome>('/arene', extra: ready);
    if (outcome?.won == true) await ref.read(rivalryProgressProvider.notifier).won(r.id, side);
  }
}

class _Pair extends StatelessWidget {
  const _Pair({required this.a, required this.b});
  final Fighter a;
  final Fighter b;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 64,
    height: 40,
    child: Stack(
      children: [
        Positioned(left: 0, child: _avatar(a)),
        Positioned(right: 0, child: _avatar(b)),
      ],
    ),
  );

  Widget _avatar(Fighter f) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.background, width: 2),
    ),
    child: FighterPortrait(imageId: f.imageId, borderRadius: 20),
  );
}

class _RivalrySheet extends ConsumerWidget {
  const _RivalrySheet({required this.rivalry, required this.a, required this.b, required this.playable});
  final Rivalry rivalry;
  final Fighter a;
  final Fighter b;

  /// Combattants dont je possède une carte.
  final Set<String> playable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lang = context.lang;
    final won = ref.watch(rivalryProgressProvider)[rivalry.id] ?? const <String>{};
    final names = {a.id: a.nom, b.id: b.nom};
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${a.nom}  vs  ${b.nom}', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          Text(
            '${l.rivalryFights(rivalry.nbCombats)} · ${a.nom} ${rivalry.scoreFor(a.id)} ${b.nom}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Text(
            l.rivalryHistory.toUpperCase(),
            style: const TextStyle(fontFamily: kDisplayFont, fontSize: 13, letterSpacing: 1.4, color: AppColors.gold),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final c in rivalry.combats)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      [_date(context, c['date'] as String?), ?(c['evenement'] as String?)].nonNulls.join(' · '),
                    ),
                    subtitle: Text(
                      [
                        c['vainqueur'] == null ? l.rivalryDraw : (names[c['vainqueur']] ?? c['vainqueur'] as String),
                        if (c['methode'] != null) fightMethodLabel(c['methode'] as String, lang),
                        if (c['round'] != null) 'R${c['round']}',
                      ].join(' · '),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (!playable.contains(a.id) && !playable.contains(b.id))
            Text(
              l.rivalryLocked,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          for (final f in [a, b])
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: FilledButton.icon(
                key: Key('rivalry-play-${f.id}'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: playable.contains(f.id) ? () => Navigator.pop(context, f.id) : null,
                icon: Icon(won.contains(f.id) ? Icons.verified : Icons.sports_mma),
                label: Text(won.contains(f.id) ? l.rivalryWonWith(f.nom) : l.rivalryPlayAs(f.nom)),
              ),
            ),
        ],
      ),
    );
  }

  String? _date(BuildContext context, String? iso) {
    if (iso == null) return null;
    final d = DateTime.tryParse(iso);
    return d == null ? iso : DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(d);
  }
}
