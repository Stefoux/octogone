import 'dart:math' as math;

import 'rarity.dart';

/// Probabilités d'un booster, calculées à partir de sa composition
/// (`booster_types.composition`, la même que celle utilisée par le serveur).
///
/// Composition : `{"slots": [{"nb": 4, "poids": {"commune": 100}}, …], "garantie": "rare"}`.
/// Chaque emplacement tire une rareté selon des poids relatifs.
class PackOdds {
  PackOdds._(this.perPack, this.atLeastOne, this.cards);

  /// Nombre moyen de cartes de chaque rareté par booster.
  final Map<Rarity, double> perPack;

  /// Probabilité d'avoir au moins une carte de cette rareté dans un booster.
  final Map<Rarity, double> atLeastOne;

  /// Nombre de cartes du booster.
  final int cards;

  factory PackOdds.fromComposition(Map<String, dynamic> composition) {
    final perPack = {for (final r in Rarity.values) r: 0.0};
    final none = {for (final r in Rarity.values) r: 1.0};
    var cards = 0;
    for (final raw in (composition['slots'] as List? ?? const [])) {
      final slot = (raw as Map).cast<String, dynamic>();
      final nb = (slot['nb'] as num?)?.toInt() ?? 1;
      cards += nb;
      final weights = (slot['poids'] as Map? ?? const {}).cast<String, dynamic>();
      final total = weights.values.fold<double>(0, (a, b) => a + (b as num).toDouble());
      if (total <= 0) continue;
      for (final r in Rarity.values) {
        final p = ((weights[r.key] as num?)?.toDouble() ?? 0) / total;
        perPack[r] = perPack[r]! + nb * p;
        none[r] = none[r]! * math.pow(1 - p, nb);
      }
    }
    return PackOdds._(
      perPack,
      {for (final r in Rarity.values) r: 1 - none[r]!},
      cards,
    );
  }

  /// « 1 sur N boosters » (arrondi) pour une rareté, ou null si impossible.
  int? oneIn(Rarity r) {
    final p = atLeastOne[r] ?? 0;
    if (p <= 0) return null;
    return (1 / p).round();
  }
}
