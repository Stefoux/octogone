import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/countries.dart';
import '../../core/theme.dart';
import '../../data/repositories/content_providers.dart';
import '../../domain/models.dart';
import '../../widgets/fighter_widgets.dart';

const _sourceLabels = {
  'ufc_com': 'ufc.com',
  'wikipedia': 'Wikipedia',
  'wikidata': 'Wikidata',
};

class FighterDetailScreen extends ConsumerWidget {
  const FighterDetailScreen({super.key, required this.fighterId});
  final String fighterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(fighterProvider(fighterId));
    return Scaffold(
      appBar: AppBar(),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (f) => f == null ? const Center(child: Text('Combattant introuvable')) : _Body(fighter: f),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.fighter});
  final Fighter fighter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = fighter;
    final stats = f.stats;
    final s = f.statsUfc;
    final p = f.palmares;
    final u = f.ufc;
    final cards = ref.watch(cardsForFighterProvider(f.id)).value ?? const [];
    final editions = {for (final e in ref.watch(editionsProvider).value ?? const <Edition>[]) e.id: e};

    String pct(Object? v) => v == null ? '—' : '${(v as num).round()} %';
    String dec(Object? v) => v == null ? '—' : (v as num).toStringAsFixed(2);
    String dur(Object? v) {
      if (v == null) return '—';
      final secs = (v as num).toInt();
      return '${secs ~/ 60} min ${(secs % 60).toString().padLeft(2, '0')}';
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
                  Text('${flagEmoji(f.pays)}  ${countryName(f.pays)}'),
                  Text(f.categorie?.label ?? 'Catégorie à vérifier', style: const TextStyle(color: AppColors.textMuted)),
                  Text('Palmarès ${f.record}', style: const TextStyle(color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    if (f.championActuel) const _Tag('Champion', AppColors.gold),
                    if (!f.championActuel && f.ancienChampion) const _Tag('Ancien champion', AppColors.steel),
                    if (f.retired) const _Tag('Retraité', AppColors.textMuted),
                    _Tag(stats.style.label, AppColors.crimson),
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
          title: 'Stats de jeu',
          trailing: OverallBadge(value: stats.overall, size: 36),
          children: [
            for (final k in StatKind.values)
              StatBar(label: k.label, value: stats[k], estimated: stats.estimated.contains(k)),
            const SizedBox(height: 6),
            const Text(
              'Calculées à partir des statistiques réelles ci-dessous (formule documentée dans game_core).',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
        _Section(title: 'Statistiques UFC', children: [
          _Row('Frappes significatives / min', dec(s['frappes_par_min'])),
          _Row('Précision de frappe', pct(s['precision_frappe_pct'])),
          _Row('Frappes encaissées / min', dec(s['frappes_encaissees_par_min'])),
          _Row('Défense de frappe', pct(s['defense_frappe_pct'])),
          _Row('Takedowns / 15 min', dec(s['takedowns_par_15min'])),
          _Row('Précision des takedowns', pct(s['precision_takedown_pct'])),
          _Row('Défense de takedown', pct(s['defense_takedown_pct'])),
          _Row('Tentatives de soumission / 15 min', dec(s['soumissions_par_15min'])),
          _Row('Knockdowns / 15 min', dec(s['knockdowns_par_15min'])),
          _Row('Durée moyenne d’un combat', dur(s['duree_moyenne_combat_s'])),
        ]),
        _Section(title: 'Palmarès professionnel', children: [
          _Row('Victoires', '${p['victoires'] ?? '—'}  (KO ${p['victoires_ko'] ?? '—'} · Sou. ${p['victoires_soumission'] ?? '—'} · Déc. ${p['victoires_decision'] ?? '—'})'),
          _Row('Défaites', '${p['defaites'] ?? '—'}  (KO ${p['defaites_ko'] ?? '—'} · Sou. ${p['defaites_soumission'] ?? '—'} · Déc. ${p['defaites_decision'] ?? '—'})'),
          if ((p['nuls'] ?? 0) != 0) _Row('Nuls', '${p['nuls']}'),
          if ((p['sans_decision'] ?? 0) != 0) _Row('Sans décision', '${p['sans_decision']}'),
          if (u['combats_ufc'] != null) _Row('Combats à l’UFC', '${u['combats_ufc']} (${u['victoires_ufc']} V – ${u['defaites_ufc']} D)'),
          if ((u['bonus_fotn'] ?? 0) != 0) _Row('Bonus « Combat de la soirée »', '${u['bonus_fotn']}'),
          if ((u['bonus_potn'] ?? 0) != 0) _Row('Bonus « Performance de la soirée »', '${u['bonus_potn']}'),
          if ((u['victoires_decision_5_rounds'] ?? 0) != 0)
            _Row('Victoires par décision en 5 rounds', '${u['victoires_decision_5_rounds']}'),
        ]),
        if (f.accomplissements.isNotEmpty)
          _Section(title: 'Distinctions (Wikipedia, en anglais)', children: [
            for (final a in f.accomplissements.take(12))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• $a', style: const TextStyle(fontSize: 13)),
              ),
          ]),
        if (cards.isNotEmpty)
          _Section(title: 'Cartes (${cards.length})', children: [
            for (final c in cards)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Text('#${c.numero}', style: const TextStyle(fontWeight: FontWeight.w700)),
                title: Text(editions[c.editionId]?.nom ?? c.editionId),
                subtitle: c.sousTitre != null ? Text(c.sousTitre!) : null,
                onTap: () => context.go('/album/${c.editionId}'),
              ),
          ]),
        _Section(title: 'Sources', children: [
          for (final e in f.sources.entries)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.link, size: 18),
              title: Text(_sourceLabels[e.key] ?? e.key),
              subtitle: Text(e.value, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => launchUrl(Uri.parse(e.value), mode: LaunchMode.externalApplication),
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
