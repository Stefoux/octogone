#!/usr/bin/env python3
"""Photos des combattants depuis Wikimedia Commons (licences libres uniquement).

Pour chaque combattant de data/fighters :
  1. image candidate : propriété P18 de Wikidata, sinon image principale de
     l'article Wikipedia si elle est libre ;
  2. métadonnées Commons : auteur, licence, URL d'origine ; on refuse toute
     image non libre (fair use) ou sans licence identifiable ;
  3. détection du visage (OpenCV, cascades de Haar fournies avec la
     bibliothèque) puis recadrage portrait 3:4 « tête et buste » ;
  4. export WebP (720×960 max) dans data/images/fighters/<id>.webp et
     attribution dans data/images/credits.json.

Sans visage détecté : recadrage centré en haut de l'image (marqué dans les
crédits). Sans image libre : la carte affichera la silhouette par défaut.

Usage : python fetch_images.py [--force] [--ids jon-jones alex-pereira]
"""
from __future__ import annotations

import argparse
import io
import json
import re
from html import unescape

import cv2
import numpy as np
import requests
from PIL import Image

from common import DATA, WIKI_UA, fetch, load_json, save_json

FIGHTERS = DATA / "fighters"
OUT = DATA / "images" / "fighters"
CREDITS = DATA / "images" / "credits.json"
COMMONS_API = "https://commons.wikimedia.org/w/api.php"
FREE = re.compile(r"(CC0|Public domain|PD[- ]|CC BY(-SA)?|GFDL|Attribution|No restrictions)", re.I)
MAX_W, MAX_H = 720, 960


def strip_html(s: str | None) -> str | None:
    if not s:
        return None
    s = re.sub(r"<[^>]+>", "", s)
    s = unescape(" ".join(s.split()))
    return s or None


def commons_info(filename: str) -> dict | None:
    title = filename if filename.startswith("File:") else f"File:{filename}"
    txt = fetch(COMMONS_API, ua=WIKI_UA, delay=0.5, params={
        "action": "query", "titles": title, "prop": "imageinfo", "format": "json", "formatversion": 2,
        "iiprop": "url|extmetadata|size|mime", "iiurlwidth": 800,
    })
    if not txt:
        return None
    pages = json.loads(txt).get("query", {}).get("pages", [])
    if not pages or "imageinfo" not in pages[0]:
        return None
    info = pages[0]["imageinfo"][0]
    meta = {k: v.get("value") for k, v in info.get("extmetadata", {}).items()}
    return {
        "titre": pages[0]["title"],
        "thumb": info.get("thumburl") or info.get("url"),
        "source_url": info.get("descriptionurl"),
        "mime": info.get("mime"),
        "auteur": strip_html(meta.get("Artist")) or strip_html(meta.get("Credit")),
        "licence": strip_html(meta.get("LicenseShortName")),
        "licence_url": meta.get("LicenseUrl"),
        "non_libre": str(meta.get("NonFree", "")).lower() == "true",
        "conditions": strip_html(meta.get("UsageTerms")),
    }


def wiki_page_image(title: str) -> str | None:
    txt = fetch("https://en.wikipedia.org/w/api.php", ua=WIKI_UA, delay=0.5, params={
        "action": "query", "titles": title, "prop": "pageprops", "format": "json", "formatversion": 2,
    })
    if not txt:
        return None
    pages = json.loads(txt).get("query", {}).get("pages", [])
    return pages[0].get("pageprops", {}).get("page_image_free") if pages else None


_cascades = None


def detect_face(img: np.ndarray) -> tuple[int, int, int, int] | None:
    """Plus grand visage détecté (x, y, w, h) en pixels, ou None."""
    global _cascades
    if _cascades is None:
        _cascades = [cv2.CascadeClassifier(cv2.data.haarcascades + n) for n in
                     ("haarcascade_frontalface_default.xml", "haarcascade_frontalface_alt2.xml",
                      "haarcascade_profileface.xml")]
    gray = cv2.cvtColor(img, cv2.COLOR_RGB2GRAY)
    gray = cv2.equalizeHist(gray)
    h, w = gray.shape
    min_side = max(24, int(min(w, h) * 0.06))
    found = []
    for c in _cascades:
        faces = c.detectMultiScale(gray, scaleFactor=1.08, minNeighbors=6, minSize=(min_side, min_side))
        found.extend(tuple(int(v) for v in f) for f in faces)
    if not found:
        return None
    # Le plus grand visage, situé de préférence dans la moitié haute.
    found.sort(key=lambda f: (f[2] * f[3]) * (1.0 if f[1] < h * 0.6 else 0.5), reverse=True)
    return found[0]


