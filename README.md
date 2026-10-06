# Octogone

Application mobile personnelle (entre amis, non publiée sur les stores, sans achat réel) de cartes à collectionner et à jouer autour des combattants de MMA.

Ce README couvre l'état actuel (phase 1). La version complète, avec l'installation Android/iOS pas à pas, arrive en phase 8. Le plan détaillé est dans [docs/PLAN.md](docs/PLAN.md).

## Structure

```
app/                 application Flutter (Riverpod, go_router, Drift)
packages/game_core/  règles du jeu en Dart pur (formule des stats, puis combat et boosters)
supabase/            migrations SQL + policies RLS, tests pgTAP, Edge Functions
data/                données réelles en JSON (combattants, éditions, images) + scripts Python
scripts/             installation Supabase, puis keystore et builds
```

## Prérequis

- Flutter 3.47 (stable), JDK 21, SDK Android (plateforme 36)
- CLI Supabase, Docker Desktop (seulement pour les tests locaux)
- Python 3.12 (scripts de données)

## Mise en route

1. **Projet Supabase** : crée un projet gratuit sur supabase.com, copie `.env.example` en `.env` et remplis `SUPABASE_PROJECT_REF`, `SUPABASE_DB_PASSWORD`, `SUPABASE_ACCESS_TOKEN` (et, si tu veux, `ADMIN_EMAIL_1` / `ADMIN_EMAIL_2`).
2. **Installation du backend et import des données** :
   ```bash
   scripts/supabase_setup.sh --donnees
   ```
3. **Lancer l'app** (téléphone branché ou émulateur) :
   ```bash
   cd app && flutter run --dart-define-from-file=config/app.json
   ```

## Données

Aucun fait n'est inventé : chaque combattant garde ses sources (`sources`, `champs_sources`) et ce qui n'a pas été trouvé est listé dans `a_verifier`. Un article Wikipedia ou une fiche ufc.com n'est retenu que si le nom correspond (au moins deux mots communs, ou le libellé Wikidata) ; les correspondances particulières sont dans `data/fighters/aliases.json`.

| Script (dans `data/scripts`) | Rôle |
|---|---|
| `import_checklist.py` | checklist d'une édition réelle (Checklist Insider), recoupée avec Checklist Center |
| `fetch_fighters.py` | combattants : ufc.com (stats officielles), Wikipedia (palmarès, bonus, titres), Wikidata (nationalité…) |
| `distinctions.py` | distinctions courtes (6 lignes max) en français et en anglais, tirées des « Championships and accomplishments » de Wikipedia ; l'app affiche la langue du téléphone (repli : français) |
| `fetch_images.py` | photos libres Wikimedia Commons, auteur et licence, recadrage visage/buste |
| `build_original_editions.py` | éditions originales « Saison AAAA » (combattants ayant combattu cette année-là) |
| `import_to_supabase.py` | envoi idempotent des JSON, des images et des boosters vers Supabase |
| `fetch_photos.py` | photos de cartes selon la rareté (galeries et articles ufc.com, Wikimedia Commons) : `--index` puis `--tous --depuis-index`, `--manquants`, `--complement` ; vérification par légende et reconnaissance faciale |
| `completer_roster.py` | nationalité et sexe des fiches sans Wikidata (liste Wikipedia des combattants UFC actuels) |
| `prepare_booster_art.py` | photos des sachets : bustes recadrés d'après le visage (disposition en V) et photo du combattant phare ; déposer les originaux dans `data/images/boosters/originaux/` puis relancer |
| `make_icon.py` | icône de l'app (Android et iOS), dessinée par script |
| `make_sounds.py` | sons de l'app (déchirure, retournement, révélation par rareté), générés sans fichier externe |
| `test_boosters_load.py` | simulation de boosters (probabilités) et ouvertures simultanées (numérotation) |
| `packages/game_core/bin/compute_stats.dart` | stats de jeu 0-99 (formule documentée dans `lib/src/stats/stat_formula.dart`) |

Ajouter une édition réelle :

```bash
cd data/scripts
.venv/bin/python import_checklist.py --id 2025-topps-chrome-ufc --nom "2025 Topps Chrome UFC" \
  --annee 2025 --gamme Chrome --cadre chrome \
  --source https://www.checklistinsider.com/2025-topps-chrome-ufc \
  --verif https://www.checklistcenter.com/2025-topps-chrome-ufc-card-checklist/
.venv/bin/python fetch_fighters.py --edition 2025-topps-chrome-ufc
```

## Boosters

Les types de boosters sont dans `data/boosters.json` (importés dans la table `booster_types`) : nombre de cartes, prix en pièces, visuel (couleurs, accent) et composition. Chaque emplacement tire une rareté selon ses poids, puis une variante (les petits tirages sortent moins), puis une carte éligible. L'app calcule les probabilités affichées à partir de ces mêmes poids.

