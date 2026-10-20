#!/usr/bin/env python3
"""Liste officielle des combattants intronisés au Hall of Fame de l'UFC
(ailes des pionniers et moderne ; pas les ailes Contributeurs ni Combats),
d'après l'article Wikipedia « UFC Hall of Fame » (qui cite ufc.com/honors).

Écrit data/hall_of_fame.json : {source, source_officielle, date, membres:
[{nom, aile, date_intronisation, id, en_base}]}. Les absents de la base sont
listés : on les ajoute ensuite avec fetch_fighters.py --noms.

  python fetch_hall_of_fame.py
"""
from __future__ import annotations

import datetime as dt
import json
import re

import mwparserfromhell

from common import DATA, WIKI_UA, canonical, fetch, load_aliases, save_json, slugify

WIKI_API = "https://en.wikipedia.org/w/api.php"
PAGE = "UFC Hall of Fame"
SOURCE = "https://en.wikipedia.org/wiki/UFC_Hall_of_Fame"
OFFICIAL = "https://www.ufc.com/honors/ufc-hall-of-fame"
WINGS = {"Pioneer wing": "pionniers", "Modern wing": "moderne"}


def wing_rows(wikitext: str, title: str) -> list[list[str]]:
    """Lignes du tableau de la section [title] (cellules en texte brut)."""
    m = re.search(rf"^===\s*{re.escape(title)}\s*===\s*$(.*?)(?=^==)", wikitext, re.M | re.S)
    if not m:
        return []
    rows = []
    for raw in m.group(1).split("\n|-")[1:]:
        cells = [c.strip() for c in re.split(r"\n\|(?!\})", "\n" + raw.strip()) if c.strip()]
        if not cells or cells[0].startswith("!"):
            continue
        rows.append(cells)
    return rows


def main() -> None:
    txt = fetch(WIKI_API, params={"action": "parse", "page": PAGE, "prop": "wikitext", "format": "json",
                                  "formatversion": "2"}, ua=WIKI_UA, delay=1)
    wikitext = json.loads(txt)["parse"]["wikitext"]
    aliases = load_aliases()
    membres = []
    for title, wing in WINGS.items():
        for cells in wing_rows(wikitext, title):
            # Colonnes : image, pays, nom, date d'intronisation, réf., événement, palmarès
            links = [str(l.title) for l in mwparserfromhell.parse(cells[2]).filter_wikilinks()] if len(cells) > 2 else []
            if not links:
                continue
            nom = links[0].split("(")[0].strip()
            date = mwparserfromhell.parse(cells[3]).strip_code().strip() if len(cells) > 3 else None
            fid = slugify(canonical(nom, aliases))
            membres.append({
                "nom": nom, "aile": wing, "date_intronisation": date, "id": fid,
                "en_base": (DATA / "fighters" / f"{fid}.json").exists(),
            })
    save_json(DATA / "hall_of_fame.json", {
        "source": SOURCE, "source_officielle": OFFICIAL, "date": dt.date.today().isoformat(), "membres": membres,
    })
    absents = [m["nom"] for m in membres if not m["en_base"]]
    print(f"{len(membres)} intronisés ({sum(m['aile'] == 'pionniers' for m in membres)} pionniers, "
          f"{sum(m['aile'] == 'moderne' for m in membres)} aile moderne) ; {len(absents)} absents de la base")
    for n in absents:
        print(f"  absent : {n}")


if __name__ == "__main__":
    main()
