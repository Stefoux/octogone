#!/usr/bin/env python3
"""Collecte les données réelles des combattants.

Sources, par ordre de confiance :
  1. ufc.com (fiche athlète officielle) : surnom, catégorie, palmarès, statistiques UFC
     (frappes/min, précision, défense, takedowns, soumissions, durée moyenne…).
     robots.txt demande 15 s entre deux requêtes : on respecte.
  2. Wikipedia (EN) : infobox (palmarès détaillé dont défaites par KO) et tableau
     du palmarès MMA (méthodes, rounds, bonus « Fight of the Night », titres).
  3. Wikidata : identifiant ufc.com (P9722), nationalité (P27), date de naissance,
     taille. On n'utilise PAS son champ surnom (souvent vandalisé).

Chaque valeur garde sa source dans « champs_sources ». Tout ce qui manque ou se
contredit entre sources part dans « a_verifier ». Rien n'est inventé.

Usage :
  python fetch_fighters.py --edition 2024-topps-chrome-ufc     # tous les combattants d'une édition
  python fetch_fighters.py --noms "Jon Jones" "Alex Pereira"   # quelques noms
  python fetch_fighters.py --champions                         # + champions actuels (ufc.com/rankings)
"""
from __future__ import annotations

import argparse
import datetime as dt
import re
import sys

from bs4 import BeautifulSoup
import mwparserfromhell

from distinctions import build as build_distinctions
from common import (DATA, WIKI_UA, canonical, fetch, load_aliases, load_json, save_json,
                    slugify)

import json

FIGHTERS = DATA / "fighters"
UFC_DELAY = 15.0  # crawl-delay de ufc.com/robots.txt
WIKI_API = "https://en.wikipedia.org/w/api.php"
WD_API = "https://www.wikidata.org/w/api.php"

DIVISIONS = {
    # libellé ufc.com (EN ou FR) -> clé interne
    "women's strawweight": "paille_f", "women's flyweight": "mouche_f",
    "women's bantamweight": "coq_f", "women's featherweight": "plume_f",
    "strawweight": "paille_f",
    "flyweight": "mouche", "bantamweight": "coq", "featherweight": "plume",
    "lightweight": "legers", "welterweight": "mi_moyens", "middleweight": "moyens",
    "light heavyweight": "mi_lourds", "heavyweight": "lourds",
    "catch weight": None, "catchweight": None,
}
WIKI_DIVISION = {
    "strawweight": "paille", "flyweight": "mouche", "bantamweight": "coq",
    "featherweight": "plume", "lightweight": "legers", "welterweight": "mi_moyens",
    "middleweight": "moyens", "light heavyweight": "mi_lourds", "heavyweight": "lourds",
}


# ----------------------------------------------------------------------------
# Wikipedia / Wikidata
# ----------------------------------------------------------------------------

def name_tokens(s: str) -> set[str]:
    import unicodedata
    s = unicodedata.normalize("NFKD", s or "")
    s = "".join(c for c in s if not unicodedata.combining(c)).lower()
    s = re.sub(r"\(.*?\)", " ", s)
    return {t for t in re.split(r"[^a-z]+", s) if len(t) >= 3 and t not in ("the", "jr")}


def same_person(name: str, other: str | None) -> bool:
    """Au moins 2 mots en commun (ou tous ceux du nom le plus court) : « Alex Pereira » ≠ « Michel Pereira »."""
    a, b = name_tokens(name), name_tokens(other or "")
    if not a or not b:
        return False
    return len(a & b) >= min(2, len(a), len(b))


def wiki_get(params: dict) -> dict:
    params = {**params, "format": "json", "formatversion": 2}
    txt = fetch(WIKI_API, params=params, ua=WIKI_UA, delay=0.5)
    return json.loads(txt) if txt else {}


def wikidata_names(title: str) -> list[str]:
    """Libellé et alias anglais Wikidata de l'article (pour les titres du type « The Korean Zombie »)."""
    q = wiki_get({"action": "query", "titles": title, "redirects": 1, "prop": "pageprops"})
    pages = q.get("query", {}).get("pages", [])
    qid = pages[0].get("pageprops", {}).get("wikibase_item") if pages else None
    if not qid:
        return []
    txt = fetch(f"https://www.wikidata.org/wiki/Special:EntityData/{qid}.json", ua=WIKI_UA, delay=0.5)
    if not txt:
        return []
    ent = json.loads(txt)["entities"].get(qid, {})
    names = [ent.get("labels", {}).get("en", {}).get("value", "")]
    names += [a.get("value", "") for a in ent.get("aliases", {}).get("en", [])]
    return [n for n in names if n]


def page_is_fighter(name: str, title: str) -> bool:
    if same_person(name, title):
        return True
    return any(same_person(name, n) for n in wikidata_names(title))


