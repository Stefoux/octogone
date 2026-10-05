import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/content_providers.dart';
import '../../data/sync/content_sync.dart';
import '../../domain/models.dart';
import '../boosters/booster_service.dart';
import '../defis/defis_service.dart';
import '../vitrine/vitrine_service.dart';

/// Barème des fragments (economy_config.fragments) : gain au recyclage par
/// rareté ; la fabrication coûte [factor] fois ce gain.
class FragmentRates {
  const FragmentRates({required this.recycle, required this.factor});

  factory FragmentRates.fromJson(Map<String, dynamic> j) => FragmentRates(
        recycle: {
          for (final e in ((j['recyclage'] as Map?) ?? const {}).entries) e.key as String: (e.value as num).toInt(),
        },
        factor: (j['facteur_fabrication'] as num?)?.toInt() ?? 6,
      );

  /// Valeurs par défaut (identiques à la migration) si le serveur est injoignable.
  static const fallback = FragmentRates(
    recycle: {'commune': 5, 'peu_commune': 15, 'rare': 40, 'epique': 100, 'legendaire': 400, 'mythique': 1600},
    factor: 6,
  );

  final Map<String, int> recycle;
  final int factor;

  int gain(String rarete) => recycle[rarete] ?? 0;

  /// Coût de fabrication, ou null si la variante ne se fabrique pas
  /// (numérotée ou réservée aux cartes spéciales) — même règle que le serveur.
  int? craftCost(Variant v, {CardSeries? series}) {
    if (v.tirage != null || series?.tirage != null) return null;
    if (v.eligibilite?.containsKey('carte') ?? false) return null;
    return gain(v.rarete) * factor;
  }
}

final fragmentRatesProvider = FutureProvider<FragmentRates>((ref) async {
  try {
    final row = await ref.watch(supabaseProvider).from('economy_config').select('fragments').maybeSingle();
    final j = row?['fragments'];
    return j is Map ? FragmentRates.fromJson(j.cast<String, dynamic>()) : FragmentRates.fallback;
  } catch (_) {
    return FragmentRates.fallback;
  }
});

/// Erreurs de l'atelier renvoyées par le serveur.
enum AtelierError { notEnoughFragments, notRecyclable, keepOne, notCraftable, notEligible, other }

class AtelierException implements Exception {
  AtelierException(this.kind, [this.message]);
  final AtelierError kind;
  final String? message;

  static AtelierException from(Object e) {
    if (e is AtelierException) return e;
    if (e is PostgrestException) {
      return AtelierException(
        switch (e.code) {
          'P0004' => AtelierError.notEnoughFragments,
          'P0008' => AtelierError.notRecyclable,
          'P0009' => AtelierError.keepOne,
          'P0010' => AtelierError.notCraftable,
          'P0011' => AtelierError.notEligible,
          _ => AtelierError.other,
        },
        e.message,
      );
    }
    return AtelierException(AtelierError.other, '$e');
  }

  @override
  String toString() => 'AtelierException($kind, $message)';
}

/// Résultat d'un recyclage.
class RecycleResult {
  const RecycleResult({required this.cards, required this.gained, required this.fragments});
  final int cards;
  final int gained;
  final int fragments;
}

/// Appels serveur de l'atelier (remplacés par un faux dans les tests).
abstract class AtelierService {
  Future<RecycleResult> recycle(List<String> ownedIds);
  Future<void> craft(String cardId, String variantId);
  Future<void> protect(String ownedId, bool protect);
}

class SupabaseAtelierService implements AtelierService {
  SupabaseAtelierService(this.ref);
  final Ref ref;

  SupabaseClient get _client => ref.read(supabaseProvider);

  Future<void> _refresh() async {
    await ContentSync(ref.read(databaseProvider), _client).syncOwnedCards();
    ref
      ..invalidate(walletProvider)
      ..invalidate(vitrineProvider)
      ..invalidate(defisProvider);
  }

  @override
  Future<RecycleResult> recycle(List<String> ownedIds) async {
    try {
      final rows = await _client.rpc<List<dynamic>>('recycler', params: {'p_ids': ownedIds});
      final r = (rows.first as Map).cast<String, dynamic>();
      await _refresh();
      return RecycleResult(
        cards: (r['cartes'] as num).toInt(),
        gained: (r['fragments_gagnes'] as num).toInt(),
        fragments: (r['fragments'] as num).toInt(),
      );
    } catch (e) {
      throw AtelierException.from(e);
    }
  }

  @override
  Future<void> craft(String cardId, String variantId) async {
    try {
      await _client.rpc<dynamic>('fabriquer', params: {'p_card': cardId, 'p_variant': variantId});
      await _refresh();
    } catch (e) {
      throw AtelierException.from(e);
    }
  }

  @override
  Future<void> protect(String ownedId, bool protect) async {
    try {
      await _client.rpc<void>('proteger', params: {'p_id': ownedId, 'p_protegee': protect});
      await _refresh();
    } catch (e) {
      throw AtelierException.from(e);
    }
  }
}

final atelierServiceProvider = Provider<AtelierService>(SupabaseAtelierService.new);

/// Un doublon recyclable et ce qu'il rapporte.
class Duplicate {
  const Duplicate({required this.owned, required this.rarete, required this.gain});
  final OwnedCard owned;
  final String rarete;
  final int gain;
}

/// Doublons recyclables (même règle que le serveur) : exemplaires en trop
/// d'une même carte dans la même variante, hors numérotées, copies admin,
/// cartes protégées ou exposées ; on garde toujours un exemplaire.
List<Duplicate> recyclableDuplicates({
  required List<OwnedCard> owned,
  required Map<String, Variant> variants,
  required Set<String> exposed,
  required FragmentRates rates,
}) {
  final out = <Duplicate>[];
  final groups = groupBy(owned, (OwnedCard o) => '${o.cardId}|${o.variantId}');
  for (final copies in groups.values) {
    if (copies.length < 2) continue;
    bool eligible(OwnedCard o) => !o.isNumbered && !o.copieAdmin && !o.verrouillee && !exposed.contains(o.id);
    final ok = copies.where(eligible).toList()..sortBy<DateTime>((o) => o.obtenueLe ?? DateTime(2000));
    // Si tous les exemplaires sont recyclables, on garde le plus ancien
    final candidates = ok.length == copies.length ? ok.skip(1) : ok;
    final rarete = variants[copies.first.variantId]?.rarete ?? 'commune';
    for (final o in candidates) {
      out.add(Duplicate(owned: o, rarete: rarete, gain: rates.gain(rarete)));
    }
  }
  return out;
}

final duplicatesProvider = Provider<List<Duplicate>>((ref) {
  final owned = ref.watch(ownedCardsProvider).value ?? const <OwnedCard>[];
  final variants = ref.watch(allVariantsProvider).value ?? const <String, Variant>{};
  final exposed = {...?ref.watch(vitrineProvider).value?.nonNulls};
  final rates = ref.watch(fragmentRatesProvider).value ?? FragmentRates.fallback;
  return recyclableDuplicates(owned: owned, variants: variants, exposed: exposed, rates: rates);
});
