#!/usr/bin/env python3
"""Vérifications à grande échelle des boosters, sur la pile Supabase LOCALE.

1. Probabilités : 100 000 boosters simulés par type (fonction serveur
   simulate_booster_tiers), comparés aux probabilités calculées à partir de la
   composition (celles affichées dans l'app).
2. Concurrence : 8 comptes de test ouvrent en même temps 48 boosters qui se
   disputent une carte numérotée /5. Il doit exister exactement 5 exemplaires,
   numérotés 1 à 5, sans doublon.

Usage : python test_boosters_load.py [--n 100000]
"""
from __future__ import annotations

import argparse
import concurrent.futures as cf
import json
import secrets
import subprocess
import sys

import requests

import common  # noqa: F401  (IPv4)
from common import DATA, ROOT, load_json

TIERS = ["commune", "peu_commune", "rare", "epique", "legendaire", "mythique"]


def local_env() -> dict:
    out = subprocess.run(["supabase", "status", "-o", "env"], cwd=ROOT, capture_output=True, text=True)
    env = dict(line.split("=", 1) for line in out.stdout.splitlines() if "=" in line)
    return {k: v.strip('"') for k, v in env.items()}


def psql(sql: str) -> str:
    out = subprocess.run(["docker", "exec", "-i", "supabase_db_octogone", "psql", "-U", "postgres", "-d", "postgres",
                          "-v", "ON_ERROR_STOP=1", "-t", "-A"], input=sql, capture_output=True, text=True)
    if out.returncode:
        raise SystemExit(out.stderr)
    return out.stdout.strip()


def expected(composition: dict) -> dict[str, tuple[float, float]]:
    """Par rareté : (cartes par booster, probabilité d'en avoir au moins une)."""
    res = {}
    for t in TIERS:
        per_pack, p_none = 0.0, 1.0
        for slot in composition["slots"]:
            total = sum(slot["poids"].values())
            p = slot["poids"].get(t, 0) / total
            per_pack += slot.get("nb", 1) * p
            p_none *= (1 - p) ** slot.get("nb", 1)
        res[t] = (per_pack, 1 - p_none)
    return res


def check_probabilities(api: str, key: str, n: int) -> bool:
    ok = True
    for b in load_json(DATA / "boosters.json")["boosters"]:
        # Par lots de 1 000 (délai maximal d’une requête de l’API)
        got: dict[str, dict] = {}
        done = 0
        while done < n:
            batch = min(1_000, n - done)
            r = requests.post(f"{api}/rest/v1/rpc/simulate_booster_tiers", json={"p_type": b["id"], "p_n": batch},
                              headers={"apikey": key, "Content-Type": "application/json"}, timeout=600)
            r.raise_for_status()
            for row in r.json():
                acc = got.setdefault(row["rarete"], {"cartes": 0, "boosters_avec": 0})
                acc["cartes"] += row["cartes"]
                acc["boosters_avec"] += row["boosters_avec"]
            done += batch
        exp = expected(b["composition"])
        print(f"\n{b['id']} — {n} boosters simulés")
        print(f"  {'rareté':<12}{'attendu/booster':>16}{'observé':>10}{'≥1 attendu':>12}{'≥1 observé':>12}   affichage")
        for t in TIERS:
            e_per, e_any = exp[t]
            if e_per == 0 and t not in got:
                continue
            o_per = got.get(t, {}).get("cartes", 0) / n
            o_any = got.get(t, {}).get("boosters_avec", 0) / n
            # tolérance : 5 écarts-types (binomial) + 0,2 % absolu
            sigma = (e_any * (1 - e_any) / n) ** 0.5
            good = abs(o_any - e_any) <= 5 * sigma + 0.002
            ok &= good
            shown = f"1 sur {round(1 / e_any)}" if 0 < e_any < 0.5 else f"{e_any:.0%}"
            print(f"  {t:<12}{e_per:>16.3f}{o_per:>10.3f}{e_any:>12.4f}{o_any:>12.4f}   {shown:<12} {'OK' if good else 'ÉCART'}")
    return ok


