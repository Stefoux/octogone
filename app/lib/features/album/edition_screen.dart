import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../data/repositories/content_providers.dart';
import '../../domain/models.dart';
import '../../widgets/fighter_widgets.dart';

/// Checklist d'une édition : séries, parallèles (tirages réels) et cartes.
class EditionScreen extends ConsumerWidget {
  const EditionScreen({super.key, required this.editionId});
  final String editionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final edition = (ref.watch(editionsProvider).value ?? const <Edition>[])
        .where((e) => e.id == editionId)
        .firstOrNull;
    final series = ref.watch(seriesForEditionProvider(editionId)).value ?? const [];
    final cards = ref.watch(cardsForEditionProvider(editionId)).value ?? const [];
    final variants = ref.watch(variantsForEditionProvider(editionId)).value ?? const [];

    if (edition == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }
    final bySeries = <String, List<CardDef>>{};
    for (final c in cards) {
      bySeries.putIfAbsent(c.seriesId, () => []).add(c);
    }
    final variantsBySeries = <String, List<Variant>>{};
    for (final v in variants) {
      if (v.seriesId != null) variantsBySeries.putIfAbsent(v.seriesId!, () => []).add(v);
    }

    return Scaffold(
      appBar: AppBar(title: Text(edition.nom)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Text(
            [
              if (edition.dateSortie != null) 'Sortie : ${edition.dateSortie}',
              '${cards.length} cartes',
              '${series.length} séries',
            ].join(' · '),
            style: const TextStyle(color: AppColors.textMuted),
          ),
          if (edition.description != null) ...[
            const SizedBox(height: 8),
            Text(edition.description!),
          ],
          const SizedBox(height: 8),
          ToVerifyBanner(fields: edition.aVerifier),
          const SizedBox(height: 8),
          for (final s in series)
            _SeriesTile(
              series: s,
              cards: bySeries[s.id] ?? const [],
              variants: variantsBySeries[s.id] ?? const [],
            ),
          if (edition.sources.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Sources de la checklist', style: TextStyle(fontWeight: FontWeight.w700)),
            for (final url in edition.sources)
              TextButton(
                style: TextButton.styleFrom(alignment: Alignment.centerLeft, padding: EdgeInsets.zero),
                onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                child: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
          ],
        ],
      ),
    );
  }
}

class _SeriesTile extends StatelessWidget {
  const _SeriesTile({required this.series, required this.cards, required this.variants});
  final CardSeries series;
  final List<CardDef> cards;
  final List<Variant> variants;

  @override
  Widget build(BuildContext context) {
    final s = series;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          shape: const Border(),
          title: Text(s.nom, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text([
            s.typeLabel,
            '${cards.length} cartes',
            if (s.tirage != null) 'numérotée /${s.tirage}',
            if (s.cote != null) 'cote ${s.cote}',
          ].join(' · '), maxLines: 2, overflow: TextOverflow.ellipsis),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [
            if (s.exclusivite != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(s.exclusivite!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ),
            if (variants.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Parallèles', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final v in variants) _VariantChip(variant: v)],
              ),
              const SizedBox(height: 12),
            ],
            for (final c in cards) _CardRow(card: c),
          ],
        ),
      ),
    );
  }
}

class _VariantChip extends StatelessWidget {
  const _VariantChip({required this.variant});
  final Variant variant;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.rarity[variant.rarete] ?? AppColors.steel;
    return Tooltip(
      message: [rarityLabels[variant.rarete], variant.cote, variant.exclusivite].whereType<String>().join(' · '),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: .6)),
          color: color.withValues(alpha: .1),
        ),
        child: Text(
          variant.tirage == null ? variant.nom : '${variant.nom} ${variant.tirageLabel}',
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.card});
  final CardDef card;

  @override
  Widget build(BuildContext context) {
    final fighterId = card.fighterIds.firstOrNull;
    return InkWell(
      onTap: fighterId == null ? null : () => context.go('/combattants/$fighterId'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(card.numero, style: const TextStyle(color: AppColors.textMuted, fontFeatures: [])),
            ),
            Expanded(
              child: Text.rich(TextSpan(children: [
                TextSpan(text: card.nomImprime, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (card.sousTitre != null)
                  TextSpan(text: '  « ${card.sousTitre} »', style: const TextStyle(color: AppColors.textMuted)),
              ])),
            ),
            if (card.isRookie)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.crimson, borderRadius: BorderRadius.circular(4)),
                child: const Text('RC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
              ),
          ],
        ),
      ),
    );
  }
}
