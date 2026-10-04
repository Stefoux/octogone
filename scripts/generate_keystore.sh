#!/usr/bin/env bash
# =============================================================================
# Génère la clé de signature Android de l'app (une seule fois).
#
# Crée app/android/octogone-release.jks et app/android/key.properties (mots de
# passe aléatoires). Les deux fichiers sont exclus de git.
#
# ⚠ Sauvegarde ces deux fichiers (clé USB, gestionnaire de mots de passe…) :
# sans eux, une nouvelle version de l'APK ne pourra plus s'installer par-dessus
# l'ancienne (il faudra désinstaller l'app d'abord).
# =============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ANDROID_DIR="$ROOT/app/android"
KEYSTORE="$ANDROID_DIR/octogone-release.jks"
PROPS="$ANDROID_DIR/key.properties"

if [ -f "$KEYSTORE" ] || [ -f "$PROPS" ]; then
  echo "Une clé existe déjà ($KEYSTORE). Je ne l'écrase pas."
  exit 0
fi

KEYTOOL="keytool"
if [ -n "${JAVA_HOME:-}" ] && [ -x "$JAVA_HOME/bin/keytool" ]; then
  KEYTOOL="$JAVA_HOME/bin/keytool"
fi
command -v "$KEYTOOL" >/dev/null || { echo "keytool introuvable (installe un JDK 17+)"; exit 1; }

PASS="$(openssl rand -base64 30 | tr -dc 'A-Za-z0-9' | head -c 32)"

"$KEYTOOL" -genkeypair -v \
  -keystore "$KEYSTORE" -storetype PKCS12 \
  -alias octogone -keyalg RSA -keysize 4096 -validity 10000 \
  -storepass "$PASS" -keypass "$PASS" \
  -dname "CN=Octogone, OU=Usage personnel, O=Octogone, C=FR" >/dev/null 2>&1

umask 077
cat > "$PROPS" <<EOF
storePassword=$PASS
keyPassword=$PASS
keyAlias=octogone
storeFile=../octogone-release.jks
EOF
chmod 600 "$KEYSTORE" "$PROPS"

echo "✅ Clé de signature créée :"
echo "   $KEYSTORE"
echo "   $PROPS"
echo "⚠  Sauvegarde ces deux fichiers : ils sont nécessaires pour toutes les mises à jour de l'APK."
