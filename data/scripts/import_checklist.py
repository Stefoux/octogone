#!/usr/bin/env python3
"""Importe la checklist d'une édition réelle à partir d'une page Checklist Insider,
puis la recoupe avec une seconde source (Checklist Center).

Usage :
  python import_checklist.py --id 2024-topps-chrome-ufc --nom "2024 Topps Chrome UFC" \
      --annee 2024 --gamme Chrome --cadre chrome \
      --source https://www.checklistinsider.com/2024-topps-chrome-ufc \
      --verif https://www.checklistcenter.com/2024-topps-chrome-ufc-card-checklist/

Le résultat est écrit dans data/editions/<id>.json. Les écarts entre les deux
sources sont listés dans « verification.ecarts » et les champs douteux dans
« a_verifier » : rien n'est corrigé en silence.
"""
from __future__ import annotations

import argparse
import re

from common import DATA, fetch, html_to_lines, save_json, load_json

CARD_CODE = re.compile(r"^([A-Z0-9]{1,5}-[A-Z0-9]{1,5})\s+(.+)$")
CARD_NUM = re.compile(r"^(\d{1,4})\s+(.+)$")
HEADING = re.compile(r"^(.+?) Checklist$")
META = re.compile(r"^(\d+) cards?\.(.*)$")


def parse_parallels(text: str) -> list[dict]:
    """« Refractor; Gold Refractor /50; X-Fractor (1 per Mega Box); SuperFractor 1/1. »"""
    out = []
    text = text.strip().rstrip(".")
    for raw in [p.strip() for p in text.split(";") if p.strip()]:
        item = {"nom": raw, "tirage": None, "cote": None, "exclusivite": None}
        m = re.search(r"\(([^)]*)\)", raw)
        if m:
            inner = m.group(1)
            raw = raw[: m.start()].strip()
            if "exclusive" in inner.lower():
                item["exclusivite"] = inner
            else:
                item["cote"] = inner
        if re.search(r"\b1/1\b", raw):
            item["tirage"] = 1
            raw = re.sub(r"\s*1/1\b", "", raw).strip()
        else:
            m2 = re.search(r"#?/(\d[\d,]*)", raw)
            if m2:
                item["tirage"] = int(m2.group(1).replace(",", ""))
                raw = raw[: m2.start()].strip()
        item["nom"] = raw.strip()
        out.append(item)
    return out


def parse_meta(rest: str) -> dict:
    meta = {"cote": None, "exclusivite": None, "tirage": None, "paralleles": [], "notes": []}
    par = None
    if "Parallels:" in rest:
        rest, par = rest.split("Parallels:", 1)
    for part in [p.strip() for p in re.split(r"\.(?=\s|[A-Z]|$)", rest) if p.strip()]:
        low = part.lower()
        if low.startswith("pack odds"):
            meta["cote"] = part.split("-", 1)[1].strip() if "-" in part else part
        elif "exclusive" in low:
            meta["exclusivite"] = part
        elif re.fullmatch(r"/\d+", part):
            meta["tirage"] = int(part[1:])
        elif re.fullmatch(r"1:[\d,]+ packs?", part):
            meta["cote"] = part
        elif re.fullmatch(r"\d+ copies", part):
            # Formulation ambiguë de la source (tirage par carte ou total ?)
            meta["notes"].append(part)
        else:
            meta["notes"].append(part)
    if par:
        meta["paralleles"] = parse_parallels(par)
    return meta


def parse_card(line: str, coded: bool) -> dict | None:
    m = (CARD_CODE if coded else CARD_NUM).match(line)
    if not m:
        return None
    num, name = m.group(1), m.group(2).strip()
    card = {"numero": num, "nom_imprime": name, "mentions": [], "sous_titre": None}
    if name.endswith(" RC"):
        card["mentions"].append("RC")
        name = name[:-3].strip()
    m2 = re.match(r'^(.*?)\s+-\s+"(.+)"$', name)
    if m2:
        name, card["sous_titre"] = m2.group(1).strip(), m2.group(2)
    card["nom_imprime"] = name
    return card


def parse_checklist_insider(lines: list[str]) -> list[dict]:
    """Découpe la page en séries (Base, autographes, inserts)."""
    series: list[dict] = []
    group = None
    cur = None
    try:
        start = next(i for i, l in enumerate(lines) if l == "Base Checklist")
    except StopIteration:
        raise SystemExit("Section « Base Checklist » introuvable : format de page inattendu")
    for line in lines[start:]:
        if re.search(r"Autograph Checklist$", line) and line.split()[0].isdigit():
            group = "autographe"
            continue
        if re.search(r"Insert Checklist$", line) and line.split()[0].isdigit():
            group = "insert"
            continue
        if re.search(r"(Relic|Memorabilia) Checklist$", line) and line.split()[0].isdigit():
            group = "relique"
            continue
        if line in ("Downloads", "Related Posts"):
            break
        h = HEADING.match(line)
        if h and not CARD_CODE.match(line):
            name = h.group(1)
            kind = "base" if name == "Base" else (group or "insert")
            cur = {"code": None, "nom": name, "type": kind, "nb_cartes": None, "cartes": []}
            series.append(cur)
            continue
        if cur is None:
            continue
        m = META.match(line)
        if m and cur["nb_cartes"] is None:
            cur["nb_cartes"] = int(m.group(1))
            cur["_meta"] = m.group(2)
            continue
        card = parse_card(line, coded=cur["type"] != "base")
        if not card and not cur["cartes"] and cur["nb_cartes"] is not None:
            # Lignes de cotes / parallèles entre l'en-tête et la première carte
            cur["_meta"] = (cur["_meta"] + " " + line).strip()
            continue
        if card:
            cur["cartes"].append(card)
            if cur["code"] is None:
                cur["code"] = card["numero"].split("-")[0] if "-" in card["numero"] else "BASE"
    for s in series:
        s.update(parse_meta(s.pop("_meta", "")))
    return series


