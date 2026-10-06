import 'dart:convert';

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

CombatFighter _f(String id, GameStats s, {Rarity rarity = Rarity.rare}) => CombatFighter(
      id: id,
      name: id,
      baseStats: s,
      weightClass: WeightClass.fromKey('legers'),
      rarity: rarity,
    );

final player = _f('joueur', _stats(fr: 80, pu: 75, so: 70));
final opponent = _f('ia', _stats(lu: 82, so: 72));
const myTactics = [
  TacticCard(TacticKind.secondSouffle, Rarity.commune, ownedId: 'o-1'),
  TacticCard(TacticKind.instinctDeTueur, Rarity.rare, ownedId: 'o-2'),
];

/// Joueur scripté : une carte Tactique au 2e échange, puis la carte la plus
/// offensive de sa main ; mini-jeux réussis à moitié.
CombatDriver _play(int seed, {AiLevel level = AiLevel.difficile}) {
  final d = CombatDriver(CombatConfig(seed: seed, format: CombatFormat.court), player, opponent, level: level);
  var n = 0;
  while (!d.finished) {
    if (d.pending != null) {
      d.resolveSubmission(0.55);
      continue;
    }
    n++;
    if (n == 2) d.useTactic(myTactics[1]);
    if (n == 5 && d.engine.canUseTactic(0, TacticKind.secondSouffle)) d.useTactic(myTactics[0]);
    final options = d.engine.available(0);
    d.play(options.firstWhere((a) => a.offensive, orElse: () => options.first));
  }
  return d;
}

void main() {
  test('Le serveur rejoue le journal et retrouve le même résultat', () {
    for (var seed = 1; seed <= 25; seed++) {
      final d = _play(seed);
      final log = jsonDecode(jsonEncode(d.engine.log)) as List; // aller-retour réseau
      final r = CombatDriver.replay(
        CombatConfig(seed: seed, format: CombatFormat.court),
        player,
        opponent,
        level: AiLevel.difficile,
        log: log.cast<Map<String, dynamic>>(),
        playerTactics: myTactics,
      );
      expect(r, isNotNull, reason: 'graine $seed');
      expect(r!.toJson(), d.result!.toJson());
    }
  });

  test('Journal modifié, incomplet ou carte non déclarée : refusé', () {
    final d = _play(7);
    final cfg = const CombatConfig(seed: 7, format: CombatFormat.court);
    List<Map<String, dynamic>> copy() =>
        (jsonDecode(jsonEncode(d.engine.log)) as List).cast<Map<String, dynamic>>();

    // L'IA aurait joué autre chose
    final forged = copy();
    final i = forged.indexWhere((s) => s['t'] == 'echange');
    final a = forged[i]['a'] as List;
    a[1] = a[1] == 'garde' ? 'frappe_rapide' : 'garde';
    expect(CombatDriver.replay(cfg, player, opponent, level: AiLevel.difficile, log: forged, playerTactics: myTactics),
        isNull);

    // Combat arrêté avant la fin
    final cut = copy()..removeLast();
    expect(CombatDriver.replay(cfg, player, opponent, level: AiLevel.difficile, log: cut, playerTactics: myTactics),
        isNull);

    // Carte Tactique jouée mais pas déclarée (ou d'une autre rareté)
    expect(CombatDriver.replay(cfg, player, opponent, level: AiLevel.difficile, log: copy(), playerTactics: const []),
        isNull);
    expect(
        CombatDriver.replay(cfg, player, opponent,
            level: AiLevel.difficile,
            log: copy(),
            playerTactics: const [
              TacticCard(TacticKind.secondSouffle, Rarity.commune, ownedId: 'o-1'),
              TacticCard(TacticKind.instinctDeTueur, Rarity.legendaire, ownedId: 'o-2'),
            ]),
        isNull);

    // Autre niveau d'IA : autres choix
    expect(CombatDriver.replay(cfg, player, opponent, level: AiLevel.facile, log: copy(), playerTactics: myTactics),
        isNull);
  });

  test('Cartes Tactique de l’IA selon son niveau', () {
    expect(CombatDriver.aiTactics(AiLevel.facile, 3), isEmpty);
    final normal = CombatDriver.aiTactics(AiLevel.normal, 3);
    expect(normal.map((t) => t.rarity).toSet(), {Rarity.commune});
    final hard = CombatDriver.aiTactics(AiLevel.difficile, 3);
    expect(hard, hasLength(2));
    expect(hard[0].kind, isNot(hard[1].kind));
    expect(hard.map((t) => t.rarity).toSet(), {Rarity.rare});
  });

  test('Les événements sont transmis une fois, l’IA joue en début d’échange', () {
    final d = CombatDriver(const CombatConfig(seed: 11), player, opponent, level: AiLevel.normal);
    d.takeEvents();
    d.play(CombatAction.garde);
    final ev = d.takeEvents();
    expect(ev, isNotEmpty);
    expect(d.takeEvents(), isEmpty);
    expect(d.lastAiAction, isNotNull);
  });
}
