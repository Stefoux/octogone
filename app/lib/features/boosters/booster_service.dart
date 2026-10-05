import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/content_providers.dart';
import '../../data/sync/content_sync.dart';
import '../../domain/models.dart';

/// État des boosters gratuits du joueur (fonction serveur booster_status).
class BoosterStatus {
  const BoosterStatus({
    required this.testMode,
    required this.charges,
    required this.capacity,
    required this.nextIn,
    required this.pityThreshold,
    required this.sinceLegendary,
    required this.fetchedAt,
  });

  factory BoosterStatus.fromJson(Map<String, dynamic> j) => BoosterStatus(
        testMode: j['mode_test'] == true,
        charges: (j['charges'] as num?)?.toInt() ?? 0,
        capacity: (j['capacite'] as num?)?.toInt() ?? 0,
        nextIn: j['prochain_dans_s'] == null
            ? null
            : Duration(milliseconds: ((j['prochain_dans_s'] as num) * 1000).round()),
        pityThreshold: (j['pity_legendaire'] as num?)?.toInt() ?? 40,
        sinceLegendary: (j['depuis_legendaire'] as num?)?.toInt() ?? 0,
        fetchedAt: DateTime.now(),
      );

  final bool testMode;
  final int charges;
  final int capacity;
  final Duration? nextIn;
  final int pityThreshold;
  final int sinceLegendary;
  final DateTime fetchedAt;

  /// Temps restant avant la prochaine recharge, à l'instant [now].
  Duration? remaining(DateTime now) {
    if (nextIn == null) return null;
    final left = nextIn! - now.difference(fetchedAt);
    return left.isNegative ? Duration.zero : left;
  }

  /// Boosters encore possibles avant la légendaire garantie.
  int get pityLeft => (pityThreshold - sinceLegendary).clamp(1, pityThreshold);
}

/// Carte obtenue dans un booster (ordre de révélation : les plus rares à la fin).
class PulledCard {
  PulledCard(Map<String, dynamic> j)
      : ownedId = j['owned_id'] as String,
        cardId = j['card_id'] as String,
        variantId = j['variant_id'] as String,
        rarete = j['rarete'] as String,
        numeroSerie = (j['numero_serie'] as num?)?.toInt(),
        tirage = (j['tirage'] as num?)?.toInt(),
        isNew = j['nouvelle'] == true;

  final String ownedId;
  final String cardId;
  final String variantId;
  final String rarete;
  final int? numeroSerie;
  final int? tirage;
  final bool isNew;

  OwnedCard toOwned() => OwnedCard({
        'id': ownedId,
        'card_id': cardId,
        'variant_id': variantId,
        'numero_serie': numeroSerie,
        'tirage': tirage,
        'origine': 'booster',
      });
}

/// Erreurs métier renvoyées par le serveur.
enum BoosterError { noFreePack, notEnoughCoins, unavailable, other }

class BoosterException implements Exception {
  BoosterException(this.kind, [this.message]);
  final BoosterError kind;
  final String? message;

  @override
  String toString() => 'BoosterException($kind, $message)';
}

abstract class BoosterService {
  Future<BoosterStatus> status();

  /// [payment] : 'gratuit' (recharge gratuite, Standard) ou 'pieces'.
  Future<List<PulledCard>> open(String typeId, {String payment = 'gratuit'});
}

class SupabaseBoosterService implements BoosterService {
  SupabaseBoosterService(this.ref);
  final Ref ref;

  SupabaseClient get _client => ref.read(supabaseProvider);

  @override
  Future<BoosterStatus> status() async {
    final r = await _client.rpc<Map<String, dynamic>>('booster_status');
    return BoosterStatus.fromJson(r);
  }

  @override
  Future<List<PulledCard>> open(String typeId, {String payment = 'gratuit'}) async {
    try {
      final rows = await _client.rpc<List<dynamic>>('open_booster', params: {'p_type': typeId, 'p_paiement': payment});
      // Copie locale des cartes à jour (album, compteur), sans bloquer la révélation.
      await ContentSync(ref.read(databaseProvider), _client).syncOwnedCards();
      return [for (final r in rows) PulledCard((r as Map).cast<String, dynamic>())];
    } on PostgrestException catch (e) {
      throw BoosterException(
        switch (e.code) {
          'P0002' => BoosterError.noFreePack,
          'P0004' => BoosterError.notEnoughCoins,
          'P0003' => BoosterError.unavailable,
          _ => BoosterError.other,
        },
        e.message,
      );
    }
  }
}

final boosterServiceProvider = Provider<BoosterService>(SupabaseBoosterService.new);

final boosterStatusProvider = FutureProvider<BoosterStatus>((ref) => ref.watch(boosterServiceProvider).status());

/// Types de boosters (contenu synchronisé), triés.
final boosterTypesProvider = StreamProvider<List<BoosterType>>((ref) {
  final db = ref.watch(databaseProvider);
  final q = db.select(db.boosterTypes)..orderBy([(t) => OrderingTerm.asc(t.ordre)]);
  return q.watch().map((rows) => [
        for (final r in rows) BoosterType((jsonDecode(r.payload) as Map).cast<String, dynamic>()),
      ]);
});

/// Portefeuille du joueur : pièces et fragments.
class Wallet {
  const Wallet({required this.pieces, required this.fragments});
  final int pieces;
  final int fragments;
}

final walletProvider = FutureProvider<Wallet?>((ref) async {
  final client = ref.watch(supabaseProvider);
  final uid = client.auth.currentUser?.id;
  if (uid == null) return null;
  final row = await client.from('wallets').select('pieces, fragments').eq('user_id', uid).maybeSingle();
  if (row == null) return null;
  return Wallet(pieces: (row['pieces'] as num).toInt(), fragments: (row['fragments'] as num).toInt());
});

/// Collection affichée sur l'accueil (mémorisée sur l'appareil). Par défaut :
/// celle du booster « en vedette ».
class SelectedCollection extends Notifier<String?> {
  static const _key = 'collection_courante';

  @override
  String? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(_key);
      if (v != null) state = v;
    } catch (_) {}
  }

  Future<void> select(String editionId) async {
    state = editionId;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, editionId);
    } catch (_) {}
  }
}

final selectedCollectionProvider = NotifierProvider<SelectedCollection, String?>(SelectedCollection.new);

/// Boosters de la collection affichée sur l'accueil.
final currentBoostersProvider = Provider<List<BoosterType>>((ref) {
  final all = (ref.watch(boosterTypesProvider).value ?? const <BoosterType>[])
      .where((b) => b.availableAt(DateTime.now()))
      .toList();
  if (all.isEmpty) return const [];
  final selected = ref.watch(selectedCollectionProvider);
  final edition = (selected != null && all.any((b) => b.editionId == selected))
      ? selected
      : (all.firstWhereOrNull((b) => b.enVedette) ?? all.first).editionId;
  return all.where((b) => b.editionId == edition).toList();
});
