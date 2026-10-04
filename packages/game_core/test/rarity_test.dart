import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> fighter({
    bool champion = false,
    bool former = false,
    String statut = 'actif',
    int ufcWins = 0,
    int fotn = 0,
    int ko = 0,
    int sub = 0,
  }) =>
      {
        'champion_actuel': champion,
        'ancien_champion': former,
        'statut': statut,
        'palmares': {'victoires_ko': ko, 'victoires_soumission': sub},
        'ufc': {'victoires_ufc': ufcWins, 'bonus_fotn': fotn},
      };

  test('clés de rareté et bonus', () {
    expect(Rarity.fromKey('peu_commune'), Rarity.peuCommune);
    expect(Rarity.peuCommune.key, 'peu_commune');
    expect(Rarity.fromKey('inconnu'), Rarity.commune);
    expect(Rarity.rare.unlocksSignature, isFalse);
    expect(Rarity.epique.unlocksSignature, isTrue);
    expect(Rarity.values.map((r) => r.defaultStatBonus), [0, 1, 2, 3, 5, 6]);
  });

  test('règle vide : toute carte simple', () {
    expect(Eligibility.isEligible({}, fighter()), isTrue);
    expect(Eligibility.isEligible(null, fighter()), isTrue);
    expect(Eligibility.isEligible({}, fighter(), cardType: 'duel'), isFalse);
  });

  test('Ceinture d’Or : champions actuels ou anciens', () {
    const rule = {'champion': true};
    expect(Eligibility.isEligible(rule, fighter()), isFalse);
    expect(Eligibility.isEligible(rule, fighter(champion: true)), isTrue);
    expect(Eligibility.isEligible(rule, fighter(former: true)), isTrue);
  });

  test('Héritage : légendes retraitées', () {
    const rule = {'legende_retraitee': true};
    expect(Eligibility.isEligible(rule, fighter(statut: 'retraite', former: true)), isTrue);
    expect(Eligibility.isEligible(rule, fighter(statut: 'retraite', ufcWins: 12)), isTrue);
    expect(Eligibility.isEligible(rule, fighter(statut: 'retraite', ufcWins: 3)), isFalse);
    expect(Eligibility.isEligible(rule, fighter(former: true)), isFalse);
  });

  test('seuils : guerres, KO, soumissions', () {
    expect(Eligibility.isEligible({'fotn_min': 1}, fighter(fotn: 1)), isTrue);
    expect(Eligibility.isEligible({'fotn_min': 1}, fighter()), isFalse);
    expect(Eligibility.isEligible({'ko_min': 5}, fighter(ko: 4)), isFalse);
    expect(Eligibility.isEligible({'ko_min': 5}, fighter(ko: 5)), isTrue);
    expect(Eligibility.isEligible({'sub_min': 5}, fighter(sub: 7)), isTrue);
  });

  test('Trilogie : carte duel avec 3 combats ou plus', () {
    const rule = {'carte': 'duel', 'combats_min': 3};
    expect(Eligibility.isEligible(rule, fighter(), cardType: 'duel', fightsBetween: 3), isTrue);
    expect(Eligibility.isEligible(rule, fighter(), cardType: 'duel', fightsBetween: 2), isFalse);
    expect(Eligibility.isEligible(rule, fighter(), fightsBetween: 3), isFalse);
  });
}
