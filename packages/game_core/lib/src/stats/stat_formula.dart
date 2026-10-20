import 'dart:math' as math;

import '../model/fighter_record.dart';

/// # Formule des statistiques de jeu (version [StatFormula.version])
///
/// Trois catégories, chacune avec trois sous-stats (30 à 99), calculées à
/// partir des **vraies** statistiques collectées sur ufc.com et Wikipedia
/// (voir `data/scripts/fetch_fighters.py`). Aucune stat n'est saisie à la main.
///
/// | Catégorie | Sous-stat     | Mesures (poids)                                                         |
/// |-----------|---------------|-------------------------------------------------------------------------|
/// | Frappe    | Précision     | précision de frappe                                                     |
/// |           | Puissance     | part des victoires par KO (0,5), knockdowns/15 min (0,3), KO en carrière (0,2) |
/// |           | Vitesse       | frappes significatives réussies par minute                              |
/// | Lutte     | Takedown      | takedowns/15 min (0,6), précision des takedowns (0,4)                   |
/// |           | Contrôle      | takedowns/15 min (0,4), takedowns réussis à l'UFC (0,3), part des victoires par décision (0,3) |
/// |           | Soumission    | tentatives/15 min (0,4), part des victoires par soumission (0,4), soumissions en carrière (0,2) |
/// | Défense   | Menton        | taux et nombre de défaites par KO, inversés                             |
/// |           | Esquive       | défense de frappe (0,5), frappes encaissées/min inversées (0,5)         |
/// |           | Défense TD    | défense de takedown                                                     |
///
/// ## Étapes
///
/// 1. **Normalisation** de chaque mesure entre 0 et 1 ([refs], bornes de
///    l'effectif UFC). Si une mesure manque, son poids est réparti sur les
///    autres ; si toutes manquent, 0,5 et la stat est marquée « estimée ».
/// 2. **Fiabilité** : avec peu de combats UFC, le score est tiré vers 0,5
///    (`k` = [shrinkFights] combats virtuels), sauf le menton (toute la carrière).
/// 3. **Étalement** : le score est écarté de la moyenne ([spread]) pour que
///    les meilleurs se détachent, puis ramené sur 30 à 99.
/// 4. **Niveau réel** : bonus d'élite ajouté à chaque sous-stat, le plus haut
///    de : champion actuel [championBonus], ancien champion
///    [formerChampionBonus], classé n°r `[rankBonus] − 0,35 × r` ; plus jusqu'à
///    [winsBonusMax] selon les victoires à l'UFC. Plafonné à 99.
///
/// Note globale : la meilleure attaque (Frappe ou Lutte), la Défense et
/// l'autre attaque, pondérées par [overallWeights]. Les bonus de rareté (+1 à +6) s'ajoutent en
/// jeu à chaque sous-stat, plafonnés à 99. Affichage en lettres : [grade].
class StatFormula {
  static const int version = 2;

  /// Nombre de combats « virtuels » à 0,5 ajoutés pour la fiabilité.
  static const double shrinkFights = 3;

  static const int floor = 30;
  static const int ceiling = 99;

  /// Écart à la moyenne multiplié par ce facteur (notes plus étalées).
  static const double spread = 1.35;

  static const double championBonus = 10;
  static const double formerChampionBonus = 7;
  static const double rankBonus = 7;
  static const double winsBonusMax = 4;

  /// Poids dans la note globale : meilleure attaque (Frappe ou Lutte),
  /// Défense, autre attaque.
  static const List<double> overallWeights = [0.55, 0.3, 0.15];

  /// Bornes de normalisation (bas -> 0, haut -> 1).
  static const Map<String, (double, double)> refs = {
    'slpm': (1.5, 7.0), // frappes significatives réussies / min
    'strAcc': (35, 65), // % précision de frappe
    'sapm': (1.5, 6.0), // frappes encaissées / min (inversé ensuite)
    'strDef': (40, 70), // % défense de frappe
    'tdAvg': (0, 5.0), // takedowns / 15 min
    'tdAcc': (20, 60), // % précision des takedowns
    'tdDef': (40, 95), // % défense de takedown
    'tdTotal': (0, 60), // takedowns réussis à l'UFC
    'subAvg': (0, 2.0), // tentatives de soumission / 15 min
    'kdAvg': (0, 1.2), // knockdowns / 15 min
    'koShare': (0.10, 0.80), // part des victoires par KO/TKO
    'koWins': (0, 15), // victoires par KO en carrière
    'subShare': (0.0, 0.60), // part des victoires par soumission
    'subWins': (0, 15), // victoires par soumission en carrière
    'decShare': (0.1, 0.7), // part des victoires par décision
    'koLossRate': (0, 0.25), // défaites par KO / combats pros (inversé)
    'koLosses': (0, 6), // nombre de défaites par KO (inversé)
  };