def resolve_wiki_title(name: str, overrides: dict, previous: str | None = None) -> str | None:
    """Titre de l'article Wikipedia du combattant, VÉRIFIÉ (nom correspondant), ou None."""
    if name in overrides:
        return overrides[name]
    if previous and page_is_fighter(name, previous):
        return previous
    # 1) titre exact (avec redirections) s'il s'agit bien d'un combattant
    for candidate in (name, f"{name} (fighter)"):
        q = wiki_get({"action": "query", "titles": candidate, "redirects": 1,
                      "prop": "categories|pageprops", "cllimit": "max"})
        pages = q.get("query", {}).get("pages", [])
        if pages and not pages[0].get("missing"):
            cats = " ".join(c["title"] for c in pages[0].get("categories", []))
            if "disambiguation" in cats.lower():
                continue
            if re.search(r"mixed martial|Ultimate Fighting Championship|UFC", cats) and \
                    page_is_fighter(name, pages[0]["title"]):
                return pages[0]["title"]
    # 2) recherche plein texte : on n'accepte qu'un résultat portant le nom du combattant
    q = wiki_get({"action": "query", "list": "search",
                  "srsearch": f'"{name}" mixed martial artist', "srlimit": 10})
    for hit in q.get("query", {}).get("search", []):
        if not ("mixed martial" in hit.get("snippet", "").lower() or "UFC" in hit.get("snippet", "")):
            continue
        if page_is_fighter(name, hit["title"]):
            return hit["title"]
    return None


def wiki_page(title: str) -> dict:
    """wikitext + HTML rendu + QID Wikidata + image libre de la page."""
    params = {"action": "query", "titles": title, "redirects": 1,
              "prop": "pageprops|revisions", "rvprop": "content", "rvslots": "main"}
    q = wiki_get(params)
    if "query" not in q:  # réponse vide ou erreur passagère : un second essai sans cache
        txt = fetch(WIKI_API, params={**params, "format": "json", "formatversion": 2}, ua=WIKI_UA,
                    delay=2, cache=False)
        q = json.loads(txt) if txt else {}
    if "query" not in q:
        raise RuntimeError(f"Wikipedia ne répond pas pour « {title} »")
    page = q["query"]["pages"][0]
    if page.get("missing") or "revisions" not in page:
        raise RuntimeError(f"article Wikipedia introuvable : « {title} »")
    wikitext = page["revisions"][0]["slots"]["main"]["content"]
    html = wiki_get({"action": "parse", "page": page["title"], "prop": "text",
                     "disableeditsection": 1}).get("parse", {}).get("text", "")
    return {
        "title": page["title"],
        "qid": page.get("pageprops", {}).get("wikibase_item"),
        "wikitext": wikitext,
        "html": html,
        "url": "https://en.wikipedia.org/wiki/" + page["title"].replace(" ", "_"),
    }


def wikidata(qid: str) -> dict:
    txt = fetch(f"https://www.wikidata.org/wiki/Special:EntityData/{qid}.json", ua=WIKI_UA, delay=0.5)
    if not txt:
        return {}
    ent = json.loads(txt)["entities"][qid]
    claims = ent.get("claims", {})

    def first(prop):
        vals = [c for c in claims.get(prop, []) if c.get("rank") != "deprecated"]
        vals.sort(key=lambda c: c.get("rank") != "preferred")
        return [v["mainsnak"].get("datavalue", {}).get("value") for v in vals if "datavalue" in v["mainsnak"]]

    out = {"url": f"https://www.wikidata.org/wiki/{qid}"}
    ufc = first("P9722")
    out["ufc_slug"] = ufc[0] if ufc else None
    sherdog = first("P2818")
    out["sherdog_id"] = sherdog[0] if sherdog else None
    dob = first("P569")
    if dob:
        out["date_naissance"] = dob[0]["time"][1:11]
    h = first("P2048")
    if h:
        amount = float(h[0]["amount"])
        unit = h[0].get("unit", "")
        out["taille_cm"] = round(amount * 100) if unit.endswith("Q11573") else round(amount)
    sex = first("P21")
    if sex:
        out["sexe"] = {"Q6581097": "M", "Q6581072": "F"}.get(sex[0]["id"])
    countries = [c["id"] for c in first("P27")]
    out["pays_qids"] = countries
    out["image_commons"] = (first("P18") or [None])[0]
    return out


_iso_cache: dict[str, str | None] = {}


def country_iso(qid: str) -> str | None:
    if qid in _iso_cache:
        return _iso_cache[qid]
    txt = fetch(f"https://www.wikidata.org/wiki/Special:EntityData/{qid}.json", ua=WIKI_UA, delay=0.5)
    iso = None
    if txt:
        claims = json.loads(txt)["entities"][qid].get("claims", {})
        for c in claims.get("P297", []):
            v = c["mainsnak"].get("datavalue", {}).get("value")
            if v:
                iso = v.upper()
                break
    _iso_cache[qid] = iso
    return iso


def infobox(wikitext: str) -> dict:
    code = mwparserfromhell.parse(wikitext)
    for t in code.filter_templates():
        if str(t.name).strip().lower().startswith("infobox martial artist"):
            out = {}
            for p in t.params:
                key = str(p.name).strip()
                val = p.value.strip_code().strip()
                out[key] = val
            return out
    return {}


