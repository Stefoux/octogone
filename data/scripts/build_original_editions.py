#!/usr/bin/env python3
"""Génère les éditions ORIGINALES annuelles (« Saison 2026 »…).

La série de base d'une saison contient les combattants de la base de données
qui ont réellement combattu à l'UFC cette année-là (d'après le tableau du
palmarès Wikipedia : champ ufc.combats_ufc_par_annee). Aucun choix arbitraire.

S'y ajoutent les combattants listés dans editions/_ajouts_saison_<année>.json
(roster élargi validé par l'utilisateur : classés UFC, Français…), même s'ils
n'ont pas combattu cette année-là.

Numérotation STABLE : une carte déjà publiée garde toujours son numéro (des
exemplaires en dépendent) ; les nouveaux combattants prennent les numéros
suivants. Ordre des nouveaux : champions en titre, catégories des lourds aux
pailles, puis ordre alphabétique.

Usage : python build_original_editions.py 2026 [2025 2024]
"""
from __future__ import annotations

import json
import sys

from common import DATA, save_json

ORDER = ["lourds", "mi_lourds", "moyens", "mi_moyens", "legers", "plume", "coq", "mouche",
         "plume_f", "coq_f", "mouche_f", "paille_f"]


def build(year: int) -> dict:
    extra = set(json.loads(p.read_text(encoding="utf-8"))["combattants"]) \
        if (p := DATA / "editions" / f"_ajouts_saison_{year}.json").exists() else set()
    fighters = []
    for p in sorted((DATA / "fighters").glob("*.json")):
        if p.name == "aliases.json":
            continue
        f = json.loads(p.read_text(encoding="utf-8"))
        per_year = (f.get("ufc") or {}).get("combats_ufc_par_annee") or {}
        if per_year.get(str(year)) or f["id"] in extra:
            fighters.append(f)
    fighters.sort(key=lambda f: (
        0 if f.get("champion_actuel") else 1,
        ORDER.index(f["categorie"]) if f.get("categorie") in ORDER else 99,
        f["nom"],
    ))
    # Cartes déjà publiées : on garde leur numéro
    previous = DATA / "editions" / f"saison-{year}.json"
    cards = []
    if previous.exists():
        cards = json.loads(previous.read_text(encoding="utf-8"))["series"][0]["cartes"]
    known = {fid for c in cards for fid in c["combattants"]}
    next_num = max((int(c["numero"]) for c in cards), default=0) + 1
    for f in fighters:
        if f["id"] in known:
            continue
        cards.append({"numero": str(next_num), "nom_imprime": f["nom"], "combattants": [f["id"]], "mentions": [],
                      "sous_titre": None})
        next_num += 1
    return {
        "id": f"saison-{year}",
        "nom": f"Saison {year}",
        "annee": year,
        "type": "originale",
        "famille_cadre": "original",
        "date_sortie": None,
        "description": (f"Édition originale : tous les combattants de la base qui ont combattu à l'UFC en {year} "
                        f"(source : palmarès Wikipedia de chaque combattant), plus le roster élargi "
                        f"(classés UFC, Français) ajouté à la suite."),
        "sources": [],
        "a_verifier": [],
        "series": [{
            "code": "BASE", "nom": "Base", "type": "base", "nb_cartes": len(cards), "cote": None,
            "exclusivite": None, "tirage": None, "paralleles": [], "notes": [], "cartes": cards,
            "source": None,
        }],
    }


def main() -> None:
    years = [int(a) for a in sys.argv[1:]] or [2026]
    for y in years:
        e = build(y)
        save_json(DATA / "editions" / f"{e['id']}.json", e)
        print(f"{e['nom']} : {len(e['series'][0]['cartes'])} cartes")


if __name__ == "__main__":
    main()
