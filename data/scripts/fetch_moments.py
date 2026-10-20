#!/usr/bin/env python3
"""Moments iconiques : vérifie chaque moment de data/moments_selection.json
et écrit data/moments.json ainsi que la fiche de chaque événement
(data/events/<id>.json).

Pour chaque moment :
  1. la ligne du palmarès Wikipedia du vainqueur donne l'adversaire, la
     méthode, le round, le temps et la date (sinon : erreur) ;
  2. l'article Wikipedia de l'événement donne la salle et la ville ;
  3. chaque « preuve » (extrait cité par le texte du verso) doit figurer mot
     pour mot dans l'article de l'événement, la fiche du vainqueur ou du
     perdant, ou la ligne du palmarès ; contrôles chiffrés en plus (âge,
     invaincu, victoires de la soirée, n-ième combat entre les deux).

Un moment qui échoue n'est pas écrit. Une fiche d'événement écrite à la main
(sans « genere_par ») n'est jamais écrasée.

  python fetch_moments.py
"""
from __future__ import annotations

import datetime as dt
import json
import re
import sys

import mwparserfromhell
from bs4 import BeautifulSoup

from build_rivalries import iso_date
from common import DATA, load_json, save_json, slugify
from fetch_fighters import record_table, same_person, wiki_page

SELECTION = DATA / "moments_selection.json"
OUT = DATA / "moments.json"
GENERATOR = "fetch_moments.py"

US_STATES = {"Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware",
             "Florida", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky",
             "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri",
             "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", "New Mexico", "New York",
             "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island",
             "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington",
             "West Virginia", "Wisconsin", "Wyoming", "D.C."}
COUNTRIES = {"United States": "US", "U.S.": "US", "United Arab Emirates": "AE", "Australia": "AU",
             "Singapore": "SG", "Canada": "CA", "Brazil": "BR", "England": "GB", "United Kingdom": "GB"}

KIND_FR = {"ko": "KO", "tko": "TKO", "submission": "soumission", "technical submission": "soumission technique",
           "decision": "décision"}
DETAIL_FR = {
    "punch": "coup de poing", "punches": "coups de poing", "head kick": "coup de pied à la tête",
    "front kick and punches": "coup de pied de face et coups de poing", "punches and knees": "coups de poing et genoux",
    "head kick and punches": "coup de pied à la tête et coups de poing", "rear-naked choke": "étranglement arrière",
    "armbar": "clé de bras", "neck crank": "torsion de la nuque", "triangle choke": "étranglement en triangle",
    "guillotine choke": "guillotine", "twister": "twister", "doctor stoppage": "arrêt médical",
    "corner stoppage": "arrêt du coin",
}
DECISION_FR = {"unanimous": "unanime", "split": "partagée", "majority": "majoritaire"}


def norm(s: str) -> str:
    """Texte comparable : renvois [12] retirés, tirets et guillemets unifiés, espaces réduits, minuscules."""
    s = re.sub(r"\[\s*[a-z0-9 ]{1,6}\s*\]", " ", s)
    s = s.replace("–", "-").replace("—", "-").replace("“", '"').replace("”", '"').replace("’", "'")
    return re.sub(r"\s+", " ", s).strip().lower()


def page_text(html: str) -> str:
    return norm(BeautifulSoup(html, "lxml").get_text(" "))


def fighter(fid: str) -> dict:
    return json.loads((DATA / "fighters" / f"{fid}.json").read_text(encoding="utf-8"))


def method_fr(m: str) -> str:
    """« Submission (rear-naked choke) » -> « soumission (étranglement arrière) »."""
    mm = re.match(r"^(.*?)\s*\((.*)\)$", m.strip())
    kind, detail = (mm.group(1), mm.group(2)) if mm else (m.strip(), None)
    k = KIND_FR[kind.lower()]
    if kind.lower() == "decision":
        return f"décision {DECISION_FR[detail.lower()]}" if detail else k
    return f"{k} ({DETAIL_FR[detail.lower()]})" if detail else k


def ordinal_fr(n: int) -> str:
    return "1er" if n == 1 else f"{n}e"


def result_texts(w: str, l: str, row: dict) -> tuple[str, str, str]:
    """Phrase de résultat FR / EN, et méthode FR."""
    m_fr, m_en, r, t = method_fr(row["methode"]), row["methode"], row["round"], row["temps"]
    if row["methode"].lower().startswith("decision"):
        how_fr = f"par {m_fr} après {r} rounds"
        how_en = f"by {m_en.lower().replace('decision (', '').rstrip(')')} decision after {r} rounds"
    elif t == "5:00":
        how_fr = f"par {m_fr} à la fin du {ordinal_fr(r)} round"
        how_en = f"by {m_en} at the end of round {r}"
    else:
        how_fr = f"par {m_fr} à {t} du {ordinal_fr(r)} round"
        how_en = f"by {m_en} at {t} of round {r}"
    return f"{w} bat {l} {how_fr}.", f"{w} defeats {l} {how_en}.", m_fr


def place(city: str | None) -> tuple[str | None, str | None]:
    """« Paradise, Nevada, United States » -> (« Paradise, Nevada », « US »)."""
    if not city:
        return None, None
    parts = [p.strip() for p in city.split(",") if p.strip()]
    if parts[-1] in COUNTRIES:
        return ", ".join(parts[:-1]) or parts[-1], COUNTRIES[parts[-1]]
    if parts[-1] in US_STATES:
        return ", ".join(parts), "US"
    raise ValueError(f"pays inconnu pour « {city} »")


