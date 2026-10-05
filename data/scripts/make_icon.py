"""Icône de l'app (Android + iOS) : le logo de l'écran d'entrée (octogone
noir, anneaux multicolores, cadre en métal noir, liseré doré). Création
originale, générée sans fichier externe.

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


def hsv(h: float) -> tuple[int, int, int]:
    """Teinte de l'arc-en-ciel (saturation 0,7, comme le shader de l'app)."""
    import colorsys
    r, g, b = colorsys.hsv_to_rgb(h % 1.0, 0.7, 1.0)
    return round(r * 255), round(g * 255), round(b * 255)


def rainbow_ring(size: int, c: float, r: float, width: float, alpha: int) -> Image.Image:
    """Anneau octogonal dont la couleur suit l'angle autour du centre (comme
    les anneaux holographiques de l'écran d'entrée) : couronne pleine entre
    deux octogones, coloriée par un dégradé conique (angles nets)."""
    import numpy as np
    yy, xx = np.mgrid[0:size, 0:size]
    hue = (np.arctan2(yy - c, xx - c) / (2 * np.pi)) % 1.0
    # hsv -> rgb vectorisé (s = 0,7, v = 1)
    k = np.stack([(5 + hue * 6) % 6, (3 + hue * 6) % 6, (1 + hue * 6) % 6], axis=-1)
    rgb = 1 - 0.7 * np.clip(np.minimum(k, 4 - k), 0, 1)
    colour = Image.fromarray((rgb * 255).astype("uint8"), "RGB")
    mask = Image.new("L", (size, size), 0)
    md = ImageDraw.Draw(mask)
    md.polygon(octagon(c, c, r + width / 2), fill=alpha)
    md.polygon(octagon(c, c, r - width / 2), fill=0)
    layer = colour.convert("RGBA")
    layer.putalpha(mask)
    return layer


def build() -> Image.Image:
    """Logo de l'écran d'entrée : octogone noir, anneaux multicolores
    concentriques, cadre en métal noir, liseré doré, halo doré."""
    big = S * 2  # dessin en double résolution puis réduction (bords lisses)
    img = radial(big, (40, 33, 22), (11, 10, 8))
    c = big / 2
    R = big * 0.42
    # Halo doré
    glow = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    ImageDraw.Draw(glow).polygon(octagon(c, c, R * 1.02), fill=GOLD + (110,))
    glow = glow.filter(ImageFilter.GaussianBlur(big * 0.04))
    img.paste(glow, (0, 0), glow)
    d = ImageDraw.Draw(img)
    # Liseré doré extérieur puis cadre en métal noir
    d.polygon(octagon(c, c, R), fill=GOLD_LIGHT)
    metal = Image.new("RGB", (big, big))
    md = ImageDraw.Draw(metal)
    for i in range(8):  # facettes du cadre, alternance sombre / reflet
        a0 = math.pi / 8 + i * math.pi / 4
        a1 = a0 + math.pi / 4
        shade = 58 if i % 2 else 14
        md.polygon([(c, c), (c + R * math.cos(a0), c + R * math.sin(a0)), (c + R * math.cos(a1), c + R * math.sin(a1))],
                   fill=(shade, shade, shade))
    mask = Image.new("L", (big, big), 0)
    ImageDraw.Draw(mask).polygon(octagon(c, c, R * 0.985), fill=255)
    img.paste(metal.filter(ImageFilter.GaussianBlur(big * 0.01)), (0, 0), mask)
    # Intérieur noir mat
    inner = radial(big, (32, 32, 32), (7, 7, 7))
    mask = Image.new("L", (big, big), 0)
    ImageDraw.Draw(mask).polygon(octagon(c, c, R * 0.93), fill=255)
    img.paste(inner, (0, 0), mask)
    # Filet doré intérieur
    d.line(octagon(c, c, R * 0.86) + [octagon(c, c, R * 0.86)[0]], fill=(156, 114, 36), width=round(big * 0.004))
    # Anneaux multicolores (lueur puis trait)
    for rr, w, a in ((0.714, 0.034, 255), (0.628, 0.02, 160)):
        ring = rainbow_ring(big, c, R * rr, big * w, a)
        halo = ring.filter(ImageFilter.GaussianBlur(big * 0.012))
        img.paste(halo, (0, 0), halo)
        img.paste(ring, (0, 0), ring)
    # Paillettes
    rng = __import__("random").Random(9)
    for _ in range(45):
        ang = rng.uniform(0, 2 * math.pi)
        dist = R * 0.85 * math.sqrt(rng.random())  # répartition uniforme sur la surface
        x, y = c + dist * math.cos(ang), c + dist * math.sin(ang)
        rad = rng.uniform(big * 0.0015, big * 0.004)
        col = hsv(ang / (2 * math.pi)) if rng.random() < 0.6 else (255, 244, 214)
        d.ellipse([x - rad, y - rad, x + rad, y + rad], fill=col)
    return img.resize((S, S), Image.LANCZOS)


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
