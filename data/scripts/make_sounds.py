#!/usr/bin/env python3
"""Génère les sons de l'app par synthèse (aucun fichier tiers, aucun droit à
gérer). Style : cinématique et métallique, avec l'ambiance d'arène (foule,
cloche, gong) réservée aux grandes raretés.

- rip : déchirure de feuille métallisée + souffle grave + coup sourd
- flip : retournement de carte
- swipe : envol d'une carte (panoramique et hauteur réglés dans l'app)
- reveal_<rareté> : intensité croissante de la Commune à la Mythique

Sortie : app/assets/sounds/*.wav (stéréo, 44 100 Hz, 16 bits).
Tout est déterministe (graines fixes) : relancer le script redonne les mêmes
fichiers.
"""
from __future__ import annotations

import wave

import numpy as np
from scipy import signal

from common import ROOT

RATE = 44100
OUT = ROOT / "app" / "assets" / "sounds"


# --- Outils -------------------------------------------------------------------

def axis(dur: float) -> np.ndarray:
    return np.arange(int(dur * RATE)) / RATE


def buffer(dur: float) -> np.ndarray:
    return np.zeros((int(dur * RATE), 2))


def place(buf: np.ndarray, sig: np.ndarray, start: float = 0.0, gain: float = 1.0, pan: float = 0.0) -> None:
    """Ajoute [sig] (mono ou stéréo) dans [buf] à [start] secondes."""
    if sig.ndim == 1:
        a = (pan + 1) * np.pi / 4  # panoramique à puissance constante
        sig = np.stack([sig * np.cos(a), sig * np.sin(a)], axis=1)
    s0 = int(start * RATE)
    n = min(len(sig), len(buf) - s0)
    if n > 0:
        buf[s0:s0 + n] += sig[:n] * gain


def sos(kind: str, freq, order: int = 2):
    return signal.butter(order, freq, btype=kind, fs=RATE, output="sos")


def filt(x: np.ndarray, kind: str, freq, order: int = 2) -> np.ndarray:
    return signal.sosfilt(sos(kind, freq, order), x, axis=0)


def env(t: np.ndarray, attack: float, decay: float) -> np.ndarray:
    return (1 - np.exp(-t / max(attack, 1e-4))) * np.exp(-t / decay)


def noise(dur: float, seed: int) -> np.ndarray:
    return np.random.default_rng(seed).uniform(-1, 1, int(dur * RATE))


def pink(dur: float, seed: int) -> np.ndarray:
    # Filtre 1/f classique (Paul Kellet, version économique)
    b = [0.049922035, -0.095993537, 0.050612699, -0.004408786]
    a = [1, -2.494956002, 2.017265875, -0.522189400]
    return signal.lfilter(b, a, noise(dur, seed)) * 4


def reverb(buf: np.ndarray, seconds: float, wet: float, seed: int = 1, bright: float = 0.5) -> np.ndarray:
    """Réverbération de salle par convolution avec une réponse synthétique
    (bruit qui décroît, plus sombre en fin de queue, légèrement différente à
    gauche et à droite pour l'espace)."""
    t = axis(seconds)
    rng = np.random.default_rng(seed)
    ir = np.zeros((len(t), 2))
    decay = np.exp(-6.9 * t / seconds)
    for ch in range(2):
        n = rng.uniform(-1, 1, len(t))
        dark = filt(n, "lowpass", 2500 + 4000 * bright)
        darker = filt(n, "lowpass", 900 + 1500 * bright)
        mixk = np.clip(t / seconds * 2, 0, 1)
        ir[:, ch] = (dark * (1 - mixk) + darker * mixk) * decay
        # Premières réflexions
        for d, g in ((0.011, 0.6), (0.019, 0.45), (0.027, 0.35), (0.041, 0.25)):
            i = int((d + 0.003 * ch) * RATE)
            if i < len(t):
                ir[i, ch] += g
    ir /= np.sqrt((ir ** 2).sum(axis=0, keepdims=True)) + 1e-9
    out = np.zeros((len(buf) + len(t) - 1, 2))
    for ch in range(2):
        out[:, ch] = signal.fftconvolve(buf[:, ch], ir[:, ch])
    dry = np.zeros_like(out)
    dry[:len(buf)] = buf
    return dry * (1 - wet * 0.5) + out * wet * 2.2


