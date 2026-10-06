#!/usr/bin/env python3
"""Classements officiels UFC (champion + 15 classés par catégorie), lus sur
ufc.com/rankings et ajoutés aux fiches combattants :

  ufc.classement = {"categorie": "mi_lourds", "rang": 3, "date": "2026-10-05"}
  (rang 0 = champion ; source dans sources.classement)

Sert à la Route vers la ceinture. Seul le bloc officiel est lu (pas le
classement livre pour livre ni le bloc « meta »). Un combattant absent de la
base est signalé, pas inventé.

  python fetch_rankings.py           # page en cache si elle existe
  python fetch_rankings.py --frais   # recharge la page (crawl-delay 15 s)
"""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json

from bs4 import BeautifulSoup

from common import CACHE, DATA, canonical, fetch, load_aliases, load_json, save_json, slugify

URL = "https://www.ufc.com/rankings"
UFC_DELAY = 15

# Intitulé de la catégorie (page en français ou en anglais) -> clé de la base
DIVISIONS = [
    ("paille", True, "paille_f"), ("strawweight", True, "paille_f"),
    ("mouche", True, "mouche_f"), ("flyweight", True, "mouche_f"),
    ("coq", True, "coq_f"), ("bantamweight", True, "coq_f"),
    ("plume", True, "plume_f"), ("featherweight", True, "plume_f"),
    ("mi-lourds", False, "mi_lourds"), ("light heavyweight", False, "mi_lourds"),
    ("mi-moyens", False, "mi_moyens"), ("welterweight", False, "mi_moyens"),
    ("moyens", False, "moyens"), ("middleweight", False, "moyens"),
    ("lourds", False, "lourds"), ("heavyweight", False, "lourds"),
    ("légers", False, "legers"), ("lightweight", False, "legers"),
    ("plume", False, "plume"), ("featherweight", False, "plume"),
    ("coq", False, "coq"), ("bantamweight", False, "coq"),
    ("mouche", False, "mouche"), ("flyweight", False, "mouche"),
]


def division_key(title: str) -> str | None:
    t = " ".join(title.lower().split())
    if "pound" in t or "livre pour livre" in t:
        return None
    feminine = "fémin" in t or "women" in t
    for word, fem, key in DIVISIONS:
        if fem == feminine and word in t:
            return key
    return None


def parse(html: str) -> dict[str, list[tuple[int, str]]]:
    """{catégorie: [(rang, nom), …]} du bloc officiel (rang 0 = champion)."""
    b = BeautifulSoup(html, "lxml")
    block = b.select_one(".block-views-blockathlete-rankings-block-1") or b
    out: dict[str, list[tuple[int, str]]] = {}
    for g in block.select(".view-grouping"):
        head = g.select_one(".view-grouping-header")
        key = division_key(head.get_text(" ", strip=True)) if head else None
        if key is None or key in out:
            continue
        rows: list[tuple[int, str]] = []
        champ = g.select_one(".rankings--athlete--champion h5 a, .rankings--athlete--champion a")
        if champ:
            rows.append((0, " ".join(champ.get_text(" ", strip=True).split())))
        for r in g.select("tbody tr"):
            rank = r.select_one(".views-field-weight-class-rank")
            a = r.select_one(".views-field-title a")
            if not a or not rank or not rank.get_text(strip=True).isdigit():
                continue
            rows.append((int(rank.get_text(strip=True)), " ".join(a.get_text(" ", strip=True).split())))
        out[key] = rows
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--frais", action="store_true", help="recharger la page au lieu du cache")
    args = ap.parse_args()

    cache_file = CACHE / "http" / f"{hashlib.sha1(URL.encode()).hexdigest()}.html"
    html = fetch(URL, delay=UFC_DELAY, cache=not args.frais)
    if not html:
        raise SystemExit("ufc.com/rankings indisponible")
    date = dt.date.fromtimestamp(cache_file.stat().st_mtime).isoformat() if cache_file.exists() else dt.date.today().isoformat()

    aliases = load_aliases()
    ranked: dict[str, dict] = {}
    missing: list[str] = []
    for key, rows in parse(html).items():
        for rang, name in rows:
            fid = slugify(canonical(name, aliases))
            if not (DATA / "fighters" / f"{fid}.json").exists():
                missing.append(f"{key} n°{rang} : {name}")
                continue
            ranked.setdefault(fid, {"categorie": key, "rang": rang, "date": date})

    changed = 0
    for path in sorted((DATA / "fighters").glob("*.json")):
        if path.name == "aliases.json":
            continue
        f = load_json(path)
        ufc = f.setdefault("ufc", {})
        before = json.dumps(ufc.get("classement"), sort_keys=True)
        if f["id"] in ranked:
            ufc["classement"] = ranked[f["id"]]
            f.setdefault("sources", {})["classement"] = URL
        else:
            ufc.pop("classement", None)
            (f.get("sources") or {}).pop("classement", None)
        if json.dumps(ufc.get("classement"), sort_keys=True) != before:
            save_json(path, f)
            changed += 1

    print(f"classements du {date} : {len(ranked)} combattants classés, {changed} fiches mises à jour")
    for m in missing:
        print(f"  absent de la base : {m}")


if __name__ == "__main__":
    main()
