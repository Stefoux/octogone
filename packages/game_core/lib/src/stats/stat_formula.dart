import 'dart:math' as math;

import '../model/fighter_record.dart';

/// # Formule des statistiques de jeu (version [StatFormula.version])
///
/// Les 7 stats de jeu (0-99) sont calculées à partir des **vraies**
/// statistiques collectées sur ufc.com et Wikipedia (voir
/// `data/scripts/fetch_fighters.py`). Aucune stat n'est saisie à la main.
///
/// ## Étapes
///
/// 1. **Normalisation.** Chaque mesure réelle est ramenée entre 0 et 1 par une
///    échelle linéaire bornée `n(x, bas, haut)` : `bas` donne 0, `haut` donne 1.
///    Les bornes ([refs]) correspondent aux valeurs courantes de l'effectif UFC,
///    de l'athlète modeste au meilleur de la discipline. Pour les mesures où
///    « moins, c'est mieux » (frappes encaissées), on inverse.
///
/// 2. **Combinaison.** Chaque stat est une moyenne pondérée de mesures :
///
///    | Stat       | Mesures (poids)                                                        |
///    |------------|------------------------------------------------------------------------|
///    | Frappe     | frappes réussies/min (0,5) + précision de frappe (0,5)                 |
///    | Puissance  | part des victoires par KO (0,7) + knockdowns/15 min (0,3)              |
///    | Lutte      | takedowns/15 min (0,4) + précision TD (0,25) + défense TD (0,35)       |
///    | Soumission | tentatives/15 min (0,5) + part des victoires par soumission (0,5)      |
///    | Défense    | frappes encaissées/min, inversé (0,5) + défense de frappe (0,5)        |
///    | Cardio     | durée moyenne des combats (0,6) + victoires par décision en 5 rounds (0,4) |
///    | Menton     | taux de défaites par KO (0,5) + nombre de défaites par KO (0,5), inversés |
///
///    Si une mesure manque, son poids est réparti sur les autres. Si toutes
///    manquent, le score vaut 0,5 et la stat est marquée « estimée ».
///
/// 3. **Fiabilité.** Avec peu de combats UFC, les moyennes sont instables (un
///    seul KO éclair donne 100 % de victoires par KO). On tire donc le score
///    vers 0,5 selon le nombre de combats UFC `c` :
///    `score' = (c × score + k × 0,5) / (c + k)` avec `k` = [shrinkFights].
///    Le Menton n'est pas concerné (il porte sur toute la carrière).
///
/// 4. **Échelle finale.** `stat = 30 + 69 × score'`, arrondi. Le plancher de 30
///    traduit le fait que tout combattant UFC est un athlète professionnel ;
///    99 est réservé au tout meilleur de la discipline.
///
/// Les bonus de rareté (+1 à +6) s'ajoutent ensuite, en jeu, plafonnés à 99.
class StatFormula {
  static const int version = 1;

  /// Nombre de combats « virtuels » à 0,5 ajoutés pour la fiabilité.
  static const double shrinkFights = 3;

  static const int floor = 30;
  static const int ceiling = 99;

  /// Bornes de normalisation (bas -> 0, haut -> 1).
  static const Map<String, (double, double)> refs = {
    'slpm': (1.5, 7.0), // frappes significatives réussies / min
    'strAcc': (35, 65), // % précision de frappe
    'sapm': (1.5, 6.0), // frappes encaissées / min (inversé ensuite)
    'strDef': (40, 70), // % défense de frappe
    'tdAvg': (0, 5.0), // takedowns / 15 min
    'tdAcc': (20, 60), // % précision des takedowns
    'tdDef': (40, 95), // % défense de takedown
    'subAvg': (0, 2.0), // tentatives de soumission / 15 min
    'kdAvg': (0, 1.2), // knockdowns / 15 min
    'koShare': (0.10, 0.80), // part des victoires par KO/TKO
    'subShare': (0.0, 0.60), // part des victoires par soumission
    'avgTime': (240, 900), // durée moyenne d'un combat (s) : 4 à 15 min
    'fiveRdDec': (0, 3), // victoires par décision en 5 rounds
    'koLossRate': (0, 0.25), // défaites par KO / combats pros (inversé)
    'koLosses': (0, 6), // nombre de défaites par KO (inversé)
  };

  static double norm(String key, double x) {
    final (lo, hi) = refs[key]!;
    return ((x - lo) / (hi - lo)).clamp(0.0, 1.0);
  }

