#!/usr/bin/env python3
"""Photos de cartes selon la rareté : combat, célébration, ceinture.

Source : les articles de ufc.com (résultats d'événements, actualités), dont
chaque photo a une légende d'agence qui nomme le combattant et décrit la
scène (« X of France kicks Y… », « X celebrates his victory… », « X poses
with the championship belt… »). Usage privé : photos officielles.

Vérifications pour chaque photo retenue :
  1. la légende nomme le combattant comme sujet de la phrase ;
  2. le type (combat, célébration, ceinture) se lit dans la légende ;
  3. son visage est retrouvé sur la photo (reconnaissance faciale contre une
     photo de référence du même combattant) : c'est aussi lui qu'on centre ;
  4. résolution suffisante ; les photos à filigrane sont écartées à la revue
     visuelle (planches de contrôle), jamais retouchées.
Recadrage au format de la carte (0,70), WebP compressé.

Sortie : data/images/photos/<id>-<type>.webp + data/images/photos.json.

    .venv/bin/python fetch_photos.py --combattants alex-pereira benoit-saint-denis
    .venv/bin/python fetch_photos.py --tous
"""
from __future__ import annotations

import argparse
import io
import json
import re
import unicodedata
from dataclasses import dataclass, field
from pathlib import Path

import cv2
import numpy as np
import requests
from bs4 import BeautifulSoup
from PIL import Image

from common import BROWSER_UA, CACHE, DATA, fetch

UFC = "https://www.ufc.com"
UFC_DELAY = 15.0  # crawl-delay de ufc.com/robots.txt
OUT = DATA / "images" / "photos"
META = DATA / "images" / "photos.json"
MODELS = CACHE / "models"
CARD_ASPECT = 0.70  # largeur / hauteur de la zone photo d'une carte
OUT_W, OUT_H = 700, 1000
MIN_SIDE = 600  # côté minimal (px) de la zone recadrée avant redimensionnement
FACE_MATCH = 0.36  # seuil de similarité (cosinus SFace) pour « même personne »
FACE_MATCH_NAMED = 0.28  # seuil quand la légende nomme le combattant et que ce visage se détache des autres
FACE_MARGIN = 0.08
MIN_FACE = 0.07  # hauteur minimale du visage, en part de la hauteur du cadre

RARETES_COMBAT = ["commune", "peu_commune", "rare", "epique"]

# --- Légendes ------------------------------------------------------------------

ACTION = re.compile(
    r"\b(punch(es)?|kicks?|knees?|elbows?|strikes?|lands?|throws?|takes? down|takedown|grapples?|"
    r"attempts?|secures?|controls?|battles?|chokes?|submits?|slams?|clinch(es)?|wrestles?|"
    r"defends?|escapes?|dodges?|blocks?|trades?|exchanges?|works for|goes for|swings?)\b", re.I)
CELEBRATION = re.compile(r"\b(celebrat\w*|victory|win\b|wins\b|defeat(ing|s)\b|is declared the winner|"
                         r"has (his|her) hand raised|knock(ing|s)? out\b|knockout (over|against|of)\b|"
                         r"submitting|submits\b|stopping\b|TKO (over|against|of)\b)", re.I)
LOSS = re.compile(r"\b(loss|loses|lost|defeated by|after (his|her) defeat)\b", re.I)
BELT = re.compile(r"\b(belt|championship title|title belt)\b", re.I)
BELT_SCENE = re.compile(r"\b(poses?|celebrat\w*|holds?|is (presented|awarded)|receives?|with (the|his|her))\b", re.I)
EXCLUDE = re.compile(r"\b(weighs? in|weigh-in|faces? off|face-?off|press conference|media day|portrait|"
                     r"warms? up|walks? (out|to the octagon)|enters the octagon|prepares?|interview\w*|"
                     r"open workout|ceremonial|backstage|arrives?|fans?|meet and greet|stares?|staredown|"
                     r"touch(es)? gloves|listens?|speaks?|trains?|training|shown|side by side|hugs?|embrace\w*)\b", re.I)


def norm(s: str) -> str:
    s = "".join(c for c in unicodedata.normalize("NFKD", s) if not unicodedata.combining(c))
    return re.sub(r"[^a-z0-9 ]", " ", s.lower().replace("’", "'").replace("-", " ")).strip()


