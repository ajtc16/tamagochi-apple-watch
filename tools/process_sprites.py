#!/usr/bin/env python3
"""Procesa los PNG de sprites_raw/ y los deja listos en sprites_clean/.

Para cada imagen:
  1. Convierte a RGBA.
  2. Hace transparente el magenta (~#FF00FF) con tolerancia (R>200, B>200, G<80),
     de forma vectorizada con numpy.
  3. Recorta al bounding box del contenido no transparente.
  4. Reescala a 256x256 manteniendo proporción (Image.NEAREST) y centra sobre
     un lienzo transparente de 256x256.
  5. Limpia bordes semitransparentes: alpha en [1, 200] -> 0 o 255 (umbral 128).
  6. Guarda como PNG optimizado con el mismo nombre.
"""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = ROOT / "sprites_raw"
CLEAN_DIR = ROOT / "sprites_clean"

CANVAS = 256
EDGE_LO, EDGE_HI = 1, 200
EDGE_THRESHOLD = 128
SMALL_PX = 16  # ancho/alto de recorte por debajo del cual es "sospechoso"

# Nombres de asset que el código referencia en runtime (Pet.spriteName + items).
EXPECTED_ASSETS: set[str] = {
    "pet_egg_idle", "pet_egg_cracked", "pet_ghost",
    *(
        f"pet_{stage}_{mood}"
        for stage in ("baby", "child", "adult")
        for mood in ("idle", "happy", "sleeping", "sad", "sick")
    ),
    "item_food_fruit", "item_food_meal", "item_soap",
    "item_ball", "item_medicine", "item_poop",
}


def magenta_to_transparent(arr: np.ndarray) -> np.ndarray:
    """Pone alpha=0 en los píxeles cercanos al magenta. Vectorizado."""
    r, g, b = arr[..., 0], arr[..., 1], arr[..., 2]
    mask = (r > 200) & (b > 200) & (g < 80)
    arr[mask, 3] = 0
    return arr


def process(path: Path) -> tuple[int, int] | None:
    """Procesa una imagen. Devuelve (w, h) del recorte, o None si quedó vacía."""
    img = Image.open(path).convert("RGBA")
    arr = np.array(img)
    arr = magenta_to_transparent(arr)

    # 3. Bounding box del contenido no transparente.
    alpha = arr[..., 3]
    ys, xs = np.where(alpha > 0)
    if xs.size == 0:
        return None

    x0, x1 = int(xs.min()), int(xs.max()) + 1
    y0, y1 = int(ys.min()), int(ys.max()) + 1
    cropped = Image.fromarray(arr[y0:y1, x0:x1])
    cw, ch = cropped.size

    # 4. Reescalar manteniendo proporción (sin suavizar) y centrar.
    scale = min(CANVAS / cw, CANVAS / ch)
    new_w = max(1, round(cw * scale))
    new_h = max(1, round(ch * scale))
    resized = cropped.resize((new_w, new_h), Image.NEAREST)

    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    canvas.paste(resized, ((CANVAS - new_w) // 2, (CANVAS - new_h) // 2))

    # 5. Limpiar bordes semitransparentes.
    out = np.array(canvas)
    a = out[..., 3]
    band = (a >= EDGE_LO) & (a <= EDGE_HI)
    a[band] = np.where(a[band] < EDGE_THRESHOLD, 0, 255)
    out[..., 3] = a
    result = Image.fromarray(out)

    # 6. Guardar PNG optimizado.
    CLEAN_DIR.mkdir(parents=True, exist_ok=True)
    result.save(CLEAN_DIR / path.name, format="PNG", optimize=True)
    return cw, ch


def main() -> None:
    files = sorted(RAW_DIR.glob("*.png")) if RAW_DIR.is_dir() else []

    processed: list[str] = []
    empty: list[str] = []
    small: list[tuple[str, int, int]] = []

    for path in files:
        res = process(path)
        if res is None:
            empty.append(path.name)
            continue
        cw, ch = res
        processed.append(path.name)
        if cw < SMALL_PX or ch < SMALL_PX:
            small.append((path.name, cw, ch))

    produced = {p.stem for p in CLEAN_DIR.glob("*.png")} if CLEAN_DIR.is_dir() else set()
    missing = sorted(EXPECTED_ASSETS - produced)
    extra = sorted(produced - EXPECTED_ASSETS)

    print("=" * 48)
    print(f"Carpeta origen : {RAW_DIR}")
    if not RAW_DIR.is_dir():
        print("  (no existe todavía)")
    print(f"Carpeta destino: {CLEAN_DIR}")
    print("-" * 48)
    print(f"Procesadas OK  : {len(processed)}")
    if empty:
        print(f"Vacías (todo transparente): {len(empty)}")
        for name in empty:
            print(f"    - {name}")

    print("-" * 48)
    if small:
        print(f"Sospechosamente pequeñas tras recorte (<{SMALL_PX}px):")
        for name, cw, ch in small:
            print(f"    - {name}: {cw}x{ch}")
    else:
        print("Sospechosamente pequeñas: ninguna")

    print("-" * 48)
    if missing:
        print(f"Faltan {len(missing)} de {len(EXPECTED_ASSETS)} assets esperados:")
        for name in missing:
            print(f"    - {name}")
    else:
        print(f"No falta ningún asset esperado ({len(EXPECTED_ASSETS)}/{len(EXPECTED_ASSETS)}).")

    if extra:
        print("-" * 48)
        print(f"Extra (no esperados por el código): {len(extra)}")
        for name in extra:
            print(f"    - {name}")
    print("=" * 48)


if __name__ == "__main__":
    main()
