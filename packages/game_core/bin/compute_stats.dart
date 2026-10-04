// Calcule les stats de jeu de chaque combattant de data/fighters/*.json et les
// écrit dans le champ « stats_jeu » (avec la version de la formule).
//
//   dart run game_core:compute_stats            (depuis packages/game_core)
//   dart run bin/compute_stats.dart ../../data/fighters
import 'dart:convert';
import 'dart:io';

import 'package:game_core/game_core.dart';

void main(List<String> args) {
  final dir = Directory(args.isNotEmpty ? args.first : '../../data/fighters');
  if (!dir.existsSync()) {
    stderr.writeln('Dossier introuvable : ${dir.path}');
    exit(1);
  }
  final encoder = const JsonEncoder.withIndent('  ');
  var count = 0;
  final styles = <FighterStyle, int>{};
  for (final f in dir.listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last;
    if (!name.endsWith('.json') || name.startsWith('_') || name == 'aliases.json') {
      continue;
    }
    final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    final stats = StatFormula.compute(RealStats.fromFighterJson(json));
    json['stats_jeu'] = stats.toJson();
    f.writeAsStringSync('${encoder.convert(json)}\n');
    styles.update(stats.style, (v) => v + 1, ifAbsent: () => 1);
    count++;
  }
  stdout.writeln('$count combattants mis à jour (formule v${StatFormula.version}).');
  stdout.writeln('Styles : ${styles.entries.map((e) => '${e.key.label} ${e.value}').join(', ')}');
}