def bust_crop(img: np.ndarray, face: tuple[int, int, int, int] | None) -> tuple[int, int, int, int]:
    """Fenêtre 3:4 : visage ≈ 28 % de la hauteur, yeux vers le tiers haut."""
    h, w = img.shape[:2]
    if face:
        fx, fy, fw, fh = face
        crop_h = min(h, int(fh / 0.28))
        crop_w = int(crop_h * 3 / 4)
        if crop_w > w:
            crop_w = w
            crop_h = min(h, int(crop_w * 4 / 3))
        cx = fx + fw / 2
        top = int(fy + fh * 0.45 - crop_h * 0.33)
        left = int(cx - crop_w / 2)
    else:
        crop_w = min(w, int(h * 3 / 4))
        crop_h = min(h, int(crop_w * 4 / 3))
        left = (w - crop_w) // 2
        top = 0
    left = max(0, min(left, w - crop_w))
    top = max(0, min(top, h - crop_h))
    return left, top, crop_w, crop_h


def process(fighter: dict, force: bool) -> dict | None:
    fid = fighter["id"]
    out_path = OUT / f"{fid}.webp"
    candidates = [fighter.get("image_commons")]
    if fighter.get("wikipedia_titre"):
        candidates.append(wiki_page_image(fighter["wikipedia_titre"]))
    for cand in [c for c in dict.fromkeys(candidates) if c]:
        info = commons_info(cand)
        if not info or not info["thumb"]:
            continue
        if info["non_libre"] or not info["licence"] or not FREE.search(info["licence"]):
            continue
        if out_path.exists() and not force:
            raw = None
        else:
            r = requests.get(info["thumb"], headers={"User-Agent": WIKI_UA}, timeout=60)
            if r.status_code != 200:
                continue
            raw = r.content
        if raw is not None:
            pil = Image.open(io.BytesIO(raw)).convert("RGB")
            arr = np.array(pil)
            face = detect_face(arr)
            left, top, cw, ch = bust_crop(arr, face)
            crop = pil.crop((left, top, left + cw, top + ch))
            crop.thumbnail((MAX_W, MAX_H), Image.LANCZOS)
            OUT.mkdir(parents=True, exist_ok=True)
            crop.save(out_path, "WEBP", quality=80, method=6)
            visage = None
            if face:
                fx, fy, fw, fh = face
                visage = {"x": round((fx - left) / cw, 4), "y": round((fy - top) / ch, 4),
                          "w": round(fw / cw, 4), "h": round(fh / ch, 4)}
            focal = ((visage["x"] + visage["w"] / 2, visage["y"] + visage["h"] / 2) if visage else (0.5, 0.35))
            meta = {
                "fichier": f"fighters/{fid}.webp",
                "largeur": crop.width, "hauteur": crop.height,
                "focal_x": round(min(max(focal[0], 0), 1), 4), "focal_y": round(min(max(focal[1], 0), 1), 4),
                "visage": visage,
                "recadrage": "visage" if face else "centre_haut",
            }
        else:
            meta = load_json(CREDITS, {}).get(fid, {})
        meta.update({
            "fighter_id": fid,
            "titre": info["titre"], "auteur": info["auteur"], "licence": info["licence"],
            "licence_url": info["licence_url"], "source_url": info["source_url"],
        })
        if not info["auteur"]:
            meta["a_verifier"] = ["auteur"]
        return meta
    return None


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--ids", nargs="*")
    args = ap.parse_args()
    credits = load_json(CREDITS, {})
    files = sorted(p for p in FIGHTERS.glob("*.json") if p.name != "aliases.json")
    stats = {"ok": 0, "sans_image": 0, "visage": 0}
    for p in files:
        f = json.loads(p.read_text(encoding="utf-8"))
        if args.ids and f["id"] not in args.ids:
            continue
        if f["id"] in credits and not args.force and (OUT / f"{f['id']}.webp").exists():
            stats["ok"] += 1
            stats["visage"] += credits[f["id"]].get("recadrage") == "visage"
            continue
        try:
            meta = process(f, args.force)
        except Exception as exc:  # une image ratée ne bloque pas les autres
            print(f"{f['id']}: ERREUR {exc!r}")
            meta = None
        if meta:
            credits[f["id"]] = meta
            stats["ok"] += 1
            stats["visage"] += meta.get("recadrage") == "visage"
            print(f"{f['id']}: {meta['licence']} — {meta.get('auteur') or '?'} ({meta.get('recadrage')})", flush=True)
        else:
            credits.pop(f["id"], None)
            stats["sans_image"] += 1
            print(f"{f['id']}: aucune image libre -> silhouette", flush=True)
        save_json(CREDITS, credits)
    print(f"\nImages : {stats['ok']} (dont {stats['visage']} recadrées sur le visage), "
          f"sans image libre : {stats['sans_image']}")


if __name__ == "__main__":
    main()
