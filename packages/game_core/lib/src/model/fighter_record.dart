/// Données réelles d'un combattant, telles que collectées par
/// `data/scripts/fetch_fighters.py` (ufc.com, Wikipedia, Wikidata).
///
/// Tout champ peut être `null` : la donnée n'a pas été trouvée et figure
/// dans `aVerifier` côté JSON. La formule des stats sait faire sans.
class RealStats {
  const RealStats({
    this.strikesLandedPerMin,
    this.strikingAccuracyPct,
    this.strikesAbsorbedPerMin,
    this.strikingDefensePct,
    this.takedownsPer15,
    this.takedownAccuracyPct,
    this.takedownDefensePct,
    this.submissionsPer15,
    this.knockdownsPer15,
    this.avgFightTimeSeconds,
    this.wins,
    this.losses,
    this.draws,
    this.winsKo,
    this.winsSubmission,
    this.winsDecision,
    this.lossesKo,
    this.ufcFights,
    this.fiveRoundDecisionWins,
  });

  /// Frappes significatives réussies par minute (ufc.com « Sig. Str. Landed »).
  final double? strikesLandedPerMin;

  /// Précision des frappes significatives, en %.
  final double? strikingAccuracyPct;

  /// Frappes significatives encaissées par minute.
  final double? strikesAbsorbedPerMin;

  /// Défense de frappe (part des frappes adverses qui ne touchent pas), en %.
  final double? strikingDefensePct;

  /// Takedowns réussis par 15 minutes.
  final double? takedownsPer15;
  final double? takedownAccuracyPct;
  final double? takedownDefensePct;

  /// Tentatives de soumission par 15 minutes.
  final double? submissionsPer15;

  /// Knockdowns infligés par 15 minutes.
  final double? knockdownsPer15;

  /// Durée moyenne des combats à l'UFC, en secondes.
  final int? avgFightTimeSeconds;

  // Palmarès professionnel complet (toutes organisations).
  final int? wins;
  final int? losses;
  final int? draws;
  final int? winsKo;
  final int? winsSubmission;
  final int? winsDecision;
  final int? lossesKo;

  /// Nombre de combats à l'UFC (sert à pondérer la fiabilité des stats).
  final int? ufcFights;

  /// Victoires par décision au bout de 5 rounds.
  final int? fiveRoundDecisionWins;

  int? get totalFights =>
      wins == null || losses == null ? null : wins! + losses! + (draws ?? 0);

  /// Construit à partir du JSON de `data/fighters/<id>.json` (ou de la ligne
  /// Supabase équivalente, qui reprend les mêmes clés).
  factory RealStats.fromFighterJson(Map<String, dynamic> j) {
    final s = (j['stats_ufc'] as Map?)?.cast<String, dynamic>() ?? const {};
    final p = (j['palmares'] as Map?)?.cast<String, dynamic>() ?? const {};
    final u = (j['ufc'] as Map?)?.cast<String, dynamic>() ?? const {};
    double? d(Object? v) => v is num ? v.toDouble() : null;
    int? i(Object? v) => v is num ? v.toInt() : null;
    return RealStats(
      strikesLandedPerMin: d(s['frappes_par_min']),
      strikingAccuracyPct: d(s['precision_frappe_pct']),
      strikesAbsorbedPerMin: d(s['frappes_encaissees_par_min']),
      strikingDefensePct: d(s['defense_frappe_pct']),
      takedownsPer15: d(s['takedowns_par_15min']),
      takedownAccuracyPct: d(s['precision_takedown_pct']),
      takedownDefensePct: d(s['defense_takedown_pct']),
      submissionsPer15: d(s['soumissions_par_15min']),
      knockdownsPer15: d(s['knockdowns_par_15min']),
      avgFightTimeSeconds: i(s['duree_moyenne_combat_s']),
      wins: i(p['victoires']),
      losses: i(p['defaites']),
      draws: i(p['nuls']),
      winsKo: i(p['victoires_ko']),
      winsSubmission: i(p['victoires_soumission']),
      winsDecision: i(p['victoires_decision']),
      lossesKo: i(p['defaites_ko']),
      ufcFights: i(u['combats_ufc']),
      fiveRoundDecisionWins: i(u['victoires_decision_5_rounds']),
    );
  }
}