def subject_is(caption: str, names: list[str]) -> bool:
    """Le combattant est le SUJET de la légende : son nom ouvre la phrase
    (avant le premier verbe), pas seulement cité comme adversaire."""
    c = norm(caption)
    for n in names:
        nn = norm(n)
        if not nn:
            continue
        m = re.match(rf"^(ufc \w+ )?(champion |contender )?{re.escape(nn)}\b(.*)$", c)
        if m:
            rest = m.group(3).strip()
            # « X and Y celebrate… » : deux sujets, la photo n'est pas la sienne seule
            return not rest.startswith("and ")
    return False


def classify(caption: str) -> str | None:
    """« ceinture », « celebration », « action » ou None si la scène ne convient pas.
    Seules les légendes d'agence complètes (« … during the UFC … event … ») sont
    retenues : un texte alternatif vague ne prouve ni la scène ni le sujet."""
    if not caption or EXCLUDE.search(caption) or not re.search(r"\bduring\b.*\bUFC\b|\bUFC\b.*\bevent\b", caption):
        return None
    if BELT.search(caption) and BELT_SCENE.search(caption) and not re.search(r"\bBMF\b", caption):
        return "ceinture"  # ceinture de champion UFC (pas la ceinture BMF)
    if CELEBRATION.search(caption) and not LOSS.search(caption):
        return "celebration"
    if ACTION.search(caption) and re.search(r"\bfight\b|\bbout\b|\bround\b|\boctagon\b", caption, re.I):
        return "action"
    return None


# --- Articles ufc.com --------------------------------------------------------------

@dataclass
class Candidate:
    image_url: str
    caption: str
    source_url: str
    type: str
    credit: str | None = None


def article_photos(url: str) -> list[tuple[str, str, str | None]]:
    """(url image, légende, crédit) pour chaque photo légendée d'un article."""
    page = fetch(url, delay=UFC_DELAY)
    if not page:
        return []
    b = BeautifulSoup(page, "lxml")
    out = []
    for img in b.select("img"):
        src = img.get("data-src") or img.get("src") or ""
        if not src or "/images/" not in src or src.endswith(".svg"):
            continue
        caption = ""
        fig = img.find_parent(["figure", "div"], class_=re.compile(r"media|image|figure|gallery|caption", re.I))
        for holder in (img.find_parent("figure"), fig):
            if holder is None:
                continue
            cap = holder.select_one("figcaption, .field--name-field-media-caption, .c-caption, [class*=caption]")
            if cap and len(cap.get_text(" ", strip=True)) > 30:
                caption = " ".join(cap.get_text(" ", strip=True).split())
                break
        if not caption:
            caption = " ".join((img.get("alt") or img.get("title") or "").split())
        if len(caption) < 30:
            continue
        credit = None
        m = re.search(r"\((?:Photo by )?([^)]*Zuffa[^)]*)\)", caption)
        if m:
            credit = m.group(1)
        url = largest(src)
        if PROMO.search(url) and not re.search(r"getty", url, re.I):
            continue  # affiche ou visuel promo : la légende voisine ne la décrit pas
        out.append((url, caption, credit))
    return out


PROMO = re.compile(r"1200x1200|_ENG_|poster|EVENT-ART|key-?art|_SG_|thumbnail", re.I)


def largest(src: str) -> str:
    """Version la plus grande d'une image ufc.com (sans le style de redimensionnement)."""
    if src.startswith("/"):
        src = UFC + src
    return re.sub(r"/images/styles/[^/]+/s3/", "/images/", src).split("?")[0]


# --- Wikimedia Commons (seconde source, photos libres) -------------------------------

COMMONS_API = "https://commons.wikimedia.org/w/api.php"
# Commons : descriptions libres, donc règles strictes. « Ultimate Fighting
# Championship », « Fight Night », « World Tour »… ne prouvent pas une scène
# de combat ; on les retire avant d'analyser.
C_NOISE = re.compile(r"ultimate fighting championship|fight night|world tour|fight club|fighter|fighters", re.I)
C_ACTION = re.compile(r"\b(punch\w*|kick\w*|strik(es|ing)|takedown|grappl\w*|in action|knee\w*|elbow\w*|"
                      r"submission attempt|ground and pound)\b", re.I)
