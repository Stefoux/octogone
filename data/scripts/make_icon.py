"""Icône de l'app (Android + iOS) : octogone noir à bord doré et losange,
comme l'emblème des boosters. Création originale, générée sans fichier externe.

    .venv/bin/python make_icon.py
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

APP = Path(__file__).resolve().parents[2] / "app"
S = 1024
GOLD = (226, 176, 79)
GOLD_LIGHT = (247, 226, 174)
GOLD_DEEP = (156, 114, 36)


def octagon(cx: float, cy: float, r: float) -> list[tuple[float, float]]:
    return [(cx + r * math.cos(math.pi / 8 + i * math.pi / 4), cy + r * math.sin(math.pi / 8 + i * math.pi / 4))
            for i in range(8)]


def radial(size: int, inner: tuple, outer: tuple) -> Image.Image:
    img = Image.new("RGB", (size, size), outer)
    px = img.load()
    c = size / 2
    for y in range(size):
        for x in range(size):
            t = min(1.0, math.hypot(x - c, y - c * 0.85) / (size * 0.72))
            px[x, y] = tuple(round(inner[k] + (outer[k] - inner[k]) * t) for k in range(3))
    return img


def build() -> Image.Image:
    img = radial(S, (40, 33, 22), (11, 10, 8))
    c = S / 2
    # Halo doré
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(glow).polygon(octagon(c, c, S * 0.40), fill=GOLD + (120,))
    img.paste(glow.filter(ImageFilter.GaussianBlur(40)), (0, 0), glow.filter(ImageFilter.GaussianBlur(40)))
    d = ImageDraw.Draw(img)
    # Bord doré (trois anneaux pour un effet métal), puis octogone noir
    d.polygon(octagon(c, c, S * 0.40), fill=GOLD_DEEP)
    d.polygon(octagon(c, c, S * 0.385), fill=GOLD_LIGHT)
    d.polygon(octagon(c, c, S * 0.37), fill=GOLD)
    inner = radial(S, (34, 34, 34), (6, 6, 6))
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).polygon(octagon(c, c, S * 0.345), fill=255)
    img.paste(inner, (0, 0), mask)
    # Liseré intérieur
    d.line(octagon(c, c, S * 0.29) + [octagon(c, c, S * 0.29)[0]], fill=GOLD_DEEP, width=6)
    # Losange central
    h, w = S * 0.17, S * 0.11
    d.polygon([(c, c - h), (c + w, c), (c, c + h), (c - w, c)], fill=GOLD)
    d.polygon([(c, c - h), (c + w, c), (c, c)], fill=GOLD_LIGHT)
    d.polygon([(c, c + h), (c - w, c), (c, c)], fill=GOLD_DEEP)
    return img


def foreground() -> Image.Image:
    """Premier plan de l'icône adaptative Android (fond transparent, l'emblème
    tient dans la zone sûre de 66/108)."""
    full = build().convert("RGBA")
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).polygon(octagon(S / 2, S / 2, S * 0.405), fill=255)
    full.putalpha(mask)
    canvas = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    scaled = full.resize((round(S * 0.6), round(S * 0.6)), Image.LANCZOS)
    canvas.paste(scaled, ((S - scaled.width) // 2, (S - scaled.height) // 2), scaled)
    return canvas


def main() -> None:
    icon = build()
    fg = foreground()
    res = APP / "android/app/src/main/res"
    for folder, px in {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}.items():
        fg.resize((px, px), Image.LANCZOS).save(res / f"mipmap-{folder}/ic_launcher_foreground.png")
    (res / "mipmap-anydpi-v26").mkdir(exist_ok=True)
    (res / "mipmap-anydpi-v26/ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/octogone_background" />\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
        '</adaptive-icon>\n')
    for folder, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        icon.resize((px, px), Image.LANCZOS).save(APP / f"android/app/src/main/res/mipmap-{folder}/ic_launcher.png")
    ios = APP / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for f in ios.glob("Icon-App-*.png"):
        size = round(float(f.stem.split("-")[-1].split("x")[0]) * int(f.stem.split("@")[1][0]))
        icon.resize((size, size), Image.LANCZOS).save(f)
    print("icônes écrites")


if __name__ == "__main__":
    main()