def echo(buf: np.ndarray, delay: float, feedback: float, taps: int, mix: float) -> np.ndarray:
    """Écho ping-pong (gauche puis droite) pour la grande Mythique."""
    d = int(delay * RATE)
    out = np.zeros((len(buf) + d * taps, 2))
    out[:len(buf)] += buf
    g = mix
    for k in range(1, taps + 1):
        ch = k % 2
        out[d * k:d * k + len(buf), ch] += buf[:, ch] * g + buf[:, 1 - ch] * g * 0.4
        g *= feedback
    return out


def finish(buf: np.ndarray, peak: float, fade: float = 0.25, drive: float = 1.4) -> np.ndarray:
    """Coupe le silence final, adoucit la fin, limite en douceur, normalise."""
    level = np.abs(buf).max(axis=1)
    last = np.nonzero(level > level.max() * 0.002)[0]
    buf = buf[:last[-1] + 1] if len(last) else buf
    n = min(len(buf), int(fade * RATE))
    buf[-n:] *= np.linspace(1, 0, n)[:, None] ** 2
    buf = buf / (np.abs(buf).max() + 1e-9)
    buf = np.tanh(buf * drive) / np.tanh(drive)  # limiteur doux : plus dense (drive), jamais saturé
    return buf * peak


def write(name: str, buf: np.ndarray) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    data = (np.clip(buf, -1, 1) * 32767).astype("<i2")
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())


# --- Éléments sonores -----------------------------------------------------------

def sub_drop(dur: float, f0: float, f1: float, decay: float, drive: float = 1.5) -> np.ndarray:
    """Impact grave : sinus qui chute en fréquence, légèrement saturé."""
    t = axis(dur)
    f = f1 + (f0 - f1) * np.exp(-t * 9)
    ph = 2 * np.pi * np.cumsum(f) / RATE
    x = np.sin(ph) + 0.25 * np.sin(2 * ph)
    return np.tanh(x * drive) * env(t, 0.002, decay)


def click(dur: float = 0.03, seed: int = 5, cutoff: float = 3000) -> np.ndarray:
    t = axis(dur)
    return filt(noise(dur, seed), "highpass", cutoff) * np.exp(-t / 0.004)


def body(dur: float, seed: int, cutoff: float, decay: float) -> np.ndarray:
    """Corps de l'impact : souffle grave filtré."""
    t = axis(dur)
    return filt(noise(dur, seed), "lowpass", cutoff, 4) * env(t, 0.003, decay)


def shimmer(dur: float, base: float, seed: int, decay: float, density: int = 9) -> np.ndarray:
    """Scintillement métallique : partiels inharmoniques (barre de métal)
    éparpillés en stéréo, avec un léger trémolo."""
    t = axis(dur)
    rng = np.random.default_rng(seed)
    out = np.zeros((len(t), 2))
    ratios = [1.0, 2.756, 5.404, 8.933, 1.5, 3.9, 6.3, 2.1, 4.7, 7.6, 10.2]
    for k in range(density):
        f = base * ratios[k % len(ratios)] * (1 + rng.uniform(-0.01, 0.01))
        if f > 15000:
            continue
        delay = rng.uniform(0, 0.12)
        tt = np.clip(t - delay, 0, None)
        a = (0.9 / (1 + k * 0.45)) * env(tt, 0.004, decay * rng.uniform(0.5, 1.1)) * (t >= delay)
        trem = 1 + 0.25 * np.sin(2 * np.pi * rng.uniform(5, 9) * t + rng.uniform(0, 6))
        x = np.sin(2 * np.pi * f * tt + rng.uniform(0, 6)) * a * trem
        p = rng.uniform(-0.8, 0.8)
        out[:, 0] += x * np.cos((p + 1) * np.pi / 4)
        out[:, 1] += x * np.sin((p + 1) * np.pi / 4)
    return out


