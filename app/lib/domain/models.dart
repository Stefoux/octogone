import 'package:game_core/game_core.dart';

/// Modèles lus depuis les lignes Supabase (ou leur copie dans le cache Drift).
/// Les clés JSON sont celles des tables SQL.

typedef Json = Map<String, dynamic>;

List<String> _strings(Object? v) => v is List ? [for (final e in v) '$e'] : const [];
Json _map(Object? v) => v is Map ? v.cast<String, dynamic>() : const {};

class Fighter {
  Fighter(this.json)
      : id = json['id'] as String,
        nom = json['nom'] as String,
        surnom = json['surnom'] as String?,
        pays = json['pays'] as String?,
        sexe = json['sexe'] as String?,
        categorie = WeightClass.fromKey(json['categorie'] as String?),
        statut = json['statut'] as String?,
        style = json['style'] as String?,
        championActuel = json['champion_actuel'] == true,
        ancienChampion = json['ancien_champion'] == true,
        imageId = json['image_id'] as String?,
        aVerifier = _strings(json['a_verifier']);

  final Json json;
  final String id;
  final String nom;
  final String? surnom;
  final String? pays;
  final String? sexe;
  final WeightClass? categorie;
  final String? statut;
  final String? style;
  final bool championActuel;
  final bool ancienChampion;
  final String? imageId;
  final List<String> aVerifier;

  Json get palmares => _map(json['palmares']);
  Json get statsUfc => _map(json['stats_ufc']);
  Json get ufc => _map(json['ufc']);
  Map<String, String> get sources => _map(json['sources']).map((k, v) => MapEntry(k, '$v'));
  /// Distinctions courtes dans la langue demandée (repli sur le français).
  List<String> distinctions(String lang) {
    final d = _map(json['distinctions']);
    final list = _strings(d[lang]);
    return list.isNotEmpty ? list : _strings(d['fr']);
  }

  /// Stats de jeu : retouche admin si elle existe, sinon calcul de la formule.
  GameStats get stats {
    final override = json['stats_jeu_override'];
    if (override is Map && override.isNotEmpty) {
      return GameStats.fromJson(override.cast<String, dynamic>());
    }
    final stored = _map(json['stats_jeu']);
    if (stored.isNotEmpty) return GameStats.fromJson(stored);
    return StatFormula.compute(RealStats.fromFighterJson(json));
  }

  String get record {
    final p = palmares;
    final w = p['victoires'], l = p['defaites'], d = p['nuls'] ?? 0;
    if (w == null || l == null) return '—';
    return '$w-$l${d != 0 ? '-$d' : ''}';
  }

  bool get retired => statut == 'retraite';
}

class ImageRef {
  ImageRef(Json j)
      : id = j['id'] as String,
        storagePath = j['storage_path'] as String,
        titre = j['titre'] as String?,
        auteur = j['auteur'] as String?,
        licence = j['licence'] as String?,
        licenceUrl = j['licence_url'] as String?,
        sourceUrl = j['source_url'] as String?,
        fighterId = j['fighter_id'] as String?,
        focalX = (j['focal_x'] as num?)?.toDouble(),
        focalY = (j['focal_y'] as num?)?.toDouble();

  final String id;
  final String storagePath;
  final String? titre;
  final String? auteur;
  final String? licence;
  final String? licenceUrl;
  final String? sourceUrl;
  final String? fighterId;
  final double? focalX;
  final double? focalY;
}

class Edition {
  Edition(Json j)
      : id = j['id'] as String,
        nom = j['nom'] as String,
        annee = (j['annee'] as num).toInt(),
        type = j['type'] as String,
        gamme = j['gamme'] as String?,
        familleCadre = j['famille_cadre'] as String,
        dateSortie = j['date_sortie'] as String?,
        description = j['description'] as String?,
        sources = _strings(j['sources']),
        aVerifier = _strings(j['a_verifier']);

  final String id;
  final String nom;
  final int annee;
  final String type;
  final String? gamme;
  final String familleCadre;
  final String? dateSortie;
  final String? description;
  final List<String> sources;
  final List<String> aVerifier;

  bool get isReal => type == 'reelle';
}

class CardSeries {
  CardSeries(Json j)
      : id = j['id'] as String,
        editionId = j['edition_id'] as String,
        code = j['code'] as String,
        nom = j['nom'] as String,
        type = j['type'] as String,
        nbCartes = (j['nb_cartes'] as num?)?.toInt(),
        cote = j['cote'] as String?,
        exclusivite = j['exclusivite'] as String?,
        tirage = (j['tirage'] as num?)?.toInt(),
        ordre = (j['ordre'] as num?)?.toInt() ?? 0;

  final String id;
  final String editionId;
  final String code;
  final String nom;
  final String type;
  final int? nbCartes;
  final String? cote;
  final String? exclusivite;
  final int? tirage;
  final int ordre;

  String get typeLabel => switch (type) {
        'base' => 'Base',
        'autographe' => 'Autographes',
        'relique' => 'Reliques',
        'moment' => 'Moments Historiques',
        'celebration' => 'Célébrations',
        _ => 'Insert',
      };
}

class CardDef {
  CardDef(Json j)
      : id = j['id'] as String,
        editionId = j['edition_id'] as String,
        seriesId = j['series_id'] as String,
        numero = j['numero'] as String,
        ordre = (j['ordre'] as num).toInt(),
        fighterIds = _strings(j['fighter_ids']),
        nomImprime = j['nom_imprime'] as String,
        sousTitre = j['sous_titre'] as String?,
        mentions = _strings(j['mentions']),
        imageId = j['image_id'] as String?,
        eventId = j['event_id'] as String?;

  final String id;
  final String editionId;
  final String seriesId;
  final String numero;
  final int ordre;
  final List<String> fighterIds;
  final String nomImprime;
  final String? sousTitre;
  final List<String> mentions;
  final String? imageId;
  final String? eventId;

  bool get isRookie => mentions.contains('RC');
}

class Variant {
  Variant(Json j)
      : id = j['id'] as String,
        seriesId = j['series_id'] as String?,
        editionId = j['edition_id'] as String?,
        nom = j['nom'] as String,
        rarete = j['rarete'] as String,
        effet = j['effet'] as String,
        couleur = j['couleur'] as String?,
        tirage = (j['tirage'] as num?)?.toInt(),
        cote = j['cote'] as String?,
        exclusivite = j['exclusivite'] as String?,
        reel = j['reel'] == true,
        bonusStats = (j['bonus_stats'] as num?)?.toInt() ?? 0,
        ordre = (j['ordre'] as num?)?.toInt() ?? 0;

  final String id;
  final String? seriesId;
  final String? editionId;
  final String nom;
  final String rarete;
  final String effet;
  final String? couleur;
  final int? tirage;
  final String? cote;
  final String? exclusivite;
  final bool reel;
  final int bonusStats;
  final int ordre;

  String get tirageLabel => tirage == null ? '' : (tirage == 1 ? '1/1' : '/$tirage');
}

const rarityLabels = {
  'commune': 'Commune',
  'peu_commune': 'Peu commune',
  'rare': 'Rare',
  'epique': 'Épique',
  'legendaire': 'Légendaire',
  'mythique': 'Mythique',
};