C_CELEBRATION = re.compile(r"\b(celebrat\w*|hand raised|declared the winner)\b", re.I)
C_BELT = re.compile(r"\b(belt|title)\b", re.I)
C_EXCLUDE = re.compile(r"\b(weigh\w*|press|portrait|workout|face ?off|media|signing|autograph\w*|meet|fans?|seminar|"
                       r"interview|headshot|training|trains|gym|award|red carpet|premiere|poses?|posing|visit\w*|"
                       r"camp|base|troops|marines?|army|navy|oval office|white house|foyer|tour|before|after the|"
                       r"backstage|arriv\w*|ceremony|conference|event poster|promo\w*)\b", re.I)


def classify_commons(text: str) -> str | None:
    if not text:
        return None
    clean = C_NOISE.sub(" ", text)
    if C_EXCLUDE.search(clean):
        return None
    if C_BELT.search(clean) and re.search(r"\bchampion|\bbelt\b", clean, re.I) and C_CELEBRATION.search(clean):
        return "ceinture"
    if C_CELEBRATION.search(clean):
        return "celebration"
    if C_ACTION.search(clean):
        return "action"
    return None


def commons_candidates(f: dict) -> list[tuple[str, str, str, dict]]:
    """(url vignette, description, page Commons, crédit) des fichiers Commons qui
    citent le combattant et l'UFC."""
    from fetch_images import strip_html
    from common import WIKI_UA
    txt = fetch(COMMONS_API, ua=WIKI_UA, delay=0.5, params={
        "action": "query", "generator": "search", "gsrnamespace": 6, "gsrlimit": 40,
        "gsrsearch": f'"{f["nom"]}" UFC', "prop": "imageinfo", "iiprop": "url|extmetadata|size|mime",
        "iiurlwidth": 1400, "format": "json", "formatversion": 2,
    })
    if not txt:
        return []
    out = []
    for page in json.loads(txt).get("query", {}).get("pages", []):
        info = (page.get("imageinfo") or [{}])[0]
        if not info.get("mime", "").startswith("image/") or info.get("mime") == "image/svg+xml":
            continue
        meta = {k: v.get("value") for k, v in info.get("extmetadata", {}).items()}
        desc = " ".join(filter(None, [page["title"], strip_html(meta.get("ImageDescription")), strip_html(meta.get("ObjectName"))]))
        credit = {"auteur": strip_html(meta.get("Artist")), "licence": strip_html(meta.get("LicenseShortName"))}
        out.append((info.get("thumburl") or info.get("url"), desc, info.get("descriptionurl"), credit))
    return out


def try_commons(f: dict, wanted: list[str], ref: np.ndarray, res: Result) -> None:
    from fetch_images import download as commons_download
    names = [norm(n) for n in names_of(f)]
    for url, desc, page, credit in commons_candidates(f):
        if all(t in res.photos for t in wanted):
            return
        kind = classify_commons(desc)
        if kind not in wanted or kind in res.photos or not any(n in norm(desc) for n in names):
            continue
        try:
            data = commons_download(url)
        except Exception:
            continue
        img = decode(data) if data else None
        if img is None:
            continue
        fs = faces(img)
        scored = sorted(((similarity(ref, e), b) for b, e in fs), key=lambda x: -x[0])
        if not scored or scored[0][0] < FACE_MATCH:  # légende moins fiable : seuil strict
            res.rejected.append(f"{kind} (Commons): visage non reconnu")
            continue
        crop = crop_card(img, scored[0][1], [b for _, b in scored[1:]])
        if crop is None or scored[0][1][3] < crop.shape[0] * MIN_FACE:
            res.rejected.append(f"{kind} (Commons): résolution insuffisante ou combattant trop loin")
            continue
        fichier = f"photos/{f['id']}-{kind}.webp"
        w, h = save_webp(crop, DATA / "images" / fichier)
        res.photos[kind] = {
            "fighter_id": f["id"], "type": kind, "fichier": fichier, "largeur": w, "hauteur": h,
            "source_url": page, "image_url": url, "legende": desc,
            "credit": " · ".join(filter(None, [credit.get("auteur"), credit.get("licence")])) or None,
            "similarite": round(scored[0][0], 3), "original": [int(img.shape[1]), int(img.shape[0])],
        }