def saw_voice(f: float, t: np.ndarray, bright: np.ndarray, harmonics: int = 32) -> np.ndarray:
    """Dent de scie additive dont la brillance suit [bright] (0..1)."""
    x = np.zeros_like(t)
    for k in range(1, harmonics + 1):
        if f * k > 16000:
            break
        w = np.exp(-(k - 1) / (1.5 + 14 * bright)) / k
        x += w * np.sin(2 * np.pi * f * k * t)
    return x


def brass(freqs: list[float], dur: float, attack: float, decay: float, seed: int) -> np.ndarray:
    """Accord cuivré : voix légèrement désaccordées, l'éclat s'ouvre à l'attaque."""
    t = axis(dur)
    rng = np.random.default_rng(seed)
    bright = env(t, attack * 0.6, decay * 0.8)
    bright /= bright.max() + 1e-9
    out = np.zeros((len(t), 2))
    for i, f in enumerate(freqs):
        for det, p in ((-0.004, -0.5), (0.004, 0.5)):
            v = saw_voice(f * (1 + det + rng.uniform(-0.001, 0.001)), t, bright)
            out[:, 0] += v * np.cos((p + 1) * np.pi / 4)
            out[:, 1] += v * np.sin((p + 1) * np.pi / 4)
    return out * env(t, attack, decay)[:, None] / len(freqs)


def choir(freqs: list[float], dur: float, attack: float, decay: float, seed: int) -> np.ndarray:
    """Chœur « aah » : harmoniques pondérées par les formants de la voyelle a."""
    t = axis(dur)
    rng = np.random.default_rng(seed)
    formants = ((730, 90, 1.0), (1090, 110, 0.5), (2440, 160, 0.25))
    out = np.zeros((len(t), 2))
    for f in freqs:
        for voice in range(3):
            f0 = f * (1 + rng.uniform(-0.006, 0.006))
            vib = 1 + 0.004 * np.sin(2 * np.pi * rng.uniform(4.8, 6) * t + rng.uniform(0, 6))
            x = np.zeros_like(t)
            for k in range(1, 40):
                fk = f0 * k
                if fk > 9000:
                    break
                w = sum(g * np.exp(-((fk - c) / bw) ** 2) for c, bw, g in formants) + 0.02 / k
                x += w * np.sin(2 * np.pi * fk * np.cumsum(vib) / RATE)
            p = rng.uniform(-0.7, 0.7)
            out[:, 0] += x * np.cos((p + 1) * np.pi / 4)
            out[:, 1] += x * np.sin((p + 1) * np.pi / 4)
    return out * env(t, attack, decay)[:, None] / (len(freqs) * 3)


def crowd(dur: float, intensity: float, seed: int, swell: float = 0.5) -> np.ndarray:
    """Foule d'arène : rumeur de fond, cris (bruit à formants), sifflets et
    applaudissements, qui montent en [swell] secondes."""
    t = axis(dur)
    rng = np.random.default_rng(seed)
    out = np.zeros((len(t), 2))
    shape = np.clip(t / swell, 0, 1) ** 0.7 * np.exp(-np.clip(t - swell, 0, None) / (dur * 0.55))
    # Rumeur
    for ch in range(2):
        r = filt(pink(dur, seed + ch), "bandpass", (220, 3200))
        mod = 1 + 0.3 * np.sin(2 * np.pi * 0.7 * t + ch) + 0.2 * np.sin(2 * np.pi * 1.9 * t + 2 * ch)
        out[:, ch] += r * mod * shape * 0.8
    # Cris
    for _ in range(int(30 + 70 * intensity)):
        start = rng.uniform(0, swell * 1.4)
        length = rng.uniform(0.25, 0.9)
        n = int(length * RATE)
        s0 = int(start * RATE)
        if s0 + n >= len(t):
            continue
        c = rng.uniform(450, 1400)
        v = filt(noise(length, int(rng.integers(1e6))), "bandpass", (c * 0.8, c * 1.25))
        v *= np.sin(np.linspace(0, np.pi, n)) ** 1.5 * rng.uniform(0.3, 1.0)
        p = rng.uniform(-0.9, 0.9)
        out[s0:s0 + n, 0] += v * np.cos((p + 1) * np.pi / 4) * 1.6
        out[s0:s0 + n, 1] += v * np.sin((p + 1) * np.pi / 4) * 1.6
    # Sifflets (foule en délire)
    for _ in range(int(6 * intensity)):
        start = rng.uniform(0.1, swell * 1.6)
        length = rng.uniform(0.3, 0.7)
        tt = axis(length)
        s0 = int(start * RATE)
        if s0 + len(tt) >= len(t):
            continue
        f = rng.uniform(1800, 2900) * (1 + 0.06 * np.sin(np.pi * tt / length))
        v = np.sin(2 * np.pi * np.cumsum(f) / RATE) * np.sin(np.pi * tt / length) * 0.12
        place(out, v, start, pan=rng.uniform(-0.8, 0.8))
    # Applaudissements
    for _ in range(int(120 * intensity)):
        start = rng.uniform(0.05, dur * 0.85)
        place(out, filt(noise(0.012, int(rng.integers(1e6))), "bandpass", (900, 5000)) * np.exp(-axis(0.012) / 0.003),
              start, gain=rng.uniform(0.1, 0.35) * float(np.interp(start, t, shape)), pan=rng.uniform(-0.9, 0.9))
    return out * intensity