def to_int(v) -> int | None:
    if v is None:
        return None
    m = re.search(r"\d+", str(v))
    return int(m.group()) if m else None


def record_table(html: str) -> list[dict]:
    """Tableau « Mixed martial arts record » -> liste de combats."""
    soup = BeautifulSoup(html, "lxml")
    fights = []
    for table in soup.select("table.wikitable"):
        headers = [th.get_text(" ", strip=True) for th in table.select("tr")[0].find_all(["th", "td"])]
        if not headers or "Res." not in headers[0] or "Method" not in " ".join(headers):
            continue
        idx = {h: i for i, h in enumerate(headers)}
        for tr in table.select("tr")[1:]:
            cells = [td.get_text(" ", strip=True) for td in tr.find_all(["td", "th"])]
            if len(cells) < len(headers) - 1:
                continue
            def col(name):
                i = idx.get(name)
                return cells[i] if i is not None and i < len(cells) else ""
            fights.append({
                "resultat": col("Res."), "record": col("Record"), "adversaire": col("Opponent"),
                "methode": col("Method"), "evenement": col("Event"), "date": col("Date"),
                "round": to_int(col("Round")), "temps": col("Time"), "notes": col("Notes"),
            })
        break  # le premier tableau de palmarès MMA professionnel
    return fights


def _own_text(li) -> str:
    """Texte d'un <li> sans ses sous-listes ni ses renvois [12]."""
    parts = []
    for c in li.children:
        if getattr(c, "name", None) in ("ul", "ol"):
            continue
        if getattr(c, "name", None) in ("sup", "style", "link"):
            continue
        parts.append(c.get_text(" ", strip=True) if hasattr(c, "get_text") else str(c))
    txt = " ".join(" ".join(parts).split())
    return re.sub(r"\[\s*[\w ]*\d+\s*\]", "", txt).strip()


def accomplishments(html: str) -> list[dict]:
    """Section « Championships and accomplishments » : [{org, texte}] (organisation parente)."""
    soup = BeautifulSoup(html, "lxml")
    h = None
    for tag in soup.find_all(["h2", "h3"]):
        if "accomplishments" in tag.get_text(" ", strip=True).lower():
            h = tag
            break
    if not h:
        return []
    items: list[dict] = []
    node = h.find_parent("div", class_="mw-heading") or h
    for sib in node.find_next_siblings():
        cls = sib.get("class") or []
        if sib.name == "h2" or "mw-heading2" in cls:
            break
        if sib.name in ("ul", "ol"):
            lists = [sib]
        elif hasattr(sib, "find_all"):
            # Mise en page en colonnes : listes imbriquées dans des <div> ; on garde les listes de 1er niveau.
            lists = [ul for ul in sib.find_all(["ul", "ol"]) if ul.find_parent("li") is None]
        else:
            lists = []
        for ul in lists:
            for li in ul.find_all("li", recursive=False):
                org = _own_text(li)
                subs = li.find_all("li")
                if subs:
                    for sub in subs:
                        t = _own_text(sub)
                        if t and len(t) < 220:
                            items.append({"org": org, "texte": t})
                elif org and len(org) < 220:
                    items.append({"org": None, "texte": org})
    return items[:120]


TECH_RE = re.compile(r"\(([^)]+)\)")


