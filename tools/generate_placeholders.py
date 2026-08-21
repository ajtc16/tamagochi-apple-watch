#!/usr/bin/env python3
"""Genera sprites pixel-art PLACEHOLDER animados y los escribe en el asset catalog.

Son marcadores de posición (feos pero coherentes): mascota por etapa/mood con
2-3 frames de animación, huevo, fantasma e items. Cada frame se guarda como su
propio imageset (`nombre_0.imageset`, `nombre_1.imageset`, …) para que
`UIImage(named:"nombre_0")` los encuentre y `PetSprite` los cicle.

El arte final se produce con `process_sprites.py` (sprites_raw -> sprites_clean)
y sustituye a estos placeholders usando exactamente los mismos nombres.
"""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "tamagochi Watch App" / "Assets.xcassets" / "Sprites"

S = 64
OUTLINE = (40, 40, 50, 255)
DARK = (20, 20, 30, 255)
BLUE = (120, 180, 255, 255)

STAGE_COLOR = {
    "baby":  (139, 224, 176, 255),
    "child": (92, 200, 184, 255),
    "adult": (91, 155, 224, 255),
}
STAGE_R = {"baby": 16, "child": 20, "adult": 24}

# mood -> número de frames
MOODS = {"idle": 3, "happy": 2, "sad": 3, "sick": 2, "sleeping": 3, "eating": 2}


def canvas() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


# ---------------------------------------------------------------- mascota

def draw_body(d: ImageDraw.ImageDraw, stage: str):
    color = STAGE_COLOR[stage]
    r = STAGE_R[stage]
    cx, cy = S // 2, 34
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color, outline=OUTLINE, width=2)
    d.ellipse([cx - r + 2, cy + r - 4, cx - r + 10, cy + r + 4], fill=color, outline=OUTLINE, width=1)
    d.ellipse([cx + r - 10, cy + r - 4, cx + r - 2, cy + r + 4], fill=color, outline=OUTLINE, width=1)
    if stage == "adult":
        d.polygon([(cx - r + 4, cy - r + 2), (cx - r - 2, cy - r - 8), (cx - r + 12, cy - r - 2)],
                  fill=color, outline=OUTLINE)
        d.polygon([(cx + r - 4, cy - r + 2), (cx + r + 2, cy - r - 8), (cx + r - 12, cy - r - 2)],
                  fill=color, outline=OUTLINE)
    return cx, cy, r


def draw_face(d: ImageDraw.ImageDraw, cx: int, cy: int, r: int, mood: str, f: int):
    ey = cy - 4
    lx, rx = cx - 6, cx + 6
    my = cy + 5

    def eyes_open():
        d.ellipse([lx - 2, ey - 2, lx + 2, ey + 2], fill=DARK)
        d.ellipse([rx - 2, ey - 2, rx + 2, ey + 2], fill=DARK)

    def eyes_closed():
        d.line([lx - 2, ey, lx + 2, ey], fill=DARK, width=2)
        d.line([rx - 2, ey, rx + 2, ey], fill=DARK, width=2)

    def eyes_happy():
        d.arc([lx - 3, ey - 3, lx + 3, ey + 3], 180, 360, fill=DARK, width=2)
        d.arc([rx - 3, ey - 3, rx + 3, ey + 3], 180, 360, fill=DARK, width=2)

    if mood == "idle":
        (eyes_closed if f == 2 else eyes_open)()
        d.line([cx - 3, my, cx + 3, my], fill=DARK, width=1)
    elif mood == "happy":
        eyes_happy()
        w = 6 if f == 1 else 5
        d.arc([cx - w, my - 3, cx + w, my + 4], 0, 180, fill=DARK, width=2)
    elif mood == "sad":
        d.line([lx - 2, ey - 1, lx + 2, ey + 1], fill=DARK, width=2)
        d.line([rx - 2, ey + 1, rx + 2, ey - 1], fill=DARK, width=2)
        d.arc([cx - 5, my + 1, cx + 5, my + 7], 180, 360, fill=DARK, width=2)
        ty = ey + 2 + f * 4
        d.ellipse([lx - 1, ty, lx + 2, ty + 4], fill=BLUE)
    elif mood == "sick":
        for ex in (lx, rx):
            d.line([ex - 2, ey - 2, ex + 2, ey + 2], fill=DARK, width=1)
            d.line([ex - 2, ey + 2, ex + 2, ey - 2], fill=DARK, width=1)
        d.line([cx - 3, my, cx + 3, my], fill=DARK, width=1)
        sy = cy - r - 2 + (f % 2) * 3
        d.ellipse([cx + r - 2, sy, cx + r + 2, sy + 4], fill=BLUE)
    elif mood == "sleeping":
        eyes_closed()
        d.line([cx - 3, my, cx + 3, my], fill=DARK, width=1)
        zx, zy, size = cx + r, cy - r - f * 3, 3 + f
        d.line([zx, zy, zx + size, zy], fill=(70, 70, 90, 255))
        d.line([zx + size, zy, zx, zy + size], fill=(70, 70, 90, 255))
        d.line([zx, zy + size, zx + size, zy + size], fill=(70, 70, 90, 255))
    elif mood == "eating":
        eyes_open()
        if f == 0:
            d.ellipse([cx - 3, my - 2, cx + 3, my + 4], fill=(120, 40, 40, 255), outline=DARK)
        else:
            d.line([cx - 3, my, cx + 3, my], fill=DARK, width=2)