# --- Visages ------------------------------------------------------------------------

_det = None
_rec = None


def _models():
    global _det, _rec
    if _det is None:
        _det = cv2.FaceDetectorYN.create(str(MODELS / "yunet.onnx"), "", (320, 320), 0.75, 0.3, 5000)
        _rec = cv2.FaceRecognizerSF.create(str(MODELS / "sface.onnx"), "")
    return _det, _rec


def faces(img: np.ndarray) -> list[tuple[np.ndarray, np.ndarray]]:
    """[(boîte yunet, embedding)] pour chaque visage détecté."""
    det, rec = _models()
    h, w = img.shape[:2]
    det.setInputSize((w, h))
    _, found = det.detect(img)
    if found is None:
        return []
    return [(f, rec.feature(rec.alignCrop(img, f))) for f in found]


def similarity(a: np.ndarray, b: np.ndarray) -> float:
    _, rec = _models()
    return float(rec.match(a, b, cv2.FaceRecognizerSF_FR_COSINE))


def decode(data: bytes) -> np.ndarray | None:
    arr = np.frombuffer(data, np.uint8)
    return cv2.imdecode(arr, cv2.IMREAD_COLOR)


# --- Recadrage ----------------------------------------------------------------------

def crop_card(img: np.ndarray, face_box: np.ndarray, others: list[np.ndarray]) -> np.ndarray | None:
    """Recadre au format de la carte, le combattant centré (et l'adversaire
    gardé dans le cadre quand c'est possible). None si trop petit."""
    h, w = img.shape[:2]
    ch = h
    cw = int(round(ch * CARD_ASPECT))
    if cw > w:
        cw = w
        ch = int(round(cw / CARD_ASPECT))
    if min(cw, ch) < MIN_SIDE * CARD_ASPECT:
        return None
    fx = face_box[0] + face_box[2] / 2
    fy = face_box[1] + face_box[3] / 2
    # Inclure l'adversaire si les deux visages tiennent dans la largeur
    cx = fx
    if others:
        ox = min(others, key=lambda o: abs((o[0] + o[2] / 2) - fx))
        ocx = ox[0] + ox[2] / 2
        if abs(ocx - fx) + face_box[2] < cw * 0.8:
            cx = (fx + ocx) / 2
    x0 = int(np.clip(cx - cw / 2, 0, w - cw))
    # Visage dans le tiers supérieur
    y0 = int(np.clip(fy - ch * 0.32, 0, h - ch))
    return img[y0:y0 + ch, x0:x0 + cw]


def save_webp(img: np.ndarray, path: Path) -> tuple[int, int]:
    rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    im = Image.fromarray(rgb).resize((OUT_W, OUT_H), Image.LANCZOS)
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path, "WEBP", quality=78, method=6)
    return im.size


# --- Téléchargement -------------------------------------------------------------------

def download(url: str) -> bytes | None:
    key = re.sub(r"[^a-zA-Z0-9]+", "_", url)[-180:]
    path = CACHE / "photos" / key
    if path.exists():
        return path.read_bytes()
    import time
    from common import _last_hit  # même politesse que fetch() : un accès toutes les 15 s
    domain = re.sub(r"^https?://([^/]+).*$", r"\1", url)
    wait = UFC_DELAY - (time.time() - _last_hit.get(domain, 0))
    if wait > 0:
        time.sleep(wait)
    try:
        r = requests.get(url, headers={"User-Agent": BROWSER_UA}, timeout=60)
        _last_hit[domain] = time.time()
        if r.status_code != 200 or not r.headers.get("content-type", "").startswith("image"):
            return None
    except requests.RequestException:
        return None
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(r.content)
    return r.content


# --- Collecte par combattant ----------------------------------------------------------

def load_fighters() -> dict[str, dict]:
    out = {}
    for p in sorted((DATA / "fighters").glob("*.json")):
        if p.name == "aliases.json":
            continue
        f = json.loads(p.read_text(encoding="utf-8"))
        out[f["id"]] = f
    return out


