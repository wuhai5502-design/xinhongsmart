#!/usr/bin/env python3
"""Prepare a photo for the website: WebP + JPEG, two widths, markup included.

Why this exists: the elephant in image weight is pixel width and format, not
the JPEG quality slider. A 3200 px photo at quality 70 is still heavier than a
1200 px photo at quality 86, and a PNG screenshot of a product photo is heavier
than both.

Usage
-----
    pip install pillow                       # once
    python tools/prepare-image.py photo.jpg --name xh-900-hero
    python tools/prepare-image.py scan.jpg --name xh-900-views --trim --wide 1200

Options
-------
    --name     output base name (required). Files land in uploads/ as
               <name>.jpg, <name>.webp, <name>-800.jpg, <name>-800.webp
    --wide     width of the large version, default 1200
    --small    width of the small version, default 800 (use 0 to skip)
    --trim     crop the near-white studio border before resizing
    --out      output directory, default uploads/
    --canvas   optional WxH canvas to centre the image on, e.g. 1200x800

It prints the file sizes and a ready-to-paste <picture> block, so the width and
height attributes always match the file that was actually written.
"""

import argparse
import os
import sys

try:
    from PIL import Image, ImageFilter, ImageOps
except ImportError:
    sys.exit("Pillow is not installed. Run: pip install pillow")

WHITE = 244


def trim_white(im):
    gray = im.convert("L")
    bbox = gray.point(lambda v: 255 if v < WHITE else 0).getbbox()
    if not bbox:
        return im
    pad = 12
    box = (max(0, bbox[0] - pad), max(0, bbox[1] - pad),
           min(im.width, bbox[2] + pad), min(im.height, bbox[3] + pad))
    return im.crop(box)


def fit(im, width, canvas=None):
    h = round(width * im.height / im.width)
    out = im.resize((width, h), Image.LANCZOS)
    out = out.filter(ImageFilter.UnsharpMask(radius=1.1, percent=55, threshold=3))
    if not canvas:
        return out
    cw, ch = canvas
    scale = min(cw / out.width, ch / out.height) * 0.98
    inner = out.resize((round(out.width * scale), round(out.height * scale)), Image.LANCZOS)
    plate = Image.new("RGB", (cw, ch), "white")
    plate.paste(inner, ((cw - inner.width) // 2, (ch - inner.height) // 2))
    return plate


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("source")
    ap.add_argument("--name", required=True)
    ap.add_argument("--wide", type=int, default=1200)
    ap.add_argument("--small", type=int, default=800)
    ap.add_argument("--trim", action="store_true")
    ap.add_argument("--out", default="uploads")
    ap.add_argument("--canvas", default="")
    args = ap.parse_args()

    if not os.path.exists(args.source):
        sys.exit("source not found: " + args.source)

    im = ImageOps.exif_transpose(Image.open(args.source)).convert("RGB")
    if args.trim:
        im = trim_white(im)

    canvas = None
    if args.canvas:
        cw, ch = args.canvas.lower().split("x")
        canvas = (int(cw), int(ch))

    os.makedirs(args.out, exist_ok=True)
    big = fit(im, args.wide, canvas)
    # the small version is a scaled copy of the finished image, not a second
    # fit: fitting twice into the same canvas would emit two 1200 px files
    small_img = None
    if args.small:
        small_img = big.resize(
            (args.small, round(args.small * big.height / big.width)), Image.LANCZOS)

    written = []
    for suffix, img in (("", big), (f"-{args.small}", small_img)):
        if img is None:
            continue
        jpg = os.path.join(args.out, f"{args.name}{suffix}.jpg")
        webp = os.path.join(args.out, f"{args.name}{suffix}.webp")
        img.save(jpg, "JPEG", quality=86, optimize=True, progressive=True)
        img.save(webp, "WEBP", quality=84, method=6)
        written.append((jpg, img.size))
        written.append((webp, img.size))

    for path, size in written:
        kb = os.path.getsize(path) / 1024
        flag = "  <-- heavy, lower --wide or accept" if kb > 160 and path.endswith((".jpg", ".webp")) else ""
        print(f"{os.path.basename(path):34} {kb:7.1f} KB  {size[0]}x{size[1]}{flag}")

    w, h = big.size
    small_line = ""
    if args.small:
        small_line = (f' srcset="/uploads/{args.name}-{args.small}.jpg {args.small}w, '
                      f'/uploads/{args.name}.jpg {w}w"')
    print(f"""
<picture class="product-photo">
<source type="image/webp" srcset="/uploads/{args.name}-{args.small}.webp {args.small}w, /uploads/{args.name}.webp {w}w"
        sizes="(max-width:650px) calc(100vw - 36px), 580px">
<img{small_line} sizes="(max-width:650px) calc(100vw - 36px), 580px"
     src="/uploads/{args.name}.jpg" alt="" width="{w}" height="{h}" loading="lazy" decoding="async">
</picture>""")


if __name__ == "__main__":
    main()