def check_concurrency(api: str, anon: str, secret: str) -> bool:
    # Contenu de test : une collection avec une seule carte numérotée /5 (mythique).
    psql("""
      insert into public.fighters (id, nom) values ('lt-f', 'Charge Test') on conflict do nothing;
      insert into public.editions (id, nom, annee, type, famille_cadre) values ('lt-ed', 'Charge', 2099, 'originale', 'original') on conflict do nothing;
      insert into public.series (id, edition_id, code, nom, type) values ('lt-ed:BASE', 'lt-ed', 'BASE', 'Base', 'base') on conflict do nothing;
      insert into public.cards (id, edition_id, series_id, numero, ordre, nom_imprime, fighter_ids)
        values ('lt-ed:1', 'lt-ed', 'lt-ed:BASE', '1', 1, 'Charge', '{lt-f}') on conflict do nothing;
      insert into public.variants (id, edition_id, series_id, nom, rarete, effet, reel, tirage) values
        ('lt-ed:BASE:base', 'lt-ed', 'lt-ed:BASE', 'Base', 'commune', 'base', false, null),
        ('lt-ed:BASE:noir', 'lt-ed', 'lt-ed:BASE', 'Noir', 'mythique', 'octogone_noir', false, 5) on conflict do nothing;
      insert into public.booster_types (id, edition_id, nom, type, nb_cartes, composition)
        values ('lt-myth', 'lt-ed', 'Charge', 'premium', 1, '{"slots":[{"nb":1,"poids":{"mythique":100}}]}') on conflict do nothing;
    """)
    admin = {"apikey": secret, "Content-Type": "application/json"}
    if not secret.startswith("sb_"):
        admin["Authorization"] = f"Bearer {secret}"
    tokens, ids = [], []
    try:
        for i in range(8):
            email, pw = f"charge{i}.{secrets.token_hex(3)}@octogone.test", secrets.token_urlsafe(16)
            r = requests.post(f"{api}/auth/v1/admin/users", headers=admin,
                              json={"email": email, "password": pw, "email_confirm": True,
                                    "user_metadata": {"pseudo": f"Charge{i}{secrets.token_hex(2)}"}}, timeout=30)
            r.raise_for_status()
            ids.append(r.json()["id"])
            t = requests.post(f"{api}/auth/v1/token", params={"grant_type": "password"},
                              headers={"apikey": anon}, json={"email": email, "password": pw}, timeout=30)
            t.raise_for_status()
            tokens.append(t.json()["access_token"])

        def open_one(token: str):
            r = requests.post(f"{api}/rest/v1/rpc/open_booster", json={"p_type": "lt-myth"},
                              headers={"apikey": anon, "Authorization": f"Bearer {token}",
                                       "Content-Type": "application/json"}, timeout=60)
            r.raise_for_status()
            return r.json()

        jobs = [tokens[i % len(tokens)] for i in range(48)]
        with cf.ThreadPoolExecutor(max_workers=16) as pool:
            results = [row for res in pool.map(open_one, jobs) for row in res]
        serials = sorted(r["numero_serie"] for r in results if r["variant_id"] == "lt-ed:BASE:noir")
        print(f"\nConcurrence : 48 boosters ouverts en parallèle par 8 comptes")
        print(f"  exemplaires numérotés obtenus : {serials} (les autres boosters ont reçu une carte de repli)")
        db = psql("select count(*) || ' en base, numéros ' || string_agg(numero_serie::text, ',' order by numero_serie) "
                  "from public.owned_cards where variant_id = 'lt-ed:BASE:noir'")
        print(f"  {db}")
        return serials == [1, 2, 3, 4, 5]
    finally:
        for uid in ids:
            requests.delete(f"{api}/auth/v1/admin/users/{uid}", headers=admin, timeout=30)
        psql("""
          delete from public.booster_openings where booster_type_id = 'lt-myth';
          delete from public.owned_cards where card_id = 'lt-ed:1';
          delete from public.booster_types where id = 'lt-myth';
          delete from public.editions where id = 'lt-ed';
          delete from public.fighters where id = 'lt-f';
        """)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=100_000)
    args = ap.parse_args()
    env = local_env()
    api, secret = env["API_URL"], env.get("SECRET_KEY") or env["SERVICE_ROLE_KEY"]
    anon = env.get("PUBLISHABLE_KEY") or env["ANON_KEY"]
    probs = check_probabilities(api, secret, args.n)
    conc = check_concurrency(api, anon, secret)
    print(f"\nProbabilités : {'OK' if probs else 'ÉCART'} — Concurrence : {'OK' if conc else 'ÉCHEC'}")
    sys.exit(0 if probs and conc else 1)


if __name__ == "__main__":
    main()
