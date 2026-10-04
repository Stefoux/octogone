import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Cache local du contenu (combattants, éditions, cartes…).
///
/// Chaque ligne garde la ligne Supabase complète en JSON (`payload`) plus
/// quelques colonnes indexées pour filtrer. Ainsi, un nouveau champ ajouté
/// côté serveur arrive sur l'appareil sans migration de la base locale.
mixin _SyncedRow on Table {
  TextColumn get id => text()();
  TextColumn get payload => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('FighterRow')
class Fighters extends Table with _SyncedRow {
  TextColumn get nom => text()();
  TextColumn get categorie => text().nullable()();
}

@DataClassName('EditionRow')
class Editions extends Table with _SyncedRow {
  IntColumn get annee => integer()();
}

@DataClassName('SeriesRow')
class SeriesTable extends Table with _SyncedRow {
  @override
  String get tableName => 'series';
  TextColumn get editionId => text()();
  IntColumn get ordre => integer()();
}

@DataClassName('CardRow')
class Cards extends Table with _SyncedRow {
  TextColumn get editionId => text()();
  TextColumn get seriesId => text()();
  IntColumn get ordre => integer()();

  /// Identifiants des combattants, séparés par des virgules (recherche simple).
  TextColumn get fighterIds => text()();
}

@DataClassName('VariantRow')
class Variants extends Table with _SyncedRow {
  TextColumn get seriesId => text().nullable()();
  TextColumn get editionId => text().nullable()();
}

@DataClassName('ImageRow')
class Images extends Table with _SyncedRow {
  TextColumn get fighterId => text().nullable()();
}

@DataClassName('EventRow')
class Events extends Table with _SyncedRow {}

@DataClassName('RivalryRow')
class Rivalries extends Table with _SyncedRow {
  TextColumn get fighterA => text()();
  TextColumn get fighterB => text()();
}

/// Exemplaires possédés par le joueur connecté (copie locale pour le hors ligne).
@DataClassName('OwnedCardRow')
class OwnedCards extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text()();
  TextColumn get cardId => text()();
  TextColumn get variantId => text()();
  TextColumn get payload => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Dernier `updated_at` reçu pour chaque table distante.
@DataClassName('SyncStateRow')
class SyncState extends Table {
  TextColumn get remoteTable => text()();
  DateTimeColumn get lastUpdatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {remoteTable};
}

@DriftDatabase(tables: [Fighters, Editions, SeriesTable, Cards, Variants, Images, Events, Rivalries, OwnedCards, SyncState])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(rivalries);
            await m.createTable(ownedCards);
          }
        },
      );

  static QueryExecutor _openConnection() => driftDatabase(name: 'octogone');
}
