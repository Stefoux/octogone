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