def pet_frame(stage: str, mood: str, f: int) -> Image.Image:
    img, d = canvas()
    cx, cy, r = draw_body(d, stage)
    draw_face(d, cx, cy, r, mood, f)
    return img


# ---------------------------------------------------------------- huevo / fantasma

def egg_frame(cracked: bool, f: int) -> Image.Image:
    img, d = canvas()
    cx = S // 2 + (-1 if f == 0 else 1)
    top, bot = 12, 52
    d.ellipse([cx - 14, top, cx + 14, bot], fill=(245, 230, 200, 255), outline=OUTLINE, width=2)
    midy = (top + bot) // 2
    for sx, sy in [(-6, -2), (4, 6), (-2, 12)]:
        d.ellipse([cx + sx - 2, midy + sy - 2, cx + sx + 2, midy + sy + 2], fill=(200, 165, 110, 255))
    if cracked:
        pts = [(cx - 11, midy), (cx - 6, midy - 4), (cx - 2, midy + 3),
               (cx + 3, midy - 3), (cx + 7, midy + 3), (cx + 11, midy - 1)]
        d.line(pts, fill=OUTLINE, width=2)
    return img


def ghost_frame(f: int) -> Image.Image:
    img, d = canvas()
    cx = S // 2 + (-1 if f == 0 else 1)
    r, top, cy = 15, 14, 30
    body = (235, 238, 245, 230)
    d.pieslice([cx - r, top, cx + r, top + 2 * r], 180, 360, fill=body, outline=OUTLINE, width=2)
    d.rectangle([cx - r, cy, cx + r, 46], fill=body)
    d.line([cx - r, cy, cx - r, 46], fill=OUTLINE, width=2)
    d.line([cx + r, cy, cx + r, 46], fill=OUTLINE, width=2)
    step = (2 * r) // 3
    for i in range(3):
        x0 = cx - r + i * step
        d.pieslice([x0, 42, x0 + step, 50], 0, 180, fill=body, outline=OUTLINE, width=1)
    d.ellipse([cx - 7, 26, cx - 3, 30], fill=DARK)
    d.ellipse([cx + 3, 26, cx + 7, 30], fill=DARK)
    return img


# ---------------------------------------------------------------- items

def item_food_fruit() -> Image.Image:
    img, d = canvas()
    d.ellipse([20, 24, 44, 50], fill=(220, 60, 60, 255), outline=OUTLINE, width=2)
    d.line([32, 24, 32, 16], fill=(90, 60, 30, 255), width=2)
    d.polygon([(33, 18), (42, 14), (38, 22)], fill=(80, 180, 90, 255), outline=OUTLINE)
    return img


