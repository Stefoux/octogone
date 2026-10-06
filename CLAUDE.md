# Octogone : consignes du projet

Jeu mobile de cartes de combattants (collection, boosters, combat tactique), Flutter + Supabase, pour un usage privé entre amis : pas de store, pas d'argent réel. Distribution : APK (arm64, armv7) et IPA non signée (Sideloadly / AltStore).

## Règles de travail

- Répondre en français.
- Après chaque étape testée : commit + push sur `Stefoux/octogone` (privé).
- Chaque version a sa release GitHub : `scripts/release_android.sh` construit et publie les APK ; le tag `vX.Y.Z` déclenche `.github/workflows/ios.yml`, qui ajoute l'IPA. Mettre à jour `CHANGELOG.md`, `app/pubspec.yaml` et `appVersion` (`settings_screen.dart`).
- Ne jamais committer : `.env`, `.env.test.local`, `app/config/*.json`, `app/android/key.properties`, `*.jks`. Le secret GitHub `APP_CONFIG_JSON` ne contient que l'URL et la clé publique.
- Ne pas créer de compte sur le projet Supabase cloud. Les comptes de test vivent sur le Supabase local (`.env.test.local`).
- Toute la logique sensible est côté serveur, dans des fonctions Postgres en transaction : ouverture de booster, numérotation, vitrine, etc. L'app n'écrit jamais directement dans les tables de jeu.
- L'app suit la langue du téléphone (FR / EN, repli FR). Chaque texte passe par `app/lib/l10n/app_fr.arb` et `app_en.arb`.

## Données

- Données réelles uniquement. Chaque fait garde sa source ; ce qui n'est pas trouvé va dans `a_verifier`. Ne rien inventer.
- Photos des combattants : Wikimedia Commons, avec auteur et licence (écran Crédits).
- Pas de logo officiel UFC / Topps dessiné par l'app. Photos officielles autorisées par l'utilisateur pour l'usage privé : sachets de boosters (`data/images/boosters/`) et photos de cartes selon la rareté (`data/images/photos/`, `data/scripts/fetch_photos.py`).
- Photos de cartes : combat (Commune → Épique), célébration après victoire (Légendaire ; ceinture pour la liste `data/images/ceinture_legendaire.json`), ceinture si déjà champion sinon célébration (Mythique). Chaque photo est vérifiée par sa légende d'agence ET la reconnaissance faciale, puis revue visuellement ; les refus vont dans `data/images/photos_refusees.json`. Ne jamais retirer un filigrane. Respecter le crawl-delay de 15 s de ufc.com ; ne pas utiliser les sites qui interdisent les agents d'IA (mmafighting, mmajunkie).
- UFCStats est protégé par une vérification anti-robot : ne pas la contourner, utiliser ufc.com.

## Commandes

```bash
cd app && flutter analyze && flutter test            # app
cd packages/game_core && dart test                   # règles partagées (stats, raretés, probabilités)
supabase test db                                     # pgTAP (Supabase local dans Docker)
cd data/scripts && .venv/bin/python -m unittest test_scripts
```

Émulateur (Mac Intel, x86_64) : `flutter build apk --profile --dart-define-from-file=config/app.local.json --target-platform android-x64`. `uiautomator` bloque sur les écrans très animés : piloter avec captures d'écran et `adb shell input`.

## Carte du code

- `app/lib/core/` : thème (Oswald + Barlow, palette chaude), routes, sons, l10n.
- `app/lib/data/` : cache local Drift et synchronisation du contenu.
- `app/lib/domain/` : modèles.
- `app/lib/features/` :
  - `entry` : écran d'entrée ;
  - `home` ;
  - `boosters` : sachets, ouverture, glissement ;
  - `cards` : rendu des cartes et effets holographiques ;
  - `album` ;
  - `fighters` ;
  - `vitrine` ;
  - `collection` : sélecteur de cartes ;
  - `profile`, `settings`, `credits`.
- `app/lib/widgets/` : fonds animés (`ArenaBackground`, `RarityBackdrop`), octogone, inclinaison.
- `packages/game_core/` : règles en Dart pur, compilables en JS pour le serveur.
- `supabase/migrations/` et `supabase/tests/database/` : schéma, RLS, fonctions, tests.
- `data/` : JSON sourcés et scripts Python (import, sons, icône, photos des sachets, photos de cartes, roster élargi `editions/_ajouts_saison_2026.json`).

## Roadmap

À faire dans les prochaines phases. Ne pas coder sans demande.

### Decks de combat
3 combattants et des cartes bonus (récupération de PV, etc.).

Points d'accroche :
- **Référencer les exemplaires possédés** (`owned_cards.id`), comme `vitrine_slots`. Une table `deck_slots`, écrite par une fonction `set_deck(...)` qui vérifie la propriété, sur le modèle de `set_vitrine`.
- **Choisir les cartes** avec `pickOwnedCard` (`app/lib/features/collection/owned_card_picker.dart`), avec un filtre par type de carte.
- **Le moteur de combat** va dans `packages/game_core`, en Dart pur, pour être partagé app / serveur. Les stats de jeu existent déjà (`StatFormula`).

### Échange de cartes entre joueurs
Un exemplaire change de propriétaire (`owned_cards.owner_id`) dans une fonction serveur transactionnelle, avec une proposition et une acceptation des deux côtés.

Points d'accroche :
- La suppression ou le changement de propriétaire retire déjà la carte de la vitrine : clé étrangère `on delete cascade`, et `set_vitrine` revérifie la propriété.
- La lecture des cartes d'un autre joueur est prête dans `vitrine_de(p_joueur)` : il suffit d'élargir sa condition aux amis.
- L'origine `echange` existe déjà dans `owned_cards.origine`.

### Niveaux
De l'XP gagnée en combat et via des quêtes. Prévoir une table `profils_progression` (xp, niveau) mise à jour uniquement par des fonctions serveur : fin de combat, quête validée.

### Économie déjà en place (phase 3 terminée, v0.3.5)
- Les gains et dépenses passent par `_crediter` (journal `wallet_ledger`). Les événements de jeu passent par `_evenement(joueur, type, n)` : les défis s'y abonnent. Les combats y enverront `gagner_combat` (défis déjà prêts, inactifs).
- Les futures récompenses d'XP pourront lire le journal ou ajouter une source.

### Reste du cahier des charges
- **Phases suivantes :** 4 combat contre l'IA, 5 en ligne, 6 admin, 7 contenu complet, 8 builds (voir `docs/PLAN.md`).
