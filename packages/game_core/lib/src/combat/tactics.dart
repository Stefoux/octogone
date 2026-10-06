/// Cartes Tactique : bonus à usage unique par combat (2 au plus par combat).
/// Créations originales. L'effet se renforce avec la rareté de la carte.
library;

import '../cards/rarity.dart';

enum TacticKind {
  /// Regain d'endurance.
  secondSouffle('second_souffle'),

  /// Soins (coupures, souffle) : santé récupérée.
  coinDuCoach('coin_du_coach'),

  /// Le public pousse : momentum gagné.
  fouleEnDelire('foule_en_delire'),

  /// Encaisse mieux : dégâts reçus réduits pendant 2 échanges.
  machoireDAcier('machoire_acier'),

  /// Dégâts infligés augmentés pendant 2 échanges.
  instinctDeTueur('instinct_tueur'),

  /// Sortie de crise : la prochaine tentative pour se relever ou se dégager
  /// réussit à coup sûr, et un peu d'endurance revient.
  sortieDeCrise('sortie_de_crise'),

  /// Plan de match : précision accrue pendant 2 échanges.
  planDeMatch('plan_de_match'),

  /// Pression totale : l'adversaire perd de l'endurance.
  pressionTotale('pression_totale');

  const TacticKind(this.key);
  final String key;

  static TacticKind? fromKey(String? key) {
    for (final t in values) {
      if (t.key == key) return t;
    }
    return null;
  }
}

/// Une carte Tactique jouée en combat : son type et sa rareté.
class TacticCard {
  const TacticCard(this.kind, this.rarity, {this.ownedId});

  final TacticKind kind;
  final Rarity rarity;

  /// Exemplaire possédé (vérifié par le serveur).
  final String? ownedId;

  /// Rang de rareté (0 commune … 5 mythique), plafonné à légendaire pour les effets.
  int get _tier => rarity.index.clamp(0, 4);

  /// Valeur de l'effet selon la rareté.
  num get amount => switch (kind) {
        TacticKind.secondSouffle => const [25, 32, 40, 50, 62][_tier],
        TacticKind.coinDuCoach => const [8, 11, 14, 18, 23][_tier],
        TacticKind.fouleEnDelire => const [25, 33, 42, 55, 70][_tier],
        TacticKind.machoireDAcier => const [0.25, 0.32, 0.40, 0.48, 0.58][_tier],
        TacticKind.instinctDeTueur => const [0.20, 0.27, 0.35, 0.44, 0.55][_tier],
        TacticKind.sortieDeCrise => const [5, 8, 12, 16, 20][_tier],
        TacticKind.planDeMatch => const [0.08, 0.11, 0.14, 0.18, 0.22][_tier],
        TacticKind.pressionTotale => const [10, 14, 18, 24, 30][_tier],
      };

  Map<String, dynamic> toJson() => {'type': kind.key, 'rarete': rarity.key, 'owned_id': ?ownedId};

  static TacticCard fromJson(Map<String, dynamic> j) => TacticCard(
        TacticKind.fromKey(j['type'] as String)!,
        Rarity.fromKey(j['rarete'] as String),
        ownedId: j['owned_id'] as String?,
      );
}