def bell(f: float, dur: float, seed: int, decay: float = 2.2) -> np.ndarray:
    """Cloche (partiels d'une cloche d'église : bourdon, tierce mineure…)."""
    t = axis(dur)
    rng = np.random.default_rng(seed)
    partials = ((0.5, 0.5, 1.6), (1.0, 1.0, 1.0), (1.19, 0.6, 0.8), (1.5, 0.5, 0.7), (2.0, 0.45, 0.6),
                (2.51, 0.3, 0.45), (2.66, 0.25, 0.4), (3.01, 0.2, 0.35), (4.16, 0.12, 0.25))
    out = np.zeros_like(t)
    for r, a, d in partials:
        out += a * np.sin(2 * np.pi * f * r * t + rng.uniform(0, 6)) * env(t, 0.002, decay * d)
    return out + 0.4 * click(dur, seed, 2500)[:len(t)]


def gong(f: float, dur: float, seed: int) -> np.ndarray:
    """Gong : partiels graves inharmoniques ; les aigus s'épanouissent après
    la frappe, avec un léger battement."""
    t = axis(dur)
    rng = np.random.default_rng(seed)
    out = np.zeros_like(t)
    for i, r in enumerate((1, 1.47, 1.95, 2.42, 2.87, 3.41, 4.13, 4.9, 5.7, 6.6)):
        bloom = np.clip(t / (0.05 + 0.08 * i), 0, 1)
        beat = 1 + 0.15 * np.sin(2 * np.pi * rng.uniform(0.5, 2.5) * t)
        out += (1 / (1 + 0.5 * i)) * np.sin(2 * np.pi * f * r * (1 - 0.003 * np.exp(-t)) * t) * bloom * beat \
            * np.exp(-t / (dur * (0.5 - 0.035 * i)))
    return out + 0.6 * body(dur, seed, 400, 0.15)


def whoosh(dur: float, f0: float, f1: float, seed: int) -> np.ndarray:
    """Souffle dont la hauteur glisse de f0 à f1 (bandes de bruit en fondu)."""
    t = axis(dur)
    n = noise(dur, seed)
    bands = np.geomspace(f0, f1, 7)
    pos = np.linspace(0, len(bands) - 1, len(t))
    out = np.zeros_like(t)
    for i, c in enumerate(bands):
        w = np.clip(1 - np.abs(pos - i), 0, 1)
        out += filt(n, "bandpass", (c * 0.7, min(c * 1.4, RATE / 2 - 100))) * w
    return out * np.sin(np.pi * t / dur) ** 1.6


# --- Sons de l'app ----------------------------------------------------------------

