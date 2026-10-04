#!/usr/bin/env python3
"""Envoie les données (JSON de data/) et les images vers Supabase.

Idempotent : on peut le relancer autant de fois que voulu (upsert sur les
identifiants). Les clés viennent du fichier .env (jamais versionné) :
SUPABASE_URL et SUPABASE_SECRET_KEY. Avec --local, on vise la pile Supabase
locale (supabase start).

Usage :
  python import_to_supabase.py            # projet cloud (.env)
  python import_to_supabase.py --local    # Supabase local (Docker)
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import uuid
from pathlib import Path

import requests
from dotenv import dotenv_values

import common  # noqa: F401  (force l'IPv4)
from common import DATA, ROOT, canonical, load_aliases, load_json, slugify
from rarity_rules import effect_for, max_rarity, parallel_rarity, series_rarity, stat_bonus

BATCH = 500


class Api:
    def __init__(self, url: str, key: str):
        self.url = url.rstrip("/")
        self.key = key
        self.s = requests.Session()
        self.s.headers["apikey"] = key
        if not key.startswith("sb_"):
            self.s.headers["Authorization"] = f"Bearer {key}"

    def upsert(self, table: str, rows: list[dict]) -> None:
        for i in range(0, len(rows), BATCH):
            chunk = rows[i:i + BATCH]
            r = self.s.post(
                f"{self.url}/rest/v1/{table}", params={"on_conflict": "id"}, json=chunk,
                headers={"Prefer": "resolution=merge-duplicates,return=minimal",
                         "Content-Type": "application/json"},
                timeout=120,
            )
            if r.status_code >= 300:
                raise SystemExit(f"{table}: HTTP {r.status_code} {r.text[:500]}")

    def upload(self, path: str, data: bytes, mime: str) -> None:
        r = self.s.post(f"{self.url}/storage/v1/object/cartes/{path}", data=data,
                        headers={"Content-Type": mime, "x-upsert": "true", "Cache-Control": "max-age=604800"},
                        timeout=120)
        if r.status_code >= 300:
            raise SystemExit(f"upload {path}: HTTP {r.status_code} {r.text[:300]}")


def credentials(local: bool) -> tuple[str, str]:
    if local:
        out = subprocess.run(["supabase", "status", "-o", "env"], cwd=ROOT, capture_output=True, text=True)
        env = dict(line.split("=", 1) for line in out.stdout.splitlines() if "=" in line)
        env = {k: v.strip('"') for k, v in env.items()}
        return env["API_URL"], env.get("SECRET_KEY") or env["SERVICE_ROLE_KEY"]
    # Le .env fait foi ; une variable d'environnement ne le remplace que si elle est non vide.
    env = dict(dotenv_values(ROOT / ".env"))
    env.update({k: v for k, v in os.environ.items() if v})
    url, key = env.get("SUPABASE_URL"), env.get("SUPABASE_SECRET_KEY")
    if not url or not key:
        raise SystemExit("SUPABASE_URL / SUPABASE_SECRET_KEY absents du .env (lance scripts/supabase_setup.sh)")
    return url, key


def image_id(storage_path: str) -> str:
    return str(uuid.uuid5(uuid.NAMESPACE_URL, f"octogone:image:{storage_path}"))


def load_fighters() -> list[dict]:
    out = []
    for p in sorted((DATA / "fighters").glob("*.json")):
        if p.name == "aliases.json":
            continue
        out.append(json.loads(p.read_text(encoding="utf-8")))
    return out


def fighter_row(f: dict, img: str | None) -> dict:
    return {
        "id": f["id"], "nom": f["nom"], "surnom": f.get("surnom"), "sexe": f.get("sexe"),
        "pays": f.get("pays"), "categorie": f.get("categorie"), "statut": f.get("statut"),
        "date_naissance": f.get("date_naissance"), "taille_cm": f.get("taille_cm"),
        "allonge_cm": f.get("allonge_cm"), "style": f.get("style"),
        "champion_actuel": bool(f.get("champion_actuel")), "ancien_champion": bool(f.get("ancien_champion")),
        "palmares": f.get("palmares") or {}, "stats_ufc": f.get("stats_ufc") or {}, "ufc": f.get("ufc") or {},
        "stats_jeu": f.get("stats_jeu") or {}, "accomplissements": f.get("accomplissements_en") or [],
        "image_id": img, "sources": f.get("sources") or {}, "champs_sources": f.get("champs_sources") or {},
        "a_verifier": f.get("a_verifier") or [],
    }


def edition_rows(e: dict, known_fighters: set[str], aliases: dict, ordre: int):
    real = e["type"] == "reelle"
    edition = {
        "id": e["id"], "nom": e["nom"], "annee": e["annee"], "type": e["type"],
        "marque": e.get("marque"), "gamme": e.get("gamme"), "famille_cadre": e["famille_cadre"],
        "date_sortie": e.get("date_sortie"), "description": e.get("description"),
        "sources": e.get("sources") or [], "a_verifier": e.get("a_verifier") or [], "ordre": ordre,
    }
    series, cards, variants = [], [], []
    for si, s in enumerate(e["series"]):
        sid = f"{e['id']}:{s['code']}"
        series.append({
            "id": sid, "edition_id": e["id"], "code": s["code"], "nom": s["nom"], "type": s["type"],
            "insert_type": s.get("insert_type"), "nb_cartes": s.get("nb_cartes"), "cote": s.get("cote"),
            "exclusivite": s.get("exclusivite"), "tirage": s.get("tirage"), "notes": s.get("notes") or [],
            "source": s.get("source"), "ordre": si,
        })
        base_r = series_rarity(s)
        variants.append({
            "id": f"{sid}:base", "edition_id": e["id"], "series_id": sid,
            "nom": "Base" if not s.get("tirage") else f"Base /{s['tirage']}",
            "rarete": base_r, "effet": "base", "couleur": None, "tirage": s.get("tirage"),
            "cote": s.get("cote"), "exclusivite": s.get("exclusivite"), "reel": real,
            "eligibilite": None, "bonus_stats": stat_bonus(base_r),
            "coup_signature": base_r in ("epique", "legendaire", "mythique"), "ordre": 0,
        })
        for pi, par in enumerate(s.get("paralleles") or [], 1):
            r = max_rarity(base_r, parallel_rarity(par.get("tirage")))
            effet, couleur = effect_for(par["nom"])
            variants.append({
                "id": f"{sid}:{slugify(par['nom'])}", "edition_id": e["id"], "series_id": sid,
                "nom": par["nom"], "rarete": r, "effet": effet, "couleur": couleur, "tirage": par.get("tirage"),
                "cote": par.get("cote"), "exclusivite": par.get("exclusivite"), "reel": real,
                "eligibilite": None, "bonus_stats": stat_bonus(r),
                "coup_signature": r in ("epique", "legendaire", "mythique"), "ordre": pi,
            })
        for ci, c in enumerate(s["cartes"]):
            ids = c.get("combattants") or [slugify(canonical(c["nom_imprime"], aliases))]
            missing = [i for i in ids if i not in known_fighters]
            cards.append({
                "id": f"{e['id']}:{c['numero']}", "edition_id": e["id"], "series_id": sid,
                "numero": c["numero"], "ordre": si * 10000 + ci, "fighter_ids": ids,
                "nom_imprime": c["nom_imprime"], "sous_titre": c.get("sous_titre"),
                "mentions": c.get("mentions") or [], "event_id": c.get("event_id"),
                "sources": [s["source"]] if s.get("source") else [],
                "a_verifier": [f"combattant absent : {m}" for m in missing],
            })
    return edition, series, cards, variants


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--local", action="store_true")
    ap.add_argument("--sans-images", action="store_true")
    args = ap.parse_args()
    api = Api(*credentials(args.local))
    aliases = load_aliases()

    fighters = load_fighters()
    known = {f["id"] for f in fighters}
    credits = load_json(DATA / "images" / "credits.json", {})

    # 1. Combattants (sans image : les images référencent les combattants)
    api.upsert("fighters", [fighter_row(f, None) for f in fighters])
    print(f"combattants : {len(fighters)}")

    # 2. Images (fichier + attribution)
    img_rows, img_of = [], {}
    for fid, c in credits.items():
        if fid not in known:
            continue
        path = DATA / "images" / c["fichier"]
        if not path.exists():
            continue
        if not args.sans_images:
            api.upload(c["fichier"], path.read_bytes(), "image/webp")
        iid = image_id(c["fichier"])
        img_of[fid] = iid
        img_rows.append({
            "id": iid, "storage_path": c["fichier"], "type": "portrait", "fighter_id": fid,
            "titre": c.get("titre"), "auteur": c.get("auteur"), "licence": c.get("licence"),
            "licence_url": c.get("licence_url"), "source_url": c.get("source_url"),
            "largeur": c.get("largeur"), "hauteur": c.get("hauteur"),
            "focal_x": c.get("focal_x"), "focal_y": c.get("focal_y"), "visage": c.get("visage"),
        })
    api.upsert("images", img_rows)
    print(f"images : {len(img_rows)}")

    # 3. Combattants avec leur portrait
    api.upsert("fighters", [fighter_row(f, img_of.get(f["id"])) for f in fighters])

    # 4. Éditions, séries, variantes, cartes
    eds = sorted((DATA / "editions").glob("*.json"))
    for i, p in enumerate(eds):
        if p.name.startswith("_"):
            continue
        e = json.loads(p.read_text(encoding="utf-8"))
        edition, series, cards, variants = edition_rows(e, known, aliases, i)
        api.upsert("editions", [edition])
        api.upsert("series", series)
        api.upsert("variants", variants)
        api.upsert("cards", cards)
        missing = sum(1 for c in cards if c["a_verifier"])
        print(f"{e['nom']} : {len(series)} séries, {len(variants)} variantes, {len(cards)} cartes"
              + (f" ({missing} sans fiche combattant)" if missing else ""))


if __name__ == "__main__":
    sys.exit(main())
