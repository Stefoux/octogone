import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../local/database.dart';

/// Rapatrie le contenu de Supabase dans le cache Drift.
///
/// Pour chaque table, on ne demande que les lignes modifiées depuis la
/// dernière synchronisation (`updated_at`). Les suppressions sont des
/// suppressions douces (`deleted = true`) répercutées localement. C'est ce qui
/// permet d'ajouter combattants, éditions et événements sans réinstaller l'app.
class ContentSync {
  ContentSync(this.db, this.client);

  final AppDatabase db;
  final SupabaseClient client;

  static const pageSize = 1000;

  /// Ordre : les images d'abord (référencées par combattants et cartes).
  static const tables = ['images', 'events', 'fighters', 'editions', 'series', 'variants', 'cards'];

  Future<Map<String, int>> syncAll() async {
    final report = <String, int>{};
    for (final t in tables) {
      report[t] = await _syncTable(t);
    }
    return report;
  }

  Future<int> _syncTable(String table) async {
    final state = await (db.select(db.syncState)..where((s) => s.remoteTable.equals(table)))
        .getSingleOrNull();
    final since = state?.lastUpdatedAt ?? DateTime.utc(2000);
    var offset = 0;
    var count = 0;
    DateTime? newest;
    while (true) {
      // gte + offset : les lignes importées en bloc partagent le même
      // updated_at, une pagination sur « > dernier » en sauterait.
      final rows = await client
          .from(table)
          .select()
          .gte('updated_at', since.toUtc().toIso8601String())
          .order('updated_at')
          .order('id')
          .range(offset, offset + pageSize - 1);
      if (rows.isEmpty) break;
      await db.batch((b) {
        for (final row in rows) {
          _apply(b, table, row);
        }
      });
      for (final row in rows) {
        final u = DateTime.parse(row['updated_at'] as String);
        if (newest == null || u.isAfter(newest)) newest = u;
      }
      count += rows.length;
      if (rows.length < pageSize) break;
      offset += pageSize;
    }
    if (newest != null) {
      await db.into(db.syncState).insertOnConflictUpdate(
            SyncStateCompanion.insert(remoteTable: table, lastUpdatedAt: newest),
          );
    }
    return count;
  }

  void _apply(Batch b, String table, Map<String, dynamic> row) {
    final id = '${row['id']}';
    final deleted = row['deleted'] == true;
    final payload = jsonEncode(row);
    final updated = DateTime.parse(row['updated_at'] as String);
    switch (table) {
      case 'fighters':
        deleted
            ? b.deleteWhere(db.fighters, (t) => t.id.equals(id))
            : b.insert(
                db.fighters,
                FightersCompanion.insert(
                  id: id,
                  payload: payload,
                  updatedAt: updated,
                  nom: row['nom'] as String,
                  categorie: Value(row['categorie'] as String?),
                ),
                mode: InsertMode.insertOrReplace,
              );
      case 'editions':
        deleted
            ? b.deleteWhere(db.editions, (t) => t.id.equals(id))
            : b.insert(
                db.editions,
                EditionsCompanion.insert(
                  id: id,
                  payload: payload,
                  updatedAt: updated,
                  annee: (row['annee'] as num).toInt(),
                ),
                mode: InsertMode.insertOrReplace,
              );
      case 'series':
        deleted
            ? b.deleteWhere(db.seriesTable, (t) => t.id.equals(id))
            : b.insert(
                db.seriesTable,
                SeriesTableCompanion.insert(
                  id: id,
                  payload: payload,
                  updatedAt: updated,
                  editionId: row['edition_id'] as String,
                  ordre: (row['ordre'] as num?)?.toInt() ?? 0,
                ),
                mode: InsertMode.insertOrReplace,
              );
      case 'cards':
        deleted
            ? b.deleteWhere(db.cards, (t) => t.id.equals(id))
            : b.insert(
                db.cards,
                CardsCompanion.insert(
                  id: id,
                  payload: payload,
                  updatedAt: updated,
                  editionId: row['edition_id'] as String,
                  seriesId: row['series_id'] as String,
                  ordre: (row['ordre'] as num).toInt(),
                  fighterIds: ((row['fighter_ids'] as List?) ?? const []).join(','),
                ),
                mode: InsertMode.insertOrReplace,
              );
      case 'variants':
        deleted
            ? b.deleteWhere(db.variants, (t) => t.id.equals(id))
            : b.insert(
                db.variants,
                VariantsCompanion.insert(
                  id: id,
                  payload: payload,
                  updatedAt: updated,
                  seriesId: Value(row['series_id'] as String?),
                  editionId: Value(row['edition_id'] as String?),
                ),
                mode: InsertMode.insertOrReplace,
              );
      case 'images':
        deleted
            ? b.deleteWhere(db.images, (t) => t.id.equals(id))
            : b.insert(
                db.images,
                ImagesCompanion.insert(
                  id: id,
                  payload: payload,
                  updatedAt: updated,
                  fighterId: Value(row['fighter_id'] as String?),
                ),
                mode: InsertMode.insertOrReplace,
              );
      case 'events':
        deleted
            ? b.deleteWhere(db.events, (t) => t.id.equals(id))
            : b.insert(
                db.events,
                EventsCompanion.insert(id: id, payload: payload, updatedAt: updated),
                mode: InsertMode.insertOrReplace,
              );
    }
  }
}
