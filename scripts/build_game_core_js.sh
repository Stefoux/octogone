#!/usr/bin/env bash
# Compile les règles de combat (packages/game_core) en JavaScript pour l'Edge
# Function valider-combat, qui rejoue les combats côté serveur.
set -euo pipefail
cd "$(dirname "$0")/../packages/game_core"
dart compile js -O2 --no-source-maps -o ../../supabase/functions/valider-combat/game_core.js bin/replay_js.dart
rm -f ../../supabase/functions/valider-combat/game_core.js.deps
echo "supabase/functions/valider-combat/game_core.js"
