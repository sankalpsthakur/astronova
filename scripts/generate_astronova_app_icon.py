#!/usr/bin/env python3
"""Generate the Astronova iOS app icon.

The icon is intentionally text-free so it remains legible at springboard,
spotlight, and notification sizes. It uses the app's current visual language:
cosmic black, warm gold, and a compass/orbital mark for guidance.
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "client/AstronovaApp/Assets.xcassets/AppIcon.appiconset/app-icon-1024.png"
QA_OUT = ROOT / "qa-results/2026051816/15-new-app-logo.png"
SIZE = 1024


def lerp(a: int, b: int, t: float) -> int:
    return round(a + (b - a) * t)


def blend(c1: tuple[int, int, int], c2: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(lerp(a, b, t) for a, b in zip(c1, c2))


def draw_gradient() -> Image.Image:
    center = (SIZE * 0.50, SIZE * 0.47)
    img = Image.new("RGB", (SIZE, SIZE), (5, 5, 9))
    px = img.load()
    for y in range(SIZE):
        for x in range(SIZE):
            dx = (x - center[0]) / SIZE
            dy = (y - center[1]) / SIZE
            r = min(1.0, math.hypot(dx, dy) * 1.85)
            vertical = y / SIZE
            base = blend((6, 6, 12), (21, 17, 28), 1 - r)
            warm = blend(base, (70, 47, 31), max(0.0, 1 - r * 1.8) * 0.30)
            px[x, y] = blend(warm, (2, 2, 6), max(0, vertical - 0.55) * 0.45)
    return img.convert("RGBA")


def ellipse_bbox(cx: float, cy: float, rx: float, ry: float) -> tuple[float, float, float, float]:
    return (cx - rx, cy - ry, cx + rx, cy + ry)


def main() -> None:
    img = draw_gradient()
    draw = ImageDraw.Draw(img, "RGBA")

    cx = cy = SIZE / 2
    gold = (220, 172, 78, 255)
    amber = (204, 124, 69, 255)
    cream = (245, 238, 218, 255)
    blue = (92, 177, 205, 255)

    glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow, "RGBA")
    for width, alpha in [(72, 30), (44, 48), (22, 88)]:
        glow_draw.ellipse(ellipse_bbox(cx, cy, 322, 322), outline=(*gold[:3], alpha), width=width)
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(18)))

    # Outer orbital compass ring.
    draw.ellipse(ellipse_bbox(cx, cy, 318, 318), outline=(232, 178, 78, 235), width=22)
    draw.ellipse(ellipse_bbox(cx, cy, 250, 250), outline=(245, 238, 218, 62), width=6)

    # Tilted orbital path as a guidance/astrocartography signal.
    orbit = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    orbit_draw = ImageDraw.Draw(orbit, "RGBA")
    orbit_draw.ellipse(ellipse_bbox(cx, cy, 390, 128), outline=(92, 177, 205, 170), width=12)
    orbit = orbit.rotate(-24, center=(cx, cy), resample=Image.Resampling.BICUBIC)
    img.alpha_composite(orbit)

    # Astronova "A" as a compass needle: two rising legs plus a north star.
    left = [(330, 706), (474, 298), (518, 298), (408, 706)]
    right = [(506, 298), (550, 298), (694, 706), (616, 706)]
    cross = [(418, 586), (606, 586), (628, 648), (396, 648)]
    draw.polygon(left, fill=gold)
    draw.polygon(right, fill=gold)
    draw.polygon(cross, fill=amber)

    # Inner void sharpens the mark and keeps the A readable at tiny sizes.
    draw.polygon([(512, 378), (456, 548), (568, 548)], fill=(9, 9, 16, 255))

    # North star and lower signal point.
    draw.regular_polygon((cx, 230, 5), n_sides=4, rotation=45, fill=cream)
    draw.ellipse(ellipse_bbox(cx, 768, 24, 24), fill=blue)
    draw.ellipse(ellipse_bbox(cx, 768, 10, 10), fill=cream)

    # Small star field, restrained so the icon stays premium.
    for i, (x, y, r, a) in enumerate(
        [
            (246, 292, 5, 180),
            (754, 330, 4, 145),
            (236, 666, 3, 120),
            (790, 676, 5, 160),
            (300, 778, 3, 110),
            (720, 230, 3, 130),
            (188, 462, 2, 115),
            (836, 514, 2, 115),
        ]
    ):
        color = cream if i % 2 == 0 else gold
        draw.ellipse(ellipse_bbox(x, y, r, r), fill=(*color[:3], a))

    OUT.parent.mkdir(parents=True, exist_ok=True)
    QA_OUT.parent.mkdir(parents=True, exist_ok=True)
    img.convert("RGB").save(OUT, "PNG", optimize=True)
    img.convert("RGB").save(QA_OUT, "PNG", optimize=True)
    print(OUT)
    print(QA_OUT)


if __name__ == "__main__":
    main()