def names_of(f: dict) -> list[str]:
    aliases = json.loads((DATA / "fighters" / "aliases.json").read_text(encoding="utf-8")).get("noms", {})
    names = {f["nom"]} | {k for k, v in aliases.items() if v == f["nom"]}
    return sorted(names, key=len, reverse=True)


def ever_champion(f: dict) -> bool:
    """Déjà champion UFC (en titre, ancien, ou titre UFC dans les distinctions
    sourcées de Wikipedia)."""
    if f.get("champion_actuel") or f.get("ancien_champion"):
        return True
    return any(re.search(r"\bUFC [A-Za-z' ]*Champion\b", d) for d in (f.get("distinctions") or {}).get("en", []))


def athlete_page(f: dict) -> str | None:
    slug = f.get("ufc_slug")
    if not slug:
        m = re.search(r"/athlete/([^/?#]+)", (f.get("sources") or {}).get("ufc_com") or "")
        slug = m.group(1) if m else None
    return fetch(f"{UFC}/athlete/{slug}", delay=UFC_DELAY) if slug else None


def article_links(page: str) -> list[str]:
    """Sources de photos d'une fiche ufc.com : galeries des derniers
    événements du combattant (via la page de chaque événement), puis les
    articles qui le concernent."""
    b = BeautifulSoup(page, "lxml")
    events, news = [], []
    for a in b.select("a[href]"):
        h = a["href"].split("?")[0].split("#")[0]
        if h.startswith(UFC):
            h = h[len(UFC):]
        if h.startswith("/event/") and h not in events:
            events.append(h)
        elif h.startswith("/news/") and h not in news:
            news.append(h)
    out = []
    for ev in events:
        ev_page = fetch(UFC + ev, delay=UFC_DELAY) or ""
        for g in re.findall(r'href="(/gallery/[^"#?]+)"', ev_page):
            if UFC + g not in out:
                out.append(UFC + g)
    return out + [UFC + h for h in news]


def reference_face(f: dict, page: str | None) -> np.ndarray | None:
    """Visage de référence : d'abord le portrait libre déjà dans le projet (aucun
    accès réseau), sinon la photo officielle de la fiche ufc.com."""
    local = DATA / "images" / "fighters" / f"{f['id']}.webp"
    if local.exists():
        img = cv2.imread(str(local))
        fs = faces(img) if img is not None else []
        if fs:
            return max(fs, key=lambda x: x[0][2] * x[0][3])[1]
    if page:
        b = BeautifulSoup(page, "lxml")
        for img_tag in b.select("img"):
            src = img_tag.get("src") or ""
            if "athlete_bio_full_body" in src or "headshot" in src:
                data = download(src if src.startswith("http") else UFC + src)
                img = decode(data) if data else None
                fs = faces(img) if img is not None else []
                if fs:
                    return max(fs, key=lambda x: x[0][2] * x[0][3])[1]
                break
    return None


@dataclass
class Result:
    fighter_id: str
    photos: dict = field(default_factory=dict)  # type -> entrée photos.json
    rejected: list = field(default_factory=list)


def process(f: dict, max_pages: int = 6, skip: set[str] | None = None) -> Result:
    res = Result(f["id"])
    page = athlete_page(f)
    ref = reference_face(f, page)
    if ref is None:
        res.rejected.append("aucun visage de référence (ni fiche ufc.com ni portrait)")
        return res
    names = names_of(f)
    wanted = ["action", "celebration"] + (["ceinture"] if ever_champion(f) else [])
    wanted = [w for w in wanted if w not in (skip or set())]
    if not wanted:
        return res
    if not page:
        res.rejected.append("fiche ufc.com introuvable : Commons seulement")
        try_commons(f, wanted, ref, res)
        return res
    seen: set[str] = set()
    base = page_url(f)
    for n in range(max_pages):
        if all(t in res.photos for t in wanted):
            break
        p = page if n == 0 else fetch(f"{base}?page={n}", delay=UFC_DELAY)
        if not p:
            break
        sources = [u for u in article_links(p) if u not in seen]
        if n > 0 and not sources:
            break
        for url in sources:
            seen.add(url)
            if all(t in res.photos for t in wanted):
                break
            for img_url, caption, credit in article_photos(url):
                kind = classify(caption)
                if kind not in wanted or kind in res.photos or not subject_is(caption, names):
                    continue
                entry = try_photo(f, kind, img_url, caption, credit, url, ref, res)
                if entry:
                    res.photos[kind] = entry
    if not all(t in res.photos for t in wanted):
        try_commons(f, wanted, ref, res)
    return res


