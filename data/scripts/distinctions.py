"""Distinctions courtes et traduites (FR / EN) à partir des « Championships and
accomplishments » de Wikipedia et des bonus relevés dans le palmarès.

On ne traduit pas tout : on garde l'essentiel, dans cet ordre, 6 lignes au plus
  1. titres UFC (puis titres d'autres grandes organisations)
  2. Hall of Fame de l'UFC
  3. défenses de titre UFC
  4. victoire à The Ultimate Fighter / tournoi UFC
  5. « Combattant de l'année » (toutes rédactions confondues, par année)
  6. records de l'histoire de l'UFC (2 au plus)
  7. combat / KO / soumission de l'année
  8. une ligne de bonus UFC (Performance, Combat, KO, Soumission de la soirée)
Une distinction qu'on ne sait pas traduire proprement est ignorée plutôt
qu'affichée en anglais.
"""
from __future__ import annotations

import re

MAX_LINES = 6

NUMBERS = {"one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8,
           "nine": 9, "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14, "fifteen": 15}

DIVISIONS = [  # (motif anglais, FR, EN) — « light heavyweight » avant « heavyweight »
    ("light heavyweight", "mi-lourds", "Light Heavyweight"),
    ("super heavyweight", "super-lourds", "Super Heavyweight"),
    ("heavyweight", "lourds", "Heavyweight"),
    ("middleweight", "moyens", "Middleweight"),
    ("welterweight", "mi-moyens", "Welterweight"),
    ("lightweight", "légers", "Lightweight"),
    ("featherweight", "plume", "Featherweight"),
    ("bantamweight", "coq", "Bantamweight"),
    ("flyweight", "mouche", "Flyweight"),
    ("strawweight", "paille", "Strawweight"),
    ("atomweight", "atome", "Atomweight"),
    ("openweight", "toutes catégories", "Openweight"),
]

# Organisations dont on reprend les titres (MMA, plus le kickboxing de haut niveau).
ORGS = ["UFC", "Strikeforce", "PRIDE", "WEC", "Bellator", "ONE", "Invicta FC", "Rizin", "PFL",
        "KSW", "Pancrase", "Shooto", "DEEP", "Cage Warriors", "M-1 Global", "LFA", "Jungle Fight",
        "Glory", "K-1", "EliteXC", "Dream", "DREAM", "Elite XC"]
KICKBOXING = {"Glory", "K-1"}
# Grandes organisations dont on garde le titre même quand le combattant a été champion UFC.
MAJOR_OTHER = {"PRIDE", "Strikeforce", "WEC", "Bellator", "ONE", "Invicta FC", "Rizin", "PFL", "Glory", "K-1",
               "Dream", "EliteXC", "KSW"}

# Glossaire des records « Most … in UFC history »
RECORD_TERMS = [
    (r"^finishes$", "finitions", "finishes"),
    (r"^(knockouts|knockout wins|ko/tko wins|\(t\)ko wins|knockout victories)$", "victoires par KO", "knockout wins"),
    (r"^(submission wins|submissions|submission victories)$", "victoires par soumission", "submission wins"),
    (r"^(wins|victories)$", "victoires", "wins"),
    (r"^title fight wins$", "victoires en championnat", "title fight wins"),
    (r"^(consecutive title defenses|consecutive successful title defenses)$", "défenses de titre consécutives",
     "consecutive title defenses"),
    (r"^(title defenses|successful title defenses)$", "défenses de titre", "title defenses"),
    (r"^(bouts|fights|appearances)$", "combats", "fights"),
    (r"^(significant strikes landed|significant strikes)$", "frappes significatives réussies",
     "significant strikes landed"),
    (r"^(total strikes landed)$", "frappes réussies", "total strikes landed"),
    (r"^(takedowns landed|takedowns)$", "takedowns réussis", "takedowns landed"),
    (r"^(knockdowns|knockdowns landed)$", "knockdowns", "knockdowns"),
    (r"^(post-fight bonuses|post-fight bonus awards|bonuses|bonus awards|fight night bonuses)$", "bonus de soirée",
     "post-fight bonuses"),
    (r"^performance of the night (bonuses|awards)$", "bonus Performance de la soirée",
     "Performance of the Night bonuses"),
    (r"^fight of the night (bonuses|awards)$", "bonus Combat de la soirée", "Fight of the Night bonuses"),
    (r"^(consecutive wins|winning streak|win streak)$", "victoires consécutives", "consecutive wins"),
    (r"^(first round finishes|first-round finishes)$", "finitions au 1er round", "first-round finishes"),
    (r"^(submission attempts)$", "tentatives de soumission", "submission attempts"),
    (r"^(fight time|total fight time)$", "temps de combat", "fight time"),
    (r"^(title fights)$", "combats de championnat", "title fights"),
]


def number(word: str | None) -> int | None:
    if not word:
        return None
    w = word.strip().lower()
    if w.isdigit():
        return int(w)
    return NUMBERS.get(w)


def clean(text: str) -> str:
    text = re.sub(r"\[\s*[\w ]*\d+\s*\]", "", text)  # renvois [ 121 ]
    return " ".join(text.split()).strip()


def division(text: str) -> tuple[str, str, bool] | None:
    low = text.lower()
    for pat, fr, en in DIVISIONS:
        if pat in low:
            return fr, en, "women" in low
    return None


TITLE_RE = re.compile(
    r"^(?:(?P<year>\d{4}) )?(?P<interim1>interim )?(?P<org>" + "|".join(re.escape(o) for o in ORGS) +
    r")\s+(?P<interim2>interim\s+)?(?P<div>(?:women's\s+)?[a-z' -]*?weight)\s+(?:world\s+)?champion(?:ship)?\b"
    r"(?:\s*\((?P<paren>[^)]*)\))?",
    re.I,
)


def parse_titles(items: list[dict]) -> list[dict]:
    titles: dict[tuple, dict] = {}
    for it in items:
        t = clean(it["texte"])
        m = TITLE_RE.match(t)
        if not m:
            continue
        org = m.group("org")
        org = {"Elite XC": "EliteXC", "DREAM": "Dream"}.get(org, org)
        d = division(m.group("div"))
        if not d:
            continue
        interim = bool(m.group("interim1") or m.group("interim2"))
        times = None
        paren = m.group("paren") or ""
        mt = re.search(r"(\w+) times?", paren, re.I)
        if mt:
            times = number(mt.group(1))
        key = (org, d[0], d[2], interim)
        cur = titles.get(key)
        if cur:
            # « 2017 Glory Middleweight Champion » + « 2021 … » : on additionne les règnes datés
            cur["fois"] = max(cur["fois"], times or 0) if times else cur["fois"] + (1 if m.group("year") else 0)
        else:
            titles[key] = {"org": org, "div_fr": d[0], "div_en": d[1], "feminin_div": d[2], "interim": interim,
                           "fois": times or 1}
    out = list(titles.values())
    # Un titre intérimaire n'apparaît pas si le titre incontesté de la même catégorie est listé.
    full = {(t["org"], t["div_fr"]) for t in out if not t["interim"]}
    out = [t for t in out if not (t["interim"] and (t["org"], t["div_fr"]) in full)]
    out.sort(key=lambda t: (t["org"] != "UFC", t["org"] in KICKBOXING, t["interim"]))
    return out


def parse_defenses(items: list[dict]) -> int:
    """Défenses de titre UFC, comptées titre par titre (Wikipedia liste les défenses
    juste sous chaque titre) : ligne « Overall/Total » si elle existe, sinon somme
    des règnes, sinon ligne simple."""
    groups: list[list[tuple[int, str]]] = [[]]
    for it in items:
        if not re.search(r"ultimate fighting championship|^ufc", it.get("org") or "", re.I):
            continue
        t = clean(it["texte"])
        if TITLE_RE.match(t):
            groups.append([])
            continue
        m = re.match(r"^(\w+) successful (?:title|championship) defen[cs]es?(?:\s*\(([^)]*)\))?", t, re.I)
        if m and number(m.group(1)) is not None:
            groups[-1].append((number(m.group(1)), (m.group(2) or "").lower()))
    total = 0
    for g in groups:
        if not g:
            continue
        overall = [n for n, tag in g if re.search(r"overall|total|combined", tag)]
        reigns = [n for n, tag in g if "reign" in tag]
        plain = [n for n, tag in g if not tag]
        total += max(overall) if overall else (sum(reigns) if reigns else max(plain or [0]))
    return total


def parse_hof(items: list[dict]) -> dict | None:
    """Intronisation au Hall of Fame de l'UFC : {annee, aile} (aile « combat » = un combat intronisé)."""
    best = None
    for it in items:
        t = clean(it["texte"])
        if not re.search(r"UFC Hall of Fame", t):
            continue
        y = re.search(r"(?:Class of |\b)(\d{4})\b", t)
        wing = "combat" if re.search(r"fight\s*wing", t, re.I) else "combattant"
        cand = {"annee": int(y.group(1)) if y else None, "aile": wing}
        if best is None or (best["aile"] == "combat" and wing == "combattant"):
            best = cand
    return best


def parse_tuf(items: list[dict]) -> list[tuple[str, str]]:
    out = []
    for it in items:
        t = clean(it["texte"])
        m = re.search(r"(The Ultimate Fighter(?:\s*\d+|:[^()]+?)?)\s+(?:\w+\s+)?(?:Tournament\s+)?Winner", t, re.I)
        if m:
            name = " ".join(m.group(1).split())
            out.append((f"Vainqueur de {name}", f"{name} winner"))
            continue
        m = re.match(r"^(UFC \d+) Tournament Winner", t, re.I)
        if m:
            out.append((f"Vainqueur du tournoi {m.group(1)}", f"{m.group(1)} tournament winner"))
    return out[:1]


def parse_years(items: list[dict], kind: str) -> list[int]:
    """Années d'un trophée annuel (« Fighter of the Year »…), hors classements et nominations.
    Un même combat récompensé par plusieurs rédactions, parfois l'année suivante (cérémonie),
    ne compte qu'une fois : on dédoublonne par adversaire en gardant l'année la plus ancienne."""
    by_key: dict[str, int] = {}
    for it in items:
        t = clean(it["texte"])
        if re.search(r"ranked|#\d|nominee|runner|honorable|month|breakout|breakthrough|comeback|newcomer|"
                     r"rookie|prospect|female of|best moment|international|coach", t, re.I):
            continue
        if kind == "fighter":
            m = re.match(r"^(\d{4}):? (?:male |female |overall )?(?:mma )?fighter of the year\b", t, re.I)
        else:
            m = re.match(rf"^(\d{{4}}):? (?:fan's choice )?{kind} of the year\b", t, re.I)
        if not m:
            continue
        year = int(m.group(1))
        opp = re.search(r"vs\.?\s+([^()\[\],]+?)(?:\s+at\s|\s*\(|$)", t)
        key = opp.group(1).strip().lower() if opp and kind != "fighter" else str(year)
        by_key[key] = min(year, by_key.get(key, year))
    return sorted(set(by_key.values()))


RECORD_RE = re.compile(
    r"^most (?P<thing>.+?) in (?:the )?UFC(?: (?P<div>(?:women's )?[a-z]+(?: [a-z]+)?) division)? history"
    r"(?:\s*\((?P<val>[^)]+)\))?$",
    re.I,
)


def parse_records(items: list[dict]) -> list[tuple[str, str]]:
    found = []
    for it in items:
        t = clean(it["texte"])
        m = RECORD_RE.match(t)
        if not m:
            continue
        thing = m.group("thing").strip().lower()
        term = next(((fr, en) for pat, fr, en in RECORD_TERMS if re.match(pat, thing)), None)
        if not term or "bonus" in term[0] or term[0] == "défenses de titre":
            continue  # inconnu, ou déjà dit ailleurs (ligne de bonus, ligne de défenses)
        val = m.group("val")
        if val and not re.fullmatch(r"[\d.,]+(?:\s*\w+)?", val.strip()):
            val = None
        suffix = f" ({val.strip()})" if val else ""
        div = division(m.group("div")) if m.group("div") else None
        if div:
            fr = f"Record UFC chez les poids {div[0]}{' féminins' if div[2] else ''} : {term[0]}{suffix}"
            en = f"UFC {'Women' + chr(39) + 's ' if div[2] else ''}{div[1]} record: most {term[1]}{suffix}"
        else:
            fr = f"Record de l'UFC : {term[0]}{suffix}"
            en = f"UFC record: most {term[1]}{suffix}"
        found.append((div is not None, fr, en))
    found.sort(key=lambda x: x[0])  # records toutes catégories d'abord
    seen, out = set(), []
    for _, fr, en in found:
        if fr not in seen:
            seen.add(fr)
            out.append((fr, en))
    return out[:2]


def parse_bonuses(items: list[dict], ufc: dict) -> dict[str, int]:
    counts = {"potn": 0, "fotn": 0, "kotn": 0, "sotn": 0}
    pats = {"potn": r"performance of the night", "fotn": r"fight of the night",
            "kotn": r"knockout of the night", "sotn": r"submission of the night"}
    for it in items:
        t = clean(it["texte"])
        for k, p in pats.items():
            m = re.match(rf"^(?:ultimate fighting championship\s+|ufc\s+)?{p}\s*\((\w+) times?", t, re.I)
            if m:
                counts[k] = max(counts[k], number(m.group(1)) or 0)
    # Records de bonus (« Most Performance of the Night bonuses in UFC history (14) »)
    record_pats = {"potn": r"performance of the night", "fotn": r"fight of the night",
                   "kotn": r"knockout of the night", "sotn": r"submission of the night",
                   "total": r"(?:post-fight )?bonus(?: award)?"}
    for it in items:
        m = RECORD_RE.match(clean(it["texte"]))
        if not m or m.group("div") or not m.group("val"):
            continue
        thing = m.group("thing").lower()
        val = number(re.sub(r"\D", "", m.group("val")) or None)
        for k, p in record_pats.items():
            if val and re.fullmatch(p + r"(?:es|s)?(?: bonuses| awards)?", thing):
                counts[k] = max(counts.get(k, 0), val)
                counts.setdefault("records", []).append(k)
                break
    # Repli : bonus relevés dans les notes du tableau de palmarès
    for k in ("potn", "fotn", "kotn", "sotn"):
        counts[k] = max(counts[k], int(ufc.get(f"bonus_{k}") or 0))
    return counts


def _plural(n: int, one: str, many: str) -> str:
    return one if n == 1 else many


def build(fighter: dict) -> dict[str, list[str]]:
    items = fighter.get("accomplissements_en") or []
    items = [it if isinstance(it, dict) else {"org": None, "texte": it} for it in items]
    female = fighter.get("sexe") == "F"
    fr: list[str] = []
    en: list[str] = []

    titles = parse_titles(items)
    champ = "Championne" if female else "Champion"
    has_ufc = any(t["org"] == "UFC" for t in titles)
    for t in [t for t in titles if t["org"] == "UFC"]:
        interim_fr = " intérimaire" if t["interim"] else ""
        fem_div = " féminins" if t["feminin_div"] else ""
        times_fr = f" ({t['fois']} fois)" if t["fois"] > 1 else ""
        fr.append(f"{champ}{interim_fr} UFC des poids {t['div_fr']}{fem_div}{times_fr}")
        interim_en = "Interim " if t["interim"] else ""
        women_en = "Women's " if t["feminin_div"] else ""
        times_en = f" ({t['fois']}×)" if t["fois"] > 1 else ""
        en.append(f"{interim_en}UFC {women_en}{t['div_en']} Champion{times_en}")
    others: dict[str, list[dict]] = {}
    for t in titles:
        if t["org"] == "UFC" or (has_ufc and t["org"] not in MAJOR_OTHER):
            continue
        others.setdefault(t["org"], []).append(t)
    for org, ts in list(others.items())[:2]:
        kb = " (kickboxing)" if org in KICKBOXING else ""
        divs_fr = " et ".join(dict.fromkeys(t["div_fr"] + (" féminins" if t["feminin_div"] else "") for t in ts))
        divs_en = " & ".join(dict.fromkeys(("Women's " if t["feminin_div"] else "") + t["div_en"] for t in ts))
        fr.append(f"{champ} {org} des poids {divs_fr}{kb}")
        en.append(f"{org} {divs_en} Champion{kb}")

    hof = parse_hof(items)
    if hof:
        year = f" ({hof['annee']})" if hof["annee"] else ""
        if hof["aile"] == "combat":
            fr.append(f"Hall of Fame de l'UFC, aile Combats{year}")
            en.append(f"UFC Hall of Fame, Fight Wing{year}")
        else:
            fr.append(f"Hall of Fame de l'UFC{year}")
            en.append(f"UFC Hall of Fame{year}")

    d = parse_defenses(items)
    if d:
        fr.append(f"{d} {_plural(d, 'défense de titre', 'défenses de titre')} à l'UFC")
        en.append(f"{d} UFC title {_plural(d, 'defense', 'defenses')}")

    for f_, e_ in parse_tuf(items):
        fr.append(f_)
        en.append(e_)

    years = parse_years(items, "fighter")
    if years:
        ys = ", ".join(map(str, years))
        fr.append(f"{'Combattante' if female else 'Combattant'} de l'année ({ys})")
        en.append(f"Fighter of the Year ({ys})")

    for f_, e_ in parse_records(items):
        fr.append(f_)
        en.append(e_)

    of_year = []
    for kind, lfr, len_ in (("fight", "Combat", "Fight"), ("knockout", "KO", "Knockout"),
                            ("submission", "Soumission", "Submission")):
        ys = parse_years(items, kind)
        if ys:
            of_year.append((f"{lfr} de l'année ({', '.join(map(str, ys))})",
                            f"{len_} of the Year ({', '.join(map(str, ys))})"))
    for f_, e_ in of_year[:1]:
        fr.append(f_)
        en.append(e_)

    b = parse_bonuses(items, fighter.get("ufc") or {})
    records = b.get("records", [])
    bonus_fr, bonus_en = [], []
    for k, lfr, len_ in (("potn", "Performance de la soirée", "Performance of the Night"),
                         ("fotn", "Combat de la soirée", "Fight of the Night"),
                         ("kotn", "KO de la soirée", "Knockout of the Night"),
                         ("sotn", "Soumission de la soirée", "Submission of the Night")):
        if b[k]:
            rec = k in records
            bonus_fr.append(f"{b[k]}× {lfr}{' (record)' if rec else ''}")
            bonus_en.append(f"{b[k]}× {len_}{' (record)' if rec else ''}")

    # 6 lignes au plus, dont la ligne de bonus si elle existe
    room = MAX_LINES - (1 if bonus_fr else 0)
    fr, en = fr[:room], en[:room]
    if bonus_fr:
        total_rec = f" (record : {b['total']} au total)" if "total" in records else ""
        total_rec_en = f" (record: {b['total']} total)" if "total" in records else ""
        fr.append(f"Bonus UFC{total_rec} : " + ", ".join(bonus_fr))
        en.append(f"UFC bonuses{total_rec_en}: " + ", ".join(bonus_en))
    return {"fr": fr, "en": en}