def infobox(wikitext: str) -> dict:
    code = mwparserfromhell.parse(wikitext)
    ib = next((t for t in code.filter_templates() if str(t.name).strip().lower().startswith("infobox")), None)
    if ib is None:
        return {}
    return {k: ib.get(k).value.strip_code().strip() for k in ("venue", "city") if ib.has(k)}


def check(sel: dict) -> tuple[dict, dict]:
    """Moment vérifié et fiche de son événement ; ValueError sinon."""
    w = fighter(sel["vainqueur"])
    loser = fighter(sel["perdant"]) if sel.get("perdant") else None
    loser_name = loser["nom"] if loser else sel["adversaire"]
    wp_w = wiki_page(w["wikipedia_titre"])
    fights = record_table(wp_w["html"])
    ev = sel["evenement"]
    rows = [f for f in fights if norm(f["evenement"]) == norm(ev) and f["resultat"].lower().startswith("win")]
    row = next((f for f in rows if same_person(loser_name, f["adversaire"])), None)
    if not row:
        raise ValueError(f"combat introuvable au palmarès de {w['nom']} : {loser_name} à {ev}")
    date = iso_date(row["date"])

    wp_ev = wiki_page(ev)
    ib = infobox(wp_ev["wikitext"])
    ville, pays = place(ib.get("city"))
    sources = [wp_ev["url"], wp_w["url"]]
    corpus = {wp_ev["url"]: page_text(wp_ev["html"]), wp_w["url"]: page_text(wp_w["html"]),
              "palmarès": norm(" ".join(str(v) for v in row.values()))}
    if loser and loser.get("wikipedia_titre"):
        wp_l = wiki_page(loser["wikipedia_titre"])
        corpus[wp_l["url"]] = page_text(wp_l["html"])
        sources.append(wp_l["url"])

    proofs = []
    for p in sel.get("preuves", []):
        where = next((src for src, txt in corpus.items() if norm(p) in txt), None)
        if not where:
            raise ValueError(f"preuve introuvable : « {p} »")
        proofs.append({"extrait": p, "source": where if where != "palmarès" else wp_w["url"]})
    if "age" in sel:
        born = dt.date.fromisoformat(w["date_naissance"])
        d = dt.date.fromisoformat(date)
        age = d.year - born.year - ((d.month, d.day) < (born.month, born.day))
        if age != sel["age"]:
            raise ValueError(f"âge : {age} ans, pas {sel['age']}")
    if sel.get("invaincu") and not re.match(r"^\d+\s*[-–]\s*0\b", row["record"]):
        raise ValueError(f"pas invaincu : bilan {row['record']}")
    if "victoires_soiree" in sel and len(rows) != sel["victoires_soiree"]:
        raise ValueError(f"{len(rows)} victoires à {ev}, pas {sel['victoires_soiree']}")
    if "nieme_combat" in sel:
        meetings = [f for f in fights if same_person(loser_name, f["adversaire"])
                    and (iso_date(f["date"]) or "") <= date]
        if len(meetings) != sel["nieme_combat"]:
            raise ValueError(f"{len(meetings)} combats contre {loser_name}, pas {sel['nieme_combat']}")

    res_fr, res_en, m_fr = result_texts(w["nom"], loser_name, row)
    eid = slugify(ev)
    event = {
        "id": eid, "nom": ev, "date": date, "lieu": ib.get("venue"), "ville": ville, "pays": pays,
        "resultat": res_fr, "resultat_en": res_en, "contexte": sel["contexte"], "contexte_en": sel["contexte_en"],
        "tirage": None,
        "resultats": [{"vainqueur": w["nom"], "perdant": loser_name, "methode": m_fr, "round": row["round"],
                       "temps": row["temps"]}],
        "sources": sources, "a_verifier": [], "genere_par": GENERATOR,
    }
    moment = {
        "id": eid, "titre": f"{w['nom']} vs {loser_name}",
        "combattants": [w["id"], *([loser["id"]] if loser else [])],
        "event_id": eid, "date": date, "texte": sel["contexte"], "texte_en": sel["contexte_en"],
        "sources": sources, "preuves": proofs,
    }
    return moment, event


def main() -> None:
    selection = load_json(SELECTION)["moments"]
    moments, failures = [], 0
    for sel in selection:
        try:
            moment, event = check(sel)
        except (ValueError, RuntimeError, KeyError) as exc:
            failures += 1
            print(f"✗ {sel['vainqueur']} @ {sel['evenement']} : {exc}", file=sys.stderr)
            continue
        path = DATA / "events" / f"{event['id']}.json"
        existing = load_json(path, None)
        if existing and existing.get("genere_par") != GENERATOR:
            moment["sources"] = list(dict.fromkeys([*existing.get("sources", []), *moment["sources"]]))
        else:
            save_json(path, event)
        moments.append(moment)
        print(f"✓ {moment['date']} {event['nom']} : {moment['titre']}")
    moments.sort(key=lambda m: m["date"])
    save_json(OUT, {"source": SELECTION.name, "moments": moments})
    print(f"{len(moments)} moments vérifiés, {failures} refusés")
    if failures:
        sys.exit(1)


if __name__ == "__main__":
    main()
