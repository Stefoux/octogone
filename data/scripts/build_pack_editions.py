#!/usr/bin/env python3
"""Construit les éditions des packs Premium+ à partir des données sourcées :

- champions.json : tous les champions UFC de la base, actuels (classement
  officiel ufc.com) puis anciens (palmarès Wikipedia) ;
- rivalites.json : une carte Face-à-Face par rivalité réelle de
  data/rivalries.json (2 combats ou plus entre les mêmes combattants) ;
- hall-of-fame.json : les intronisés de data/hall_of_fame.json présents dans
  la base (liste officielle sourcée, voir fetch_hall_of_fame.py) ;
- moments-iconiques.json : les moments de data/moments/*.json (chacun sourcé).

Chaque édition a sa propre échelle de raretés (« raretes »), sans règle
d'éligibilité : toutes ses cartes y ont droit.

  python build_pack_editions.py
"""
from __future__ import annotations

import json

from common import DATA, load_json, save_json

# Ordre d'affichage des catégories : hommes du plus lourd au plus léger, puis femmes
CLASS_ORDER = ["lourds", "mi_lourds", "moyens", "mi_moyens", "legers", "plume", "coq", "mouche",
               "plume_f", "coq_f", "mouche_f", "paille_f"]

RANKINGS_URL = "https://www.ufc.com/rankings"


def ladder(legendaire: tuple[str, str], epique: tuple[str, str] = ("onde_de_choc", "Onde de Choc"),
           rare: tuple[str, str] = ("neon", "Néon Main Event")) -> list[dict]:
    return [
        {"rarete": "commune", "nom": "Base", "effet": "base"},
        {"rarete": "peu_commune", "nom": "Acier d'Octogone", "effet": "acier"},
        {"rarete": "rare", "nom": rare[1], "effet": rare[0]},
        {"rarete": "epique", "nom": epique[1], "effet": epique[0]},
        {"rarete": "legendaire", "nom": legendaire[1], "effet": legendaire[0]},
        {"rarete": "mythique", "nom": "Octogone Noir", "effet": "octogone_noir", "tirage": 5},
    ]


def load_fighters() -> dict[str, dict]:
    out = {}
    for p in sorted((DATA / "fighters").glob("*.json")):
        if p.name == "aliases.json":
            continue
        f = json.loads(p.read_text(encoding="utf-8"))
        out[f["id"]] = f
    return out


def fighter_sources(f: dict, *extra: str) -> list[str]:
    src = f.get("sources") or {}
    return [s for s in [*extra, src.get("wikipedia"), src.get("ufc_com")] if s]


def edition(eid: str, nom: str, description: str, raretes: list[dict], cartes: list[dict], sources: list[str],
            serie: str) -> dict:
    return {
        "id": eid, "nom": nom, "annee": 2026, "type": "originale", "famille_cadre": "original",
        "date_sortie": None, "description": description, "sources": sources, "a_verifier": [],
        "raretes": raretes,
        "series": [{"code": "BASE", "nom": serie, "type": "base", "nb_cartes": len(cartes), "cartes": cartes}],
    }


def build_champions(fighters: dict[str, dict]) -> dict:
    def key(f):
        cat = f.get("categorie")
        return CLASS_ORDER.index(cat) if cat in CLASS_ORDER else len(CLASS_ORDER), f["nom"]

    current = sorted((f for f in fighters.values() if f.get("champion_actuel")), key=key)
    former = sorted((f for f in fighters.values() if f.get("ancien_champion") and not f.get("champion_actuel")),
                    key=lambda f: f["nom"])
    cartes = []
    for f in [*current, *former]:
        cartes.append({
            "numero": str(len(cartes) + 1),
            "nom_imprime": f["nom"],
            "combattants": [f["id"]],
            "sources": fighter_sources(f, RANKINGS_URL if f.get("champion_actuel") else None),
        })
    return edition(
        "champions", "Champions",
        f"Les champions UFC de la base : {len(current)} champions actuels (classement officiel ufc.com), puis "
        f"{len(former)} anciens champions (titres relevés dans le palmarès Wikipedia de chacun).",
        ladder(("ceinture_or", "Ceinture d'Or")), cartes, [RANKINGS_URL], "Champions",
    )


def build_rivalites(fighters: dict[str, dict]) -> dict:
    rivals = [r for r in load_json(DATA / "rivalries.json", []) if r["a"] in fighters and r["b"] in fighters]
    rivals.sort(key=lambda r: (-r["nb_combats"], fighters[r["a"]]["nom"]))
    cartes = [{
        "numero": str(i + 1),
        "nom_imprime": f"{fighters[r['a']]['nom']} vs {fighters[r['b']]['nom']}",
        "combattants": [r["a"], r["b"]],
        "sources": r.get("sources") or [],
    } for i, r in enumerate(rivals)]
    return edition(
        "rivalites", "Rivalités",
        f"Les {len(cartes)} rivalités réelles de la base (au moins deux combats entre les mêmes combattants), "
        "en cartes Face-à-Face ; bilan et combats tirés du palmarès Wikipedia de chacun.",
        ladder(("heritage", "Héritage"), rare=("face_a_face", "Face-à-Face")), cartes, [], "Rivalités",
    )


def build_hall_of_fame(fighters: dict[str, dict]) -> dict | None:
    hof = load_json(DATA / "hall_of_fame.json", None)
    if not hof:
        return None
    members = [m for m in hof["membres"] if m.get("id") in fighters]
    cartes = [{
        "numero": str(i + 1),
        "nom_imprime": fighters[m["id"]]["nom"],
        "combattants": [m["id"]],
        "mentions": [],
        "sources": [hof["source"], *fighter_sources(fighters[m["id"]])],
    } for i, m in enumerate(members)]
    return edition(
        "hall-of-fame", "Hall of Fame",
        f"Les {len(cartes)} combattants intronisés au Hall of Fame de l'UFC présents dans la base "
        "(ailes des pionniers et moderne, liste officielle sourcée).",
        ladder(("heritage", "Héritage"), epique=("cicatrice", "Cicatrice")), cartes, [hof["source"]], "Hall of Fame",
    )


def build_moments(fighters: dict[str, dict]) -> dict | None:
    moments = []
    for p in sorted((DATA / "moments").glob("*.json")):
        m = json.loads(p.read_text(encoding="utf-8"))
        if all(f in fighters for f in m["combattants"]):
            moments.append(m)
    if not moments:
        return None
    moments.sort(key=lambda m: m["date"])
    cartes = [{
        "numero": str(i + 1),
        "nom_imprime": m["titre"],
        "combattants": m["combattants"],
        "event_id": m["event_id"],
        "texte_verso": m.get("texte"),
        "sources": m["sources"],
    } for i, m in enumerate(moments)]
    return edition(
        "moments-iconiques", "Moments iconiques",
        f"{len(cartes)} grands moments de l'histoire de l'UFC, chacun sourcé (date, événement, résultat).",
        ladder(("moment", "Moment Historique")), cartes, [], "Moments iconiques",
    )


def main() -> None:
    fighters = load_fighters()
    for e in (build_champions(fighters), build_rivalites(fighters), build_hall_of_fame(fighters),
              build_moments(fighters)):
        if e is None:
            continue
        save_json(DATA / "editions" / f"{e['id']}.json", e)
        print(f"{e['nom']} : {len(e['series'][0]['cartes'])} cartes")


if __name__ == "__main__":
    main()
