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
ORIGINAL_RARITIES = load_json(DATA / "editions" / "_raretes_originales.json", {"raretes": []})["raretes"]


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

    def select(self, table: str, columns: str, filters: dict | None = None) -> list[dict]:
        out, offset = [], 0
        while True:
            r = self.s.get(f"{self.url}/rest/v1/{table}", params={"select": columns, **(filters or {})},
                           headers={"Range-Unit": "items", "Range": f"{offset}-{offset + 999}"}, timeout=60)
            if r.status_code >= 300:
                raise SystemExit(f"{table}: HTTP {r.status_code} {r.text[:300]}")
            rows = r.json()
            out += rows
            if len(rows) < 1000:
                return out
            offset += 1000

    def soft_delete(self, table: str, ids: list[str]) -> None:
        for i in range(0, len(ids), 100):
            chunk = ids[i:i + 100]
            quoted = ",".join('"' + i.replace('"', '') + '"' for i in chunk)
            r = self.s.patch(f"{self.url}/rest/v1/{table}", params={"id": f"in.({quoted})"},
                             json={"deleted": True}, headers={"Prefer": "return=minimal"}, timeout=60)
            if r.status_code >= 300:
                raise SystemExit(f"{table} (suppression): HTTP {r.status_code} {r.text[:300]}")

    def remove_files(self, paths: list[str]) -> None:
        if paths:
            self.s.delete(f"{self.url}/storage/v1/object/cartes", json={"prefixes": paths}, timeout=60)

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
        "distinctions": f.get("distinctions") or {},
        "image_id": img, "sources": f.get("sources") or {}, "champs_sources": f.get("champs_sources") or {},
        "a_verifier": f.get("a_verifier") or [], "deleted": False,
    }


def tactic_rows(e: dict, edition: dict):
    """Édition Tactique : cartes sans combattant (une par effet), une variante par rareté."""
    series, cards, variants = [], [], []
    for si, s in enumerate(e["series"]):
        sid = f"{e['id']}:{s['code']}"
        series.append({
            "id": sid, "edition_id": e["id"], "code": s["code"], "nom": s["nom"], "type": s["type"],
            "insert_type": None, "nb_cartes": len(s["cartes"]), "cote": None, "exclusivite": None, "tirage": None,
            "notes": [], "source": None, "ordre": si,
        })
        for ri, r in enumerate(e["raretes"]):
            variants.append({
                "id": f"{sid}:base" if r["rarete"] == "commune" else f"{sid}:{r['rarete']}",
                "edition_id": e["id"], "series_id": sid, "nom": r["nom"], "rarete": r["rarete"],
                "effet": r["effet"], "couleur": None, "tirage": None, "cote": None, "exclusivite": None,
                "reel": False, "eligibilite": None, "bonus_stats": 0, "coup_signature": False, "ordre": ri,
            })
        for ci, c in enumerate(s["cartes"]):
            cards.append({
                "id": f"{e['id']}:{c['numero']}", "edition_id": e["id"], "series_id": sid,
                "numero": c["numero"], "ordre": si * 10000 + ci, "fighter_ids": [],
                "nom_imprime": c["nom_imprime"], "sous_titre": None, "mentions": [], "event_id": None,
                "tactique": c["tactique"], "texte_verso": c.get("texte_verso"), "sources": [], "a_verifier": [],
            })
    for row in [edition, *series, *cards, *variants]:
        row["deleted"] = False
    return edition, series, cards, variants