def rip() -> np.ndarray:
    """Déchirure de feuille métallisée : crépitement qui s'accélère, petits
    tintements de métal, souffle grave dessous et coup sourd final."""
    dur = 0.95
    buf = buffer(dur)
    rng = np.random.default_rng(7)
    t = axis(0.62)
    tear = filt(noise(0.62, 11), "highpass", 2200)
    grain = np.repeat(rng.uniform(0.15, 1.0, len(t) // 90 + 1), 90)[:len(t)]
    tear *= grain * np.clip(t / 0.05, 0, 1) * (0.5 + 0.8 * t / 0.62) * np.exp(-np.clip(t - 0.5, 0, None) / 0.04)
    place(buf, tear, 0.0, 0.55, pan=-0.2)
    place(buf, filt(noise(0.62, 12), "highpass", 2200) * grain[::-1] * np.clip(t / 0.08, 0, 1)
          * np.exp(-np.clip(t - 0.5, 0, None) / 0.04), 0.0, 0.4, pan=0.25)
    # Crépitements de la feuille
    for _ in range(140):
        s = rng.uniform(0, 0.55) ** 0.8
        tt = axis(0.008)
        ping = filt(noise(0.008, int(rng.integers(1e6))), "bandpass", (3500, 9000)) * np.exp(-tt / 0.0015)
        place(buf, ping, s, rng.uniform(0.2, 0.7), pan=rng.uniform(-0.6, 0.6))
    # Tintements métalliques
    for _ in range(9):
        s = rng.uniform(0.05, 0.55)
        f = rng.uniform(4200, 7800)
        tt = axis(0.08)
        place(buf, np.sin(2 * np.pi * f * tt) * np.exp(-tt / 0.02), s, 0.06, pan=rng.uniform(-0.7, 0.7))
    # Souffle grave + coup sourd
    place(buf, filt(noise(0.7, 13), "lowpass", 260, 4) * np.sin(np.pi * axis(0.7) / 0.7) ** 2, 0.0, 1.4)
    place(buf, sub_drop(0.35, 120, 55, 0.08, 2.2), 0.55, 0.8)
    place(buf, body(0.2, 14, 900, 0.03), 0.55, 0.5)
    return finish(reverb(buf, 0.9, 0.18, 3, 0.6), 0.8, 0.15)


def flip() -> np.ndarray:
    """Carte qui pivote : frottement bref et claquement net."""
    buf = buffer(0.3)
    place(buf, whoosh(0.16, 1200, 5200, 21), 0.0, 0.6)
    place(buf, click(0.03, 22, 2500), 0.15, 0.7)
    place(buf, body(0.06, 23, 1600, 0.015), 0.15, 0.4)
    return finish(reverb(buf, 0.4, 0.1, 4), 0.55, 0.05)


def swipe() -> np.ndarray:
    """Envol de carte."""
    buf = buffer(0.42)
    place(buf, whoosh(0.4, 500, 3600, 31), 0.0, 1.0)
    place(buf, whoosh(0.3, 2500, 7000, 32), 0.05, 0.35)
    return finish(reverb(buf, 0.6, 0.12, 5), 0.5, 0.08)


def reveal_commune() -> np.ndarray:
    """Clic feutré."""
    buf = buffer(0.5)
    t = axis(0.25)
    place(buf, np.sin(2 * np.pi * (170 + 60 * np.exp(-t * 40)) * t) * env(t, 0.002, 0.05), 0, 0.9)
    place(buf, body(0.1, 41, 1400, 0.012), 0, 0.5)
    return finish(reverb(buf, 0.5, 0.12, 6), 0.42, 0.1, drive=1.2)


def reveal_peu_commune() -> np.ndarray:
    """Clic feutré + léger scintillement."""
    buf = buffer(1.1)
    t = axis(0.25)
    place(buf, np.sin(2 * np.pi * (190 + 60 * np.exp(-t * 40)) * t) * env(t, 0.002, 0.06), 0, 0.9)
    place(buf, body(0.12, 51, 1600, 0.015), 0, 0.5)
    place(buf, shimmer(0.9, 2300, 52, 0.35, 6), 0.02, 0.35)
    return finish(reverb(buf, 0.9, 0.2, 7), 0.52)


def reveal_rare() -> np.ndarray:
    """Impact + scintillement plus brillant."""
    buf = buffer(1.8)
    place(buf, click(0.03, 61), 0, 0.6)
    place(buf, sub_drop(0.7, 115, 46, 0.2, 1.8), 0, 1.2)
    place(buf, body(0.3, 62, 800, 0.07), 0, 0.9)
    place(buf, shimmer(1.4, 1700, 63, 0.6, 9), 0.01, 0.45)
    return finish(reverb(buf, 1.3, 0.25, 8), 0.72, drive=2.0)


def reveal_epique() -> np.ndarray:
    """Impact plus lourd + accord cuivré triomphant."""
    buf = buffer(2.6)
    place(buf, click(0.03, 71), 0, 0.7)
    place(buf, sub_drop(0.9, 120, 42, 0.25, 2.0), 0, 1.0)
    place(buf, body(0.4, 72, 600, 0.09), 0, 0.8)
    d3 = 146.83
    place(buf, brass([d3, d3 * 1.5, d3 * 2, d3 * 2.52], 2.0, 0.025, 0.7, 73), 0.02, 1.4)
    place(buf, shimmer(1.8, 1500, 74, 0.8, 10), 0.03, 0.45)
    return finish(reverb(buf, 1.8, 0.28, 9), 0.8, drive=2.2)


def reveal_legendaire() -> np.ndarray:
    """Grondement, cuivres tenus, cloche, foule qui se lève, longue réverbération."""
    buf = buffer(4.0)
    place(buf, click(0.04, 81), 0, 0.8)
    place(buf, sub_drop(1.4, 110, 36, 0.4, 2.4), 0, 1.15)
    place(buf, body(0.6, 82, 500, 0.14), 0, 0.9)
    d3 = 146.83
    place(buf, brass([d3 / 2, d3, d3 * 1.5, d3 * 2, d3 * 2.52], 3.2, 0.04, 1.3, 83), 0.03, 1.5)
    place(buf, bell(587.3, 3.2, 84, 2.4), 0.05, 0.42, pan=0.15)
    place(buf, shimmer(2.6, 1400, 85, 1.1, 11), 0.05, 0.5)
    place(buf, crowd(3.6, 0.65, 86, swell=0.7), 0.1, 0.55)
    return finish(reverb(buf, 2.4, 0.3, 10, 0.55), 0.9, 0.5, drive=2.4)


def reveal_mythique() -> np.ndarray:
    """Boom énorme, gong, chœur, cuivres, foule en délire, écho long."""
    buf = buffer(5.2)
    place(buf, click(0.05, 91, 2000), 0, 0.9)
    place(buf, sub_drop(2.0, 95, 30, 0.6, 3.0), 0, 1.3)
    place(buf, body(0.9, 92, 380, 0.22), 0, 1.0)
    place(buf, gong(98, 4.5, 93), 0.02, 0.75)
    d3 = 146.83
    swell = buffer(4.4)
    place(swell, brass([d3 / 2, d3, d3 * 1.5, d3 * 2, d3 * 2.52, d3 * 3], 4.2, 0.06, 1.8, 94), 0, 1.4)
    place(swell, choir([d3 * 2, d3 * 2.52, d3 * 3], 4.2, 0.35, 2.2, 95), 0.05, 1.6)
    place(buf, echo(swell, 0.36, 0.45, 4, 0.35)[:int(5.1 * RATE)], 0.03, 1.0)
    place(buf, bell(880, 3.5, 96, 2.0), 0.08, 0.35, pan=-0.2)
    place(buf, shimmer(3.4, 1300, 97, 1.4, 11), 0.05, 0.55)
    place(buf, crowd(4.8, 1.0, 98, swell=0.6), 0.08, 0.75)
    return finish(reverb(buf, 3.2, 0.32, 11, 0.5), 0.97, 0.8, drive=2.6)


def main() -> None:
    for name, fn in (("rip", rip), ("flip", flip), ("swipe", swipe),
                     ("reveal_commune", reveal_commune), ("reveal_peu_commune", reveal_peu_commune),
                     ("reveal_rare", reveal_rare), ("reveal_epique", reveal_epique),
                     ("reveal_legendaire", reveal_legendaire), ("reveal_mythique", reveal_mythique)):
        write(name, fn())
    for p in sorted(OUT.glob("*.wav")):
        with wave.open(str(p)) as w:
            print(f"{p.name}: {w.getnframes() / w.getframerate():.2f} s, {p.stat().st_size // 1024} Ko")


if __name__ == "__main__":
    main()