def derive_from_record(fights: list[dict]) -> dict:
    ufc = [f for f in fights if re.search(r"\bUFC\b|Ultimate Fighter|Dana White's Contender", f["evenement"])]
    wins = [f for f in fights if f["resultat"].lower().startswith("win")]
    losses = [f for f in fights if f["resultat"].lower().startswith("loss")]

    def is_ko(f):
        return re.match(r"^(T?KO)", f["methode"]) is not None

    def is_sub(f):
        return f["methode"].lower().startswith(("submission", "technical submission"))

    def is_dec(f):
        return f["methode"].lower().startswith("decision")

    # Techniques de finition des victoires (« KO (head kick) », « Submission (armbar) »…)
    GENERIC = {"punches", "punch", "strikes", "elbows", "elbows and punches", "punches and elbows",
               "doctor stoppage", "corner stoppage", "retirement", "injury", "slam", "ground and pound"}
    def canonical_tech(raw: str) -> str | None:
        t = raw.strip().lower().replace("–", "-").replace("arm-triangle-choke", "arm-triangle choke")
        if "injury" in t or "broken" in t or t.startswith("submission to") or "stoppage" in t:
            return None  # pas une technique (blessure, abandon sous les coups…)
        t = re.sub(r"\s+and punches$|^punches and\s+", "", t)  # « head kick and punches » -> « head kick »
        t = re.sub(r"\bknees\b", "knee", t)
        t = re.sub(r"\bkicks\b", "kick", t)
        return t

    tech: dict[str, int] = {}
    for f in wins:
        if is_ko(f) or is_sub(f):
            m = TECH_RE.search(f["methode"])
            t = canonical_tech(m.group(1)) if m else None
            if t:
                tech[t] = tech.get(t, 0) + 1

    def notes_count(pattern, pool):
        return sum(1 for f in pool if re.search(pattern, f["notes"], re.I))

    titles = []
    for f in fights:
        m = re.search(r"(Won|Defended|Retained) the (interim )?(UFC [A-Za-z' ]+Championship)", f["notes"])
        if m and f["resultat"].lower().startswith("win"):
            titles.append({"action": m.group(1).lower(), "interim": bool(m.group(2)), "titre": m.group(3).strip(),
                           "evenement": f["evenement"], "date": f["date"]})
    # Coup signature : la technique PRÉCISE la plus utilisée pour finir (coup de pied à la tête,
    # étranglement arrière…) ; à défaut, la plus utilisée tout court (souvent les poings).
    # Les poings (finition générique) comptent pour moitié : une technique précise l'emporte
    # dès qu'elle est au moins à moitié aussi fréquente.
    def weight(kv):
        return (kv[1] * (0.5 if kv[0] in GENERIC else 1.0), kv[0] not in GENERIC)
    signature = max(tech.items(), key=weight) if tech else None
    per_year: dict[str, int] = {}
    for f in ufc:
        m = re.search(r"\b(19|20)\d{2}\b", f["date"])
        if m:
            per_year[m.group()] = per_year.get(m.group(), 0) + 1
    last = fights[0] if fights else None  # Wikipedia : combat le plus récent en premier
    def method_counts(pool):
        return {"ko": sum(1 for f in pool if is_ko(f)), "soumission": sum(1 for f in pool if is_sub(f)),
                "decision": sum(1 for f in pool if is_dec(f)),
                "autre": sum(1 for f in pool if not (is_ko(f) or is_sub(f) or is_dec(f)))}
    table_record = {
        "victoires": len(wins), "defaites": len(losses),
        "nuls": sum(1 for f in fights if f["resultat"].lower().startswith("draw")),
        "sans_decision": sum(1 for f in fights if f["resultat"].lower().startswith("nc")
                             or "no contest" in f["resultat"].lower()),
        "v": method_counts(wins), "d": method_counts(losses),
    }
    return {
        "palmares_tableau": table_record,
        "combats_ufc_par_annee": dict(sorted(per_year.items())),
        "dernier_combat": ({"adversaire": last["adversaire"], "evenement": last["evenement"],
                            "date": last["date"], "resultat": last["resultat"], "methode": last["methode"]}
                           if last else None),
        "combats_ufc": len(ufc),
        "victoires_ufc": sum(1 for f in ufc if f["resultat"].lower().startswith("win")),
        "defaites_ufc": sum(1 for f in ufc if f["resultat"].lower().startswith("loss")),
        "victoires_decision_5_rounds": sum(1 for f in wins if is_dec(f) and f["round"] == 5),
        "combats_5_rounds_gagnes": sum(1 for f in wins if (f["round"] or 0) >= 4),
        "defaites_ko_record": sum(1 for f in losses if is_ko(f)),
        "victoires_ko_record": sum(1 for f in wins if is_ko(f)),
        "victoires_sou_record": sum(1 for f in wins if is_sub(f)),
        "bonus_fotn": notes_count(r"Fight of the Night", fights),
        "bonus_potn": notes_count(r"Performance of the Night", fights),
        "bonus_kotn": notes_count(r"Knockout of the Night", fights),
        "bonus_sotn": notes_count(r"Submission of the Night", fights),
        "combats_fotn": [{"adversaire": f["adversaire"], "evenement": f["evenement"], "date": f["date"]}
                          for f in fights if re.search(r"Fight of the Night", f["notes"], re.I)],
        "titres": titles,
        "technique_favorite": {"technique": signature[0], "finitions": signature[1]} if signature else None,
        "premier_combat_ufc": ({"adversaire": ufc[-1]["adversaire"], "evenement": ufc[-1]["evenement"],
                                "date": ufc[-1]["date"], "resultat": ufc[-1]["resultat"],
                                "methode": ufc[-1]["methode"]} if ufc else None),
    }


# ----------------------------------------------------------------------------
# ufc.com
# ----------------------------------------------------------------------------

def num(s: str | None) -> float | None:
    if s is None:
        return None
    m = re.search(r"-?\d+(?:[.,]\d+)?", s)
    return float(m.group().replace(",", ".")) if m else None


def mmss(s: str | None) -> int | None:
    m = re.search(r"(\d+):(\d{2})", s or "")
    return int(m.group(1)) * 60 + int(m.group(2)) if m else None