def page_url(f: dict) -> str:
    slug = f.get("ufc_slug")
    if not slug:
        m = re.search(r"/athlete/([^/?#]+)", (f.get("sources") or {}).get("ufc_com") or "")
        slug = m.group(1) if m else ""
    return f"{UFC}/athlete/{slug}"


REJECTED = DATA / "images" / "photos_refusees.json"


def rejected_urls() -> set[str]:
    return set(json.loads(REJECTED.read_text(encoding="utf-8"))["images"]) if REJECTED.exists() else set()


def try_photo(f: dict, kind: str, img_url: str, caption: str, credit: str | None, url: str,
              ref: np.ndarray, res: Result) -> dict | None:
    if img_url in rejected_urls():
        res.rejected.append(f"{kind}: refusée à la revue visuelle")
        return None
    data = download(img_url)
    img = decode(data) if data else None
    if img is None:
        res.rejected.append(f"{kind}: image illisible {img_url}")
        return None
    fs = faces(img)
    scored = sorted(((similarity(ref, e), b) for b, e in fs), key=lambda x: -x[0])
    ok = bool(scored) and (
        scored[0][0] >= FACE_MATCH
        or (scored[0][0] >= FACE_MATCH_NAMED and (len(scored) == 1 or scored[0][0] - scored[1][0] >= FACE_MARGIN)))
    if not ok:
        res.rejected.append(f"{kind}: visage non reconnu ({scored[0][0]:.2f})" if scored else f"{kind}: aucun visage")
        return None
    crop = crop_card(img, scored[0][1], [b for _, b in scored[1:]])
    if crop is None:
        res.rejected.append(f"{kind}: résolution insuffisante ({img.shape[1]}×{img.shape[0]})")
        return None
    if scored[0][1][3] < crop.shape[0] * MIN_FACE:
        res.rejected.append(f"{kind}: combattant trop loin dans l'image")
        return None
    fichier = f"photos/{f['id']}-{kind}.webp"
    w, h = save_webp(crop, DATA / "images" / fichier)
    return {
        "fighter_id": f["id"], "type": kind, "fichier": fichier, "largeur": w, "hauteur": h,
        "source_url": url, "image_url": img_url, "legende": caption, "credit": credit,
        "similarite": round(scored[0][0], 3), "original": [int(img.shape[1]), int(img.shape[0])],
    }


# --- Index de toutes les galeries ufc.com ------------------------------------------

INDEX = CACHE / "photo_index.json"
GALLERY_SKIP = re.compile(r"train|workout|media-day|weigh|portrait|performance-institute|behind|fan|"
                          r"press|walkout|backstage|arrival|open-|hall-of-fame|ceremon|presser|embedded", re.I)


def sitemap_galleries() -> list[str]:
    root = fetch(f"{UFC}/sitemap.xml", delay=UFC_DELAY) or ""
    out: set[str] = set()
    for page in re.findall(r"<loc>([^<]+)</loc>", root):
        xml = fetch(page.replace("&amp;", "&"), delay=UFC_DELAY) or ""
        out.update(u for u in re.findall(r"<loc>([^<]+)</loc>", xml) if "/gallery/" in u)
    return sorted(out)


def build_index(limit: int | None = None) -> dict:
    """Lit chaque galerie d'événement une fois et garde les photos de combat,
    de célébration et de ceinture (légende d'agence complète)."""
    idx = json.loads(INDEX.read_text(encoding="utf-8")) if INDEX.exists() else {"galeries": {}, "photos": []}
    galleries = [g for g in sitemap_galleries() if not GALLERY_SKIP.search(g.rsplit("/", 1)[-1])]
    todo = [g for g in galleries if g not in idx["galeries"]]
    if limit:
        todo = todo[:limit]  # par passages : chaque lancement reste court, l'index reprend où il en était
    print(f"{len(galleries)} galeries d'événements, {len(todo)} à lire", flush=True)
    for i, g in enumerate(todo, 1):
        n = 0
        for img_url, caption, credit in article_photos(g):
            kind = classify(caption)
            if kind:
                idx["photos"].append({"galerie": g, "image": img_url, "legende": caption, "credit": credit, "type": kind})
                n += 1
        idx["galeries"][g] = n
        if i % 10 == 0 or i == len(todo):
            INDEX.write_text(json.dumps(idx, ensure_ascii=False) + "\n", encoding="utf-8")
            print(f"  {i}/{len(todo)} galeries, {len(idx['photos'])} photos utiles", flush=True)
    return idx


