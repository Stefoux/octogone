// Point d'entrée JavaScript de game_core : compilé avec `dart compile js`,
// il expose les règles du jeu aux Edge Functions Supabase (Deno) via
// globalThis.octogone. Une seule implémentation des règles, côté app et serveur.
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:game_core/game_core.dart';

String _computeStats(String fighterJson) {
  final json = jsonDecode(fighterJson) as Map<String, dynamic>;
  return jsonEncode(StatFormula.compute(RealStats.fromFighterJson(json)).toJson());
}

void main() {
  final api = JSObject();
  api['version'] = StatFormula.version.toJS;
  api['computeStats'] = ((JSString s) => _computeStats(s.toDart).toJS).toJS;
  globalContext['octogone'] = api;
}
