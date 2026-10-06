import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

GameStats _stats({int fr = 60, int pu = 60, int lu = 60, int so = 60, int de = 60, int ca = 60, int me = 60}) =>
    GameStats({
      StatKind.frappe: fr,
      StatKind.puissance: pu,
      StatKind.lutte: lu,
      StatKind.soumission: so,
      StatKind.defense: de,
      StatKind.cardio: ca,
      StatKind.menton: me,
    });

CombatFighter _f(String id, GameStats s,
        {Rarity rarity = Rarity.commune, String cat = 'legers', String? technique}) =>
    CombatFighter(
      id: id,
      name: id,
      baseStats: s,
      weightClass: WeightClass.fromKey(cat),
      rarity: rarity,
      signatureTechnique: technique,
    );

final striker = _f('frappeur', _stats(fr: 85, pu: 85, lu: 40, so: 35));
final wrestler = _f('lutteur', _stats(fr: 45, pu: 45, lu: 88, so: 55));

void main() {
  test('Graine fixe : même suite de nombres', () {
    final a = CombatRng(42), b = CombatRng(42);
    expect([for (var i = 0; i < 5; i++) a.nextUint32()], [for (var i = 0; i < 5; i++) b.nextUint32()]);
    final r = CombatRng(7);
    for (var i = 0; i < 1000; i++) {
      final d = r.nextDouble();
      expect(d, inInclusiveRange(0, 1));
      expect(d, lessThan(1));
    }
  });

  test('Main de cartes selon le profil : plus de coups pour un frappeur, plus de takedowns pour un lutteur', () {
    int count(CombatFighter f, CombatAction a) {
      final rng = CombatRng(1);
      var n = 0;
      for (var i = 0; i < 4000; i++) {
        if (f.drawCard(Stance.debout, rng) == a) n++;
      }
      return n;
    }

    expect(count(striker, CombatAction.frappePuissante), greaterThan(count(wrestler, CombatAction.frappePuissante)));
    expect(count(wrestler, CombatAction.takedown), greaterThan(count(striker, CombatAction.takedown) * 2));
    final durable = _f('menton', _stats(me: 95, de: 90));
    final fragile = _f('fragile', _stats(me: 35, de: 35));
    expect(count(durable, CombatAction.esquive), greaterThan(count(fragile, CombatAction.esquive)));
  });

  test('Main de 4 cartes, Garde toujours jouable, signature quand le momentum est plein (dès Épique)', () {
    final epic = _f('epique', _stats(), rarity: Rarity.epique, technique: 'punches');
    final e = CombatEngine(const CombatConfig(seed: 3), epic, striker);
    expect(e.hand(0), hasLength(4));
    expect(e.available(0), contains(CombatAction.garde));
    expect(e.available(0), isNot(contains(CombatAction.signature)));
    e.sides[0].momentum = 100;
    expect(e.available(0), contains(CombatAction.signature));
    e.sides[1].momentum = 100; // commune : pas de signature
    expect(e.available(1), isNot(contains(CombatAction.signature)));
    expect(() => e.play(CombatAction.soumission, CombatAction.garde), throwsArgumentError);
  });

  test('Matrice : le Takedown passe sous la Frappe puissante, la Frappe rapide le sanctionne', () {
    final e = CombatEngine(const CombatConfig(seed: 1), wrestler, striker);
    final vsPower = e.successChance(0, CombatAction.takedown, CombatAction.frappePuissante);
    final vsQuick = e.successChance(0, CombatAction.takedown, CombatAction.frappeRapide);
    expect(vsPower, greaterThan(vsQuick + 0.3));
    final powerVsGuard = e.successChance(1, CombatAction.frappePuissante, CombatAction.garde);
    final powerVsQuick = e.successChance(1, CombatAction.frappePuissante, CombatAction.frappeRapide);
    expect(powerVsGuard, lessThan(powerVsQuick));
  });

  test('Rejouer la même graine avec les mêmes choix redonne exactement le même combat', () {
    CombatResult run() => simulateFight(const CombatConfig(seed: 99, format: CombatFormat.court), striker, wrestler);
    final a = run(), b = run();
    expect(a.toJson(), b.toJson());
    final c = simulateFight(const CombatConfig(seed: 100, format: CombatFormat.court), striker, wrestler);
    expect(c.toJson(), isNot(a.toJson()), reason: 'une autre graine donne un autre combat');
  });

  test('Rejeu du journal : même résultat', () {
    final cfg = const CombatConfig(seed: 1234);
    final e = CombatEngine(cfg, striker, wrestler);
    final ais = [CombatAi(AiLevel.normal, 0, seed: 1), CombatAi(AiLevel.normal, 1, seed: 2)];
    while (!e.finished) {
      e.play(ais[0].choose(e), ais[1].choose(e));
      if (e.pending != null) e.resolveSubmission(attackerSkill: 0.6, defenderSkill: 0.4);
    }
    final replay = CombatEngine(cfg, striker, wrestler);
    for (final step in e.log) {
      switch (step['t']) {
        case 'echange':
          final a = step['a'] as List;
          replay.play(CombatAction.fromKey(a[0] as String), CombatAction.fromKey(a[1] as String));
        case 'soumission':
          replay.resolveSubmission(
              attackerSkill: (step['a'] as int) / 1000, defenderSkill: (step['d'] as int) / 1000);
      }
    }
    expect(replay.result!.toJson(), e.result!.toJson());
  });

  test('Tout combat se termine ; sans finish, décision des 3 juges en 10-9', () {
    for (var seed = 1; seed <= 60; seed++) {
      final r = simulateFight(CombatConfig(seed: seed), striker, wrestler);
      expect(r.winner == null || r.winner == 0 || r.winner == 1, isTrue);
      if (!r.isFinish) {
        expect(r.scorecards, hasLength(3));
        for (final card in r.scorecards) {
          expect(card, hasLength(3));
          for (final round in card) {
            expect('${round.$1}-${round.$2}', isIn(['10-9', '9-10', '10-10', '10-8', '8-10']));
          }
        }
      }
    }
  });

  test('Cartes Tactique : effets, 2 par combat au plus, une seule fois chacune', () {
    final e = CombatEngine(const CombatConfig(seed: 5), striker, wrestler);
    e.sides[0].stamina = 30;
    e.useTactic(0, const TacticCard(TacticKind.secondSouffle, Rarity.rare));
    expect(e.sides[0].stamina, 70);
    expect(e.canUseTactic(0, TacticKind.secondSouffle), isFalse);
    e.useTactic(0, const TacticCard(TacticKind.pressionTotale, Rarity.commune));
    expect(e.sides[1].stamina, 90);
    expect(e.canUseTactic(0, TacticKind.coinDuCoach), isFalse, reason: '2 cartes au plus');
    expect(const TacticCard(TacticKind.coinDuCoach, Rarity.legendaire).amount,
        greaterThan(const TacticCard(TacticKind.coinDuCoach, Rarity.commune).amount));
  });

  test('Soumission : en attente du mini-jeu, puis finie ou échappée', () {
    var sawPending = false;
    for (var seed = 1; seed < 400 && !sawPending; seed++) {
      final grappler = _f('grappler', _stats(lu: 75, so: 95));
      final e = CombatEngine(CombatConfig(seed: seed), grappler, striker);
      e.position = Position.sol;
      e.top = 0;
      final hand = e.available(0);
      if (!hand.contains(CombatAction.soumission)) continue;
      e.play(CombatAction.soumission, CombatAction.seRelever);
      if (e.pending != null) {
        sawPending = true;
        expect(() => e.play(CombatAction.garde, CombatAction.garde), throwsStateError);
        e.resolveSubmission(attackerSkill: 1, defenderSkill: 0);
        expect(e.pending, isNull);
      }
    }
    expect(sawPending, isTrue);
  });

  test('IA : le niveau difficile bat le niveau facile la plupart du temps', () {
    final equal = _f('a', _stats()), equal2 = _f('b', _stats());
    var hard = 0, n = 0;
    for (var seed = 1; seed <= 200; seed++) {
      final r = simulateFight(CombatConfig(seed: seed, format: CombatFormat.court), equal, equal2,
          redLevel: AiLevel.difficile, blueLevel: AiLevel.facile);
      if (r.winner == 0) hard++;
      if (r.winner != null) n++;
    }
    expect(hard / n, greaterThan(0.55));
  });

  test('Poids libre : le plus lourd a l’avantage, mais seulement en poids libre', () {
    final light = _f('leger', _stats(), cat: 'mouche');
    final heavy = _f('lourd', _stats(), cat: 'lourds');
    final same = CombatEngine(const CombatConfig(seed: 1), heavy, light);
    final open = CombatEngine(const CombatConfig(seed: 1, openWeight: true), heavy, light);
    expect(open.damageEstimate(0, CombatAction.frappePuissante, CombatAction.frappeRapide),
        greaterThan(same.damageEstimate(0, CombatAction.frappePuissante, CombatAction.frappeRapide)));
  });
}
