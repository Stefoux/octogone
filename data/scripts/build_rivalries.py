#!/usr/bin/env python3
"""Rivalités réelles entre combattants de la base : paires qui se sont affrontées
au moins deux fois en MMA professionnel, d'après les tableaux de palmarès
Wikipedia (pages déjà en cache). Sert aux cartes « Rivalités », « Face-à-Face »
et « Trilogie » (3 combats ou plus).

Chaque combat garde date, événement, vainqueur et méthode ; la source est
l'article Wikipedia du combattant. Sortie : data/rivalries.json.
"""
from __future__ import annotations

import json
import re

import datetime as dt

from common import DATA, save_json
from fetch_fighters import record_table, same_person, wiki_page


def iso_date(raw: str) -> str | None:
    """« 14 June 2026 », « June 14, 2026 », « 2026-06-14 » -> 2026-06-14."""
    raw = re.sub(r"\[.*?\]", "", raw).strip()
    for fmt in ("%d %B %Y", "%B %d, %Y", "%Y-%m-%d", "%B %d %Y", "%d %b %Y", "%b %d, %Y"):
        try:
            return dt.datetime.strptime(raw, fmt).date().isoformat()
        except ValueError:
            continue
    return None


def main() -> None:
    fighters = {}
    for p in sorted((DATA / "fighters").glob("*.json")):
        if p.name == "aliases.json":
            continue
        f = json.loads(p.read_text(encoding="utf-8"))
        fighters[f["id"]] = f

    def find_id(name: str) -> str | None:
        for fid, f in fighters.items():
            if same_person(f["nom"], name):
                return fid
        return None

    pairs: dict[tuple[str, str], dict] = {}
    for fid, f in fighters.items():
        if not f.get("wikipedia_titre"):
            continue
        try:
            fights = record_table(wiki_page(f["wikipedia_titre"])["html"])
        except Exception:
            continue
        for fight in fights:
            opp = find_id(re.sub(r"\[.*?\]", "", fight["adversaire"]).strip())
            if not opp or opp == fid:
                continue
            key = tuple(sorted((fid, opp)))
            res = fight["resultat"].lower()
            winner = fid if res.startswith("win") else opp if res.startswith("loss") else None
            entry = pairs.setdefault(key, {"a": key[0], "b": key[1], "combats": {}, "sources": set()})
            day = iso_date(fight["date"])
            # Clé = nom de l'événement (« UFC 275 ») : la date peut différer d'un jour selon
            # que la page donne l'heure locale ou celle des États-Unis.
            event = re.sub(r"[^a-z0-9 ]", "", fight["evenement"].split(":")[0].lower()).strip()
            fkey = event or day or fight["date"]
            entry["combats"].setdefault(fkey, {
                "date": day or fight["date"], "evenement": fight["evenement"], "vainqueur": winner,
                "methode": fight["methode"], "round": fight["round"],
                "resultat": "nul" if res.startswith("draw") else "sans_decision" if "nc" in res else None,
            })
            entry["sources"].add(f"https://en.wikipedia.org/wiki/{f['wikipedia_titre'].replace(' ', '_')}")

    def prefix(event: str) -> str:
        words = re.sub(r"[^a-z0-9 ]", " ", event.lower()).split()
        return " ".join(words[:2])

    def same_fight(x: dict, y: dict) -> bool:
        if x["date"] == y["date"]:
            return True
        try:
            gap = abs((dt.date.fromisoformat(x["date"]) - dt.date.fromisoformat(y["date"])).days)
        except ValueError:
            return False
        return gap <= 1 and prefix(x["evenement"]) == prefix(y["evenement"])

    out = []
    for e in pairs.values():
        combats: list[dict] = []
        for c in sorted(e["combats"].values(), key=lambda c: c["date"]):
            if not any(same_fight(c, k) for k in combats):
                combats.append(c)
        if len(combats) < 2:
            continue
        wins_a = sum(1 for c in combats if c["vainqueur"] == e["a"])
        wins_b = sum(1 for c in combats if c["vainqueur"] == e["b"])
        out.append({"id": f"{e['a']}--{e['b']}", "a": e["a"], "b": e["b"], "nb_combats": len(combats),
                    "bilan": {e["a"]: wins_a, e["b"]: wins_b}, "combats": combats,
                    "sources": sorted(e["sources"])})
    out.sort(key=lambda r: (-r["nb_combats"], r["id"]))
    save_json(DATA / "rivalries.json", out)
    trilogies = [r for r in out if r["nb_combats"] >= 3]
    print(f"{len(out)} rivalités (2 combats ou plus), dont {len(trilogies)} à 3 combats ou plus :")
    for r in trilogies:
        print(f"  {fighters[r['a']]['nom']} vs {fighters[r['b']]['nom']} : {r['nb_combats']} combats, "
              f"bilan {r['bilan'][r['a']]}-{r['bilan'][r['b']]}")


if __name__ == "__main__":
    main()
