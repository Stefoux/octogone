"""Outils partagés par les scripts de données Octogone.

Règle d'or : on ne fabrique jamais un fait. Chaque valeur vient d'une page
dont on garde l'URL ; si on ne trouve pas, on marque le champ « a_verifier ».
"""
from __future__ import annotations

import hashlib
import html
import json
import re
import time
import unicodedata
from pathlib import Path

import socket

import requests
import urllib3.util.connection as _urllib3_conn

# L'IPv6 de certains réseaux domestiques fait patienter chaque connexion
# jusqu'au timeout avant de retomber sur l'IPv4 : on force l'IPv4.
_urllib3_conn.allowed_gai_family = lambda: socket.AF_INET

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data"
CACHE = DATA / "cache"
CACHE.mkdir(parents=True, exist_ok=True)

# Identifiant honnête pour les API Wikimedia (exigé par leur politique d'usage).
WIKI_UA = "OctogoneCardsDataBot/1.0 (projet perso non commercial; contact via le README du depot)"
BROWSER_UA = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/129.0 Safari/537.36"
)

_last_hit: dict[str, float] = {}


def fetch(url: str, *, delay: float = 1.0, ua: str = BROWSER_UA, headers: dict | None = None,
          cache: bool = True, params: dict | None = None) -> str | None:
    """GET avec cache disque et délai minimal par domaine (politesse)."""
    key_src = url + (json.dumps(params, sort_keys=True) if params else "")
    key = hashlib.sha1(key_src.encode()).hexdigest()
    path = CACHE / "http" / f"{key}.html"
    if cache and path.exists():
        return path.read_text(encoding="utf-8")
    domain = re.sub(r"^https?://([^/]+).*$", r"\1", url)
    wait = delay - (time.time() - _last_hit.get(domain, 0))
    if wait > 0:
        time.sleep(wait)
    h = {"User-Agent": ua, "Accept-Language": "en-US,en;q=0.9"}
    if headers:
        h.update(headers)
    for attempt in range(3):
        try:
            r = requests.get(url, headers=h, params=params, timeout=30)
            _last_hit[domain] = time.time()
            if r.status_code == 404:
                return None
            if r.status_code in (429, 503):
                time.sleep(10 * (attempt + 1))
                continue
            r.raise_for_status()
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(r.text, encoding="utf-8")
            return r.text
        except requests.RequestException:
            time.sleep(3 * (attempt + 1))
    return None


def html_to_lines(s: str) -> list[str]:
    s = re.sub(r"(?is)<(script|style|noscript).*?</\1>", "", s)
    s = re.sub(r"(?i)<br\s*/?>|</p>|</li>|</h\d>|</tr>|</div>|</td>|</dd>|</dt>", "\n", s)
    s = re.sub(r"<[^>]+>", "", s)
    s = html.unescape(s)
    return [ln.strip() for ln in s.split("\n") if ln.strip()]


def slugify(name: str) -> str:
    n = unicodedata.normalize("NFKD", name)
    n = "".join(c for c in n if not unicodedata.combining(c))
    n = n.replace("ł", "l").replace("Ł", "L").replace("ø", "o").replace("đ", "d")
    n = re.sub(r"[^a-zA-Z0-9]+", "-", n).strip("-").lower()
    return n


def load_json(path: Path, default=None):
    if path.exists():
        return json.loads(path.read_text(encoding="utf-8"))
    return default


def save_json(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def load_aliases() -> dict[str, str]:
    """Nom imprimé sur la carte -> nom canonique (fautes de frappe, ordre asiatique…)."""
    return load_json(DATA / "fighters" / "aliases.json", {}).get("noms", {})


def canonical(name: str, aliases: dict[str, str] | None = None) -> str:
    aliases = aliases if aliases is not None else load_aliases()
    return aliases.get(name.strip(), name.strip())
