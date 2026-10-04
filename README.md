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
| `import_to_supabase.py` | envoi idempotent des JSON et des images vers Supabase |
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

## Tests

```bash
cd packages/game_core && dart test        # formule des stats
cd app && flutter analyze && flutter test  # analyse + widget tests
supabase start && supabase test db         # policies RLS (Supabase local dans Docker)
```

## Mentions

Projet non officiel et non commercial. Aucun logo officiel : les noms d'éditions apparaissent en texte et les cadres de cartes sont des créations originales. Les photos proviennent de Wikimedia Commons sous licence libre ; les attributions sont affichées dans l'écran « Crédits » de l'app.
