// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $FightersTable extends Fighters
    with TableInfo<$FightersTable, FighterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FightersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomMeta = const VerificationMeta('nom');
  @override
  late final GeneratedColumn<String> nom = GeneratedColumn<String>(
    'nom',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categorieMeta = const VerificationMeta(
    'categorie',
  );
  @override
  late final GeneratedColumn<String> categorie = GeneratedColumn<String>(
    'categorie',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    payload,
    updatedAt,
    nom,
    categorie,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fighters';
  @override
  VerificationContext validateIntegrity(
    Insertable<FighterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('nom')) {
      context.handle(
        _nomMeta,
        nom.isAcceptableOrUnknown(data['nom']!, _nomMeta),
      );
    } else if (isInserting) {
      context.missing(_nomMeta);
    }
    if (data.containsKey('categorie')) {
      context.handle(
        _categorieMeta,
        categorie.isAcceptableOrUnknown(data['categorie']!, _categorieMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FighterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FighterRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      nom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nom'],
      )!,
      categorie: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categorie'],
      ),
    );
  }

  @override
  $FightersTable createAlias(String alias) {
    return $FightersTable(attachedDatabase, alias);
  }
}

class FighterRow extends DataClass implements Insertable<FighterRow> {
  final String id;
  final String payload;
  final DateTime updatedAt;
  final String nom;
  final String? categorie;
  const FighterRow({
    required this.id,
    required this.payload,
    required this.updatedAt,
    required this.nom,
    this.categorie,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['payload'] = Variable<String>(payload);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['nom'] = Variable<String>(nom);
    if (!nullToAbsent || categorie != null) {
      map['categorie'] = Variable<String>(categorie);
    }
    return map;
  }

  FightersCompanion toCompanion(bool nullToAbsent) {
    return FightersCompanion(
      id: Value(id),
      payload: Value(payload),
      updatedAt: Value(updatedAt),
      nom: Value(nom),
      categorie: categorie == null && nullToAbsent
          ? const Value.absent()
          : Value(categorie),
    );
  }

  factory FighterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FighterRow(
      id: serializer.fromJson<String>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      nom: serializer.fromJson<String>(json['nom']),
      categorie: serializer.fromJson<String?>(json['categorie']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'payload': serializer.toJson<String>(payload),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'nom': serializer.toJson<String>(nom),
      'categorie': serializer.toJson<String?>(categorie),
    };
  }

  FighterRow copyWith({
    String? id,
    String? payload,
    DateTime? updatedAt,
    String? nom,
    Value<String?> categorie = const Value.absent(),
  }) => FighterRow(
    id: id ?? this.id,
    payload: payload ?? this.payload,
    updatedAt: updatedAt ?? this.updatedAt,
    nom: nom ?? this.nom,
    categorie: categorie.present ? categorie.value : this.categorie,
  );
  FighterRow copyWithCompanion(FightersCompanion data) {
    return FighterRow(
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      nom: data.nom.present ? data.nom.value : this.nom,
      categorie: data.categorie.present ? data.categorie.value : this.categorie,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FighterRow(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('nom: $nom, ')
          ..write('categorie: $categorie')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payload, updatedAt, nom, categorie);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FighterRow &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.updatedAt == this.updatedAt &&
          other.nom == this.nom &&
          other.categorie == this.categorie);
}

class FightersCompanion extends UpdateCompanion<FighterRow> {
  final Value<String> id;
  final Value<String> payload;
  final Value<DateTime> updatedAt;
  final Value<String> nom;
  final Value<String?> categorie;
  final Value<int> rowid;
  const FightersCompanion({
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.nom = const Value.absent(),
    this.categorie = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FightersCompanion.insert({
    required String id,
    required String payload,
    required DateTime updatedAt,
    required String nom,
    this.categorie = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       payload = Value(payload),
       updatedAt = Value(updatedAt),
       nom = Value(nom);
  static Insertable<FighterRow> custom({
    Expression<String>? id,
    Expression<String>? payload,
    Expression<DateTime>? updatedAt,
    Expression<String>? nom,
    Expression<String>? categorie,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (nom != null) 'nom': nom,
      if (categorie != null) 'categorie': categorie,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FightersCompanion copyWith({
    Value<String>? id,
    Value<String>? payload,
    Value<DateTime>? updatedAt,
    Value<String>? nom,
    Value<String?>? categorie,
    Value<int>? rowid,
  }) {
    return FightersCompanion(
      id: id ?? this.id,
      payload: payload ?? this.payload,
      updatedAt: updatedAt ?? this.updatedAt,
      nom: nom ?? this.nom,
      categorie: categorie ?? this.categorie,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (nom.present) {
      map['nom'] = Variable<String>(nom.value);
    }
    if (categorie.present) {
      map['categorie'] = Variable<String>(categorie.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FightersCompanion(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('nom: $nom, ')
          ..write('categorie: $categorie, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EditionsTable extends Editions
    with TableInfo<$EditionsTable, EditionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EditionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _anneeMeta = const VerificationMeta('annee');
  @override
  late final GeneratedColumn<int> annee = GeneratedColumn<int>(
    'annee',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, payload, updatedAt, annee];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'editions';
  @override
  VerificationContext validateIntegrity(
    Insertable<EditionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('annee')) {
      context.handle(
        _anneeMeta,
        annee.isAcceptableOrUnknown(data['annee']!, _anneeMeta),
      );
    } else if (isInserting) {
      context.missing(_anneeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EditionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EditionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      annee: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}annee'],
      )!,
    );
  }

  @override
  $EditionsTable createAlias(String alias) {
    return $EditionsTable(attachedDatabase, alias);
  }
}

class EditionRow extends DataClass implements Insertable<EditionRow> {
  final String id;
  final String payload;
  final DateTime updatedAt;
  final int annee;
  const EditionRow({
    required this.id,
    required this.payload,
    required this.updatedAt,
    required this.annee,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['payload'] = Variable<String>(payload);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['annee'] = Variable<int>(annee);
    return map;
  }

  EditionsCompanion toCompanion(bool nullToAbsent) {
    return EditionsCompanion(
      id: Value(id),
      payload: Value(payload),
      updatedAt: Value(updatedAt),
      annee: Value(annee),
    );
  }

  factory EditionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EditionRow(
      id: serializer.fromJson<String>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      annee: serializer.fromJson<int>(json['annee']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'payload': serializer.toJson<String>(payload),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'annee': serializer.toJson<int>(annee),
    };
  }

  EditionRow copyWith({
    String? id,
    String? payload,
    DateTime? updatedAt,
    int? annee,
  }) => EditionRow(
    id: id ?? this.id,
    payload: payload ?? this.payload,
    updatedAt: updatedAt ?? this.updatedAt,
    annee: annee ?? this.annee,
  );
  EditionRow copyWithCompanion(EditionsCompanion data) {
    return EditionRow(
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      annee: data.annee.present ? data.annee.value : this.annee,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EditionRow(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('annee: $annee')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payload, updatedAt, annee);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EditionRow &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.updatedAt == this.updatedAt &&
          other.annee == this.annee);
}

class EditionsCompanion extends UpdateCompanion<EditionRow> {
  final Value<String> id;
  final Value<String> payload;
  final Value<DateTime> updatedAt;
  final Value<int> annee;
  final Value<int> rowid;
  const EditionsCompanion({
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.annee = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EditionsCompanion.insert({
    required String id,
    required String payload,
    required DateTime updatedAt,
    required int annee,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       payload = Value(payload),
       updatedAt = Value(updatedAt),
       annee = Value(annee);
  static Insertable<EditionRow> custom({
    Expression<String>? id,
    Expression<String>? payload,
    Expression<DateTime>? updatedAt,
    Expression<int>? annee,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (annee != null) 'annee': annee,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EditionsCompanion copyWith({
    Value<String>? id,
    Value<String>? payload,
    Value<DateTime>? updatedAt,
    Value<int>? annee,
    Value<int>? rowid,
  }) {
    return EditionsCompanion(
      id: id ?? this.id,
      payload: payload ?? this.payload,
      updatedAt: updatedAt ?? this.updatedAt,
      annee: annee ?? this.annee,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (annee.present) {
      map['annee'] = Variable<int>(annee.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EditionsCompanion(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('annee: $annee, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SeriesTableTable extends SeriesTable
    with TableInfo<$SeriesTableTable, SeriesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editionIdMeta = const VerificationMeta(
    'editionId',
  );
  @override
  late final GeneratedColumn<String> editionId = GeneratedColumn<String>(
    'edition_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ordreMeta = const VerificationMeta('ordre');
  @override
  late final GeneratedColumn<int> ordre = GeneratedColumn<int>(
    'ordre',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    payload,
    updatedAt,
    editionId,
    ordre,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'series';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeriesRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('edition_id')) {
      context.handle(
        _editionIdMeta,
        editionId.isAcceptableOrUnknown(data['edition_id']!, _editionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_editionIdMeta);
    }
    if (data.containsKey('ordre')) {
      context.handle(
        _ordreMeta,
        ordre.isAcceptableOrUnknown(data['ordre']!, _ordreMeta),
      );
    } else if (isInserting) {
      context.missing(_ordreMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SeriesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeriesRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      editionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}edition_id'],
      )!,
      ordre: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordre'],
      )!,
    );
  }

  @override
  $SeriesTableTable createAlias(String alias) {
    return $SeriesTableTable(attachedDatabase, alias);
  }
}

class SeriesRow extends DataClass implements Insertable<SeriesRow> {
  final String id;
  final String payload;
  final DateTime updatedAt;
  final String editionId;
  final int ordre;
  const SeriesRow({
    required this.id,
    required this.payload,
    required this.updatedAt,
    required this.editionId,
    required this.ordre,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['payload'] = Variable<String>(payload);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['edition_id'] = Variable<String>(editionId);
    map['ordre'] = Variable<int>(ordre);
    return map;
  }

  SeriesTableCompanion toCompanion(bool nullToAbsent) {
    return SeriesTableCompanion(
      id: Value(id),
      payload: Value(payload),
      updatedAt: Value(updatedAt),
      editionId: Value(editionId),
      ordre: Value(ordre),
    );
  }

  factory SeriesRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeriesRow(
      id: serializer.fromJson<String>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      editionId: serializer.fromJson<String>(json['editionId']),
      ordre: serializer.fromJson<int>(json['ordre']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'payload': serializer.toJson<String>(payload),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'editionId': serializer.toJson<String>(editionId),
      'ordre': serializer.toJson<int>(ordre),
    };
  }

  SeriesRow copyWith({
    String? id,
    String? payload,
    DateTime? updatedAt,
    String? editionId,
    int? ordre,
  }) => SeriesRow(
    id: id ?? this.id,
    payload: payload ?? this.payload,
    updatedAt: updatedAt ?? this.updatedAt,
    editionId: editionId ?? this.editionId,
    ordre: ordre ?? this.ordre,
  );
  SeriesRow copyWithCompanion(SeriesTableCompanion data) {
    return SeriesRow(
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      editionId: data.editionId.present ? data.editionId.value : this.editionId,
      ordre: data.ordre.present ? data.ordre.value : this.ordre,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeriesRow(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('editionId: $editionId, ')
          ..write('ordre: $ordre')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payload, updatedAt, editionId, ordre);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeriesRow &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.updatedAt == this.updatedAt &&
          other.editionId == this.editionId &&
          other.ordre == this.ordre);
}

class SeriesTableCompanion extends UpdateCompanion<SeriesRow> {
  final Value<String> id;
  final Value<String> payload;
  final Value<DateTime> updatedAt;
  final Value<String> editionId;
  final Value<int> ordre;
  final Value<int> rowid;
  const SeriesTableCompanion({
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.editionId = const Value.absent(),
    this.ordre = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SeriesTableCompanion.insert({
    required String id,
    required String payload,
    required DateTime updatedAt,
    required String editionId,
    required int ordre,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       payload = Value(payload),
       updatedAt = Value(updatedAt),
       editionId = Value(editionId),
       ordre = Value(ordre);
  static Insertable<SeriesRow> custom({
    Expression<String>? id,
    Expression<String>? payload,
    Expression<DateTime>? updatedAt,
    Expression<String>? editionId,
    Expression<int>? ordre,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (editionId != null) 'edition_id': editionId,
      if (ordre != null) 'ordre': ordre,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SeriesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? payload,
    Value<DateTime>? updatedAt,
    Value<String>? editionId,
    Value<int>? ordre,
    Value<int>? rowid,
  }) {
    return SeriesTableCompanion(
      id: id ?? this.id,
      payload: payload ?? this.payload,
      updatedAt: updatedAt ?? this.updatedAt,
      editionId: editionId ?? this.editionId,
      ordre: ordre ?? this.ordre,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (editionId.present) {
      map['edition_id'] = Variable<String>(editionId.value);
    }
    if (ordre.present) {
      map['ordre'] = Variable<int>(ordre.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeriesTableCompanion(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('editionId: $editionId, ')
          ..write('ordre: $ordre, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CardsTable extends Cards with TableInfo<$CardsTable, CardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editionIdMeta = const VerificationMeta(
    'editionId',
  );
  @override
  late final GeneratedColumn<String> editionId = GeneratedColumn<String>(
    'edition_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ordreMeta = const VerificationMeta('ordre');
  @override
  late final GeneratedColumn<int> ordre = GeneratedColumn<int>(
    'ordre',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fighterIdsMeta = const VerificationMeta(
    'fighterIds',
  );
  @override
  late final GeneratedColumn<String> fighterIds = GeneratedColumn<String>(
    'fighter_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    payload,
    updatedAt,
    editionId,
    seriesId,
    ordre,
    fighterIds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<CardRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('edition_id')) {
      context.handle(
        _editionIdMeta,
        editionId.isAcceptableOrUnknown(data['edition_id']!, _editionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_editionIdMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('ordre')) {
      context.handle(
        _ordreMeta,
        ordre.isAcceptableOrUnknown(data['ordre']!, _ordreMeta),
      );
    } else if (isInserting) {
      context.missing(_ordreMeta);
    }
    if (data.containsKey('fighter_ids')) {
      context.handle(
        _fighterIdsMeta,
        fighterIds.isAcceptableOrUnknown(data['fighter_ids']!, _fighterIdsMeta),
      );
    } else if (isInserting) {
      context.missing(_fighterIdsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      editionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}edition_id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      )!,
      ordre: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordre'],
      )!,
      fighterIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fighter_ids'],
      )!,
    );
  }

  @override
  $CardsTable createAlias(String alias) {
    return $CardsTable(attachedDatabase, alias);
  }
}

class CardRow extends DataClass implements Insertable<CardRow> {
  final String id;
  final String payload;
  final DateTime updatedAt;
  final String editionId;
  final String seriesId;
  final int ordre;

  /// Identifiants des combattants, séparés par des virgules (recherche simple).
  final String fighterIds;
  const CardRow({
    required this.id,
    required this.payload,
    required this.updatedAt,
    required this.editionId,
    required this.seriesId,
    required this.ordre,
    required this.fighterIds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['payload'] = Variable<String>(payload);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['edition_id'] = Variable<String>(editionId);
    map['series_id'] = Variable<String>(seriesId);
    map['ordre'] = Variable<int>(ordre);
    map['fighter_ids'] = Variable<String>(fighterIds);
    return map;
  }

  CardsCompanion toCompanion(bool nullToAbsent) {
    return CardsCompanion(
      id: Value(id),
      payload: Value(payload),
      updatedAt: Value(updatedAt),
      editionId: Value(editionId),
      seriesId: Value(seriesId),
      ordre: Value(ordre),
      fighterIds: Value(fighterIds),
    );
  }

  factory CardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardRow(
      id: serializer.fromJson<String>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      editionId: serializer.fromJson<String>(json['editionId']),
      seriesId: serializer.fromJson<String>(json['seriesId']),
      ordre: serializer.fromJson<int>(json['ordre']),
      fighterIds: serializer.fromJson<String>(json['fighterIds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'payload': serializer.toJson<String>(payload),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'editionId': serializer.toJson<String>(editionId),
      'seriesId': serializer.toJson<String>(seriesId),
      'ordre': serializer.toJson<int>(ordre),
      'fighterIds': serializer.toJson<String>(fighterIds),
    };
  }

  CardRow copyWith({
    String? id,
    String? payload,
    DateTime? updatedAt,
    String? editionId,
    String? seriesId,
    int? ordre,
    String? fighterIds,
  }) => CardRow(
    id: id ?? this.id,
    payload: payload ?? this.payload,
    updatedAt: updatedAt ?? this.updatedAt,
    editionId: editionId ?? this.editionId,
    seriesId: seriesId ?? this.seriesId,
    ordre: ordre ?? this.ordre,
    fighterIds: fighterIds ?? this.fighterIds,
  );
  CardRow copyWithCompanion(CardsCompanion data) {
    return CardRow(
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      editionId: data.editionId.present ? data.editionId.value : this.editionId,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      ordre: data.ordre.present ? data.ordre.value : this.ordre,
      fighterIds: data.fighterIds.present
          ? data.fighterIds.value
          : this.fighterIds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardRow(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('editionId: $editionId, ')
          ..write('seriesId: $seriesId, ')
          ..write('ordre: $ordre, ')
          ..write('fighterIds: $fighterIds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    payload,
    updatedAt,
    editionId,
    seriesId,
    ordre,
    fighterIds,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardRow &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.updatedAt == this.updatedAt &&
          other.editionId == this.editionId &&
          other.seriesId == this.seriesId &&
          other.ordre == this.ordre &&
          other.fighterIds == this.fighterIds);
}

class CardsCompanion extends UpdateCompanion<CardRow> {
  final Value<String> id;
  final Value<String> payload;
  final Value<DateTime> updatedAt;
  final Value<String> editionId;
  final Value<String> seriesId;
  final Value<int> ordre;
  final Value<String> fighterIds;
  final Value<int> rowid;
  const CardsCompanion({
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.editionId = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.ordre = const Value.absent(),
    this.fighterIds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CardsCompanion.insert({
    required String id,
    required String payload,
    required DateTime updatedAt,
    required String editionId,
    required String seriesId,
    required int ordre,
    required String fighterIds,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       payload = Value(payload),
       updatedAt = Value(updatedAt),
       editionId = Value(editionId),
       seriesId = Value(seriesId),
       ordre = Value(ordre),
       fighterIds = Value(fighterIds);
  static Insertable<CardRow> custom({
    Expression<String>? id,
    Expression<String>? payload,
    Expression<DateTime>? updatedAt,
    Expression<String>? editionId,
    Expression<String>? seriesId,
    Expression<int>? ordre,
    Expression<String>? fighterIds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (editionId != null) 'edition_id': editionId,
      if (seriesId != null) 'series_id': seriesId,
      if (ordre != null) 'ordre': ordre,
      if (fighterIds != null) 'fighter_ids': fighterIds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CardsCompanion copyWith({
    Value<String>? id,
    Value<String>? payload,
    Value<DateTime>? updatedAt,
    Value<String>? editionId,
    Value<String>? seriesId,
    Value<int>? ordre,
    Value<String>? fighterIds,
    Value<int>? rowid,
  }) {
    return CardsCompanion(
      id: id ?? this.id,
      payload: payload ?? this.payload,
      updatedAt: updatedAt ?? this.updatedAt,
      editionId: editionId ?? this.editionId,
      seriesId: seriesId ?? this.seriesId,
      ordre: ordre ?? this.ordre,
      fighterIds: fighterIds ?? this.fighterIds,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (editionId.present) {
      map['edition_id'] = Variable<String>(editionId.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (ordre.present) {
      map['ordre'] = Variable<int>(ordre.value);
    }
    if (fighterIds.present) {
      map['fighter_ids'] = Variable<String>(fighterIds.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardsCompanion(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('editionId: $editionId, ')
          ..write('seriesId: $seriesId, ')
          ..write('ordre: $ordre, ')
          ..write('fighterIds: $fighterIds, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VariantsTable extends Variants
    with TableInfo<$VariantsTable, VariantRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VariantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _editionIdMeta = const VerificationMeta(
    'editionId',
  );
  @override
  late final GeneratedColumn<String> editionId = GeneratedColumn<String>(
    'edition_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    payload,
    updatedAt,
    seriesId,
    editionId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'variants';
  @override
  VerificationContext validateIntegrity(
    Insertable<VariantRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    }
    if (data.containsKey('edition_id')) {
      context.handle(
        _editionIdMeta,
        editionId.isAcceptableOrUnknown(data['edition_id']!, _editionIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VariantRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VariantRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      ),
      editionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}edition_id'],
      ),
    );
  }

  @override
  $VariantsTable createAlias(String alias) {
    return $VariantsTable(attachedDatabase, alias);
  }
}

class VariantRow extends DataClass implements Insertable<VariantRow> {
  final String id;
  final String payload;
  final DateTime updatedAt;
  final String? seriesId;
  final String? editionId;
  const VariantRow({
    required this.id,
    required this.payload,
    required this.updatedAt,
    this.seriesId,
    this.editionId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['payload'] = Variable<String>(payload);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || seriesId != null) {
      map['series_id'] = Variable<String>(seriesId);
    }
    if (!nullToAbsent || editionId != null) {
      map['edition_id'] = Variable<String>(editionId);
    }
    return map;
  }

  VariantsCompanion toCompanion(bool nullToAbsent) {
    return VariantsCompanion(
      id: Value(id),
      payload: Value(payload),
      updatedAt: Value(updatedAt),
      seriesId: seriesId == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesId),
      editionId: editionId == null && nullToAbsent
          ? const Value.absent()
          : Value(editionId),
    );
  }

  factory VariantRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VariantRow(
      id: serializer.fromJson<String>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      seriesId: serializer.fromJson<String?>(json['seriesId']),
      editionId: serializer.fromJson<String?>(json['editionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'payload': serializer.toJson<String>(payload),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'seriesId': serializer.toJson<String?>(seriesId),
      'editionId': serializer.toJson<String?>(editionId),
    };
  }

  VariantRow copyWith({
    String? id,
    String? payload,
    DateTime? updatedAt,
    Value<String?> seriesId = const Value.absent(),
    Value<String?> editionId = const Value.absent(),
  }) => VariantRow(
    id: id ?? this.id,
    payload: payload ?? this.payload,
    updatedAt: updatedAt ?? this.updatedAt,
    seriesId: seriesId.present ? seriesId.value : this.seriesId,
    editionId: editionId.present ? editionId.value : this.editionId,
  );
  VariantRow copyWithCompanion(VariantsCompanion data) {
    return VariantRow(
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      editionId: data.editionId.present ? data.editionId.value : this.editionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VariantRow(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('seriesId: $seriesId, ')
          ..write('editionId: $editionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payload, updatedAt, seriesId, editionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VariantRow &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.updatedAt == this.updatedAt &&
          other.seriesId == this.seriesId &&
          other.editionId == this.editionId);
}

class VariantsCompanion extends UpdateCompanion<VariantRow> {
  final Value<String> id;
  final Value<String> payload;
  final Value<DateTime> updatedAt;
  final Value<String?> seriesId;
  final Value<String?> editionId;
  final Value<int> rowid;
  const VariantsCompanion({
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.editionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VariantsCompanion.insert({
    required String id,
    required String payload,
    required DateTime updatedAt,
    this.seriesId = const Value.absent(),
    this.editionId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       payload = Value(payload),
       updatedAt = Value(updatedAt);
  static Insertable<VariantRow> custom({
    Expression<String>? id,
    Expression<String>? payload,
    Expression<DateTime>? updatedAt,
    Expression<String>? seriesId,
    Expression<String>? editionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (seriesId != null) 'series_id': seriesId,
      if (editionId != null) 'edition_id': editionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VariantsCompanion copyWith({
    Value<String>? id,
    Value<String>? payload,
    Value<DateTime>? updatedAt,
    Value<String?>? seriesId,
    Value<String?>? editionId,
    Value<int>? rowid,
  }) {
    return VariantsCompanion(
      id: id ?? this.id,
      payload: payload ?? this.payload,
      updatedAt: updatedAt ?? this.updatedAt,
      seriesId: seriesId ?? this.seriesId,
      editionId: editionId ?? this.editionId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (editionId.present) {
      map['edition_id'] = Variable<String>(editionId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VariantsCompanion(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('seriesId: $seriesId, ')
          ..write('editionId: $editionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImagesTable extends Images with TableInfo<$ImagesTable, ImageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fighterIdMeta = const VerificationMeta(
    'fighterId',
  );
  @override
  late final GeneratedColumn<String> fighterId = GeneratedColumn<String>(
    'fighter_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, payload, updatedAt, fighterId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'images';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('fighter_id')) {
      context.handle(
        _fighterIdMeta,
        fighterId.isAcceptableOrUnknown(data['fighter_id']!, _fighterIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      fighterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fighter_id'],
      ),
    );
  }

  @override
  $ImagesTable createAlias(String alias) {
    return $ImagesTable(attachedDatabase, alias);
  }
}

class ImageRow extends DataClass implements Insertable<ImageRow> {
  final String id;
  final String payload;
  final DateTime updatedAt;
  final String? fighterId;
  const ImageRow({
    required this.id,
    required this.payload,
    required this.updatedAt,
    this.fighterId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['payload'] = Variable<String>(payload);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || fighterId != null) {
      map['fighter_id'] = Variable<String>(fighterId);
    }
    return map;
  }

  ImagesCompanion toCompanion(bool nullToAbsent) {
    return ImagesCompanion(
      id: Value(id),
      payload: Value(payload),
      updatedAt: Value(updatedAt),
      fighterId: fighterId == null && nullToAbsent
          ? const Value.absent()
          : Value(fighterId),
    );
  }

  factory ImageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImageRow(
      id: serializer.fromJson<String>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      fighterId: serializer.fromJson<String?>(json['fighterId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'payload': serializer.toJson<String>(payload),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'fighterId': serializer.toJson<String?>(fighterId),
    };
  }

  ImageRow copyWith({
    String? id,
    String? payload,
    DateTime? updatedAt,
    Value<String?> fighterId = const Value.absent(),
  }) => ImageRow(
    id: id ?? this.id,
    payload: payload ?? this.payload,
    updatedAt: updatedAt ?? this.updatedAt,
    fighterId: fighterId.present ? fighterId.value : this.fighterId,
  );
  ImageRow copyWithCompanion(ImagesCompanion data) {
    return ImageRow(
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      fighterId: data.fighterId.present ? data.fighterId.value : this.fighterId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImageRow(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('fighterId: $fighterId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payload, updatedAt, fighterId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImageRow &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.updatedAt == this.updatedAt &&
          other.fighterId == this.fighterId);
}

class ImagesCompanion extends UpdateCompanion<ImageRow> {
  final Value<String> id;
  final Value<String> payload;
  final Value<DateTime> updatedAt;
  final Value<String?> fighterId;
  final Value<int> rowid;
  const ImagesCompanion({
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.fighterId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImagesCompanion.insert({
    required String id,
    required String payload,
    required DateTime updatedAt,
    this.fighterId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       payload = Value(payload),
       updatedAt = Value(updatedAt);
  static Insertable<ImageRow> custom({
    Expression<String>? id,
    Expression<String>? payload,
    Expression<DateTime>? updatedAt,
    Expression<String>? fighterId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (fighterId != null) 'fighter_id': fighterId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImagesCompanion copyWith({
    Value<String>? id,
    Value<String>? payload,
    Value<DateTime>? updatedAt,
    Value<String?>? fighterId,
    Value<int>? rowid,
  }) {
    return ImagesCompanion(
      id: id ?? this.id,
      payload: payload ?? this.payload,
      updatedAt: updatedAt ?? this.updatedAt,
      fighterId: fighterId ?? this.fighterId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (fighterId.present) {
      map['fighter_id'] = Variable<String>(fighterId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImagesCompanion(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('fighterId: $fighterId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventsTable extends Events with TableInfo<$EventsTable, EventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, payload, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }
}

class EventRow extends DataClass implements Insertable<EventRow> {
  final String id;
  final String payload;
  final DateTime updatedAt;
  const EventRow({
    required this.id,
    required this.payload,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['payload'] = Variable<String>(payload);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      id: Value(id),
      payload: Value(payload),
      updatedAt: Value(updatedAt),
    );
  }

  factory EventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventRow(
      id: serializer.fromJson<String>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'payload': serializer.toJson<String>(payload),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  EventRow copyWith({String? id, String? payload, DateTime? updatedAt}) =>
      EventRow(
        id: id ?? this.id,
        payload: payload ?? this.payload,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  EventRow copyWithCompanion(EventsCompanion data) {
    return EventRow(
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventRow(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payload, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventRow &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.updatedAt == this.updatedAt);
}

class EventsCompanion extends UpdateCompanion<EventRow> {
  final Value<String> id;
  final Value<String> payload;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const EventsCompanion({
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventsCompanion.insert({
    required String id,
    required String payload,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       payload = Value(payload),
       updatedAt = Value(updatedAt);
  static Insertable<EventRow> custom({
    Expression<String>? id,
    Expression<String>? payload,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventsCompanion copyWith({
    Value<String>? id,
    Value<String>? payload,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return EventsCompanion(
      id: id ?? this.id,
      payload: payload ?? this.payload,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RivalriesTable extends Rivalries
    with TableInfo<$RivalriesTable, RivalryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RivalriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fighterAMeta = const VerificationMeta(
    'fighterA',
  );
  @override
  late final GeneratedColumn<String> fighterA = GeneratedColumn<String>(
    'fighter_a',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fighterBMeta = const VerificationMeta(
    'fighterB',
  );
  @override
  late final GeneratedColumn<String> fighterB = GeneratedColumn<String>(
    'fighter_b',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    payload,
    updatedAt,
    fighterA,
    fighterB,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rivalries';
  @override
  VerificationContext validateIntegrity(
    Insertable<RivalryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('fighter_a')) {
      context.handle(
        _fighterAMeta,
        fighterA.isAcceptableOrUnknown(data['fighter_a']!, _fighterAMeta),
      );
    } else if (isInserting) {
      context.missing(_fighterAMeta);
    }
    if (data.containsKey('fighter_b')) {
      context.handle(
        _fighterBMeta,
        fighterB.isAcceptableOrUnknown(data['fighter_b']!, _fighterBMeta),
      );
    } else if (isInserting) {
      context.missing(_fighterBMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RivalryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RivalryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      fighterA: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fighter_a'],
      )!,
      fighterB: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fighter_b'],
      )!,
    );
  }

  @override
  $RivalriesTable createAlias(String alias) {
    return $RivalriesTable(attachedDatabase, alias);
  }
}

class RivalryRow extends DataClass implements Insertable<RivalryRow> {
  final String id;
  final String payload;
  final DateTime updatedAt;
  final String fighterA;
  final String fighterB;
  const RivalryRow({
    required this.id,
    required this.payload,
    required this.updatedAt,
    required this.fighterA,
    required this.fighterB,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['payload'] = Variable<String>(payload);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['fighter_a'] = Variable<String>(fighterA);
    map['fighter_b'] = Variable<String>(fighterB);
    return map;
  }

  RivalriesCompanion toCompanion(bool nullToAbsent) {
    return RivalriesCompanion(
      id: Value(id),
      payload: Value(payload),
      updatedAt: Value(updatedAt),
      fighterA: Value(fighterA),
      fighterB: Value(fighterB),
    );
  }

  factory RivalryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RivalryRow(
      id: serializer.fromJson<String>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      fighterA: serializer.fromJson<String>(json['fighterA']),
      fighterB: serializer.fromJson<String>(json['fighterB']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'payload': serializer.toJson<String>(payload),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'fighterA': serializer.toJson<String>(fighterA),
      'fighterB': serializer.toJson<String>(fighterB),
    };
  }

  RivalryRow copyWith({
    String? id,
    String? payload,
    DateTime? updatedAt,
    String? fighterA,
    String? fighterB,
  }) => RivalryRow(
    id: id ?? this.id,
    payload: payload ?? this.payload,
    updatedAt: updatedAt ?? this.updatedAt,
    fighterA: fighterA ?? this.fighterA,
    fighterB: fighterB ?? this.fighterB,
  );
  RivalryRow copyWithCompanion(RivalriesCompanion data) {
    return RivalryRow(
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      fighterA: data.fighterA.present ? data.fighterA.value : this.fighterA,
      fighterB: data.fighterB.present ? data.fighterB.value : this.fighterB,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RivalryRow(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('fighterA: $fighterA, ')
          ..write('fighterB: $fighterB')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payload, updatedAt, fighterA, fighterB);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RivalryRow &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.updatedAt == this.updatedAt &&
          other.fighterA == this.fighterA &&
          other.fighterB == this.fighterB);
}

class RivalriesCompanion extends UpdateCompanion<RivalryRow> {
  final Value<String> id;
  final Value<String> payload;
  final Value<DateTime> updatedAt;
  final Value<String> fighterA;
  final Value<String> fighterB;
  final Value<int> rowid;
  const RivalriesCompanion({
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.fighterA = const Value.absent(),
    this.fighterB = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RivalriesCompanion.insert({
    required String id,
    required String payload,
    required DateTime updatedAt,
    required String fighterA,
    required String fighterB,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       payload = Value(payload),
       updatedAt = Value(updatedAt),
       fighterA = Value(fighterA),
       fighterB = Value(fighterB);
  static Insertable<RivalryRow> custom({
    Expression<String>? id,
    Expression<String>? payload,
    Expression<DateTime>? updatedAt,
    Expression<String>? fighterA,
    Expression<String>? fighterB,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (fighterA != null) 'fighter_a': fighterA,
      if (fighterB != null) 'fighter_b': fighterB,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RivalriesCompanion copyWith({
    Value<String>? id,
    Value<String>? payload,
    Value<DateTime>? updatedAt,
    Value<String>? fighterA,
    Value<String>? fighterB,
    Value<int>? rowid,
  }) {
    return RivalriesCompanion(
      id: id ?? this.id,
      payload: payload ?? this.payload,
      updatedAt: updatedAt ?? this.updatedAt,
      fighterA: fighterA ?? this.fighterA,
      fighterB: fighterB ?? this.fighterB,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (fighterA.present) {
      map['fighter_a'] = Variable<String>(fighterA.value);
    }
    if (fighterB.present) {
      map['fighter_b'] = Variable<String>(fighterB.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RivalriesCompanion(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('fighterA: $fighterA, ')
          ..write('fighterB: $fighterB, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OwnedCardsTable extends OwnedCards
    with TableInfo<$OwnedCardsTable, OwnedCardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OwnedCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variantIdMeta = const VerificationMeta(
    'variantId',
  );
  @override
  late final GeneratedColumn<String> variantId = GeneratedColumn<String>(
    'variant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerId,
    cardId,
    variantId,
    payload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'owned_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<OwnedCardRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('variant_id')) {
      context.handle(
        _variantIdMeta,
        variantId.isAcceptableOrUnknown(data['variant_id']!, _variantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_variantIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OwnedCardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OwnedCardRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      variantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $OwnedCardsTable createAlias(String alias) {
    return $OwnedCardsTable(attachedDatabase, alias);
  }
}

class OwnedCardRow extends DataClass implements Insertable<OwnedCardRow> {
  final String id;
  final String ownerId;
  final String cardId;
  final String variantId;
  final String payload;
  const OwnedCardRow({
    required this.id,
    required this.ownerId,
    required this.cardId,
    required this.variantId,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_id'] = Variable<String>(ownerId);
    map['card_id'] = Variable<String>(cardId);
    map['variant_id'] = Variable<String>(variantId);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  OwnedCardsCompanion toCompanion(bool nullToAbsent) {
    return OwnedCardsCompanion(
      id: Value(id),
      ownerId: Value(ownerId),
      cardId: Value(cardId),
      variantId: Value(variantId),
      payload: Value(payload),
    );
  }

  factory OwnedCardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OwnedCardRow(
      id: serializer.fromJson<String>(json['id']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      cardId: serializer.fromJson<String>(json['cardId']),
      variantId: serializer.fromJson<String>(json['variantId']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerId': serializer.toJson<String>(ownerId),
      'cardId': serializer.toJson<String>(cardId),
      'variantId': serializer.toJson<String>(variantId),
      'payload': serializer.toJson<String>(payload),
    };
  }

  OwnedCardRow copyWith({
    String? id,
    String? ownerId,
    String? cardId,
    String? variantId,
    String? payload,
  }) => OwnedCardRow(
    id: id ?? this.id,
    ownerId: ownerId ?? this.ownerId,
    cardId: cardId ?? this.cardId,
    variantId: variantId ?? this.variantId,
    payload: payload ?? this.payload,
  );
  OwnedCardRow copyWithCompanion(OwnedCardsCompanion data) {
    return OwnedCardRow(
      id: data.id.present ? data.id.value : this.id,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      variantId: data.variantId.present ? data.variantId.value : this.variantId,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OwnedCardRow(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('cardId: $cardId, ')
          ..write('variantId: $variantId, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ownerId, cardId, variantId, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OwnedCardRow &&
          other.id == this.id &&
          other.ownerId == this.ownerId &&
          other.cardId == this.cardId &&
          other.variantId == this.variantId &&
          other.payload == this.payload);
}

class OwnedCardsCompanion extends UpdateCompanion<OwnedCardRow> {
  final Value<String> id;
  final Value<String> ownerId;
  final Value<String> cardId;
  final Value<String> variantId;
  final Value<String> payload;
  final Value<int> rowid;
  const OwnedCardsCompanion({
    this.id = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.cardId = const Value.absent(),
    this.variantId = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OwnedCardsCompanion.insert({
    required String id,
    required String ownerId,
    required String cardId,
    required String variantId,
    required String payload,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ownerId = Value(ownerId),
       cardId = Value(cardId),
       variantId = Value(variantId),
       payload = Value(payload);
  static Insertable<OwnedCardRow> custom({
    Expression<String>? id,
    Expression<String>? ownerId,
    Expression<String>? cardId,
    Expression<String>? variantId,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      if (cardId != null) 'card_id': cardId,
      if (variantId != null) 'variant_id': variantId,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OwnedCardsCompanion copyWith({
    Value<String>? id,
    Value<String>? ownerId,
    Value<String>? cardId,
    Value<String>? variantId,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return OwnedCardsCompanion(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      cardId: cardId ?? this.cardId,
      variantId: variantId ?? this.variantId,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (variantId.present) {
      map['variant_id'] = Variable<String>(variantId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OwnedCardsCompanion(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('cardId: $cardId, ')
          ..write('variantId: $variantId, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _remoteTableMeta = const VerificationMeta(
    'remoteTable',
  );
  @override
  late final GeneratedColumn<String> remoteTable = GeneratedColumn<String>(
    'remote_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUpdatedAtMeta = const VerificationMeta(
    'lastUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUpdatedAt =
      GeneratedColumn<DateTime>(
        'last_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [remoteTable, lastUpdatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('remote_table')) {
      context.handle(
        _remoteTableMeta,
        remoteTable.isAcceptableOrUnknown(
          data['remote_table']!,
          _remoteTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remoteTableMeta);
    }
    if (data.containsKey('last_updated_at')) {
      context.handle(
        _lastUpdatedAtMeta,
        lastUpdatedAt.isAcceptableOrUnknown(
          data['last_updated_at']!,
          _lastUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUpdatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {remoteTable};
  @override
  SyncStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateRow(
      remoteTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_table'],
      )!,
      lastUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_updated_at'],
      )!,
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateRow extends DataClass implements Insertable<SyncStateRow> {
  final String remoteTable;
  final DateTime lastUpdatedAt;
  const SyncStateRow({required this.remoteTable, required this.lastUpdatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['remote_table'] = Variable<String>(remoteTable);
    map['last_updated_at'] = Variable<DateTime>(lastUpdatedAt);
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      remoteTable: Value(remoteTable),
      lastUpdatedAt: Value(lastUpdatedAt),
    );
  }

  factory SyncStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateRow(
      remoteTable: serializer.fromJson<String>(json['remoteTable']),
      lastUpdatedAt: serializer.fromJson<DateTime>(json['lastUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'remoteTable': serializer.toJson<String>(remoteTable),
      'lastUpdatedAt': serializer.toJson<DateTime>(lastUpdatedAt),
    };
  }

  SyncStateRow copyWith({String? remoteTable, DateTime? lastUpdatedAt}) =>
      SyncStateRow(
        remoteTable: remoteTable ?? this.remoteTable,
        lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      );
  SyncStateRow copyWithCompanion(SyncStateCompanion data) {
    return SyncStateRow(
      remoteTable: data.remoteTable.present
          ? data.remoteTable.value
          : this.remoteTable,
      lastUpdatedAt: data.lastUpdatedAt.present
          ? data.lastUpdatedAt.value
          : this.lastUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateRow(')
          ..write('remoteTable: $remoteTable, ')
          ..write('lastUpdatedAt: $lastUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(remoteTable, lastUpdatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateRow &&
          other.remoteTable == this.remoteTable &&
          other.lastUpdatedAt == this.lastUpdatedAt);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateRow> {
  final Value<String> remoteTable;
  final Value<DateTime> lastUpdatedAt;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.remoteTable = const Value.absent(),
    this.lastUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String remoteTable,
    required DateTime lastUpdatedAt,
    this.rowid = const Value.absent(),
  }) : remoteTable = Value(remoteTable),
       lastUpdatedAt = Value(lastUpdatedAt);
  static Insertable<SyncStateRow> custom({
    Expression<String>? remoteTable,
    Expression<DateTime>? lastUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (remoteTable != null) 'remote_table': remoteTable,
      if (lastUpdatedAt != null) 'last_updated_at': lastUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith({
    Value<String>? remoteTable,
    Value<DateTime>? lastUpdatedAt,
    Value<int>? rowid,
  }) {
    return SyncStateCompanion(
      remoteTable: remoteTable ?? this.remoteTable,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (remoteTable.present) {
      map['remote_table'] = Variable<String>(remoteTable.value);
    }
    if (lastUpdatedAt.present) {
      map['last_updated_at'] = Variable<DateTime>(lastUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('remoteTable: $remoteTable, ')
          ..write('lastUpdatedAt: $lastUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FightersTable fighters = $FightersTable(this);
  late final $EditionsTable editions = $EditionsTable(this);
  late final $SeriesTableTable seriesTable = $SeriesTableTable(this);
  late final $CardsTable cards = $CardsTable(this);
  late final $VariantsTable variants = $VariantsTable(this);
  late final $ImagesTable images = $ImagesTable(this);
  late final $EventsTable events = $EventsTable(this);
  late final $RivalriesTable rivalries = $RivalriesTable(this);
  late final $OwnedCardsTable ownedCards = $OwnedCardsTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    fighters,
    editions,
    seriesTable,
    cards,
    variants,
    images,
    events,
    rivalries,
    ownedCards,
    syncState,
  ];
}

typedef $$FightersTableCreateCompanionBuilder = FightersCompanion Function({
  required String id,
  required String payload,
  required DateTime updatedAt,
  required String nom,
  Value<String?> categorie,
  Value<int> rowid,
});
typedef $$FightersTableUpdateCompanionBuilder = FightersCompanion Function({
  Value<String> id,
  Value<String> payload,
  Value<DateTime> updatedAt,
  Value<String> nom,
  Value<String?> categorie,
  Value<int> rowid,
});

class $$FightersTableFilterComposer
    extends Composer<_$AppDatabase, $FightersTable> {
  $$FightersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nom => $composableBuilder(
    column: $table.nom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categorie => $composableBuilder(
    column: $table.categorie,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FightersTableOrderingComposer
    extends Composer<_$AppDatabase, $FightersTable> {
  $$FightersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nom => $composableBuilder(
    column: $table.nom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categorie => $composableBuilder(
    column: $table.categorie,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FightersTableAnnotationComposer
    extends Composer<_$AppDatabase, $FightersTable> {
  $$FightersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get nom =>
      $composableBuilder(column: $table.nom, builder: (column) => column);

  GeneratedColumn<String> get categorie =>
      $composableBuilder(column: $table.categorie, builder: (column) => column);
}

class $$FightersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FightersTable,
          FighterRow,
          $$FightersTableFilterComposer,
          $$FightersTableOrderingComposer,
          $$FightersTableAnnotationComposer,
          $$FightersTableCreateCompanionBuilder,
          $$FightersTableUpdateCompanionBuilder,
          (
            FighterRow,
            BaseReferences<_$AppDatabase, $FightersTable, FighterRow>,
          ),
          FighterRow,
          PrefetchHooks Function()
        > {
  $$FightersTableTableManager(_$AppDatabase db, $FightersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FightersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FightersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FightersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> nom = const Value.absent(),
                Value<String?> categorie = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FightersCompanion(
                id: id,
                payload: payload,
                updatedAt: updatedAt,
                nom: nom,
                categorie: categorie,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String payload,
                required DateTime updatedAt,
                required String nom,
                Value<String?> categorie = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FightersCompanion.insert(
                id: id,
                payload: payload,
                updatedAt: updatedAt,
                nom: nom,
                categorie: categorie,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FightersTable, FighterRow>(table),
                  BaseReferences<_$AppDatabase, $FightersTable, FighterRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FightersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FightersTable,
      FighterRow,
      $$FightersTableFilterComposer,
      $$FightersTableOrderingComposer,
      $$FightersTableAnnotationComposer,
      $$FightersTableCreateCompanionBuilder,
      $$FightersTableUpdateCompanionBuilder,
      (FighterRow, BaseReferences<_$AppDatabase, $FightersTable, FighterRow>),
      FighterRow,
      PrefetchHooks Function()
    >;
typedef $$EditionsTableCreateCompanionBuilder = EditionsCompanion Function({
  required String id,
  required String payload,
  required DateTime updatedAt,
  required int annee,
  Value<int> rowid,
});
typedef $$EditionsTableUpdateCompanionBuilder = EditionsCompanion Function({
  Value<String> id,
  Value<String> payload,
  Value<DateTime> updatedAt,
  Value<int> annee,
  Value<int> rowid,
});

class $$EditionsTableFilterComposer
    extends Composer<_$AppDatabase, $EditionsTable> {
  $$EditionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get annee => $composableBuilder(
    column: $table.annee,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EditionsTableOrderingComposer
    extends Composer<_$AppDatabase, $EditionsTable> {
  $$EditionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get annee => $composableBuilder(
    column: $table.annee,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EditionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EditionsTable> {
  $$EditionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get annee =>
      $composableBuilder(column: $table.annee, builder: (column) => column);
}

class $$EditionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EditionsTable,
          EditionRow,
          $$EditionsTableFilterComposer,
          $$EditionsTableOrderingComposer,
          $$EditionsTableAnnotationComposer,
          $$EditionsTableCreateCompanionBuilder,
          $$EditionsTableUpdateCompanionBuilder,
          (
            EditionRow,
            BaseReferences<_$AppDatabase, $EditionsTable, EditionRow>,
          ),
          EditionRow,
          PrefetchHooks Function()
        > {
  $$EditionsTableTableManager(_$AppDatabase db, $EditionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EditionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EditionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EditionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> annee = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EditionsCompanion(
                id: id,
                payload: payload,
                updatedAt: updatedAt,
                annee: annee,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String payload,
                required DateTime updatedAt,
                required int annee,
                Value<int> rowid = const Value.absent(),
              }) => EditionsCompanion.insert(
                id: id,
                payload: payload,
                updatedAt: updatedAt,
                annee: annee,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EditionsTable, EditionRow>(table),
                  BaseReferences<_$AppDatabase, $EditionsTable, EditionRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EditionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EditionsTable,
      EditionRow,
      $$EditionsTableFilterComposer,
      $$EditionsTableOrderingComposer,
      $$EditionsTableAnnotationComposer,
      $$EditionsTableCreateCompanionBuilder,
      $$EditionsTableUpdateCompanionBuilder,
      (EditionRow, BaseReferences<_$AppDatabase, $EditionsTable, EditionRow>),
      EditionRow,
      PrefetchHooks Function()
    >;
typedef $$SeriesTableTableCreateCompanionBuilder =
    SeriesTableCompanion Function({
      required String id,
      required String payload,
      required DateTime updatedAt,
      required String editionId,
      required int ordre,
      Value<int> rowid,
    });
typedef $$SeriesTableTableUpdateCompanionBuilder =
    SeriesTableCompanion Function({
      Value<String> id,
      Value<String> payload,
      Value<DateTime> updatedAt,
      Value<String> editionId,
      Value<int> ordre,
      Value<int> rowid,
    });

class $$SeriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $SeriesTableTable> {
  $$SeriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get editionId => $composableBuilder(
    column: $table.editionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ordre => $composableBuilder(
    column: $table.ordre,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SeriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SeriesTableTable> {
  $$SeriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get editionId => $composableBuilder(
    column: $table.editionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ordre => $composableBuilder(
    column: $table.ordre,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SeriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeriesTableTable> {
  $$SeriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get editionId =>
      $composableBuilder(column: $table.editionId, builder: (column) => column);

  GeneratedColumn<int> get ordre =>
      $composableBuilder(column: $table.ordre, builder: (column) => column);
}

class $$SeriesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeriesTableTable,
          SeriesRow,
          $$SeriesTableTableFilterComposer,
          $$SeriesTableTableOrderingComposer,
          $$SeriesTableTableAnnotationComposer,
          $$SeriesTableTableCreateCompanionBuilder,
          $$SeriesTableTableUpdateCompanionBuilder,
          (
            SeriesRow,
            BaseReferences<_$AppDatabase, $SeriesTableTable, SeriesRow>,
          ),
          SeriesRow,
          PrefetchHooks Function()
        > {
  $$SeriesTableTableTableManager(_$AppDatabase db, $SeriesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeriesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeriesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> editionId = const Value.absent(),
                Value<int> ordre = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeriesTableCompanion(
                id: id,
                payload: payload,
                updatedAt: updatedAt,
                editionId: editionId,
                ordre: ordre,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String payload,
                required DateTime updatedAt,
                required String editionId,
                required int ordre,
                Value<int> rowid = const Value.absent(),
              }) => SeriesTableCompanion.insert(
                id: id,
                payload: payload,
                updatedAt: updatedAt,
                editionId: editionId,
                ordre: ordre,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SeriesTableTable, SeriesRow>(table),
                  BaseReferences<_$AppDatabase, $SeriesTableTable, SeriesRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SeriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeriesTableTable,
      SeriesRow,
      $$SeriesTableTableFilterComposer,
      $$SeriesTableTableOrderingComposer,
      $$SeriesTableTableAnnotationComposer,
      $$SeriesTableTableCreateCompanionBuilder,
      $$SeriesTableTableUpdateCompanionBuilder,
      (SeriesRow, BaseReferences<_$AppDatabase, $SeriesTableTable, SeriesRow>),
      SeriesRow,
      PrefetchHooks Function()
    >;
typedef $$CardsTableCreateCompanionBuilder = CardsCompanion Function({
  required String id,
  required String payload,
  required DateTime updatedAt,
  required String editionId,
  required String seriesId,
  required int ordre,
  required String fighterIds,
  Value<int> rowid,
});
typedef $$CardsTableUpdateCompanionBuilder = CardsCompanion Function({
  Value<String> id,
  Value<String> payload,
  Value<DateTime> updatedAt,
  Value<String> editionId,
  Value<String> seriesId,
  Value<int> ordre,
  Value<String> fighterIds,
  Value<int> rowid,
});

class $$CardsTableFilterComposer extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get editionId => $composableBuilder(
    column: $table.editionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ordre => $composableBuilder(
    column: $table.ordre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fighterIds => $composableBuilder(
    column: $table.fighterIds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CardsTableOrderingComposer
    extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get editionId => $composableBuilder(
    column: $table.editionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ordre => $composableBuilder(
    column: $table.ordre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fighterIds => $composableBuilder(
    column: $table.fighterIds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get editionId =>
      $composableBuilder(column: $table.editionId, builder: (column) => column);

  GeneratedColumn<String> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<int> get ordre =>
      $composableBuilder(column: $table.ordre, builder: (column) => column);

  GeneratedColumn<String> get fighterIds => $composableBuilder(
    column: $table.fighterIds,
    builder: (column) => column,
  );
}

class $$CardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CardsTable,
          CardRow,
          $$CardsTableFilterComposer,
          $$CardsTableOrderingComposer,
          $$CardsTableAnnotationComposer,
          $$CardsTableCreateCompanionBuilder,
          $$CardsTableUpdateCompanionBuilder,
          (CardRow, BaseReferences<_$AppDatabase, $CardsTable, CardRow>),
          CardRow,
          PrefetchHooks Function()
        > {
  $$CardsTableTableManager(_$AppDatabase db, $CardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> editionId = const Value.absent(),
                Value<String> seriesId = const Value.absent(),
                Value<int> ordre = const Value.absent(),
                Value<String> fighterIds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CardsCompanion(
                id: id,
                payload: payload,
                updatedAt: updatedAt,
                editionId: editionId,
                seriesId: seriesId,
                ordre: ordre,
                fighterIds: fighterIds,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String payload,
                required DateTime updatedAt,
                required String editionId,
                required String seriesId,
                required int ordre,
                required String fighterIds,
                Value<int> rowid = const Value.absent(),
              }) => CardsCompanion.insert(
                id: id,
                payload: payload,
                updatedAt: updatedAt,
                editionId: editionId,
                seriesId: seriesId,
                ordre: ordre,
                fighterIds: fighterIds,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CardsTable, CardRow>(table),
                  BaseReferences<_$AppDatabase, $CardsTable, CardRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CardsTable,
      CardRow,
      $$CardsTableFilterComposer,
      $$CardsTableOrderingComposer,
      $$CardsTableAnnotationComposer,
      $$CardsTableCreateCompanionBuilder,
      $$CardsTableUpdateCompanionBuilder,
      (CardRow, BaseReferences<_$AppDatabase, $CardsTable, CardRow>),
      CardRow,
      PrefetchHooks Function()
    >;
typedef $$VariantsTableCreateCompanionBuilder = VariantsCompanion Function({
  required String id,
  required String payload,
  required DateTime updatedAt,
  Value<String?> seriesId,
  Value<String?> editionId,
  Value<int> rowid,
});
typedef $$VariantsTableUpdateCompanionBuilder = VariantsCompanion Function({
  Value<String> id,
  Value<String> payload,
  Value<DateTime> updatedAt,
  Value<String?> seriesId,
  Value<String?> editionId,
  Value<int> rowid,
});

class $$VariantsTableFilterComposer
    extends Composer<_$AppDatabase, $VariantsTable> {
  $$VariantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get editionId => $composableBuilder(
    column: $table.editionId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VariantsTableOrderingComposer
    extends Composer<_$AppDatabase, $VariantsTable> {
  $$VariantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get editionId => $composableBuilder(
    column: $table.editionId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VariantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VariantsTable> {
  $$VariantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<String> get editionId =>
      $composableBuilder(column: $table.editionId, builder: (column) => column);
}

class $$VariantsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VariantsTable,
          VariantRow,
          $$VariantsTableFilterComposer,
          $$VariantsTableOrderingComposer,
          $$VariantsTableAnnotationComposer,
          $$VariantsTableCreateCompanionBuilder,
          $$VariantsTableUpdateCompanionBuilder,
          (
            VariantRow,
            BaseReferences<_$AppDatabase, $VariantsTable, VariantRow>,
          ),
          VariantRow,
          PrefetchHooks Function()
        > {
  $$VariantsTableTableManager(_$AppDatabase db, $VariantsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VariantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VariantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VariantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> seriesId = const Value.absent(),
                Value<String?> editionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VariantsCompanion(
                id: id,
                payload: payload,
                updatedAt: updatedAt,
                seriesId: seriesId,
                editionId: editionId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String payload,
                required DateTime updatedAt,
                Value<String?> seriesId = const Value.absent(),
                Value<String?> editionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VariantsCompanion.insert(
                id: id,
                payload: payload,
                updatedAt: updatedAt,
                seriesId: seriesId,
                editionId: editionId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VariantsTable, VariantRow>(table),
                  BaseReferences<_$AppDatabase, $VariantsTable, VariantRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VariantsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VariantsTable,
      VariantRow,
      $$VariantsTableFilterComposer,
      $$VariantsTableOrderingComposer,
      $$VariantsTableAnnotationComposer,
      $$VariantsTableCreateCompanionBuilder,
      $$VariantsTableUpdateCompanionBuilder,
      (VariantRow, BaseReferences<_$AppDatabase, $VariantsTable, VariantRow>),
      VariantRow,
      PrefetchHooks Function()
    >;
typedef $$ImagesTableCreateCompanionBuilder = ImagesCompanion Function({
  required String id,
  required String payload,
  required DateTime updatedAt,
  Value<String?> fighterId,
  Value<int> rowid,
});
typedef $$ImagesTableUpdateCompanionBuilder = ImagesCompanion Function({
  Value<String> id,
  Value<String> payload,
  Value<DateTime> updatedAt,
  Value<String?> fighterId,
  Value<int> rowid,
});

class $$ImagesTableFilterComposer
    extends Composer<_$AppDatabase, $ImagesTable> {
  $$ImagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fighterId => $composableBuilder(
    column: $table.fighterId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ImagesTable> {
  $$ImagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fighterId => $composableBuilder(
    column: $table.fighterId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImagesTable> {
  $$ImagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get fighterId =>
      $composableBuilder(column: $table.fighterId, builder: (column) => column);
}

class $$ImagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImagesTable,
          ImageRow,
          $$ImagesTableFilterComposer,
          $$ImagesTableOrderingComposer,
          $$ImagesTableAnnotationComposer,
          $$ImagesTableCreateCompanionBuilder,
          $$ImagesTableUpdateCompanionBuilder,
          (ImageRow, BaseReferences<_$AppDatabase, $ImagesTable, ImageRow>),
          ImageRow,
          PrefetchHooks Function()
        > {
  $$ImagesTableTableManager(_$AppDatabase db, $ImagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> fighterId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImagesCompanion(
                id: id,
                payload: payload,
                updatedAt: updatedAt,
                fighterId: fighterId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String payload,
                required DateTime updatedAt,
                Value<String?> fighterId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImagesCompanion.insert(
                id: id,
                payload: payload,
                updatedAt: updatedAt,
                fighterId: fighterId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ImagesTable, ImageRow>(table),
                  BaseReferences<_$AppDatabase, $ImagesTable, ImageRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImagesTable,
      ImageRow,
      $$ImagesTableFilterComposer,
      $$ImagesTableOrderingComposer,
      $$ImagesTableAnnotationComposer,
      $$ImagesTableCreateCompanionBuilder,
      $$ImagesTableUpdateCompanionBuilder,
      (ImageRow, BaseReferences<_$AppDatabase, $ImagesTable, ImageRow>),
      ImageRow,
      PrefetchHooks Function()
    >;
typedef $$EventsTableCreateCompanionBuilder = EventsCompanion Function({
  required String id,
  required String payload,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$EventsTableUpdateCompanionBuilder = EventsCompanion Function({
  Value<String> id,
  Value<String> payload,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$EventsTableFilterComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$EventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventsTable,
          EventRow,
          $$EventsTableFilterComposer,
          $$EventsTableOrderingComposer,
          $$EventsTableAnnotationComposer,
          $$EventsTableCreateCompanionBuilder,
          $$EventsTableUpdateCompanionBuilder,
          (EventRow, BaseReferences<_$AppDatabase, $EventsTable, EventRow>),
          EventRow,
          PrefetchHooks Function()
        > {
  $$EventsTableTableManager(_$AppDatabase db, $EventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventsCompanion(
                id: id,
                payload: payload,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String payload,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => EventsCompanion.insert(
                id: id,
                payload: payload,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EventsTable, EventRow>(table),
                  BaseReferences<_$AppDatabase, $EventsTable, EventRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventsTable,
      EventRow,
      $$EventsTableFilterComposer,
      $$EventsTableOrderingComposer,
      $$EventsTableAnnotationComposer,
      $$EventsTableCreateCompanionBuilder,
      $$EventsTableUpdateCompanionBuilder,
      (EventRow, BaseReferences<_$AppDatabase, $EventsTable, EventRow>),
      EventRow,
      PrefetchHooks Function()
    >;
typedef $$RivalriesTableCreateCompanionBuilder = RivalriesCompanion Function({
  required String id,
  required String payload,
  required DateTime updatedAt,
  required String fighterA,
  required String fighterB,
  Value<int> rowid,
});
typedef $$RivalriesTableUpdateCompanionBuilder = RivalriesCompanion Function({
  Value<String> id,
  Value<String> payload,
  Value<DateTime> updatedAt,
  Value<String> fighterA,
  Value<String> fighterB,
  Value<int> rowid,
});

class $$RivalriesTableFilterComposer
    extends Composer<_$AppDatabase, $RivalriesTable> {
  $$RivalriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fighterA => $composableBuilder(
    column: $table.fighterA,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fighterB => $composableBuilder(
    column: $table.fighterB,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RivalriesTableOrderingComposer
    extends Composer<_$AppDatabase, $RivalriesTable> {
  $$RivalriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fighterA => $composableBuilder(
    column: $table.fighterA,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fighterB => $composableBuilder(
    column: $table.fighterB,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RivalriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RivalriesTable> {
  $$RivalriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get fighterA =>
      $composableBuilder(column: $table.fighterA, builder: (column) => column);

  GeneratedColumn<String> get fighterB =>
      $composableBuilder(column: $table.fighterB, builder: (column) => column);
}

class $$RivalriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RivalriesTable,
          RivalryRow,
          $$RivalriesTableFilterComposer,
          $$RivalriesTableOrderingComposer,
          $$RivalriesTableAnnotationComposer,
          $$RivalriesTableCreateCompanionBuilder,
          $$RivalriesTableUpdateCompanionBuilder,
          (
            RivalryRow,
            BaseReferences<_$AppDatabase, $RivalriesTable, RivalryRow>,
          ),
          RivalryRow,
          PrefetchHooks Function()
        > {
  $$RivalriesTableTableManager(_$AppDatabase db, $RivalriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RivalriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RivalriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RivalriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> fighterA = const Value.absent(),
                Value<String> fighterB = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RivalriesCompanion(
                id: id,
                payload: payload,
                updatedAt: updatedAt,
                fighterA: fighterA,
                fighterB: fighterB,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String payload,
                required DateTime updatedAt,
                required String fighterA,
                required String fighterB,
                Value<int> rowid = const Value.absent(),
              }) => RivalriesCompanion.insert(
                id: id,
                payload: payload,
                updatedAt: updatedAt,
                fighterA: fighterA,
                fighterB: fighterB,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RivalriesTable, RivalryRow>(table),
                  BaseReferences<_$AppDatabase, $RivalriesTable, RivalryRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RivalriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RivalriesTable,
      RivalryRow,
      $$RivalriesTableFilterComposer,
      $$RivalriesTableOrderingComposer,
      $$RivalriesTableAnnotationComposer,
      $$RivalriesTableCreateCompanionBuilder,
      $$RivalriesTableUpdateCompanionBuilder,
      (RivalryRow, BaseReferences<_$AppDatabase, $RivalriesTable, RivalryRow>),
      RivalryRow,
      PrefetchHooks Function()
    >;
typedef $$OwnedCardsTableCreateCompanionBuilder = OwnedCardsCompanion Function({
  required String id,
  required String ownerId,
  required String cardId,
  required String variantId,
  required String payload,
  Value<int> rowid,
});
typedef $$OwnedCardsTableUpdateCompanionBuilder = OwnedCardsCompanion Function({
  Value<String> id,
  Value<String> ownerId,
  Value<String> cardId,
  Value<String> variantId,
  Value<String> payload,
  Value<int> rowid,
});

class $$OwnedCardsTableFilterComposer
    extends Composer<_$AppDatabase, $OwnedCardsTable> {
  $$OwnedCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OwnedCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $OwnedCardsTable> {
  $$OwnedCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OwnedCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OwnedCardsTable> {
  $$OwnedCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<String> get variantId =>
      $composableBuilder(column: $table.variantId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$OwnedCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OwnedCardsTable,
          OwnedCardRow,
          $$OwnedCardsTableFilterComposer,
          $$OwnedCardsTableOrderingComposer,
          $$OwnedCardsTableAnnotationComposer,
          $$OwnedCardsTableCreateCompanionBuilder,
          $$OwnedCardsTableUpdateCompanionBuilder,
          (
            OwnedCardRow,
            BaseReferences<_$AppDatabase, $OwnedCardsTable, OwnedCardRow>,
          ),
          OwnedCardRow,
          PrefetchHooks Function()
        > {
  $$OwnedCardsTableTableManager(_$AppDatabase db, $OwnedCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OwnedCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OwnedCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OwnedCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> cardId = const Value.absent(),
                Value<String> variantId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OwnedCardsCompanion(
                id: id,
                ownerId: ownerId,
                cardId: cardId,
                variantId: variantId,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ownerId,
                required String cardId,
                required String variantId,
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => OwnedCardsCompanion.insert(
                id: id,
                ownerId: ownerId,
                cardId: cardId,
                variantId: variantId,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OwnedCardsTable, OwnedCardRow>(table),
                  BaseReferences<_$AppDatabase, $OwnedCardsTable, OwnedCardRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OwnedCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OwnedCardsTable,
      OwnedCardRow,
      $$OwnedCardsTableFilterComposer,
      $$OwnedCardsTableOrderingComposer,
      $$OwnedCardsTableAnnotationComposer,
      $$OwnedCardsTableCreateCompanionBuilder,
      $$OwnedCardsTableUpdateCompanionBuilder,
      (
        OwnedCardRow,
        BaseReferences<_$AppDatabase, $OwnedCardsTable, OwnedCardRow>,
      ),
      OwnedCardRow,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableCreateCompanionBuilder = SyncStateCompanion Function({
  required String remoteTable,
  required DateTime lastUpdatedAt,
  Value<int> rowid,
});
typedef $$SyncStateTableUpdateCompanionBuilder = SyncStateCompanion Function({
  Value<String> remoteTable,
  Value<DateTime> lastUpdatedAt,
  Value<int> rowid,
});

class $$SyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get remoteTable => $composableBuilder(
    column: $table.remoteTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get remoteTable => $composableBuilder(
    column: $table.remoteTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get remoteTable => $composableBuilder(
    column: $table.remoteTable,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => column,
  );
}

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateTable,
          SyncStateRow,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (
            SyncStateRow,
            BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateRow>,
          ),
          SyncStateRow,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$AppDatabase db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> remoteTable = const Value.absent(),
                Value<DateTime> lastUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion(
                remoteTable: remoteTable,
                lastUpdatedAt: lastUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String remoteTable,
                required DateTime lastUpdatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion.insert(
                remoteTable: remoteTable,
                lastUpdatedAt: lastUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncStateTable, SyncStateRow>(table),
                  BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateTable,
      SyncStateRow,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (
        SyncStateRow,
        BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateRow>,
      ),
      SyncStateRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FightersTableTableManager get fighters =>
      $$FightersTableTableManager(_db, _db.fighters);
  $$EditionsTableTableManager get editions =>
      $$EditionsTableTableManager(_db, _db.editions);
  $$SeriesTableTableTableManager get seriesTable =>
      $$SeriesTableTableTableManager(_db, _db.seriesTable);
  $$CardsTableTableManager get cards =>
      $$CardsTableTableManager(_db, _db.cards);
  $$VariantsTableTableManager get variants =>
      $$VariantsTableTableManager(_db, _db.variants);
  $$ImagesTableTableManager get images =>
      $$ImagesTableTableManager(_db, _db.images);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
  $$RivalriesTableTableManager get rivalries =>
      $$RivalriesTableTableManager(_db, _db.rivalries);
  $$OwnedCardsTableTableManager get ownedCards =>
      $$OwnedCardsTableTableManager(_db, _db.ownedCards);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
}
