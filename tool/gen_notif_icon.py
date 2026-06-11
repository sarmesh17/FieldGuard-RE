"""Generate the Android notification small-icon from the colorful app icon.

Android renders the notification *small* icon as a monochrome mask: it ignores
RGB and uses only the alpha channel, tinting the shape with the notification
accent colour. So a colourful icon shows up as a white blob. This script turns
the brand logo into a white silhouette (white RGB everywhere, alpha = shape) at
each density, written to android/.../drawable-*/ic_notification.png.

Rules baked in (see chat notes):
  * White RGB on EVERY pixel (even transparent ones) so LANCZOS downscale can't
    blend in a dark halo.
  * PNG per density (NOT a vector) — old Android renders vector small-icons as a
    blank/blob.
  * Cream background + transparent margin are dropped; the bird + pin remain.

Our employee icon has no "HQ" ribbon, so there's nothing to exclude. Re-run
after changing the source:  python tool/gen_notif_icon.py   (needs: pip install pillow)
"""

import os

from PIL import Image

SRC = "assets/images/FieldGuard.png"
BG = (254, 252, 247)        # cream background (#FEFCF7), dropped
BG_TOL = 60                 # colour distance under which a pixel counts as bg
ALPHA_MIN = 40              # below this the source pixel is treated as empty
PAD = 1.22                  # square-canvas size as a multiple of the logo bbox
SIZES = {"mdpi": 24, "hdpi": 36, "xhdpi": 48, "xxhdpi": 72, "xxxhdpi": 96}
RES_DIR = "android/app/src/main/res"


def dist(c, r):
    return ((c[0] - r[0]) ** 2 + (c[1] - r[1]) ** 2 + (c[2] - r[2]) ** 2) ** 0.5


def main():
    src = Image.open(SRC).convert("RGBA")
    w, h = src.size
    px = src.load()

    # White silhouette: white RGB everywhere, alpha carries the shape.
    sil = Image.new("RGBA", (w, h), (255, 255, 255, 0))
    sp = sil.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a <= ALPHA_MIN or dist((r, g, b), BG) <= BG_TOL:
                continue  # transparent margin or cream background -> skip
            sp[x, y] = (255, 255, 255, 255)  # logo -> solid white

    bbox = sil.getbbox()
    if bbox is None:
        raise SystemExit("No logo pixels found — check BG/ALPHA thresholds.")
    sil = sil.crop(bbox)
    cw, ch = sil.size

    # Centre on a padded square canvas (also white RGB -> no dark halo).
    side = int(max(cw, ch) * PAD)
    canvas = Image.new("RGBA", (side, side), (255, 255, 255, 0))
    canvas.paste(sil, ((side - cw) // 2, (side - ch) // 2), sil)

    for d, s in SIZES.items():
        out_dir = os.path.join(RES_DIR, f"drawable-{d}")
        os.makedirs(out_dir, exist_ok=True)
        out = os.path.join(out_dir, "ic_notification.png")
        canvas.resize((s, s), Image.LANCZOS).save(out)
        print(f"wrote {out} ({s}x{s})")


if __name__ == "__main__":
    main()