  static GameStats compute(RealStats r) {
    final est = <StatKind>{};

    double combine(StatKind kind, List<(double?, double)> parts,
        {bool shrink = true}) {
      final present = parts.where((p) => p.$1 != null).toList();
      if (present.isEmpty) {
        est.add(kind);
        return 0.5;
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

    final wins = r.wins;
    final koShare =
        (wins != null && wins > 0 && r.winsKo != null) ? r.winsKo! / wins : null;
    final subShare = (wins != null && wins > 0 && r.winsSubmission != null)
        ? r.winsSubmission! / wins
        : null;
    final total = r.totalFights;
    final koLossRate = (total != null && total > 0 && r.lossesKo != null)
        ? r.lossesKo! / total
        : null;

    final scores = <StatKind, double>{
      StatKind.frappe: combine(StatKind.frappe, [
        (n('slpm', r.strikesLandedPerMin), 0.5),
        (n('strAcc', r.strikingAccuracyPct), 0.5),
      ]),
      StatKind.puissance: combine(StatKind.puissance, [
        (n('koShare', koShare), 0.7),
        (n('kdAvg', r.knockdownsPer15), 0.3),
      ]),
      StatKind.lutte: combine(StatKind.lutte, [
        (n('tdAvg', r.takedownsPer15), 0.4),
        (n('tdAcc', r.takedownAccuracyPct), 0.25),
        (n('tdDef', r.takedownDefensePct), 0.35),
      ]),
      StatKind.soumission: combine(StatKind.soumission, [
        (n('subAvg', r.submissionsPer15), 0.5),
        (n('subShare', subShare), 0.5),
      ]),
      StatKind.defense: combine(StatKind.defense, [
        (inv(n('sapm', r.strikesAbsorbedPerMin)), 0.5),
        (n('strDef', r.strikingDefensePct), 0.5),
      ]),
      StatKind.cardio: combine(StatKind.cardio, [
        (n('avgTime', r.avgFightTimeSeconds), 0.6),
        (n('fiveRdDec', r.fiveRoundDecisionWins), 0.4),
      ]),
      StatKind.menton: combine(
          StatKind.menton,
          [
            (inv(n('koLossRate', koLossRate)), 0.5),
            (inv(n('koLosses', r.lossesKo)), 0.5),
          ],
          shrink: false),
    };

    int scale(double s) =>
        (floor + (ceiling - floor) * s).round().clamp(floor, ceiling);

    return GameStats(
      {for (final e in scores.entries) e.key: scale(e.value)},
      estimated: est,
    );
  }
}

enum StatKind {
  frappe('Frappe', 'FRA'),
  puissance('Puissance', 'PUI'),
  lutte('Lutte', 'LUT'),
  soumission('Soumission', 'SOU'),
  defense('Défense', 'DÉF'),
  cardio('Cardio', 'CAR'),
  menton('Menton', 'MEN');

  const StatKind(this.label, this.short);
  final String label;
  final String short;
}

/// Style dominant, déduit des stats (sert à l'IA et à l'équilibrage).
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

  /// Note globale : moyenne des 7 stats.
  int get overall =>
      (values.values.fold<int>(0, (a, b) => a + b) / values.length).round();

  FighterStyle get style {
    final striking = (this[StatKind.frappe] + this[StatKind.puissance]) / 2;
    final wrestling = this[StatKind.lutte].toDouble();
    final grappling = this[StatKind.soumission].toDouble();
    final best = math.max(striking, math.max(wrestling, grappling));
    final second = [striking, wrestling, grappling]..sort();
    // Moins de 5 points d'écart entre les deux meilleurs domaines : complet.
    if (best - second[1] < 5) return FighterStyle.complet;
    if (best == striking) return FighterStyle.frappeur;
    if (best == wrestling) return FighterStyle.lutteur;
    return FighterStyle.grappler;
  }

  /// Applique un bonus de rareté (+1 à +6), plafonné à 99.
  GameStats withBonus(int bonus) => GameStats(
        {
          for (final e in values.entries)
            e.key: (e.value + bonus).clamp(0, StatFormula.ceiling)
        },
        estimated: estimated,
      );

  Map<String, dynamic> toJson() => {
        for (final e in values.entries) e.key.name: e.value,
        'globale': overall,
        'style': style.name,
        'estimees': [for (final k in estimated) k.name],
        'formule_version': StatFormula.version,
      };

  factory GameStats.fromJson(Map<String, dynamic> j) => GameStats(
        {for (final k in StatKind.values) k: (j[k.name] as num?)?.toInt() ?? 50},
        estimated: {
          for (final s in (j['estimees'] as List? ?? const []))
            StatKind.values.byName(s as String)
        },
      );
}
