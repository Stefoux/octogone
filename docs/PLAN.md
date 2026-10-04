# Plan de réalisation

Chaque phase se termine par : `flutter analyze` sans erreur, tests, build APK et essai sur émulateur Android, plus la liste de ce qui n'a pas pu être testé.

| # | Phase | Contenu | État |
|---|---|---|---|
| 1 | Fondations | Monorepo, schéma Supabase + RLS, auth email/pseudo, données réelles (252 combattants, 2024 Topps Chrome UFC, Saison 2026), pipeline d'images Commons, cache Drift | terminée en local (cloud : en attente du .env) |
| 2 | Cartes et album | Recto/verso, familles de cadres, raretés et parallèles en shaders, gyroscope, album à emplacements | à faire |
| 3 | Boosters et économie | Ouverture serveur (Edge Function + transaction), numérotation globale, anti-malchance, animations, pièces, défis, fragments | à faire |
| 4 | Combat contre l'IA | Moteur `game_core`, IA 3 niveaux, modes, hors ligne, équilibrage sur 10 000 combats | à faire |
| 5 | En ligne | Amis, combats temps réel arbitrés serveur, défis asynchrones, échanges atomiques | à faire |
| 6 | Admin | Rôle en base, mode admin, panneau, import galerie, tests d'accès | à faire |
| 7 | Contenu complet | 100+ combattants, 2e édition réelle, Moments Historiques (dont UFC Freedom 250), Célébrations, inserts originaux, saisons | à faire |
| 8 | Builds | Keystore, APK signé, IPA non signé, GitHub Actions, README complet | à faire |

## Choix techniques

- **Un seul moteur de règles** (`packages/game_core`, Dart pur) : utilisé par l'app hors ligne et, compilé en JavaScript, par les Edge Functions pour arbitrer les parties en ligne.
- **Numérotation globale** : compteur par (carte, variante) verrouillé dans une transaction Postgres + contrainte d'unicité `(carte, variante, numéro)`.
- **Combats en ligne** : échéance de chaque échange stockée en base ; la résolution est déclenchée par les clients et validée par le serveur (« Garde » automatique pour l'absent), avec un nettoyage `pg_cron`.
- **Données** : scripts Python ; chaque champ garde sa source, les manques sont marqués `a_verifier`.

## Faits vérifiés à la préparation (4 octobre 2026)

- MacBook Pro 13" 2018 : macOS Tahoe non supporté → Xcode 26.3 maximum (après passage à Sequoia 15.6+) ; Xcode 16.2 sur macOS 14.5. Flutter 3.47.6 demande Xcode ≥ 15.
- Topps : licence UFC depuis 2009, perdue au profit de Panini en 2021, récupérée via Fanatics (2024 Topps Chrome UFC).
- UFC Freedom 250 : 14 juin 2026, pelouse sud de la Maison-Blanche ; Gaethje bat Topuria (titre des légers), Gane bat Pereira (titre intérimaire des lourds).
- UFCStats.com protège désormais ses pages par une vérification anti-robot : les statistiques viennent des fiches officielles ufc.com (même fournisseur de données), en respectant leur `crawl-delay` de 15 s.