def norm_typo(s: str) -> str:
    """Neutralise la typographie (apostrophes et guillemets courbes) pour comparer."""
    return (s.replace("\u2019", "'").replace("\u2018", "'")
             .replace("\u201c", '"').replace("\u201d", '"').strip())


def parse_checklist_center(lines: list[str]) -> dict[str, str]:
    """Renvoie {numero: nom} pour toutes les cartes listées (base et codes)."""
    cards = {}
    for line in lines:
        m = CARD_CODE.match(line) or CARD_NUM.match(line)
        if not m:
            continue
        num, name = m.group(1), norm_typo(m.group(2))
        name = re.sub(r"\s+RC$", "", name)
        name = re.sub(r'\s+[-–]\s+".*"$', "", name)
        if CARD_NUM.match(line) and (int(num) > 400 or name.lower() == "cards"):
            continue
        cards.setdefault(num, name)
    return cards


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--id", required=True)
    ap.add_argument("--nom", required=True)
    ap.add_argument("--annee", type=int, required=True)
    ap.add_argument("--gamme", required=True)
    ap.add_argument("--cadre", required=True, help="famille de cadre : chrome, papier, finest…")
    ap.add_argument("--source", required=True)
    ap.add_argument("--verif", help="seconde source pour recouper")
    ap.add_argument("--date-sortie")
    args = ap.parse_args()

    page = fetch(args.source)
    if not page:
        raise SystemExit(f"Impossible de lire {args.source}")
    lines = html_to_lines(page)
    series = parse_checklist_insider(lines)
    for s in series:
        s["source"] = args.source

    a_verifier: list[str] = []
    for s in series:
        if s["nb_cartes"] is not None and s["nb_cartes"] != len(s["cartes"]):
            a_verifier.append(
                f"serie {s['nom']}: {s['nb_cartes']} cartes annoncees, {len(s['cartes'])} listees")
        for note in s.get("notes", []):
            if "copies" in note:
                a_verifier.append(f"serie {s['nom']}: tirage « {note} » ambigu (par carte ou total ?)")

    verification = None
    if args.verif:
        vpage = fetch(args.verif)
        if vpage:
            other = parse_checklist_center(html_to_lines(vpage))
            ecarts = []
            for s in series:
                for c in s["cartes"]:
                    o = other.get(c["numero"])
                    if o is None:
                        ecarts.append({"numero": c["numero"], "source": c["nom_imprime"], "verif": None})
                    elif o.lower() != c["nom_imprime"].lower():
                        ecarts.append({"numero": c["numero"], "source": c["nom_imprime"], "verif": o})
            verification = {"source": args.verif, "cartes_trouvees": len(other), "ecarts": ecarts}

    date = args.date_sortie
    if not date:
        for l in lines:
            m = re.match(r"^(?:Estimated )?Release Date:\s*(.+)$", l)
            if m:
                date = m.group(1).strip()
                break

    out_path = DATA / "editions" / f"{args.id}.json"
    previous = load_json(out_path, {})
    edition = {
        "id": args.id,
        "nom": args.nom,
        "annee": args.annee,
        "marque": "Topps",
        "gamme": args.gamme,
        "type": "reelle",
        "famille_cadre": args.cadre,
        "date_sortie": date,
        "sources": [u for u in [args.source, args.verif] if u],
        "a_verifier": a_verifier,
        "verification": verification,
        "series": series,
    }
    # On conserve les ajouts manuels éventuels (notes, corrections sourcées).
    for k in ("notes", "corrections"):
        if k in previous:
            edition[k] = previous[k]
    save_json(out_path, edition)
    total = sum(len(s["cartes"]) for s in series)
    print(f"{args.nom}: {len(series)} séries, {total} cartes -> {out_path.relative_to(DATA.parent)}")
    for s in series:
        print(f"  {s['type']:<10} {s['code'] or '?':<5} {s['nom']:<32} {len(s['cartes']):>4} cartes, "
              f"{len(s['paralleles'])} parallèles")
    if verification:
        print(f"Recoupement : {len(verification['ecarts'])} écart(s) avec {args.verif}")
    for a in a_verifier:
        print("  À VÉRIFIER :", a)


if __name__ == "__main__":
    main()