def ufc_profile(slug: str) -> dict | None:
    url = f"https://www.ufc.com/athlete/{slug}"
    page = fetch(url, delay=UFC_DELAY)
    if not page or "hero-profile" not in page:
        return None
    b = BeautifulSoup(page, "lxml")

    def t(el):
        return " ".join(el.get_text(" ", strip=True).split()) if el else None

    out: dict = {"url": url}
    nick = b.select_one(".hero-profile__nickname")
    out["surnom"] = t(nick).strip('"“” ') if nick else None
    name = b.select_one(".hero-profile__name")
    out["nom"] = t(name)
    div = b.select_one(".hero-profile__division-title")
    out["division_brute"] = t(div)
    rec = b.select_one(".hero-profile__division-body")
    m = re.search(r"(\d+)-(\d+)-(\d+)", t(rec) or "")
    out["record"] = [int(x) for x in m.groups()] if m else None
    tags = [t(x) for x in b.select(".hero-profile__tag")]
    out["tags"] = tags

    # Statistiques comparées, repérées par leur libellé (EN ou FR selon la géolocalisation).
    # Valeur absente sur la page = None (jamais 0) : ufc.com n'affiche pas tout pour tous.
    LABELS = [
        (r"landed|atterri", "frappes_par_min"),
        (r"absorbed|absorb", "frappes_encaissees_par_min"),
        (r"takedown avg|mises au sol$|moyenne de mises au sol", "takedowns_par_15min"),
        (r"submission avg|soumissions", "soumissions_par_15min"),
        (r"str\.? defen|coups sign\. d[ée]fendus", "defense_frappe_pct"),
        (r"takedown defen|mises au sol d[ée]fendues", "defense_takedown_pct"),
        (r"knockdown", "knockdowns_par_15min"),
        (r"fight time|temps de combat", "duree_moyenne"),
    ]
    stats = {}
    for g in b.select(".c-stat-compare__group"):
        label = (t(g.select_one(".c-stat-compare__label")) or "").lower()
        number = t(g.select_one(".c-stat-compare__number"))
        for pat, key in LABELS:
            if re.search(pat, label) and key not in stats:
                if key == "duree_moyenne":
                    secs = mmss(number)
                    stats["duree_moyenne_s"] = secs if secs else None
                else:
                    stats[key] = num(number) if number else None
                break

    # Précision (frappes, takedowns) : réussis / tentés
    for ov in b.select(".c-overlap__inner"):
        title = (t(ov.select_one(".c-overlap--stats__title, .e-t3")) or t(ov) or "").lower()
        key = "takedown" if re.search(r"takedown|mise", title) else "frappe"
        values = []
        for item in ov.select(".c-overlap__stats"):
            v = item.select_one(".c-overlap__stats-value")
            values.append(num(t(v)) if v and t(v) else None)
        landed, attempted = (values + [None, None])[:2]
        pct_el = ov.select_one(".e-chart-circle__percent")
        pct = num(t(pct_el)) if pct_el and t(pct_el) else None
        if attempted:
            landed = landed or 0
            stats[f"precision_{key}_pct"] = round(100 * landed / attempted)
        elif pct is not None and landed is not None:
            stats[f"precision_{key}_pct"] = pct
        stats[f"{key}_reussies"] = landed
        stats[f"{key}_tentees"] = attempted

    # Victoires par méthode (2e bloc 3 barres : KO/TKO, DEC, SUB)
    bars = b.select(".c-stat-3bar")
    for bar in bars:
        labels = [t(x) for x in bar.select(".c-stat-3bar__label")]
        values = [t(x) for x in bar.select(".c-stat-3bar__value")]
        if labels and labels[0] and labels[0].upper().startswith("KO"):
            out["victoires_methode"] = {
                "ko": int(num(values[0]) or 0) if len(values) > 0 else None,
                "decision": int(num(values[1]) or 0) if len(values) > 1 else None,
                "soumission": int(num(values[2]) or 0) if len(values) > 2 else None,
            }
        elif labels and labels[0] and labels[0].lower() in ("standing", "permanent", "debout"):
            out["position_frappes"] = [int(num(v) or 0) for v in values[:3]]

    bio = {}
    for f in b.select(".c-bio__field"):
        lab = t(f.select_one(".c-bio__label"))
        txt = t(f.select_one(".c-bio__text"))
        if lab:
            bio[lab.lower()] = txt
    def bio_get(*names):
        for n in names:
            if n in bio:
                return bio[n]
        return None
    out["statut"] = bio_get("status", "statut")
    out["style"] = bio_get("fighting style", "style de combat")
    out["lieu_naissance"] = bio_get("place of birth", "lieu de naissance")
    h = num(bio_get("height", "taille"))
    r = num(bio_get("reach", "portée"))
    out["taille_cm"] = round(h * 2.54) if h else None
    out["allonge_cm"] = round(r * 2.54) if r else None
    out["debut_ufc"] = bio_get("octagon debut", "débuts dans l'octogone")
    out["stats"] = stats
    return out


DIVISION_FR = {
    "poids paille": "paille_f", "poids mouche": "mouche", "poids coq": "coq", "poids plume": "plume",
    "poids légers": "legers", "poids légers ": "legers", "poids mi-moyens": "mi_moyens",
    "poids moyens": "moyens", "poids mi-lourds": "mi_lourds", "poids lourds": "lourds",
}
FEMININE = {"mouche": "mouche_f", "coq": "coq_f", "plume": "plume_f", "paille_f": "paille_f"}


def division_key(raw: str | None, sexe: str | None) -> str | None:
    """« Heavyweight Division », « Women's Flyweight Division », « Poids plume Division »…"""
    if not raw:
        return None
    low = raw.lower().replace("division", "").strip()
    feminine = "women" in low or "fémin" in low or sexe == "F"
    low = re.sub(r"^women's\s+", "", low)
    low = re.sub(r"\s+féminins?$", "", low).strip()
    k = DIVISIONS.get(low) or DIVISION_FR.get(low)
    if k is None:
        return None
    return FEMININE.get(k, k) if feminine else k