def edition_rows(e: dict, known_fighters: set[str], aliases: dict, ordre: int):
    real = e["type"] == "reelle"
    edition = {
        "id": e["id"], "nom": e["nom"], "annee": e["annee"], "type": e["type"],
        "marque": e.get("marque"), "gamme": e.get("gamme"), "famille_cadre": e["famille_cadre"],
        "date_sortie": e.get("date_sortie"), "description": e.get("description"),
        "sources": e.get("sources") or [], "a_verifier": e.get("a_verifier") or [], "ordre": ordre,
    }
    if e["type"] == "tactique":
        return tactic_rows(e, edition)
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
        if not real and s["type"] == "base":
            # Raretés originales (Acier d'Octogone… Octogone Noir) sur les cartes de base d'une saison.
            for oi, r in enumerate(ORIGINAL_RARITIES, 1):
                if r["eligibilite"].get("carte"):
                    continue  # duel, événement, célébration : cartes spéciales (inserts)
                variants.append({
                    "id": f"{sid}:{r['effet']}", "edition_id": e["id"], "series_id": sid, "nom": r["nom"],
                    "rarete": r["rarete"], "effet": r["effet"], "couleur": None, "tirage": r.get("tirage"),
                    "cote": None, "exclusivite": None, "reel": False, "eligibilite": r["eligibilite"],
                    "bonus_stats": r["bonus_stats"],
                    "coup_signature": r["rarete"] in ("epique", "legendaire", "mythique"), "ordre": 100 + oi,
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
    # Réactive une ligne retirée lors d'un import précédent (identifiant réutilisé)
    for row in [edition, *series, *cards, *variants]:
        row["deleted"] = False
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
            "deleted": False,  # réactive une image retirée lors d'un import précédent
        })
    api.upsert("images", img_rows)
    # Images qui ne sont plus d'actualité (combattant sans photo libre, photo remplacée) :
    # suppression douce (répercutée sur les téléphones) + fichier retiré du stockage.
    current = {r["id"] for r in img_rows}
    stale = [r for r in api.select("images", "id,storage_path,deleted,type,importe_par")
             if r["id"] not in current and not r["deleted"] and r["type"] == "portrait" and not r["importe_par"]]
    if stale:
        api.soft_delete("images", [r["id"] for r in stale])
        if not args.sans_images:
            api.remove_files([r["storage_path"] for r in stale])
    print(f"images : {len(img_rows)}" + (f" ({len(stale)} retirées)" if stale else ""))

    # 2 bis. Photos de cartes selon la rareté (combat, célébration, ceinture)
    import_card_photos(api, known, args.sans_images)

    # 3. Combattants avec leur portrait
    api.upsert("fighters", [fighter_row(f, img_of.get(f["id"])) for f in fighters])

    # 4. Événements (Moments Historiques)
    ev_rows = []
    for p in sorted((DATA / "events").glob("*.json")):
        ev = json.loads(p.read_text(encoding="utf-8"))
        ev_rows.append({
            "id": ev["id"], "nom": ev["nom"], "date": ev.get("date"), "lieu": ev.get("lieu"), "ville": ev.get("ville"),
            "pays": ev.get("pays"), "resultat": ev.get("resultat"), "contexte": ev.get("contexte"),
            "resultats": {"fr": ev.get("resultats") or [], "contexte_en": ev.get("contexte_en"),
                          "resultat_en": ev.get("resultat_en")},
            "tirage": ev.get("tirage"), "sources": ev.get("sources") or [], "a_verifier": ev.get("a_verifier") or [],
            "deleted": False,
        })
    if ev_rows:
        api.upsert("events", ev_rows)
    print(f"événements : {len(ev_rows)}")

    # Rivalités réelles (2 combats ou plus)
    rivals = load_json(DATA / "rivalries.json", [])
    riv_rows = [{"id": r["id"], "fighter_a": r["a"], "fighter_b": r["b"], "nb_combats": r["nb_combats"],
                 "bilan": r["bilan"], "combats": r["combats"], "sources": r["sources"], "deleted": False}
                for r in rivals if r["a"] in known and r["b"] in known]
    if riv_rows:
        api.upsert("rivalries", riv_rows)
    print(f"rivalités : {len(riv_rows)}")

    # 5. Éditions, séries, variantes, cartes
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
        # Éléments retirés de l'édition (ex. carte d'un combattant qui n'a finalement pas combattu
        # cette saison) : suppression douce, répercutée sur les téléphones à la synchro.
        removed = 0
        for table, rows in (("cards", cards), ("variants", variants), ("series", series)):
            keep = {r["id"] for r in rows}
            stale = [r["id"] for r in api.select(table, "id,deleted", {"edition_id": f"eq.{e['id']}"})
                     if r["id"] not in keep and not r["deleted"]]
            if stale:
                api.soft_delete(table, stale)
                removed += len(stale)
        missing = sum(1 for c in cards if c["a_verifier"])
        print(f"{e['nom']} : {len(series)} séries, {len(variants)} variantes, {len(cards)} cartes"
              + (f" ({missing} sans fiche combattant)" if missing else "")
              + (f", {removed} élément(s) retiré(s)" if removed else ""))
    import_boosters(api)
    import_defis(api)
    import_succes(api)


