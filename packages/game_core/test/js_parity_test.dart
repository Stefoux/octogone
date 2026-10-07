@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

/// Le serveur rejoue les combats avec game_core compilé en JavaScript : les
/// mêmes journaux doivent donner exactement les mêmes résultats qu'en Dart.
void main() {
  final node = Process.runSync('which', ['node']).stdout.toString().trim();

  test('Parité Dart / JavaScript du rejeu de combat', () async {
    final dir = await Directory.systemTemp.createTemp('octogone_js');
    addTearDown(() => dir.delete(recursive: true));
    final js = '${dir.path}/game_core.js';
    final compile = await Process.run('dart', ['compile', 'js', '-O2', '-o', js, 'bin/replay_js.dart']);
    expect(compile.exitCode, 0, reason: '${compile.stdout}${compile.stderr}');

    final fighters = [
      for (final f in Directory('../../data/fighters').listSync().whereType<File>())
        if (f.path.endsWith('.json') && !f.path.endsWith('aliases.json'))
          (jsonDecode(f.readAsStringSync()) as Map).cast<String, dynamic>(),
    ].where((f) => f['stats_jeu'] != null && f['categorie'] != null).toList()
      ..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));

    final inputs = <String>[];
    final expected = <String>[];
    for (var i = 0; i < 40; i++) {
      final rng = CombatRng(7000 + i);
      Map<String, dynamic> card(Map<String, dynamic> f, Rarity r, {int? bonus}) => {
            'id': f['id'],
            'nom': f['nom'],
            'categorie': f['categorie'],
            'sexe': f['sexe'],
            'stats_jeu': f['stats_jeu'],
            'rarete': r.key,
            'bonus_stats': ?bonus,
            'technique': ((f['ufc'] as Map?)?['technique_favorite'] as Map?)?['technique'],
          };
      final a = fighters[rng.nextInt(fighters.length)];
      final b = fighters[rng.nextInt(fighters.length)];
      final ra = Rarity.values[rng.nextInt(6)];
      final level = AiLevel.values[i % 3];
      final config = CombatConfig(
        seed: 1000000 + i * 7919,
        format: i.isEven ? CombatFormat.court : CombatFormat.complet,
        titleFight: i % 5 == 0,
        openWeight: a['categorie'] != b['categorie'],
      );
      final habits = HabitProfile.fromJson({
        'debout': {'frappe_puissante': 3.41, 'takedown': 1.2},
        'dessous': {'se_relever': 2.0},
      });
      final tactics = [
        TacticCard(TacticKind.values[i % 8], Rarity.values[i % 5], ownedId: 'o-$i'),
        TacticCard(TacticKind.values[(i + 3) % 8], Rarity.commune, ownedId: 'p-$i'),
      ];
      final pa = card(a, ra, bonus: ra.defaultStatBonus);
      final pb = card(b, ra);
      final d = CombatDriver(config, CombatFighter.fromJson(pa), CombatFighter.fromJson(pb),
          level: level, habits: level == AiLevel.difficile ? habits : null);
      var n = 0;
      while (!d.finished) {
        if (d.pending != null) {
          d.resolveSubmission(((n * 37) % 100) / 100);
          continue;
        }
        n++;
        if (n == 2 && d.engine.canUseTactic(0, tactics[0].kind)) d.useTactic(tactics[0]);
        if (n == 6 && d.engine.canUseTactic(0, tactics[1].kind)) d.useTactic(tactics[1]);
        final options = d.engine.available(0);
        d.play(options[(n * 5 + i) % options.length]);
      }
      final input = jsonEncode({
        'config': config.toJson(),
        'joueur': pa,
        'adversaire': pb,
        'niveau': level.name,
        'habitudes': level == AiLevel.difficile ? habits.toJson() : null,
        'tactiques': [for (final t in tactics) t.toJson()],
        'journal': d.engine.log,
      });
      final vm = replayCombatJson(input);
      expect(jsonDecode(vm)['ok'], isTrue, reason: 'Dart, combat $i');
      expect(jsonDecode(vm)['resultat'], d.result!.toJson());
      inputs.add(input);
      expected.add(vm);
    }

    File('${dir.path}/inputs.json').writeAsStringSync(jsonEncode(inputs));
    File('${dir.path}/run.cjs').writeAsStringSync('''
globalThis.self = globalThis;
require(${jsonEncode(js)});
const inputs = require(${jsonEncode('${dir.path}/inputs.json')});
process.stdout.write(JSON.stringify(inputs.map((i) => globalThis.octogoneReplay(i))));
''');
    final run = await Process.run(node, ['${dir.path}/run.cjs']);
    expect(run.exitCode, 0, reason: '${run.stderr}');
    final outputs = (jsonDecode(run.stdout as String) as List).cast<String>();
    expect(outputs, hasLength(expected.length));
    for (var i = 0; i < outputs.length; i++) {
      expect(jsonDecode(outputs[i]), jsonDecode(expected[i]), reason: 'combat $i');
    }
  }, skip: node.isEmpty ? 'node absent' : null, timeout: const Timeout(Duration(minutes: 3)));
}
