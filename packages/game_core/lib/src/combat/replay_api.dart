/// Rejeu d'un combat à partir de données JSON : point d'entrée de la
/// vérification serveur (game_core compilé en JavaScript, Edge Function
/// valider-combat).
library;

import 'dart:convert';

import 'ai.dart';
import 'driver.dart';
import 'engine.dart';
import 'fighter.dart';
import 'tactics.dart';

/// Entrée : {config, joueur, adversaire, niveau, habitudes?, tactiques, journal}
/// (combattants au format de [CombatFighter.fromJson]). Sortie :
/// {ok: true, resultat} si le journal correspond au combat recalculé, sinon
/// {ok: false}.
String replayCombatJson(String input) {
  try {
    final j = (jsonDecode(input) as Map).cast<String, dynamic>();
    Map<String, dynamic> m(Object? v) => (v as Map).cast<String, dynamic>();
    final result = CombatDriver.replay(
      CombatConfig.fromJson(m(j['config'])),
      CombatFighter.fromJson(m(j['joueur'])),
      CombatFighter.fromJson(m(j['adversaire'])),
      level: AiLevel.fromName(j['niveau'] as String?),
      habits: j['habitudes'] == null ? null : HabitProfile.fromJson(m(j['habitudes'])),
      playerTactics: [for (final t in (j['tactiques'] as List? ?? const [])) TacticCard.fromJson(m(t))],
      log: [for (final s in j['journal'] as List) m(s)],
    );
    return jsonEncode(result == null ? {'ok': false} : {'ok': true, 'resultat': result.toJson()});
  } on Object catch (e) {
    return jsonEncode({'ok': false, 'erreur': '$e'});
  }
}
