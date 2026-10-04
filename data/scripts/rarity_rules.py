"""Correspondance entre les parallèles RÉELS d'une édition et les niveaux de
rareté du jeu (commune → mythique) + l'effet visuel à appliquer.

Les tirages et cotes réels restent stockés tels quels (champs « tirage »,
« cote ») ; seule la rareté « de jeu » est déduite ici, par des règles fixes :

  Parallèle numéroté :  /150 et plus -> rare ; /50 à /149 -> épique ;
                        /10 à /49 -> légendaire ; moins de /10 (dont 1/1) -> mythique
  Parallèle non numéroté (Refractor, Prism…) -> peu commune
  Carte de base -> commune

  Série d'insert : cote moins rare que 1:20 paquets -> peu commune ; jusqu'à 1:100 -> rare ;
                   jusqu'à 1:500 -> épique ; au-delà -> légendaire.
  Série d'autographes -> épique au minimum.
  La rareté d'une variante est la plus haute des deux (série, parallèle).
"""
from __future__ import annotations

import re

ORDER = ["commune", "peu_commune", "rare", "epique", "legendaire", "mythique"]

# Effet visuel + teinte par nom de parallèle réel (les effets sont des
# créations originales « dans l'esprit » des Refractors, pas des copies).
EFFECTS = [
    (r"superfractor", "superfractor", "#E8B04A"),
    (r"x-?fractor", "x_fractor", None),
    (r"sepia", "sepia", "#B08A5A"),
    (r"negative", "negative", None),
    (r"prism", "prism", None),
    (r"speckle", "speckle", None),
    (r"blue wave", "wave", "#2F6BFF"),
    (r"magenta", "refractor", "#FF2DA6"),
    (r"purple", "refractor", "#8A4DFF"),
    (r"aqua", "refractor", "#19D3DA"),
    (r"blue", "refractor", "#2F6BFF"),
    (r"green", "refractor", "#1DB954"),
    (r"gold", "refractor", "#E8B04A"),
    (r"orange", "refractor", "#FF7A1A"),
    (r"black", "refractor", "#1A1A1A"),
    (r"red", "refractor", "#E5262E"),
    (r"refractor", "refractor", None),
]


def max_rarity(*r: str) -> str:
    return max(r, key=ORDER.index)


def parallel_rarity(tirage: int | None, numbered_series: bool = False) -> str:
    if tirage is None:
        return "peu_commune"
    if tirage >= 150:
        return "rare"
    if tirage >= 50:
        return "epique"
    if tirage >= 10:
        return "legendaire"
    return "mythique"


def odds_packs(cote: str | None) -> int | None:
    """« 1:72 Hobby; 1:7 Breaker Delight » -> 72 (première cote citée = Hobby)."""
    if not cote:
        return None
    m = re.search(r"1:([\d,]+)", cote)
    return int(m.group(1).replace(",", "")) if m else None


def series_rarity(series: dict) -> str:
    kind = series["type"]
    if kind == "base":
        return "commune"
    if series.get("tirage"):
        return parallel_rarity(series["tirage"])
    n = odds_packs(series.get("cote"))
    if n is None:
        r = "rare"
    elif n < 20:
        r = "peu_commune"
    elif n <= 100:
        r = "rare"
    elif n <= 500:
        r = "epique"
    else:
        r = "legendaire"
    if any("copies" in note for note in series.get("notes", [])):
        r = max_rarity(r, "legendaire")
    if kind == "autographe":
        r = max_rarity(r, "epique")
    return r


def effect_for(name: str) -> tuple[str, str | None]:
    low = name.lower()
    for pat, effect, color in EFFECTS:
        if re.search(pat, low):
            return effect, color
    return "refractor", None


def stat_bonus(rarity: str) -> int:
    """+1 (peu commune) à +6 (mythique) ; coup signature dès épique."""
    return {"commune": 0, "peu_commune": 1, "rare": 2, "epique": 3, "legendaire": 5, "mythique": 6}[rarity]
