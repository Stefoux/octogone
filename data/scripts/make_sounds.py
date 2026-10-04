#!/usr/bin/env python3
"""Génère les sons de l'app par synthèse (aucun fichier tiers, aucun droit à
gérer) : déchirure du booster, retournement de carte, carillon de révélation
selon la rareté. Sortie : app/assets/sounds/*.wav (mono, 22 050 Hz, 16 bits).
"""
from __future__ import annotations

import math
import random
import struct
import wave

from common import ROOT

RATE = 22050
OUT = ROOT / "app" / "assets" / "sounds"


def write(name: str, samples: list[float]) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    peak = max(1e-9, max(abs(s) for s in samples))
    gain = 0.85 / peak
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * gain)) * 32767)) for s in samples))


def bell(freq: float, dur: float, decay: float = 4.0, start: float = 0.0, total: float | None = None) -> list[float]:
    """Note de cloche (fondamentale + harmoniques inharmoniques légères)."""
    n = int((total or (start + dur)) * RATE)
    out = [0.0] * n
    s0 = int(start * RATE)
    for i in range(int(dur * RATE)):
        t = i / RATE
        env = math.exp(-decay * t) * min(1.0, t * 400)
        v = (math.sin(2 * math.pi * freq * t)
             + 0.45 * math.sin(2 * math.pi * freq * 2.01 * t)
             + 0.2 * math.sin(2 * math.pi * freq * 3.02 * t))
        if s0 + i < n:
            out[s0 + i] += v * env
    return out


def mix(*tracks: list[float]) -> list[float]:
    n = max(len(t) for t in tracks)
    return [sum(t[i] for t in tracks if i < len(t)) for i in range(n)]


def lowpass(x: list[float], k: int) -> list[float]:
    out, acc = [], 0.0
    for i, v in enumerate(x):
        acc += v
        if i >= k:
            acc -= x[i - k]
        out.append(acc / k)
    return out


def rip() -> list[float]:
    rnd = random.Random(7)
    n = int(0.5 * RATE)
    noise = [rnd.uniform(-1, 1) for _ in range(n)]
    noise = [a - b for a, b in zip(noise, lowpass(noise, 6))]  # garde les aigus (papier)
    out = []
    crackle = 1.0
    for i, v in enumerate(noise):
        t = i / RATE
        if i % 180 == 0:
            crackle = 0.3 + rnd.random() * 0.9
        env = min(1.0, t * 60) * math.exp(-3.2 * max(0, t - 0.08))
        out.append(v * env * crackle)
    return out


def flip() -> list[float]:
    rnd = random.Random(3)
    n = int(0.16 * RATE)
    noise = lowpass([rnd.uniform(-1, 1) for _ in range(n)], 4)
    return [v * math.sin(math.pi * (i / n)) ** 2 for i, v in enumerate(noise)]


def shimmer(dur: float, start: float, total: float) -> list[float]:
    n = int(total * RATE)
    out = [0.0] * n
    s0 = int(start * RATE)
    for i in range(int(dur * RATE)):
        t = i / RATE
        v = sum(math.sin(2 * math.pi * f * t) for f in (2637, 3136, 3520)) / 3
        env = math.sin(math.pi * t / dur) * (0.5 + 0.5 * math.sin(2 * math.pi * 11 * t))
        if s0 + i < n:
            out[s0 + i] += 0.35 * v * env
    return out


def boom(total: float) -> list[float]:
    n = int(total * RATE)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / RATE
        f = 40 + 70 * math.exp(-6 * t)
        phase += 2 * math.pi * f / RATE
        out.append(math.sin(phase) * math.exp(-3.5 * t) * min(1, t * 200))
    return out


def main() -> None:
    C6, E6, G6, C7 = 1046.5, 1318.5, 1568.0, 2093.0
    write("rip", rip())
    write("flip", flip())
    write("reveal_commune", bell(1760, 0.12, decay=30))
    write("reveal_peu_commune", mix(bell(1318.5, 0.25, 14), bell(1760, 0.25, 14, start=0.06)))
    write("reveal_rare", mix(bell(C6, 0.5, 7), bell(E6, 0.5, 7, start=0.09)))
    write("reveal_epique", mix(bell(C6, 0.7, 6), bell(E6, 0.7, 6, start=0.09), bell(G6, 0.7, 6, start=0.18)))
    total = 1.1
    write("reveal_legendaire", mix(
        bell(C6, 0.9, 4.5, total=total), bell(E6, 0.9, 4.5, start=0.08, total=total),
        bell(G6, 0.9, 4.5, start=0.16, total=total), bell(C7, 0.9, 4, start=0.24, total=total),
        shimmer(0.8, 0.25, total)))
    total = 1.5
    write("reveal_mythique", mix(
        boom(total), bell(C6, 1.2, 3.5, start=0.15, total=total), bell(E6, 1.2, 3.5, start=0.23, total=total),
        bell(G6, 1.2, 3.5, start=0.31, total=total), bell(C7, 1.2, 3, start=0.39, total=total),
        shimmer(1.0, 0.4, total)))
    for p in sorted(OUT.glob("*.wav")):
        print(f"{p.name}: {p.stat().st_size // 1024} Ko")


if __name__ == "__main__":
    main()