def wiki_division(weight_class: str, sexe: str | None) -> str | None:
    """Infobox « weight_class » : on garde la catégorie marquée « present », sinon la dernière citée."""
    if not weight_class:
        return None
    pat = re.compile(r"(light heavyweight|heavyweight|middleweight|welterweight|lightweight|"
                     r"featherweight|bantamweight|flyweight|strawweight)(?:[^\n,;]*?\(([^)]*)\))?", re.I)
    found = [(m.group(1).lower(), (m.group(2) or "").lower()) for m in pat.finditer(weight_class)]
    if not found:
        return None
    current = [d for d, years in found if "present" in years]
    div = current[-1] if current else found[-1][0]
    k = WIKI_DIVISION[div]
    if k == "paille":
        return "paille_f"
    return FEMININE.get(k, k) if sexe == "F" else k


def champions_now() -> dict[str, str]:
    """{nom: division} des champions actuels d'après ufc.com/rankings."""
    page = fetch("https://www.ufc.com/rankings", delay=UFC_DELAY)
    if not page:
        return {}
    b = BeautifulSoup(page, "lxml")
    out = {}
    for grouping in b.select(".view-grouping"):
        head = grouping.select_one(".view-grouping-header")
        champ = grouping.select_one(".rankings--athlete--champion h5 a, .rankings--athlete--champion a")
        if head and champ:
            div = " ".join(head.get_text(" ", strip=True).split())
            if "pound" in div.lower():
                continue
            out[" ".join(champ.get_text(" ", strip=True).split())] = div
    return out


# ----------------------------------------------------------------------------
# Assemblage
# ----------------------------------------------------------------------------

