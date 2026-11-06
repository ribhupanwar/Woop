#!/usr/bin/env python3
"""Generate Woop's original iOS app icon: a gold recovery arc around a bold W.

The mark is deliberately distinct from other wearable brands. Outputs are copied
into the iOS asset catalog by the Woop IPA workflow before XcodeGen runs.
"""
import math
import os
import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.abspath(__file__))
NAVY_TOP = (10, 19, 34)
NAVY_BOTTOM = (4, 8, 16)
GLOW = (24, 39, 61)
GOLD_LIGHT = (255, 239, 184)
GOLD = (232, 184, 75)
GOLD_DEEP = (190, 126, 35)


def mix(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def render(size, safe=1.0):
    ss = 3
    n = size * ss
    yy, xx = np.mgrid[0:n, 0:n]
    y = yy / max(1, n - 1)
    bg = np.zeros((n, n, 3), dtype=np.uint8)
    glow_dist = np.sqrt((xx - n * .5) ** 2 + (yy - n * .39) ** 2) / (n * .78)
    glow = np.clip(1 - glow_dist, 0, 1) ** 2
    for c in range(3):
        base = NAVY_TOP[c] + (NAVY_BOTTOM[c] - NAVY_TOP[c]) * y
        bg[:, :, c] = np.clip(base + glow * GLOW[c] * .52, 0, 255)
    img = Image.fromarray(bg, "RGB").convert("RGBA")
    d = ImageDraw.Draw(img)

    cx = cy = n / 2
    radius = n * .355 * safe
    stroke = n * .105 * safe
    # An open, clockwise recovery arc, with a warm metallic gradient.
    start, sweep, steps = 225.0, 290.0, 1400
    for i in range(steps + 1):
        t = i / steps
        angle = math.radians(start + sweep * t)
        px = cx + radius * math.cos(angle)
        py = cy + radius * math.sin(angle)
        col = mix(GOLD_LIGHT, GOLD, min(1, t * 2)) if t < .5 else mix(GOLD, GOLD_DEEP, (t - .5) * 2)
        r = stroke / 2
        d.ellipse((px-r, py-r, px+r, py+r), fill=col + (255,))

    # Custom geometric W monogram, drawn as a clean continuous stroke.
    # It sits inside the ring and remains legible at small Home Screen sizes.
    pts = [
        (cx - n*.205, cy - n*.115),
        (cx - n*.105, cy + n*.145),
        (cx,           cy - n*.045),
        (cx + n*.105, cy + n*.145),
        (cx + n*.205, cy - n*.115),
    ]
    d.line(pts, fill=(255, 244, 211, 255), width=max(14, int(n*.043)), joint="curve")
    rr = n * .022
    for px, py in (pts[0], pts[-1]):
        d.ellipse((px-rr, py-rr, px+rr, py+rr), fill=GOLD_LIGHT + (255,))

    return img.convert("RGB").resize((size, size), Image.Resampling.LANCZOS)


if __name__ == "__main__":
    render(1024).save(os.path.join(ROOT, "woop_icon_1024.png"))
    render(432, safe=.82).save(os.path.join(ROOT, "woop_icon_432.png"))
    print("Generated Woop icon assets.")
