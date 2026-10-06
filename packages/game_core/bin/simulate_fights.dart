// Simulation d'équilibrage : N combats IA contre IA entre vrais combattants
// (même catégorie, raretés tirées comme dans les boosters), puis rapport :
// répartition des fins, styles, effet de la rareté et de la note globale.
//
//   dart run bin/simulate_fights.dart ../../data/fighters 10000 [--json rapport.json]
import 'dart:convert';
import 'dart:io';

import 'package:game_core/game_core.dart';

void main(List<String> args) {
  final dir = Directory(args.isNotEmpty ? args[0] : '../../data/fighters');
  final n = args.length > 1 ? int.parse(args[1]) : 10000;
  final jsonOut = args.contains('--json') ? args[args.indexOf('--json') + 1] : null;

  final fighters = <Map<String, dynamic>>[];
  for (final f in dir.listSync().whereType<File>()) {
    if (!f.path.endsWith('.json') || f.path.endsWith('aliases.json')) continue;
    final j = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    if (j['stats_jeu'] == null || j['categorie'] == null) continue;
    fighters.add(j);
  }
  final byClass = <String, List<Map<String, dynamic>>>{};
  for (final f in fighters) {
    byClass.putIfAbsent(f['categorie'] as String, () => []).add(f);
  }
  final classes = byClass.keys.where((k) => byClass[k]!.length >= 2).toList()..sort();

  final rng = CombatRng(20261006);
  // Raretés tirées comme dans les boosters (proportions approximatives)
  const rarityWeights = [52.0, 22.0, 13.0, 8.0, 4.0, 1.0];

  final finishes = <String, int>{};
  final styleWins = <String, List<int>>{}; // 'frappeur>lutteur' -> [victoires du 1er, combats décidés]
  final rarityGap = <int, List<int>>{}; // écart de rareté -> [victoires du plus rare, combats]
  final overallGap = <int, List<int>>{}; // tranche d'écart de note -> [victoires du meilleur, combats]
  final rounds = <int, int>{};
  var exchanges = 0;

  for (var i = 0; i < n; i++) {
    final cls = classes[rng.nextInt(classes.length)];
    final pool = byClass[cls]!;
    final a = pool[rng.nextInt(pool.length)];
    var b = pool[rng.nextInt(pool.length)];
    while (identical(a, b)) {
      b = pool[rng.nextInt(pool.length)];
    }
    Map<String, dynamic> card(Map<String, dynamic> f) {
      final r = Rarity.values[rng.weighted(rarityWeights)];
      return {...f, 'rarete': r.key, 'technique': ((f['ufc'] as Map?)?['technique_favorite'] as Map?)?['technique']};
    }

    final ra = CombatFighter.fromJson(card(a));
    final rb = CombatFighter.fromJson(card(b));
    final config = CombatConfig(seed: 1000 + i, format: i.isEven ? CombatFormat.complet : CombatFormat.court);
    final r = simulateFight(config, ra, rb);
    finishes[r.method.name] = (finishes[r.method.name] ?? 0) + 1;
    if (r.isFinish) rounds[r.round] = (rounds[r.round] ?? 0) + 1;
    exchanges += (r.round - 1) * config.exchangesPerRound + r.exchange;
    if (r.winner == null) continue;

    // Styles (à niveau égal : écart de note globale de 3 points au plus)
    final sa = ra.style.name, sb = rb.style.name;
    if (sa != sb && (ra.stats.overall - rb.stats.overall).abs() <= 3) {
      final key = ([sa, sb]..sort()).join(' vs ');
      final first = key.split(' vs ').first;
      final w = styleWins.putIfAbsent(key, () => [0, 0]);
      w[1]++;
      final winnerStyle = r.winner == 0 ? sa : sb;
      if (winnerStyle == first) w[0]++;
    }
    // Rareté
    final gap = ra.rarity.index - rb.rarity.index;
    if (gap != 0) {
      final g = rarityGap.putIfAbsent(gap.abs(), () => [0, 0]);
      g[1]++;
      if ((gap > 0 && r.winner == 0) || (gap < 0 && r.winner == 1)) g[0]++;
    }
    // Note globale (avec bonus de rareté)
    final od = ra.stats.overall - rb.stats.overall;
    if (od != 0) {
      final bucket = (od.abs() ~/ 5) * 5;
      final g = overallGap.putIfAbsent(bucket > 20 ? 20 : bucket, () => [0, 0]);
      g[1]++;
      if ((od > 0 && r.winner == 0) || (od < 0 && r.winner == 1)) g[0]++;
    }
  }

  // Rareté seule : le même combattant contre lui-même, raretés différentes
  final pure = <int, List<int>>{};
  for (var i = 0; i < n ~/ 2; i++) {
    final cls = classes[rng.nextInt(classes.length)];
    final f = byClass[cls]![rng.nextInt(byClass[cls]!.length)];
    final lo = rng.nextInt(5);
    final hi = lo + 1 + rng.nextInt(5 - lo);
    Map<String, dynamic> withR(int r) => {
      ...f,
      'rarete': Rarity.values[r].key,
      'technique': ((f['ufc'] as Map?)?['technique_favorite'] as Map?)?['technique'],
    };
    final r = simulateFight(
      CombatConfig(seed: 500000 + i, format: i.isEven ? CombatFormat.complet : CombatFormat.court),
      CombatFighter.fromJson(withR(hi)),
      CombatFighter.fromJson(withR(lo)),
    );
    if (r.winner == null) continue;
    final g = pure.putIfAbsent(hi - lo, () => [0, 0]);
    g[1]++;
    if (r.winner == 0) g[0]++;
  }

  // Niveaux d'IA : combattants tirés au hasard, chaque niveau joue les deux coins
  // (et à combattant égal : le même contre lui-même)
  final levels = <String, List<int>>{};
  final levelsEqual = <String, List<int>>{};
  for (final pair in [
    [AiLevel.normal, AiLevel.facile],
    [AiLevel.difficile, AiLevel.normal],
    [AiLevel.difficile, AiLevel.facile],
  ]) {
    final key = '${pair[0].name} contre ${pair[1].name}';
    final g = levels.putIfAbsent(key, () => [0, 0]);
    final ge = levelsEqual.putIfAbsent(key, () => [0, 0]);
    for (var i = 0; i < n ~/ 8; i++) {
      final cls = classes[rng.nextInt(classes.length)];
      final pool = byClass[cls]!;
      final fa = CombatFighter.fromJson({...pool[rng.nextInt(pool.length)], 'rarete': 'commune'});
      final fb = CombatFighter.fromJson({...pool[rng.nextInt(pool.length)], 'rarete': 'commune'});
      final swap = i.isOdd;
      for (final (g, opp) in [(g, fb), (ge, fa)]) {
        final r = simulateFight(
          CombatConfig(seed: 900000 + i),
          swap ? opp : fa,
          swap ? fa : opp,
          redLevel: swap ? pair[1] : pair[0],
          blueLevel: swap ? pair[0] : pair[1],
        );
        if (r.winner == null) continue;
        g[1]++;
        if (r.winner == (swap ? 1 : 0)) g[0]++;
      }
    }
  }

  String pct(int a, int b) => b == 0 ? '-' : '${(100 * a / b).toStringAsFixed(1)} %';
  final total = finishes.values.fold<int>(0, (a, b) => a + b);
  final ko = (finishes['ko'] ?? 0) + (finishes['tko'] ?? 0);
  final sub = finishes['soumission'] ?? 0;
  final dec =
      (finishes['decisionUnanime'] ?? 0) + (finishes['decisionPartagee'] ?? 0) + (finishes['decisionMajoritaire'] ?? 0);
  final draw = finishes['nul'] ?? 0;
  stdout.writeln('$n combats simulés (${fighters.length} combattants, ${classes.length} catégories)');
  stdout.writeln(
    'Fins : KO/TKO ${pct(ko, total)} · soumission ${pct(sub, total)} · décision ${pct(dec, total)} · nul ${pct(draw, total)}',
  );
  stdout.writeln('Durée moyenne : ${(exchanges / n).toStringAsFixed(1)} échanges ; finish par round : $rounds');
  stdout.writeln('Styles (victoires du premier) :');
  for (final e in (styleWins.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))) {
    stdout.writeln('  ${e.key} : ${pct(e.value[0], e.value[1])} (${e.value[1]} combats)');
  }
  stdout.writeln('Rareté (victoires du plus rare, selon l’écart de rang) :');
  for (final k in (rarityGap.keys.toList()..sort())) {
    stdout.writeln('  +$k : ${pct(rarityGap[k]![0], rarityGap[k]![1])} (${rarityGap[k]![1]} combats)');
  }
  stdout.writeln('Rareté seule (même combattant, victoires de la carte la plus rare) :');
  for (final k in (pure.keys.toList()..sort())) {
    stdout.writeln('  +$k : ${pct(pure[k]![0], pure[k]![1])} (${pure[k]![1]} combats)');
  }
  stdout.writeln('Note globale (victoires du mieux noté, selon l’écart) :');
  for (final k in (overallGap.keys.toList()..sort())) {
    stdout.writeln(
      '  ${k == 20 ? '20+' : '$k-${k + 4}'} pts : ${pct(overallGap[k]![0], overallGap[k]![1])} (${overallGap[k]![1]} combats)',
    );
  }
  stdout.writeln('Niveaux d’IA (victoires du premier) :');
  for (final e in levels.entries) {
    stdout.writeln('  ${e.key} : ${pct(e.value[0], e.value[1])} (${e.value[1]} combats)');
  }
  stdout.writeln('Niveaux d’IA à combattant égal (le même des deux côtés) :');
  for (final e in levelsEqual.entries) {
    stdout.writeln('  ${e.key} : ${pct(e.value[0], e.value[1])} (${e.value[1]} combats)');
  }
  if (jsonOut != null) {
    File(jsonOut).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'combats': n,
        'fins': finishes,
        'styles': {for (final e in styleWins.entries) e.key: e.value},
        'rarete': {for (final e in rarityGap.entries) '${e.key}': e.value},
        'note': {for (final e in overallGap.entries) '${e.key}': e.value},
        'echanges_moyens': exchanges / n,
        'niveaux_ia': levels,
        'niveaux_ia_egaux': levelsEqual,
        'rarete_seule': {for (final e in pure.entries) '${e.key}': e.value},
      }),
    );
  }
}
