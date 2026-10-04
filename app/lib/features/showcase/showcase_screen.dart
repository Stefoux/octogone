import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repositories/content_providers.dart';
import '../../domain/models.dart';
import '../cards/card_detail_screen.dart' show openPreview;
import '../cards/card_view.dart';
import '../cards/trading_card.dart';

/// Raretés originales qui n'existent que sur des cartes spéciales (duel,
/// événement, célébration) : définies ici pour l'aperçu.
const _specialRarities = {
  'face_a_face': ('rare', 2),
  'main_levee': ('epique', 4),
  'moment': ('legendaire', 5),
  'trilogie': ('mythique', 6),
};

/// Ordre d'affichage des raretés originales.
const _originalOrder = [
  'acier', 'neon', 'face_a_face', 'cicatrice', 'onde_de_choc', 'cle_fatale', 'main_levee',
  'ceinture_or', 'heritage', 'moment', 'trilogie', 'octogone_noir',
];

/// Vitrine des effets : chaque rareté sur un vrai combattant éligible (avec
/// photo), à ouvrir en grand pour voir les reflets bouger.
class ShowcaseScreen extends ConsumerWidget {
  const ShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final samples = _buildSamples(ref);
    return Scaffold(
      appBar: AppBar(title: Text(l.effectsShowcase)),
      body: samples.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: Text(l.showcaseIntro, style: const TextStyle(color: AppColors.textMuted)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: kCardAspect * 0.86,
                  ),
                  itemCount: samples.length,
                  itemBuilder: (context, i) {
                    final v = samples[i];
                    final color = AppColors.rarity[v.variant.rarete] ?? AppColors.steel;
                    return GestureDetector(
                      onTap: () => openPreview(context, v),
                      child: Column(children: [
                        Expanded(child: TradingCard(view: v, animate: false)),
                        const SizedBox(height: 6),
                        Text(variantLabel(l, v.effect, v.variant.nom),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12.5)),
                        Text(rarityLabel(l, v.variant.rarete),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ]),
                    );
                  },
                ),
              ),
            ]),
    );
  }

  List<CardView> _buildSamples(WidgetRef ref) {
    final fighters = ref.watch(fightersProvider).value ?? const <Fighter>[];
    final variants = ref.watch(allVariantsProvider).value ?? const <String, Variant>{};
    final editions = ref.watch(editionsProvider).value ?? const <Edition>[];
    final rivalries = ref.watch(rivalriesProvider).value ?? const <Rivalry>[];
    final events = ref.watch(eventsProvider).value ?? const <String, EventInfo>{};
    if (fighters.isEmpty || variants.isEmpty || editions.isEmpty) return const [];

    final withPhoto = fighters.where((f) => f.imageId != null).toList()
      ..sort((a, b) => b.stats.overall.compareTo(a.stats.overall));
    final byId = {for (final f in fighters) f.id: f};
    final used = <String>{};

    Fighter? pick(bool Function(Fighter f) ok) {
      final f = withPhoto.firstWhereOrNull((f) => !used.contains(f.id) && ok(f)) ??
          withPhoto.firstWhereOrNull(ok);
      if (f != null) used.add(f.id);
      return f;
    }

    final original = editions.firstWhereOrNull((e) => e.type == 'originale');
    final real = editions.firstWhereOrNull((e) => e.isReal);
    final out = <CardView>[];

    // --- Raretés originales ---
    final seasonVariants = {
      for (final v in variants.values.where((v) => v.editionId == original?.id)) v.effet: v,
    };
    for (final effet in _originalOrder) {
      Variant? variant = seasonVariants[effet];
      if (variant == null && _specialRarities.containsKey(effet)) {
        final (rarete, bonus) = _specialRarities[effet]!;
        variant = Variant({
          'id': 'apercu:$effet', 'nom': effet, 'rarete': rarete, 'effet': effet, 'reel': false,
          'bonus_stats': bonus, 'tirage': effet == 'trilogie' ? 3 : (effet == 'moment' ? 250 : null),
          'edition_id': original?.id,
        });
      }
      if (variant == null) continue;
      final rule = variant.eligibilite;

      if (effet == 'face_a_face' || effet == 'trilogie') {
        final need = effet == 'trilogie' ? 3 : 2;
        final r = rivalries.firstWhereOrNull((r) =>
            r.nbCombats >= need &&
            byId[r.fighterA]?.imageId != null &&
            byId[r.fighterB]?.imageId != null &&
            !used.contains(r.id));
        if (r == null) continue;
        used.add(r.id);
        out.add(CardView(variant: variant, fighters: [byId[r.fighterA]!, byId[r.fighterB]!], rivalry: r, edition: original));
        continue;
      }
      if (effet == 'moment') {
        final ev = events.values.firstOrNull;
        if (ev == null) continue;
        // Vainqueur du combat principal (premier résultat) s'il est dans la base.
        final winner = fighters.firstWhereOrNull((f) => ev.resultat('fr')?.startsWith(f.nom) ?? false);
        out.add(CardView(variant: variant, fighters: [?winner], event: ev, edition: original));
        continue;
      }
      final f = effet == 'main_levee'
          ? pick((f) => f.championActuel)
          : pick((f) => Eligibility.isEligible(rule, f.json));
      if (f == null) continue;
      out.add(CardView(variant: variant, fighters: [f], edition: original));
    }

    // --- Parallèles réels (2024 Topps Chrome UFC, série de base) ---
    if (real != null) {
      final base = variants.values
          .where((v) => v.editionId == real.id && v.seriesId?.endsWith(':BASE') == true)
          .sortedBy<num>((v) => v.ordre);
      for (final v in base) {
        final f = pick((_) => true);
        if (f == null) break;
        out.add(CardView(variant: v, fighters: [f], edition: real));
      }
    }
    return out;
  }
}