  static double norm(String key, double x) {
    final (lo, hi) = refs[key]!;
    return ((x - lo) / (hi - lo)).clamp(0.0, 1.0);
  }

  /// Bonus d'élite (points ajoutés à chaque sous-stat).
  static double eliteBonus(RealStats r) {
    var title = 0.0;
    if (r.championNow || r.rank == 0) title = championBonus;
    if (r.formerChampion) title = math.max(title, formerChampionBonus);
    if (r.rank != null && r.rank! > 0) title = math.max(title, rankBonus - 0.35 * r.rank!);
    final wins = math.min(winsBonusMax, (r.ufcWins ?? 0) * 0.3);
    return title + wins;
  }

  static GameStats compute(RealStats r) {
    final est = <StatKind>{};

    double combine(StatKind kind, List<(double?, double)> parts, {bool shrink = true}) {
      final present = parts.where((p) => p.$1 != null).toList();
      if (present.isEmpty) {
        // Aucune mesure (fiche ufc.com sans stats) : estimée d'après le taux
        // de victoires à l'UFC, sinon neutre.
        est.add(kind);
        final w = r.ufcWins, l = r.ufcFights;
        if (w == null || l == null || l == 0) return 0.5;
        return 0.5 + (w / l - 0.5) * 0.6;
      }
      final wsum = present.fold<double>(0, (a, p) => a + p.$2);
      var score = present.fold<double>(0, (a, p) => a + p.$1! * p.$2) / wsum;
      if (shrink) {
        final c = (r.ufcFights ?? 0).toDouble();
        score = (c * score + shrinkFights * 0.5) / (c + shrinkFights);
      }
      return score;
    }

    double? n(String key, num? x) => x == null ? null : norm(key, x.toDouble());
    double? inv(double? v) => v == null ? null : 1 - v;
    double? share(int? part) => (r.wins != null && r.wins! > 0 && part != null) ? part / r.wins! : null;

    final total = r.totalFights;
    final koLossRate = (total != null && total > 0 && r.lossesKo != null) ? r.lossesKo! / total : null;

    final scores = <StatKind, double>{
      StatKind.precision: combine(StatKind.precision, [(n('strAcc', r.strikingAccuracyPct), 1)]),
      StatKind.puissance: combine(StatKind.puissance, [
        (n('koShare', share(r.winsKo)), 0.5),
        (n('kdAvg', r.knockdownsPer15), 0.3),
        (n('koWins', r.winsKo), 0.2),
      ]),
      StatKind.vitesse: combine(StatKind.vitesse, [(n('slpm', r.strikesLandedPerMin), 1)]),
      StatKind.takedown: combine(StatKind.takedown, [
        (n('tdAvg', r.takedownsPer15), 0.6),
        (n('tdAcc', r.takedownAccuracyPct), 0.4),
      ]),
      StatKind.controle: combine(StatKind.controle, [
        (n('tdAvg', r.takedownsPer15), 0.4),
        (n('tdTotal', r.takedownsLanded), 0.3),
        (n('decShare', share(r.winsDecision)), 0.3),
      ]),
      StatKind.soumission: combine(StatKind.soumission, [
        (n('subAvg', r.submissionsPer15), 0.4),
        (n('subShare', share(r.winsSubmission)), 0.4),
        (n('subWins', r.winsSubmission), 0.2),
      ]),
      StatKind.menton: combine(
        StatKind.menton,
        [(inv(n('koLossRate', koLossRate)), 0.5), (inv(n('koLosses', r.lossesKo)), 0.5)],
        shrink: false,
      ),
      StatKind.esquive: combine(StatKind.esquive, [
        (n('strDef', r.strikingDefensePct), 0.5),
        (inv(n('sapm', r.strikesAbsorbedPerMin)), 0.5),
      ]),
      StatKind.defenseTd: combine(StatKind.defenseTd, [(n('tdDef', r.takedownDefensePct), 1)]),
    };

    final bonus = eliteBonus(r);
    int scale(double s) {
      final spreadOut = (0.5 + (s - 0.5) * spread).clamp(0.0, 1.0);
      return (floor + (ceiling - floor) * spreadOut + bonus).round().clamp(floor, ceiling);
    }

    return GameStats({for (final e in scores.entries) e.key: scale(e.value)}, estimated: est);
  }