def image_date(url: str) -> str:
    m = re.search(r"/images/(?:image/)?(\d{4}-\d{2})/", url)
    return m.group(1) if m else "0000-00"


def process_indexed(f: dict, idx: dict, skip: set[str] | None = None) -> Result:
    """Comme process(), mais en piochant dans l'index des galeries (photos les
    plus récentes d'abord), puis dans Commons pour ce qui manque."""
    res = Result(f["id"])
    page = athlete_page(f)
    ref = reference_face(f, page)
    if ref is None:
        res.rejected.append("aucun visage de référence (ni fiche ufc.com ni portrait)")
        return res
    names = names_of(f)
    wanted = ["action", "celebration"] + (["ceinture"] if ever_champion(f) else [])
    wanted = [w for w in wanted if w not in (skip or set())]
    if not wanted:
        return res
    mine = sorted((p for p in idx["photos"] if p["type"] in wanted and subject_is(p["legende"], names)),
                  key=lambda p: image_date(p["image"]), reverse=True)
    tried: dict[str, int] = {}
    for p in mine:
        kind = p["type"]
        if kind in res.photos or tried.get(kind, 0) >= 4:
            continue
        tried[kind] = tried.get(kind, 0) + 1
        entry = try_photo(f, kind, p["image"], p["legende"], p.get("credit"), p["galerie"], ref, res)
        if entry:
            res.photos[kind] = entry
        if all(t in res.photos for t in wanted):
            break
    if not all(t in res.photos for t in wanted):
        try_commons(f, wanted, ref, res)
    return res