def build_fighter(name: str, overrides: dict, champions: dict[str, str]) -> dict:
    fid = slugify(name)
    path = FIGHTERS / f"{fid}.json"
    prev = load_json(path, {})
    a_verifier: list[str] = []
    ecarts_sources: dict[str, str] = {}  # désaccords tranchés à la majorité (transparence)
    sources: dict[str, str] = {}
    champs: dict[str, str] = {}

    title = resolve_wiki_title(name, overrides.get("wikipedia", {}), prev.get("wikipedia_titre"))
    if not title:
        a_verifier.append("article Wikipedia introuvable")
    wp = wiki_page(title) if title else None
    wd = wikidata(wp["qid"]) if wp and wp.get("qid") else {}
    ib = infobox(wp["wikitext"]) if wp else {}
    fights = record_table(wp["html"]) if wp else []
    derived = derive_from_record(fights) if fights else {}
    accomp = accomplishments(wp["html"]) if wp else []
    if wp:
        sources["wikipedia"] = wp["url"]
    if wd:
        sources["wikidata"] = wd["url"]

    # L'identifiant Wikidata est parfois périmé : on essaie aussi le nom et le nom inversé.
    parts = name.split()
    candidates = [overrides.get("ufc", {}).get(name), wd.get("ufc_slug"), prev.get("ufc_slug"), fid,
                  slugify(" ".join(parts[1:] + parts[:1])) if len(parts) > 1 else None]
    ufc = None
    for slug in dict.fromkeys(c for c in candidates if c):
        ufc = ufc_profile(slug)
        if ufc and not same_person(name, ufc.get("nom")) and \
                not any(same_person(ufc.get("nom") or "", n) for n in ([wp["title"]] if wp else [])):
            ufc = None  # fiche d'un autre combattant : on la rejette
        if ufc:
            break
    if ufc:
        f_slug = slug
    else:
        f_slug = None
        a_verifier.append("fiche ufc.com introuvable")
    if ufc:
        sources["ufc_com"] = ufc["url"]

    f: dict = {"id": fid, "nom": name, "ufc_slug": f_slug}
    if wp:
        f["wikipedia_titre"] = wp["title"]

    # Surnom : ufc.com, sinon infobox Wikipedia
    if ufc and ufc.get("surnom"):
        f["surnom"] = ufc["surnom"]; champs["surnom"] = "ufc_com"
        if ib.get("nickname") and ib["nickname"].strip('"“” ').lower() not in ufc["surnom"].lower():
            f["surnom_wikipedia"] = ib["nickname"]
    elif ib.get("nickname"):
        f["surnom"] = re.split(r"\n|<br", ib["nickname"])[0].strip('"“” '); champs["surnom"] = "wikipedia"
    else:
        f["surnom"] = None

    f["sexe"] = wd.get("sexe")
    if not f["sexe"]:
        a_verifier.append("sexe")

    isos = [country_iso(q) for q in wd.get("pays_qids", [])]
    isos = [i for i in isos if i]
    f["pays"] = isos[0] if isos else None
    if len(isos) > 1:
        f["autres_pays"] = isos[1:]
    champs["pays"] = "wikidata"
    if not f["pays"]:
        a_verifier.append("pays")

    f["categorie"] = division_key(ufc.get("division_brute") if ufc else None, f["sexe"])
    if f["categorie"]:
        champs["categorie"] = "ufc_com"
    else:
        wc = ib.get("weight_class") or ib.get("weightclass") or ib.get("division") or ""
        f["categorie"] = wiki_division(wc, f["sexe"])
        if f["categorie"]:
            champs["categorie"] = "wikipedia"
        else:
            a_verifier.append("categorie")

    statut = (ufc or {}).get("statut") or ""
    f["statut"] = ("actif" if statut.lower() in ("active", "actif") else
                   "retraite" if statut.lower() in ("retired", "retraité", "retraite") else
                   "inactif" if statut else None)
    if f["statut"] is None:
        a_verifier.append("statut")
    f["date_naissance"] = wd.get("date_naissance")
    f["taille_cm"] = (ufc or {}).get("taille_cm") or wd.get("taille_cm")
    f["allonge_cm"] = (ufc or {}).get("allonge_cm")
    if not f["allonge_cm"]:
        a_verifier.append("allonge_cm")
    f["style"] = (ufc or {}).get("style") or (ib.get("style") or None)
    f["lieu_naissance"] = (ufc or {}).get("lieu_naissance")

    # Palmarès pro : infobox Wikipedia (détail) recoupé avec ufc.com (W-L-D)
    def ibv(*keys):
        """Valeur numérique d'infobox ; champ présent mais vide = 0."""
        for k in keys:
            if k in ib:
                return to_int(ib[k]) or 0
        return None
    has_mma = any(k.startswith(("mma_", "mma")) and "win" in k for k in ib)
    pal = {
        "victoires_ko": ibv("mma_kowin", "mmakowins"), "victoires_soumission": ibv("mma_subwin", "mmasubwins"),
        "victoires_decision": ibv("mma_decwin", "mmadecwins"),
        "defaites_ko": ibv("mma_koloss", "mmakolosses"), "defaites_soumission": ibv("mma_subloss", "mmasublosses"),
        "defaites_decision": ibv("mma_decloss", "mmadeclosses"),
        "nuls": ibv("mma_draw", "mmadraws") or 0, "sans_decision": ibv("mma_nc", "mmanc") or 0,
    }
    if has_mma:
        other_w = ibv("mma_otherwin", "mma_dqwin") or 0
        other_l = ibv("mma_otherloss", "mma_dqloss") or 0
        pal["victoires"] = sum(pal[k] or 0 for k in ("victoires_ko", "victoires_soumission", "victoires_decision")) + other_w
        pal["defaites"] = sum(pal[k] or 0 for k in ("defaites_ko", "defaites_soumission", "defaites_decision")) + other_l
    else:
        pal["victoires"] = pal["defaites"] = None
        for k in list(pal):
            if k not in ("nuls", "sans_decision"):
                pal[k] = None
    # Trois sources possibles : tableau du palmarès (Wikipedia), infobox (Wikipedia, parfois
    # vandalisée) et ufc.com. On retient le bilan V-D le plus partagé ; en cas d'égalité,
    # le tableau (le plus détaillé), puis l'infobox, puis ufc.com. Tout désaccord est signalé.
    tr = derived.get("palmares_tableau") if derived else None
    cands = {}
    if tr and tr["victoires"] + tr["defaites"] > 0:
        cands["wikipedia_tableau"] = (tr["victoires"], tr["defaites"])
    if pal["victoires"] is not None and pal["victoires"] >= 0 and (pal.get("nuls") or 0) >= 0:
        cands["wikipedia_infobox"] = (pal["victoires"], pal["defaites"])
    if ufc and ufc.get("record"):
        cands["ufc_com"] = tuple(ufc["record"][:2])
    if cands:
        votes = {}
        for v in cands.values():
            votes[v] = votes.get(v, 0) + 1
        prio = ["wikipedia_tableau", "wikipedia_infobox", "ufc_com"]
        best = max(cands.items(), key=lambda kv: (votes[kv[1]], -prio.index(kv[0])))
        chosen_src, chosen = best
        if len(set(cands.values())) > 1:
            detail = ", ".join(f"{k} {v[0]}-{v[1]}" for k, v in cands.items())
            ecarts_sources["palmares"] = detail
            if votes[chosen] < 2:  # aucune majorité : vraiment à vérifier
                a_verifier.append(f"palmares ({detail})")
        if chosen_src == "wikipedia_tableau":
            pal = {"victoires": tr["victoires"], "defaites": tr["defaites"], "nuls": tr["nuls"],
                   "sans_decision": tr["sans_decision"],
                   "victoires_ko": tr["v"]["ko"], "victoires_soumission": tr["v"]["soumission"],
                   "victoires_decision": tr["v"]["decision"],
                   "defaites_ko": tr["d"]["ko"], "defaites_soumission": tr["d"]["soumission"],
                   "defaites_decision": tr["d"]["decision"]}
        elif chosen_src == "ufc_com":
            w, l, d = ufc["record"]
            vm = ufc.get("victoires_methode") or {}
            pal = {"victoires": w, "defaites": l, "nuls": d, "sans_decision": 0,
                   "victoires_ko": vm.get("ko"), "victoires_soumission": vm.get("soumission"),
                   "victoires_decision": vm.get("decision"),
                   "defaites_ko": tr["d"]["ko"] if tr else None,
                   "defaites_soumission": tr["d"]["soumission"] if tr else None,
                   "defaites_decision": tr["d"]["decision"] if tr else None}
        champs["palmares"] = chosen_src
    for k, v in pal.items():
        if v is None:
            a_verifier.append(f"palmares.{k}")
    f["palmares"] = pal

    st = (ufc or {}).get("stats") or {}
    f["stats_ufc"] = {
        "frappes_par_min": st.get("frappes_par_min"),
        "precision_frappe_pct": st.get("precision_frappe_pct"),
        "frappes_encaissees_par_min": st.get("frappes_encaissees_par_min"),
        "defense_frappe_pct": st.get("defense_frappe_pct"),
        "takedowns_par_15min": st.get("takedowns_par_15min"),
        "precision_takedown_pct": st.get("precision_takedown_pct"),
        "defense_takedown_pct": st.get("defense_takedown_pct"),
        "soumissions_par_15min": st.get("soumissions_par_15min"),
        "knockdowns_par_15min": st.get("knockdowns_par_15min"),
        "duree_moyenne_combat_s": st.get("duree_moyenne_s"),
        "frappes_reussies": st.get("frappe_reussies"),
        "takedowns_reussis": st.get("takedown_reussies"),
    }
    if not any(v is not None for v in f["stats_ufc"].values()):
        a_verifier.append("stats_ufc (absentes de la fiche ufc.com)")
    else:
        champs["stats_ufc"] = "ufc_com"

    f["ufc"] = {k: v for k, v in derived.items() if not k.endswith("_record")}
    if derived:
        champs["ufc"] = "wikipedia_tableau"

    # Champion actuel (ufc.com/rankings), ancien champion (titres gagnés au palmarès)
    champ_div = champions.get(ufc["nom"] if ufc and ufc.get("nom") else name) or champions.get(name)
    f["champion_actuel"] = bool(champ_div)
    if champ_div:
        f["champion_division"] = champ_div
        champs["champion_actuel"] = "ufc_com_rankings"
    f["ancien_champion"] = any(t["action"] == "won" for t in derived.get("titres", []))
    f["accomplissements_en"] = accomp
    if accomp:
        champs["accomplissements_en"] = "wikipedia"

    f["distinctions"] = build_distinctions(f)
    f["image_commons"] = wd.get("image_commons")
    f["sources"] = sources
    f["champs_sources"] = champs
    f["a_verifier"] = sorted(set(a_verifier))
    f["ecarts_sources"] = ecarts_sources
    f["maj"] = dt.date.today().isoformat()
    # Conserver les éventuels ajouts manuels sourcés
    for k in ("corrections", "notes", "image"):
        if k in prev:
            f[k] = prev[k]
    save_json(path, f)
    return f


