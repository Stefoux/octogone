import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repositories/content_providers.dart';
import '../../domain/models.dart';
import '../../widgets/fighter_widgets.dart';

class FighterDetailScreen extends ConsumerWidget {
  const FighterDetailScreen({super.key, required this.fighterId});
  final String fighterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(fighterProvider(fighterId));
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.errorWithMessage('$e'))),
        data: (f) => f == null ? Center(child: Text(l.fighterNotFound)) : _Body(fighter: f),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.fighter});
  final Fighter fighter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = fighter;
    final female = f.sexe == 'F';
    final stats = f.stats;
    final s = f.statsUfc;
    final p = f.palmares;
    final u = f.ufc;
    final distinctions = f.distinctions(context.lang);
    final cards = ref.watch(cardsForFighterProvider(f.id)).value ?? const [];
    final editions = {for (final e in ref.watch(editionsProvider).value ?? const <Edition>[]) e.id: e};

    String v(Object? x) => x == null ? '—' : '$x';
    String pct(Object? x) => x == null ? '—' : (context.lang == 'en' ? '${(x as num).round()}%' : '${(x as num).round()} %');
    String dec(Object? x) => x == null ? '—' : (x as num).toStringAsFixed(2);
    String dur(Object? x) {
      if (x == null) return '—';
      final secs = (x as num).toInt();
      return l.minutesSeconds(secs ~/ 60, (secs % 60).toString().padLeft(2, '0'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 120, height: 160, child: FighterPortrait(imageId: f.imageId, borderRadius: 16)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.nom, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  if (f.surnom != null)
                    Text('« ${f.surnom} »', style: const TextStyle(color: AppColors.gold, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 8),
                  Text('${flagEmoji(f.pays)}  ${countryLabel(context, f.pays)}'),
                  Text(weightClassLabel(l, f.categorie), style: const TextStyle(color: AppColors.textMuted)),
                  Text(l.recordLabel(f.record), style: const TextStyle(color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    if (f.championActuel) _Tag(female ? l.tagChampionF : l.tagChampion, AppColors.gold),
                    if (!f.championActuel && f.ancienChampion)
                      _Tag(female ? l.tagFormerChampionF : l.tagFormerChampion, AppColors.steel),
                    if (f.retired) _Tag(female ? l.tagRetiredF : l.tagRetired, AppColors.textMuted),
                    _Tag(styleLabel(l, stats.style), AppColors.crimson),
                  ]),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ToVerifyBanner(fields: f.aVerifier),
        const SizedBox(height: 16),
        _Section(
          title: l.gameStats,
          trailing: OverallBadge(value: stats.overall, size: 36),
          children: [
            for (final k in StatKind.values)
              StatBar(label: statLabel(l, k), value: stats[k], estimated: stats.estimated.contains(k)),
            const SizedBox(height: 6),
            Text(l.gameStatsNote, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
        _Section(title: l.ufcStats, children: [
          _Row(l.sigStrikesPerMin, dec(s['frappes_par_min'])),
          _Row(l.strikeAccuracy, pct(s['precision_frappe_pct'])),
          _Row(l.strikesAbsorbed, dec(s['frappes_encaissees_par_min'])),
          _Row(l.strikeDefense, pct(s['defense_frappe_pct'])),
          _Row(l.takedownsPer15, dec(s['takedowns_par_15min'])),
          _Row(l.takedownAccuracy, pct(s['precision_takedown_pct'])),
          _Row(l.takedownDefense, pct(s['defense_takedown_pct'])),
          _Row(l.subsPer15, dec(s['soumissions_par_15min'])),
          _Row(l.knockdownsPer15, dec(s['knockdowns_par_15min'])),
          _Row(l.avgFightTime, dur(s['duree_moyenne_combat_s'])),
        ]),
        _Section(title: l.proRecord, children: [
          _Row(l.wins, l.methodBreakdown(v(p['victoires']), v(p['victoires_ko']), v(p['victoires_soumission']),
              v(p['victoires_decision']))),
          _Row(l.losses, l.methodBreakdown(v(p['defaites']), v(p['defaites_ko']), v(p['defaites_soumission']),
              v(p['defaites_decision']))),
          if ((p['nuls'] ?? 0) != 0) _Row(l.draws, v(p['nuls'])),
          if ((p['sans_decision'] ?? 0) != 0) _Row(l.noContests, v(p['sans_decision'])),
          if (u['combats_ufc'] != null)
            _Row(l.ufcFights, l.ufcFightsValue(v(u['combats_ufc']), v(u['victoires_ufc']), v(u['defaites_ufc']))),
          if ((u['bonus_fotn'] ?? 0) != 0) _Row(l.bonusFotn, v(u['bonus_fotn'])),
          if ((u['bonus_potn'] ?? 0) != 0) _Row(l.bonusPotn, v(u['bonus_potn'])),
          if ((u['victoires_decision_5_rounds'] ?? 0) != 0)
            _Row(l.fiveRoundDecisions, v(u['victoires_decision_5_rounds'])),
        ]),
        if (distinctions.isNotEmpty)
          _Section(title: l.distinctions, children: [
            for (final d in distinctions)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2, right: 8),
                      child: Icon(Icons.emoji_events_outlined, size: 16, color: AppColors.gold),
                    ),
                    Expanded(child: Text(d, style: const TextStyle(fontSize: 14))),
                  ],
                ),
              ),
          ]),
        if (cards.isNotEmpty)
          _Section(title: l.cardsCount(cards.length), children: [
            for (final c in cards)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Text('#${c.numero}', style: const TextStyle(fontWeight: FontWeight.w700)),
                title: Text(editions[c.editionId]?.nom ?? c.editionId),
                subtitle: c.sousTitre != null ? Text(c.sousTitre!) : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/carte/${Uri.encodeComponent(c.id)}'),
              ),
          ]),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: .5)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.trailing});
  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                  ?trailing,
                ]),
                const SizedBox(height: 8),
                ...children,
              ],
            ),
          ),
        ),
      );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: AppColors.textMuted))),
            const SizedBox(width: 12),
            Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );
}
