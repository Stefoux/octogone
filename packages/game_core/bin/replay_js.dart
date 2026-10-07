// Point d'entrée JavaScript : `dart compile js -O2 -o <sortie>.js bin/replay_js.dart`
// définit globalThis.octogoneReplay(json) -> json (voir lib/src/combat/replay_api.dart),
// utilisé par l'Edge Function supabase/functions/valider-combat.
import 'dart:js_interop';

import 'package:game_core/game_core.dart';

@JS('octogoneReplay')
external set octogoneReplay(JSFunction f);

void main() {
  octogoneReplay = ((JSString input) => replayCombatJson(input.toDart).toJS).toJS;
}