  /// Lettre d'une stat : S (90 et plus), puis A, B, C de 10 en 10 avec + et −,
  /// D en dessous de 60.
  static String grade(int v) {
    if (v >= 90) return 'S';
    if (v < 50) return 'D-';
    if (v < 55) return 'D';
    if (v < 60) return 'D+';
    final letter = v >= 80 ? 'A' : (v >= 70 ? 'B' : 'C');
    final d = v % 10;
    return d <= 2 ? '$letter-' : (d >= 7 ? '$letter+' : letter);
  }
}

/// Catégories de stats.
enum StatCategory {
  frappe('Frappe'),
  lutte('Lutte'),
  defense('Défense');

  const StatCategory(this.label);
  final String label;

  List<StatKind> get kinds => [for (final k in StatKind.values) if (k.category == this) k];
}

enum StatKind {
  precision('Précision', 'PRÉ', StatCategory.frappe),
  puissance('Puissance', 'PUI', StatCategory.frappe),
  vitesse('Vitesse', 'VIT', StatCategory.frappe),
  takedown('Takedown', 'TKD', StatCategory.lutte),
  controle('Contrôle', 'CTL', StatCategory.lutte),
  soumission('Soumission', 'SOU', StatCategory.lutte),
  menton('Menton', 'MEN', StatCategory.defense),
  esquive('Esquive', 'ESQ', StatCategory.defense),
  defenseTd('Défense TD', 'DTD', StatCategory.defense);

  const StatKind(this.label, this.short, this.category);
  final String label;
  final String short;
  final StatCategory category;
}

enum FighterStyle {
  frappeur('Frappeur'),
  lutteur('Lutteur'),
  grappler('Grappler'),
  complet('Complet');

  const FighterStyle(this.label);
  final String label;
}

class GameStats {
  GameStats(Map<StatKind, int> values, {Set<StatKind> estimated = const {}})
    : values = Map.unmodifiable(values),
      estimated = Set.unmodifiable(estimated);

  final Map<StatKind, int> values;

  /// Stats calculées sans aucune donnée réelle (valeur neutre).
  final Set<StatKind> estimated;

  int operator [](StatKind k) => values[k]!;

  /// Valeur d'une catégorie : moyenne de ses trois sous-stats.
  int category(StatCategory c) {
    final ks = c.kinds;
    return (ks.fold<int>(0, (a, k) => a + this[k]) / ks.length).round();
  }

  /// Note globale : meilleure attaque, Défense, autre attaque ([StatFormula.overallWeights]).
  int get overall {
    final f = category(StatCategory.frappe), l = category(StatCategory.lutte);
    final w = StatFormula.overallWeights;
    return (math.max(f, l) * w[0] + category(StatCategory.defense) * w[1] + math.min(f, l) * w[2]).round();
  }

  FighterStyle get style {
    final striking = category(StatCategory.frappe);
    final grappling = category(StatCategory.lutte);
    // Moins de 5 points d'écart entre Frappe et Lutte : complet.
    if ((striking - grappling).abs() < 5) return FighterStyle.complet;
    if (striking > grappling) return FighterStyle.frappeur;
    final wrestling = (this[StatKind.takedown] + this[StatKind.controle]) / 2;
    return this[StatKind.soumission] > wrestling ? FighterStyle.grappler : FighterStyle.lutteur;
  }

  /// Applique un bonus de rareté (+1 à +6), plafonné à 99.
  GameStats withBonus(int bonus) => GameStats({
    for (final e in values.entries) e.key: (e.value + bonus).clamp(0, StatFormula.ceiling),
  }, estimated: estimated);

  Map<String, dynamic> toJson() => {
    for (final e in values.entries) e.key.name: e.value,
    for (final c in StatCategory.values) 'categorie_${c.name}': category(c),
    'globale': overall,
    'style': style.name,
    'estimees': [for (final k in estimated) k.name],
    'formule_version': StatFormula.version,
  };

  factory GameStats.fromJson(Map<String, dynamic> j) => GameStats({
    for (final k in StatKind.values) k: (j[k.name] as num?)?.toInt() ?? 50,
  }, estimated: {for (final s in (j['estimees'] as List? ?? const [])) ?StatKind.values.asNameMap()[s]});
}
