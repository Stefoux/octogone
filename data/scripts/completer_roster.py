#!/usr/bin/env python3
"""Complète les fiches sans article Wikipedia (donc sans Wikidata) :

- pays : drapeau de la liste Wikipedia « List of current UFC fighters » ;
- sexe : déduit de la catégorie ufc.com (catégories « Women's … » -> F).

Chaque valeur ajoutée garde sa source dans champs_sources et sort de
a_verifier. Rien n'est deviné : sans drapeau dans la liste, le pays reste à
vérifier.

    .venv/bin/python completer_roster.py
"""
from __future__ import annotations

import json
import re
import unicodedata

from common import DATA, WIKI_UA, fetch, save_json

LIST_URL = "https://en.wikipedia.org/wiki/List_of_current_UFC_fighters"
# Codes de drapeau de la liste (IOC / FIFA) -> code pays ISO 3166-1 alpha-2 de l'app
ISO2 = {
    "AFG": "AF", "ARG": "AR", "ARM": "AM", "AUS": "AU", "AUT": "AT", "AZE": "AZ", "BEL": "BE", "BLR": "BY",
    "BOL": "BO", "BRA": "BR", "BUL": "BG", "CAN": "CA", "CHI": "CL", "CHN": "CN", "CMR": "CM", "COL": "CO",
    "CRO": "HR", "CUB": "CU", "CZE": "CZ", "DEN": "DK", "DOM": "DO", "ECU": "EC", "ENG": "GB", "ESP": "ES",
    "FIN": "FI", "FRA": "FR", "GBR": "GB", "GEO": "GE", "GER": "DE", "GRE": "GR", "IRL": "IE", "IRN": "IR",
    "ISR": "IL", "ITA": "IT", "JAM": "JM", "JPN": "JP", "KAZ": "KZ", "KGZ": "KG", "KOR": "KR", "LTU": "LT",
    "MAR": "MA", "MDA": "MD", "MEX": "MX", "MGL": "MN", "NED": "NL", "NGR": "NG", "NIR": "GB", "NOR": "NO",
    "NZL": "NZ", "PAR": "PY", "PER": "PE", "PHI": "PH", "POL": "PL", "POR": "PT", "PUR": "PR", "ROU": "RO",
    "RSA": "ZA", "RUS": "RU", "SCO": "GB", "SRB": "RS", "SUI": "CH", "SVK": "SK", "SWE": "SE", "TJK": "TJ",
    "THA": "TH", "TUR": "TR", "UGA": "UG", "UKR": "UA", "URU": "UY", "USA": "US", "UZB": "UZ", "VEN": "VE",
    "WAL": "GB",
}


def norm(s: str) -> str:
    s = "".join(c for c in unicodedata.normalize("NFKD", s) if not unicodedata.combining(c))
    return re.sub(r"[^a-z ]", "", s.lower().replace("-", " ")).strip()


def roster_flags() -> dict[str, str]:
    txt = fetch("https://en.wikipedia.org/w/api.php", ua=WIKI_UA, delay=1,
                params={"action": "parse", "page": "List of current UFC fighters", "prop": "wikitext",
                        "format": "json", "formatversion": "2"})
    lines = json.loads(txt)["parse"]["wikitext"].split("\n")
    flags = {}
    for i, l in enumerate(lines):
        m = re.search(r"flag\|icon\|([A-Z]{3})", l)
        if not m or i + 1 >= len(lines) or lines[i - 1].strip() != "|-":
            continue
        nxt = lines[i + 1]
        s = re.search(r"sortname\|([^|}]+)\|([^|}]+)", nxt)
        name = f"{s.group(1)} {s.group(2)}" if s else re.sub(r"\[\[(?:[^|\]]*\|)?([^\]]+)\]\]", r"\1",
                                                               nxt.lstrip("|")).split("(")[0].strip()
        if name:
            flags[norm(name)] = m.group(1)
    return flags


def main() -> None:
    flags = roster_flags()
    aliases = json.loads((DATA / "fighters" / "aliases.json").read_text(encoding="utf-8")).get("noms", {})
    changed = 0
    for p in sorted((DATA / "fighters").glob("*.json")):
        if p.name == "aliases.json":
            continue
        f = json.loads(p.read_text(encoding="utf-8"))
        av = f.setdefault("a_verifier", [])
        src = f.setdefault("champs_sources", {})
        touched = False
        if not f.get("pays"):
            names = [f["nom"]] + [k for k, v in aliases.items() if v == f["nom"]]
            code = next((flags[norm(n)] for n in names if norm(n) in flags), None)
            if code and code in ISO2:
                f["pays"] = ISO2[code]
                src["pays"] = LIST_URL
                av[:] = [x for x in av if x != "pays"]
                touched = True
        if not f.get("sexe") and f.get("categorie"):
            f["sexe"] = "F" if f["categorie"].endswith("_f") else "M"
            src["sexe"] = (f.get("sources") or {}).get("ufc_com") or "ufc_com (catégorie)"
            av[:] = [x for x in av if x != "sexe"]
            touched = True
        if touched:
            save_json(p, f)
            changed += 1
            print(f"{f['nom']}: pays={f.get('pays')} sexe={f.get('sexe')}")
    print(f"{changed} fiches complétées")


if __name__ == "__main__":
    main()