def raretes_for(kind: str, f: dict, photos: dict, belt_legendary: set[str]) -> list[str]:
    """Raretés illustrées par une photo, selon les règles validées :
    combat jusqu'à Épique (la célébration le remplace s'il manque) ;
    Légendaire = célébration, ou ceinture pour la liste validée ;
    Mythique = ceinture si déjà champion, sinon célébration."""
    champ = ever_champion(f)
    if kind == "action":
        r = list(RARETES_COMBAT)
        # Image provisoire : sans célébration ni ceinture ni portrait, la photo de
        # combat évite une silhouette sur les Légendaire et Mythique
        portrait = (DATA / "images" / "fighters" / f"{f['id']}.webp").exists()
        if not portrait and "celebration" not in photos:
            if "ceinture" not in photos:
                r += ["legendaire", "mythique"]
            elif f["id"] not in belt_legendary:
                r += ["legendaire"]
        return r
    if kind == "ceinture":
        r = ["mythique"] if champ else []
        if f["id"] in belt_legendary:
            r.insert(0, "legendaire")
        return r
    if kind == "celebration":
        # Sans photo de combat correcte, la célébration illustre aussi Commune à Épique
        r = [] if "action" in photos else list(RARETES_COMBAT)
        if f["id"] not in belt_legendary or "ceinture" not in photos:
            r.append("legendaire")
        if not champ or "ceinture" not in photos:
            r.append("mythique")
        return r
    return []


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--combattants", nargs="*", default=[])
    ap.add_argument("--tous", action="store_true")
    ap.add_argument("--test-legendes", action="store_true")
    ap.add_argument("--index", action="store_true", help="construire l'index des galeries ufc.com")
    ap.add_argument("--depuis-index", action="store_true", help="choisir les photos dans l'index")
    ap.add_argument("--max", type=int, default=None, help="nombre maximal de galeries (ou de combattants) par passage")
    ap.add_argument("--manquants", action="store_true",
                    help="refaire depuis l'index les combattants à qui il manque une photo (types manquants seulement)")
    ap.add_argument("--complement", action="store_true",
                    help="second passage : articles ufc.com pour les combattants à qui il manque une photo")
    args = ap.parse_args()
    if args.test_legendes:
        return test_legendes()
    if args.index:
        build_index(args.max)
        return
    idx = json.loads(INDEX.read_text(encoding="utf-8")) if args.depuis_index else None
    fighters = load_fighters()
    ids = list(fighters) if args.tous else args.combattants
    meta = json.loads(META.read_text(encoding="utf-8")) if META.exists() else {"photos": [], "manquantes": {}}
    meta.setdefault("traites", [])
    if args.tous and args.depuis_index:
        # Par passages : on reprend après les combattants déjà traités
        ids = [i for i in ids if i not in meta["traites"]]
        if args.max:
            ids = ids[:args.max]
    if args.manquants:
        have_any = {p["fighter_id"] for p in meta["photos"]}
        ids = [i for i in fighters if i in meta.get("manquantes", {}) or i not in have_any]
    if args.complement:
        meta.setdefault("complement", [])
        ids = [i for i in meta.get("manquantes", {}) if i not in meta["complement"]]
        if args.max:
            ids = ids[:args.max]
    by_key = {(p["fighter_id"], p["type"]): p for p in meta["photos"]}
    belt_path = DATA / "images" / "ceinture_legendaire.json"
    belt_legendary = set(json.loads(belt_path.read_text(encoding="utf-8"))["combattants"]) if belt_path.exists() else set()
    for i, fid in enumerate(ids, 1):
        f = fighters[fid]
        if args.complement:
            have = {k for (x, k) in by_key if x == fid}
            res = process(f, max_pages=2, skip=have)
        elif args.manquants:
            have = {k for (x, k) in by_key if x == fid}
            res = process_indexed(f, idx, skip=have)
        else:
            res = process_indexed(f, idx) if idx is not None else process(f)
        for kind, entry in res.photos.items():
            by_key[(fid, kind)] = entry
        have = {k for (x, k) in by_key if x == fid}
        wanted = {"action", "celebration"} | ({"ceinture"} if ever_champion(f) else set())
        missing = sorted(wanted - have)
        if missing:
            meta["manquantes"][fid] = {"types": missing, "raisons": res.rejected[-6:]}
        else:
            meta["manquantes"].pop(fid, None)
        print(f"[{i}/{len(ids)}] {f['nom']}: {', '.join(sorted(res.photos)) or 'aucune'}"
              + (f" — manque {', '.join(missing)}" if missing else ""), flush=True)
        # Raretés recalculées pour toutes les photos du combattant
        photos_f = {k: v for (x, k), v in by_key.items() if x == fid}
        for k, v in photos_f.items():
            v["raretes"] = raretes_for(k, f, photos_f, belt_legendary)
        if idx is not None and fid not in meta["traites"]:
            meta["traites"].append(fid)
        if args.complement and fid not in meta["complement"]:
            meta["complement"].append(fid)
        meta["photos"] = sorted(by_key.values(), key=lambda p: (p["fighter_id"], p["type"]))
        META.write_text(json.dumps(meta, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def test_legendes() -> None:
    samples = [
        "Benoit Saint Denis of France kicks Ismael Bonfim of Brazil in a lightweight fight during the UFC Fight Night event at UFC APEX on July 01, 2023 in Las Vegas, Nevada.",
        "Benoit Saint Denis of France reacts after defeating Thiago Moises of Brazil in a lightweight fight during the UFC Fight Night event at The Accor Arena on September 02, 2023 in Paris, France.",
        "Benoit Saint Denis of France celebrates his TKO victory over Gabriel Miranda of Brazil in a lightweight fight during the UFC Fight Night event.",
        "Ismael Bonfim of Brazil punches Benoit Saint Denis of France in a lightweight fight during the UFC Fight Night event.",
        "Alex Pereira of Brazil poses with the championship belt after his victory during the UFC 300 event.",
        "Benoit Saint Denis of France faces off with Paddy Pimblett during the UFC 329 press conference.",
        "Benoit Saint Denis of France poses on the scale during the UFC 329 ceremonial weigh-in.",
    ]
    for s in samples:
        print(f"{classify(s) or '—':12s} sujet={subject_is(s, ['Benoît Saint Denis', 'Benoit Saint-Denis'])!s:5s} {s[:70]}")


if __name__ == "__main__":
    main()