def item_food_meal() -> Image.Image:
    img, d = canvas()
    d.ellipse([12, 40, 52, 52], fill=(220, 220, 230, 255), outline=OUTLINE, width=2)
    d.pieslice([20, 26, 44, 50], 180, 360, fill=(200, 150, 90, 255), outline=OUTLINE, width=2)
    return img


def item_soap() -> Image.Image:
    img, d = canvas()
    d.rounded_rectangle([18, 30, 46, 46], radius=5, fill=(120, 200, 240, 255), outline=OUTLINE, width=2)
    for bx, by, br in [(24, 26, 3), (34, 22, 4), (42, 28, 2)]:
        d.ellipse([bx - br, by - br, bx + br, by + br], fill=(200, 240, 255, 220), outline=OUTLINE)
    return img


def item_ball() -> Image.Image:
    img, d = canvas()
    d.ellipse([20, 24, 44, 48], fill=(240, 120, 60, 255), outline=OUTLINE, width=2)
    d.arc([20, 24, 44, 48], 20, 160, fill=OUTLINE, width=2)
    d.line([21, 36, 43, 36], fill=OUTLINE, width=1)
    return img


def item_medicine() -> Image.Image:
    img, d = canvas()
    d.rounded_rectangle([18, 28, 46, 40], radius=6, fill=(240, 240, 245, 255), outline=OUTLINE, width=2)
    d.rounded_rectangle([32, 28, 46, 40], radius=6, fill=(230, 90, 90, 255))
    d.rounded_rectangle([18, 28, 46, 40], radius=6, outline=OUTLINE, width=2)
    return img


def item_poop() -> Image.Image:
    img, d = canvas()
    d.ellipse([18, 42, 46, 52], fill=(120, 80, 40, 255), outline=OUTLINE, width=2)
    d.ellipse([22, 34, 42, 46], fill=(140, 95, 50, 255), outline=OUTLINE, width=2)
    d.ellipse([26, 28, 38, 40], fill=(160, 110, 60, 255), outline=OUTLINE, width=2)
    d.ellipse([28, 32, 31, 35], fill=DARK)
    d.ellipse([33, 32, 36, 35], fill=DARK)
    return img


ITEMS = {
    "item_food_fruit": item_food_fruit,
    "item_food_meal": item_food_meal,
    "item_soap": item_soap,
    "item_ball": item_ball,
    "item_medicine": item_medicine,
    "item_poop": item_poop,
}


# ---------------------------------------------------------------- escritura

def save_imageset(name: str, image: Image.Image):
    folder = ASSETS / f"{name}.imageset"
    folder.mkdir(parents=True, exist_ok=True)
    image.save(folder / f"{name}.png", "PNG", optimize=True)
    contents = {
        "images": [{"idiom": "universal", "filename": f"{name}.png"}],
        "info": {"author": "xcode", "version": 1},
    }
    (folder / "Contents.json").write_text(json.dumps(contents, indent=2))


def main():
    ASSETS.mkdir(parents=True, exist_ok=True)
    # Contents.json de la carpeta (sin namespace: los nombres quedan planos).
    (ASSETS / "Contents.json").write_text(
        json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2))

    count = 0

    # Mascota por etapa/mood (animada).
    for stage in ("baby", "child", "adult"):
        for mood, nframes in MOODS.items():
            for f in range(nframes):
                save_imageset(f"pet_{stage}_{mood}_{f}", pet_frame(stage, mood, f))
                count += 1

    # Huevo (idle + cracked) y fantasma, 2 frames cada uno.
    for f in range(2):
        save_imageset(f"pet_egg_idle_{f}", egg_frame(False, f)); count += 1
        save_imageset(f"pet_egg_cracked_{f}", egg_frame(True, f)); count += 1
        save_imageset(f"pet_ghost_{f}", ghost_frame(f)); count += 1

    # Items (estáticos, un frame).
    for name, fn in ITEMS.items():
        save_imageset(name, fn()); count += 1

    print(f"Generados {count} imagesets en {ASSETS.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
