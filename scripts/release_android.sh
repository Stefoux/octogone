#!/usr/bin/env bash
# =============================================================================
# Publie une version Android sur GitHub Releases.
#
#   scripts/release_android.sh            # construit puis publie la version de app/pubspec.yaml
#   scripts/release_android.sh --sans-build   # publie les APK déjà construits
#
# Étapes :
#   1. lit la version dans app/pubspec.yaml (ex. 0.1.1+2) ;
#   2. construit les APK release (un par processeur) avec la config cloud ;
#   3. vérifie version et signature (clé release, pas la clé de debug) ;
#   4. crée le tag vX.Y.Z et la release GitHub, notes tirées de CHANGELOG.md,
#      avec les APK arm64 (quasi tous les téléphones) et armv7 (anciens modèles).
# =============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
die() { echo "❌ $*" >&2; exit 1; }

VERSION_FULL="$(grep -E '^version:' app/pubspec.yaml | awk '{print $2}')"
VERSION="${VERSION_FULL%%+*}"
TAG="v$VERSION"
[ -n "$VERSION" ] || die "version introuvable dans app/pubspec.yaml"

command -v gh >/dev/null || die "GitHub CLI absente (brew install gh)"
gh auth status >/dev/null 2>&1 || die "gh non connecté (gh auth login)"
[ -f app/config/app.json ] || die "app/config/app.json absent (lance scripts/supabase_setup.sh)"
[ -f app/android/key.properties ] || die "clé de signature absente (lance scripts/generate_keystore.sh)"
gh release view "$TAG" >/dev/null 2>&1 && die "la release $TAG existe déjà : augmente la version dans app/pubspec.yaml"

NOTES="$(awk -v v="## $VERSION" '$0==v{f=1;next} /^## /{f=0} f' CHANGELOG.md)"
[ -n "$(echo "$NOTES" | tr -d '[:space:]')" ] || die "pas de section « ## $VERSION » dans CHANGELOG.md"

if [ -n "$(git status --porcelain)" ]; then
  die "des modifications ne sont pas commitées : commite avant de publier"
fi

OUT="app/build/app/outputs/flutter-apk"
if [ "${1:-}" != "--sans-build" ]; then
  echo "▶ Build release $VERSION_FULL"
  (cd app && flutter build apk --release --split-per-abi --dart-define-from-file=config/app.json)
fi

BT="$(ls -d "${ANDROID_HOME:-/usr/local/share/android-commandlinetools}"/build-tools/* | tail -1)"
mkdir -p dist
ASSETS=()
for abi in arm64-v8a:arm64 armeabi-v7a:armv7; do
  src="$OUT/app-${abi%%:*}-release.apk"
  dst="dist/Octogone-$VERSION-${abi##*:}.apk"
  [ -f "$src" ] || die "$src introuvable"
  name="$("$BT/aapt2" dump badging "$src" | sed -n "s/.*versionName='\([^']*\)'.*/\1/p" | head -1)"
  [ "$name" = "$VERSION" ] || die "$src est en version $name, pas $VERSION (reconstruis sans --sans-build)"
  "$BT/apksigner" verify --print-certs "$src" 2>/dev/null | grep -q "CN=Octogone" \
    || die "$src n'est pas signé avec la clé release"
  cp "$src" "$dst"
  ASSETS+=("$dst")
done

echo "▶ Tag $TAG et release GitHub"
git tag -a "$TAG" -m "Octogone $VERSION"
git push -q origin "$TAG"
gh release create "$TAG" "${ASSETS[@]}" \
  --title "Octogone $VERSION" \
  --notes "$NOTES

---
**Installation** : télécharge \`Octogone-$VERSION-arm64.apk\` sur ton téléphone Android et ouvre-le (autorise l'installation depuis cette source). La version armv7 ne sert qu'aux téléphones anciens (avant 2017 environ). La mise à jour s'installe par-dessus la version précédente.

**iPhone** : \`Octogone-$VERSION.ipa\` est ajoutée automatiquement par GitHub Actions une vingtaine de minutes après la publication ; installation avec Sideloadly ou AltStore (voir le README)."

echo "✅ $(gh release view "$TAG" --json url --jq .url)"
