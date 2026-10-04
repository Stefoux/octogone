#!/usr/bin/env bash
# =============================================================================
# Installation / mise à jour du projet Supabase cloud d'Octogone.
#
# Prérequis : un projet créé sur supabase.com et un fichier .env à la racine
# (copie de .env.example) avec SUPABASE_PROJECT_REF, SUPABASE_DB_PASSWORD et
# SUPABASE_ACCESS_TOKEN. Optionnel : ADMIN_EMAIL_1 et ADMIN_EMAIL_2.
#
# Le script :
#   1. lie le dossier au projet et applique les migrations SQL (tables, RLS) ;
#   2. récupère les clés d'API et les écrit dans .env (sans les afficher) ;
#   3. désactive la confirmation par email (inscription immédiate entre amis) ;
#   4. enregistre les emails admin (sans les écrire dans un fichier versionné) ;
#   5. déploie les Edge Functions (s'il y en a) ;
#   6. génère app/config/app.json pour la compilation de l'app ;
#   7. importe les données (combattants, éditions, images) si --donnees.
#
# Relançable sans risque : tout est idempotent.
# Usage : scripts/supabase_setup.sh [--donnees]
# =============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env"
cd "$ROOT"

die() { echo "❌ $*" >&2; exit 1; }
step() { echo; echo "▶ $*"; }

[ -f "$ENV_FILE" ] || die ".env introuvable : copie .env.example en .env et remplis-le."
set -a; # shellcheck disable=SC1090
source "$ENV_FILE"; set +a
: "${SUPABASE_PROJECT_REF:?SUPABASE_PROJECT_REF manquant dans .env}"
: "${SUPABASE_DB_PASSWORD:?SUPABASE_DB_PASSWORD manquant dans .env}"
: "${SUPABASE_ACCESS_TOKEN:?SUPABASE_ACCESS_TOKEN manquant dans .env}"
export SUPABASE_ACCESS_TOKEN
command -v supabase >/dev/null || die "CLI Supabase absente (brew install supabase/tap/supabase)"

API="https://api.supabase.com/v1/projects/$SUPABASE_PROJECT_REF"
auth_header=(-H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" -H "Content-Type: application/json")

# Écrit KEY=VALUE dans .env (remplace la ligne si elle existe), sans rien afficher.
set_env() {
  python3 - "$ENV_FILE" "$1" "$2" <<'PY'
import sys, re, pathlib
path, key, value = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3]
lines = path.read_text().splitlines()
out, done = [], False
for l in lines:
    if re.match(rf"^{re.escape(key)}=", l):
        out.append(f"{key}={value}"); done = True
    else:
        out.append(l)
if not done:
    out.append(f"{key}={value}")
path.write_text("\n".join(out) + "\n")
PY
}

step "Liaison au projet $SUPABASE_PROJECT_REF"
supabase link --project-ref "$SUPABASE_PROJECT_REF" -p "$SUPABASE_DB_PASSWORD" >/dev/null

step "Application des migrations (tables, policies RLS, bucket d'images)"
supabase db push -p "$SUPABASE_DB_PASSWORD" --include-all --yes

step "Récupération des clés d'API (écrites dans .env, non affichées)"
KEYS_JSON="$(supabase projects api-keys --project-ref "$SUPABASE_PROJECT_REF" --reveal -o json)"
read -r PUB SECRET < <(python3 -c '
import json, sys
keys = json.loads(sys.stdin.read())
def pick(*names):
    for k in keys:
        if k.get("type") in names or k.get("name") in names:
            return k.get("api_key") or ""
    return ""
pub = pick("publishable") or pick("anon")
sec = pick("secret") or pick("service_role")
print(pub, sec)
' <<<"$KEYS_JSON")
[ -n "$PUB" ] && [ -n "$SECRET" ] || die "Impossible de lire les clés d'API du projet."
set_env SUPABASE_URL "https://$SUPABASE_PROJECT_REF.supabase.co"
set_env SUPABASE_PUBLISHABLE_KEY "$PUB"
set_env SUPABASE_SECRET_KEY "$SECRET"
echo "   clés enregistrées dans .env"

step "Inscription sans confirmation par email"
curl -sf -X PATCH "$API/config/auth" "${auth_header[@]}" \
  -d '{"mailer_autoconfirm": true, "external_email_enabled": true, "password_min_length": 8}' >/dev/null \
  && echo "   confirmation par email désactivée" \
  || echo "   ⚠ échec : désactive « Confirm email » à la main (Authentication > Sign In / Providers > Email)"

if [ -n "${ADMIN_EMAIL_1:-}" ] || [ -n "${ADMIN_EMAIL_2:-}" ]; then
  step "Emails admin"
  SQL="$(python3 -c '
import json, os
emails = [e.strip().lower() for e in (os.environ.get("ADMIN_EMAIL_1",""), os.environ.get("ADMIN_EMAIL_2","")) if e.strip()]
values = ",".join("(\x27" + e.replace("\x27", "\x27\x27") + "\x27)" for e in emails)
print(json.dumps({"query": f"insert into public.admin_emails(email) values {values} on conflict do nothing; select public.sync_admin_roles();"}))
')"
  curl -sf -X POST "$API/database/query" "${auth_header[@]}" -d "$SQL" >/dev/null \
    && echo "   admins enregistrés (rôle appliqué aux comptes existants et futurs)" \
    || echo "   ⚠ échec de l'enregistrement des admins"
fi

if [ -d supabase/functions ] && [ -n "$(ls -A supabase/functions 2>/dev/null)" ]; then
  step "Déploiement des Edge Functions"
  supabase functions deploy --project-ref "$SUPABASE_PROJECT_REF"
fi

step "Configuration de l'app (app/config/app.json)"
python3 - "$ROOT/app/config/app.json" <<PY
import json, sys
json.dump({"SUPABASE_URL": "https://$SUPABASE_PROJECT_REF.supabase.co",
           "SUPABASE_PUBLISHABLE_KEY": "$PUB"}, open(sys.argv[1], "w"), indent=2)
PY
echo "   compile avec : flutter build apk --release --dart-define-from-file=config/app.json"

if [ "${1:-}" = "--donnees" ]; then
  step "Import des données (combattants, éditions, images)"
  "$ROOT/data/scripts/.venv/bin/python" "$ROOT/data/scripts/import_to_supabase.py"
fi

echo; echo "✅ Projet Supabase prêt."
