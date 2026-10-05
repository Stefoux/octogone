import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models.dart';
import '../local/database.dart';
import '../sync/content_sync.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final supabaseProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

Json _decode(String payload) => (jsonDecode(payload) as Map).cast<String, dynamic>();

// -----------------------------------------------------------------------------
// Synchronisation
// -----------------------------------------------------------------------------

class SyncStatus {
  const SyncStatus({this.running = false, this.lastSync, this.error, this.received = 0});
  final bool running;
  final DateTime? lastSync;
  final String? error;
  final int received;
}

class SyncController extends Notifier<SyncStatus> {
  @override
  SyncStatus build() => const SyncStatus();

  Future<void> sync() async {
    if (state.running) return;
    state = SyncStatus(running: true, lastSync: state.lastSync);
    try {
      final report = await ContentSync(ref.read(databaseProvider), ref.read(supabaseProvider)).syncAll();
      state = SyncStatus(lastSync: DateTime.now(), received: report.values.sum);
    } catch (e) {
      // Hors ligne : on garde le cache, on signale simplement l'échec.
      state = SyncStatus(lastSync: state.lastSync, error: '$e');
    }
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncStatus>(SyncController.new);

// -----------------------------------------------------------------------------
// Lecture du cache (flux Drift : l'UI se met à jour dès qu'une synchro arrive)
// -----------------------------------------------------------------------------

final fightersProvider = StreamProvider<List<Fighter>>((ref) {
  final db = ref.watch(databaseProvider);
  final q = db.select(db.fighters)..orderBy([(t) => OrderingTerm.asc(t.nom)]);
  return q.watch().map((rows) => [for (final r in rows) Fighter(_decode(r.payload))]);
});

final fighterProvider = Provider.family<AsyncValue<Fighter?>, String>((ref, id) {
  return ref.watch(fightersProvider).whenData((list) => list.firstWhereOrNull((f) => f.id == id));
});

final imagesProvider = StreamProvider<Map<String, ImageRef>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.images).watch().map(
        (rows) => {for (final r in rows) r.id: ImageRef(_decode(r.payload))},
      );
});

/// Photos de carte par combattant puis par rareté (fighter_id -> rareté -> image).
final cardPhotosProvider = Provider<Map<String, Map<String, ImageRef>>>((ref) {
  final out = <String, Map<String, ImageRef>>{};
  for (final img in (ref.watch(imagesProvider).value ?? const <String, ImageRef>{}).values) {
    final f = img.fighterId;
    if (f == null || img.raretes.isEmpty) continue;
    final byRarity = out.putIfAbsent(f, () => {});
    for (final r in img.raretes) {
      byRarity[r] = img;
    }
  }
  return out;
});

final editionsProvider = StreamProvider<List<Edition>>((ref) {
  final db = ref.watch(databaseProvider);
  final q = db.select(db.editions)..orderBy([(t) => OrderingTerm.desc(t.annee)]);
  return q.watch().map((rows) => [for (final r in rows) Edition(_decode(r.payload))]);
});

final seriesForEditionProvider = StreamProvider.family<List<CardSeries>, String>((ref, editionId) {
  final db = ref.watch(databaseProvider);
  final q = db.select(db.seriesTable)
    ..where((t) => t.editionId.equals(editionId))
    ..orderBy([(t) => OrderingTerm.asc(t.ordre)]);
  return q.watch().map((rows) => [for (final r in rows) CardSeries(_decode(r.payload))]);
});

final cardsForEditionProvider = StreamProvider.family<List<CardDef>, String>((ref, editionId) {
  final db = ref.watch(databaseProvider);
  final q = db.select(db.cards)
    ..where((t) => t.editionId.equals(editionId))
    ..orderBy([(t) => OrderingTerm.asc(t.ordre)]);
  return q.watch().map((rows) => [for (final r in rows) CardDef(_decode(r.payload))]);
});

final cardsForFighterProvider = StreamProvider.family<List<CardDef>, String>((ref, fighterId) {
  final db = ref.watch(databaseProvider);
  // fighter_ids est stocké « a,b » : on encadre de virgules pour un match exact.
  final q = db.select(db.cards)
    ..where((t) => (const Constant(',') + t.fighterIds + const Constant(',')).like('%,$fighterId,%'))
    ..orderBy([(t) => OrderingTerm.asc(t.editionId), (t) => OrderingTerm.asc(t.ordre)]);
  return q.watch().map((rows) => [for (final r in rows) CardDef(_decode(r.payload))]);
});

final variantsForEditionProvider = StreamProvider.family<List<Variant>, String>((ref, editionId) {
  final db = ref.watch(databaseProvider);
  final q = db.select(db.variants)..where((t) => t.editionId.equals(editionId));
  return q.watch().map(
        (rows) => [for (final r in rows) Variant(_decode(r.payload))]..sort((a, b) => a.ordre.compareTo(b.ordre)),
      );
});

// -----------------------------------------------------------------------------
// Index en mémoire (quelques milliers de lignes au plus)
// -----------------------------------------------------------------------------

final allCardsProvider = StreamProvider<Map<String, CardDef>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.cards).watch().map((rows) => {for (final r in rows) r.id: CardDef(_decode(r.payload))});
});

final allSeriesProvider = StreamProvider<Map<String, CardSeries>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.seriesTable).watch().map((rows) => {for (final r in rows) r.id: CardSeries(_decode(r.payload))});
});

final allVariantsProvider = StreamProvider<Map<String, Variant>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.variants).watch().map((rows) => {for (final r in rows) r.id: Variant(_decode(r.payload))});
});

final editionsByIdProvider = Provider<Map<String, Edition>>((ref) {
  return {for (final e in ref.watch(editionsProvider).value ?? const <Edition>[]) e.id: e};
});

final fightersByIdProvider = Provider<Map<String, Fighter>>((ref) {
  return {for (final f in ref.watch(fightersProvider).value ?? const <Fighter>[]) f.id: f};
});

final eventsProvider = StreamProvider<Map<String, EventInfo>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.events).watch().map((rows) => {for (final r in rows) r.id: EventInfo(_decode(r.payload))});
});

final rivalriesProvider = StreamProvider<List<Rivalry>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.rivalries).watch().map(
        (rows) => [for (final r in rows) Rivalry(_decode(r.payload))]..sort((a, b) => b.nbCombats.compareTo(a.nbCombats)),
      );
});

/// Cartes possédées par le joueur connecté.
final ownedCardsProvider = StreamProvider<List<OwnedCard>>((ref) {
  final db = ref.watch(databaseProvider);
  final uid = ref.watch(supabaseProvider).auth.currentUser?.id;
  final q = db.select(db.ownedCards)..where((t) => t.ownerId.equals(uid ?? ''));
  return q.watch().map((rows) => [for (final r in rows) OwnedCard(_decode(r.payload))]);
});

/// Exemplaires possédés, regroupés par carte.
final ownedByCardProvider = Provider<Map<String, List<OwnedCard>>>((ref) {
  final out = <String, List<OwnedCard>>{};
  for (final o in ref.watch(ownedCardsProvider).value ?? const <OwnedCard>[]) {
    out.putIfAbsent(o.cardId, () => []).add(o);
  }
  return out;
});