def edition_names(edition_id: str) -> list[str]:
    e = load_json(DATA / "editions" / f"{edition_id}.json")
    if not e:
        raise SystemExit(f"édition {edition_id} introuvable")
    aliases = load_aliases()
    names = []
    for s in e["series"]:
        for c in s["cartes"]:
            for n in c.get("combattants") or [c["nom_imprime"]]:
                cn = canonical(n, aliases)
                if cn not in names:
                    names.append(cn)
    return names


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--edition", action="append", default=[])
    ap.add_argument("--noms", nargs="*", default=[])
    ap.add_argument("--champions", action="store_true")
    ap.add_argument("--force", action="store_true", help="refaire même si le fichier existe")
    args = ap.parse_args()

    overrides = load_json(FIGHTERS / "aliases.json", {})
    names: list[str] = list(args.noms)
    for e in args.edition:
        names += [n for n in edition_names(e) if n not in names]
    champions = champions_now()  # toujours : sert à marquer « champion_actuel »
    if args.champions:
        aliases = load_aliases()
        for n in champions:
            cn = canonical(n, aliases)
            if cn not in names:
                names.append(cn)
    print(f"{len(names)} combattants à traiter ; champions trouvés sur ufc.com : {len(champions)}")
    for i, n in enumerate(names, 1):
        path = FIGHTERS / f"{slugify(n)}.json"
        if path.exists() and not args.force:
            continue
        try:
            f = build_fighter(n, overrides, champions)
            flag = f" ⚠ {len(f['a_verifier'])} à vérifier" if f["a_verifier"] else ""
            print(f"[{i}/{len(names)}] {n} -> {f.get('categorie')} {f.get('pays')} "
                  f"{f['palmares'].get('victoires')}-{f['palmares'].get('defaites')}{flag}", flush=True)
        except Exception as exc:  # on continue : un combattant raté ne bloque pas les autres
            print(f"[{i}/{len(names)}] {n} -> ERREUR {exc!r}", file=sys.stderr, flush=True)


if __name__ == "__main__":
    main()