def import_boosters(api: "Api") -> None:
    data = load_json(DATA / "boosters.json", {"boosters": []})["boosters"]
    editions = {p.stem for p in (DATA / "editions").glob("*.json") if not p.name.startswith("_")}
    rows = [{
        "id": b["id"], "edition_id": b["edition_id"], "nom": b["nom"], "type": b["type"],
        "nb_cartes": b["nb_cartes"], "prix_pieces": b["prix_pieces"], "en_vedette": b.get("en_vedette", False),
        "actif": b.get("actif", True), "debut": b.get("debut"), "fin": b.get("fin"), "ordre": b.get("ordre", 0),
        "visuel": b.get("visuel") or {}, "composition": b["composition"], "deleted": False,
    } for b in data if b["edition_id"] in editions]
    for b in rows:
        n = sum(s.get("nb", 1) for s in b["composition"]["slots"])
        tac = b["composition"].get("tactique")
        if tac:
            if tac.get("edition") not in editions:
                raise SystemExit(f"{b['id']} : édition Tactique inconnue ({tac.get('edition')})")
            n += tac.get("nb", 1)
        if n != b["nb_cartes"]:
            raise SystemExit(f"{b['id']} : {n} emplacements pour {b['nb_cartes']} cartes annoncées")
    if rows:
        api.upsert("booster_types", rows)
    print(f"boosters : {len(rows)}")


def import_card_photos(api: "Api", known: set[str], sans_images: bool) -> None:
    """data/images/photos.json : une entrée par photo (combattant, type,
    raretés illustrées, fichier, page source, légende). Les photos retirées du
    fichier sont désactivées en base."""
    photos = load_json(DATA / "images" / "photos.json", {"photos": []})["photos"]
    rows = []
    for ph in photos:
        path = DATA / "images" / ph["fichier"]
        if ph["fighter_id"] not in known or not path.exists() or not ph.get("raretes"):
            continue
        if not sans_images:
            api.upload(ph["fichier"], path.read_bytes(), "image/webp")
        rows.append({
            "id": image_id(ph["fichier"]), "storage_path": ph["fichier"], "type": ph["type"],
            "fighter_id": ph["fighter_id"], "raretes": ph["raretes"], "titre": ph.get("legende"),
            "auteur": ph.get("credit"), "licence": "Photo officielle (usage privé)", "licence_url": None,
            "source_url": ph.get("source_url"), "largeur": ph.get("largeur"), "hauteur": ph.get("hauteur"),
            "focal_x": 0.5, "focal_y": 0.32, "visage": None, "deleted": False,
        })
    if rows:
        api.upsert("images", rows)
    current = {r["id"] for r in rows}
    stale = [r for r in api.select("images", "id,storage_path,deleted,type,importe_par")
             if r["id"] not in current and not r["deleted"] and r["type"] in ("action", "celebration", "ceinture")
             and not r["importe_par"]]
    if stale:
        api.soft_delete("images", [r["id"] for r in stale])
    print(f"photos de cartes : {len(rows)}" + (f" ({len(stale)} retirées)" if stale else ""))


def import_defis(api: "Api") -> None:
    data = load_json(DATA / "defis.json", {"defis": []})["defis"]
    rows = [{
        "id": d["id"], "periode": d["periode"], "type": d["type"], "objectif": d["objectif"],
        "pieces": d["pieces"], "libelle": d["libelle"], "actif": d.get("actif", True),
    } for d in data]
    for d in rows:
        if d["periode"] not in ("jour", "semaine") or not d["libelle"].get("fr") or not d["libelle"].get("en"):
            raise SystemExit(f"défi invalide : {d['id']}")
    if rows:
        api.upsert("defi_modeles", rows)
    print(f"défis : {len(rows)} ({sum(r['actif'] for r in rows)} actifs)")


def import_succes(api: "Api") -> None:
    data = load_json(DATA / "succes.json", {"succes": []})["succes"]
    rows = [{
        "id": d["id"], "type": d["type"], "objectif": d["objectif"], "pieces": d["pieces"],
        "libelle": d["libelle"], "ordre": d.get("ordre", 0), "actif": d.get("actif", True),
    } for d in data]
    if rows:
        api.upsert("succes_modeles", rows)
    print(f"succès : {len(rows)}")


if __name__ == "__main__":
    sys.exit(main())
