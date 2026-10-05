#!/usr/bin/env python3
"""Prépare les photos des sachets de boosters.

Entrée : data/images/boosters/originaux/
  - combattant-1.png … combattant-5.png (détourés, fond transparent)
  - champion.jpg (photo du combattant phare, gardée entière avec son fond)
Sortie : app/assets/boosters/
  - combattant-N.png : buste (tête + haut du buste) recadré d'après le visage,
    fondu vers le bas pour se superposer proprement dans la disposition en V ;
  - champion.jpg : agrandi et légèrement accentué.

Pour changer une photo : remplacer le fichier dans originaux/ (même nom) puis
relancer ce script. Le code de l'app n'a pas à changer.

    .venv/bin/python prepare_booster_art.py
"""
from __future__ import annotations

import cv2
import numpy as np
from PIL import Image, ImageFilter

from common import ROOT

SRC = ROOT / "data" / "images" / "boosters" / "originaux"
OUT = ROOT / "app" / "assets" / "boosters"

# Buste : du haut du crâne (avec un peu d'air) jusque sous les pectoraux,
# soit 3,3 hauteurs de visage détecté ; rapport largeur/hauteur 0,8.
BUST_H_FACES = 3.3
BUST_ASPECT = 0.8
BUST_OUT_W = 560
FADE = 0.28  # part basse du buste qui s'efface en transparence

_cascades = [cv2.CascadeClassifier(cv2.data.haarcascades + n)
             for n in ("haarcascade_frontalface_default.xml", "haarcascade_frontalface_alt2.xml")]


def face_box(rgba: Image.Image) -> tuple[int, int, int, int] | None:
    """Plus grand visage détecté (x, y, l, h), sinon None."""
    rgb = Image.new("RGB", rgba.size, (128, 128, 128))
    rgb.paste(rgba, mask=rgba.split()[3])
    gray = cv2.cvtColor(np.array(rgb), cv2.COLOR_RGB2GRAY)
    best = None
    for c in _cascades:
        faces = c.detectMultiScale(gray, scaleFactor=1.05, minNeighbors=5, minSize=(30, 30))
        for f in faces:
            if best is None or f[2] * f[3] > best[2] * best[3]:
                best = tuple(int(v) for v in f)
        if best is not None:
            break
    return best


def fallback_face(rgba: Image.Image) -> tuple[int, int, int, int]:
    """Sans visage détecté : tête estimée d'après la silhouette (haut du
    contour, largeur des premières lignes opaques)."""
    a = np.array(rgba.split()[3]) > 40
    rows = np.nonzero(a.any(axis=1))[0]
    top = int(rows[0])
    h = a.shape[0]
    band = a[top:top + max(10, h // 8)]
    cols = np.nonzero(band.any(axis=0))[0]
    w = max(20, int(cols[-1] - cols[0]))
    cx = int((cols[0] + cols[-1]) / 2)
    fh = int(w * 0.95)
    return cx - w // 2, top + fh // 6, w, fh


def bust(path) -> Image.Image:
    im = Image.open(path).convert("RGBA")
    fx, fy, fw, fh = face_box(im) or fallback_face(im)
    cx = fx + fw / 2
    h = fh * BUST_H_FACES
    w = h * BUST_ASPECT
    top = fy - fh * 0.6
    box = (cx - w / 2, top, cx + w / 2, top + h)
    # Recadrage avec marge transparente si la boîte dépasse l'image
    canvas = Image.new("RGBA", (int(round(w)), int(round(h))), (0, 0, 0, 0))
    src = im.crop(tuple(int(round(v)) for v in box))
    canvas.paste(src, (0, 0))
    out_h = int(BUST_OUT_W / BUST_ASPECT)
    canvas = canvas.resize((BUST_OUT_W, out_h), Image.LANCZOS)
    # Légère accentuation après agrandissement
    rgb = canvas.convert("RGB").filter(ImageFilter.UnsharpMask(radius=1.6, percent=55, threshold=2))
    alpha = np.array(canvas.split()[3]).astype(np.float32)
    # Fondu vers le bas
    y = np.linspace(0, 1, out_h)[:, None]
    fade = np.clip((1 - y) / FADE, 0, 1) ** 1.4
    alpha *= fade
    result = rgb.convert("RGBA")
    result.putalpha(Image.fromarray(alpha.astype(np.uint8)))
    return result


def champion(path) -> Image.Image:
    im = Image.open(path).convert("RGB")
    target_w = 760
    im = im.resize((target_w, int(im.height * target_w / im.width)), Image.LANCZOS)
    return im.filter(ImageFilter.UnsharpMask(radius=2, percent=60, threshold=3))


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for i in range(1, 6):
        src = SRC / f"combattant-{i}.png"
        if not src.exists():
            print(f"absent : {src.name} (le sachet garde l'ancien visuel)")
            continue
        found = face_box(Image.open(src).convert("RGBA")) is not None
        bust(src).save(OUT / f"combattant-{i}.png", optimize=True)
        print(f"combattant-{i}.png : buste {'d’après le visage' if found else 'estimé (visage non détecté)'}")
    src = SRC / "champion.jpg"
    if src.exists():
        champion(src).save(OUT / "champion.jpg", quality=88, optimize=True)
        print("champion.jpg : prêt")
    for p in sorted(OUT.iterdir()):
        print(f"  {p.name} : {p.stat().st_size // 1024} Ko")


if __name__ == "__main__":
    main()
