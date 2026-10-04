import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

void main() {
  // Même composition que data/boosters.json (Saison 2026 Standard). Les valeurs
  // attendues sont celles validées par la simulation de 100 000 boosters côté serveur.
  const standard = {
    'slots': [
      {'nb': 4, 'poids': {'commune': 100}},
      {'nb': 1, 'poids': {'peu_commune': 75, 'rare': 22, 'epique': 3}},
      {'nb': 1, 'poids': {'peu_commune': 50, 'rare': 33, 'epique': 12.5, 'legendaire': 4, 'mythique': 0.5}},
    ],
  };

  test('cartes par booster et probabilité d’au moins une', () {
    final o = PackOdds.fromComposition(standard);
    expect(o.cards, 6);
    expect(o.perPack[Rarity.commune], closeTo(4, 1e-9));
    expect(o.perPack[Rarity.peuCommune], closeTo(1.25, 1e-9));
    expect(o.atLeastOne[Rarity.rare], closeTo(0.4774, 1e-4));
    expect(o.atLeastOne[Rarity.epique], closeTo(0.1512, 1e-4));
    expect(o.atLeastOne[Rarity.legendaire], closeTo(0.04, 1e-9));
  });

  test('affichage « 1 sur N boosters »', () {
    final o = PackOdds.fromComposition(standard);
    expect(o.oneIn(Rarity.legendaire), 25);
    expect(o.oneIn(Rarity.mythique), 200);
    expect(o.oneIn(Rarity.epique), 7);
  });

  test('rareté absente : null', () {
    final o = PackOdds.fromComposition({
      'slots': [
        {'nb': 3, 'poids': {'commune': 1}},
      ],
    });
    expect(o.oneIn(Rarity.mythique), isNull);
    expect(o.atLeastOne[Rarity.commune], 1);
  });
}