L'ouverture se fait uniquement côté serveur (`open_booster`, migration `20261005000100_boosters.sql`) dans une transaction : paiement, anti-malchance, numéro de série unique pour tous les joueurs (verrou sur `print_runs`), cartes ajoutées à la collection.

Réglages dans la table `economy_config` :

| Colonne | Défaut | Rôle |
|---|---|---|
| `mode_test` | `true` | boosters illimités et gratuits pendant les tests |
| `intervalle_gratuit` | `12 hours` | délai entre deux boosters gratuits |
| `capacite_gratuite` | `2` | boosters gratuits mis de côté au maximum |
| `pity_legendaire` | `40` | Légendaire garantie au plus tard tous les N boosters |

Fin des tests (éditeur SQL de Supabase, en attendant l'écran admin de la phase 6) :

```sql
update public.economy_config set mode_test = false;
```

Vérifier les probabilités et la concurrence sur le Supabase local :

```bash
cd data/scripts && .venv/bin/python test_boosters_load.py --n 100000
```

## Économie

Tout se passe côté serveur et chaque mouvement de pièces ou de fragments est inscrit dans `wallet_ledger`.

- **Atelier** (`20261007000200_atelier.sql`) : `recycler(ids)` (garde au moins un exemplaire de chaque variante ; jamais les numérotées, copies admin, cartes protégées ou exposées), `fabriquer(carte, variante)` (pas les numérotées ni les variantes spéciales, éligibilité respectée), `proteger(id, bool)`. Barème dans `economy_config.fragments`.
- **Défis** (`data/defis.json`) : `nb_defis_jour` et `nb_defis_semaine` dans `economy_config` (4 et 3), un par type, renouvelés à minuit et le lundi (heure de Paris). La progression est comptée par `_evenement(joueur, type, quantité)`, appelé par les fonctions serveur ; récompense avec `recuperer_defi`.
- **Succès** (`data/succes.json`) : progression calculée depuis les données du joueur (`_valeur_succes`), récompense avec `recuperer_succes`.
- Les récompenses passent par `_crediter(joueur, source, pièces, fragments)`. Les combats de la phase 4 s'y brancheront, avec `plafond_combat_jour`.

## Versions

Chaque version de l'app est publiée dans les [releases GitHub](https://github.com/Stefoux/octogone/releases) avec ses APK et son IPA (ajoutée par GitHub Actions une vingtaine de minutes après le tag). Pour publier : augmenter `version` dans `app/pubspec.yaml`, décrire la version dans [CHANGELOG.md](CHANGELOG.md), commiter, puis :

```bash
scripts/release_android.sh
```

## Installer sur iPhone (Apple ID gratuit)

Chaque release contient aussi `Octogone-X.Y.Z.ipa`, une IPA **non signée** construite par GitHub Actions ([workflow](.github/workflows/ios.yml)) : elle est signée avec ton Apple ID au moment de l'installation.

1. Télécharge l'IPA depuis la [page des releases](https://github.com/Stefoux/octogone/releases).
2. Ouvre **Sideloadly** sur le Mac, branche l'iPhone en USB, glisse l'IPA dans la fenêtre, indique ton Apple ID (dans Sideloadly uniquement) et clique sur **Start**.
3. Sur l'iPhone (iOS 16 ou plus récent) : **Réglages > Confidentialité et sécurité > Mode développeur** → activer, puis redémarrer.
4. **Réglages > Général > VPN et gestion de l'appareil** → touche ton Apple ID → **Faire confiance**.
5. Une app signée avec un Apple ID gratuit expire au bout de **7 jours** : relance l'installation avec Sideloadly (ou utilise AltStore, qui peut la rafraîchir automatiquement). Tes cartes ne sont pas perdues, elles sont sur le serveur.

Limites d'un Apple ID gratuit : 3 apps installées de cette façon en même temps, 10 identifiants d'app par semaine.

## Tests

```bash
cd packages/game_core && dart test        # formule des stats
cd app && flutter analyze && flutter test  # analyse + widget tests
supabase start && supabase test db         # policies RLS, boosters (Supabase local dans Docker)
cd data/scripts && .venv/bin/python -m unittest test_scripts  # scripts de données
```

## Mentions

Projet non officiel et non commercial. Aucun logo officiel : les noms d'éditions apparaissent en texte et les cadres de cartes sont des créations originales. Les photos proviennent de Wikimedia Commons sous licence libre ; les attributions sont affichées dans l'écran « Crédits » de l'app. Les sachets de boosters utilisent des photos officielles de combattants, pour un usage privé entre amis (aucune photo de vrai paquet) et les sons sont synthétisés par `data/scripts/make_sounds.py`.
