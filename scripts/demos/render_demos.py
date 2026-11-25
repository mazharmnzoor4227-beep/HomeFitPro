#!/usr/bin/env python3
"""Render looping WebP demos + still PNGs + contact sheet. Original mannequin."""
from __future__ import annotations
import argparse, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
from mannequin import (  # noqa: E402
    FRAMES, FPS_MS, sample_motion, pingpong_times, loop_times, render_frame, plant, constrain,
)
from demo_poses import EXERCISES  # noqa: E402

OUT = ROOT / "assets" / "demos"
STILL = OUT / "still"
PREVIEW = Path("/tmp/demo-preview")
MAX_KB = 300


def times_for(spec, n):
    if spec.get("mode") == "loop":
        return loop_times(n)
    return pingpong_times(n, hold=spec.get("hold", 0.12))


def frames_of(slug, n=FRAMES, size=512, ss=2):
    spec = EXERCISES[slug]
    keys = [plant(constrain(k)) for k in spec["build"]()]
    cam = spec.get("cam", "qtr")
    hi = spec.get("highlight") or []
    props = spec.get("props") or []
    ts = times_for(spec, n)
    mode = spec.get("mode") or "pingpong"
    return [render_frame(sample_motion(keys, t, mode), cam, hi, props, size=size, ss=ss) for t in ts]


def save_webp(frames, path: Path, quality=80):
    frames[0].save(
        path, format="WEBP", save_all=True, append_images=frames[1:],
        duration=FPS_MS, loop=0, quality=quality, method=4, lossless=False,
    )
    kb = path.stat().st_size / 1024
    q = quality
    while kb > MAX_KB and q > 50:
        q -= 8
        frames[0].save(
            path, format="WEBP", save_all=True, append_images=frames[1:],
            duration=FPS_MS, loop=0, quality=q, method=6, lossless=False,
        )
        kb = path.stat().st_size / 1024
    return kb, q


def still_t(spec):
    if "still" in spec:
        return float(spec["still"])
    return 0.35 if spec.get("mode") == "loop" else 0.92


def render_still_frame(slug, size=512, ss=2):
    spec = EXERCISES[slug]
    keys = [plant(constrain(k)) for k in spec["build"]()]
    pose = sample_motion(keys, still_t(spec), spec.get("mode") or "pingpong")
    return render_frame(pose, spec.get("cam", "qtr"), spec.get("highlight") or [], spec.get("props") or [], size=size, ss=ss)


def render_one(slug, n=FRAMES, size=512, ss=2, preview=False):
    OUT.mkdir(parents=True, exist_ok=True)
    STILL.mkdir(parents=True, exist_ok=True)
    PREVIEW.mkdir(parents=True, exist_ok=True)
    still = render_still_frame(slug, size=size, ss=ss)
    still_path = STILL / f"{slug}.png"
    still.save(still_path, "PNG", optimize=True)
    still.save(PREVIEW / f"{slug}.png", "PNG")
    if preview:
        return 0, 0, still_path
    frames = frames_of(slug, n=n, size=size, ss=ss)
    # keep the authored still as the mid-ish hero frame already saved
    webp = OUT / f"{slug}.webp"
    kb, q = save_webp(frames, webp)
    return kb, q, still_path


def contact_sheet(slugs, dest: Path, thumb=220, cols=6):
    paths = [STILL / f"{s}.png" for s in slugs]
    paths = [p for p in paths if p.exists()]
    if not paths:
        return
    rows = (len(paths) + cols - 1) // cols
    pad, label_h = 16, 28
    W = cols * thumb + (cols + 1) * pad
    H = rows * (thumb + label_h) + (rows + 1) * pad
    sheet = Image.new("RGB", (W, H), (14, 16, 16))
    draw = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 12)
    except Exception:
        font = ImageFont.load_default()
    for i, p in enumerate(paths):
        r, c = divmod(i, cols)
        x = pad + c * (thumb + pad)
        y = pad + r * (thumb + label_h + pad)
        im = Image.open(p).convert("RGB").resize((thumb, thumb), Image.Resampling.LANCZOS)
        sheet.paste(im, (x, y))
        name = p.stem.replace("-", " ")
        draw.text((x + 4, y + thumb + 6), name, fill=(200, 196, 188), font=font)
    dest.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(dest, "PNG", optimize=True)
    return dest


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", nargs="*", help="slugs to render")
    ap.add_argument("--preview", action="store_true", help="stills only, no webp")
    ap.add_argument("--sheet", default="")
    ap.add_argument("--frames", type=int, default=FRAMES)
    ap.add_argument("--size", type=int, default=512)
    args = ap.parse_args()
    slugs = args.only or list(EXERCISES)
    for slug in slugs:
        if slug not in EXERCISES:
            print("unknown", slug, file=sys.stderr)
            continue
        print(f"render {slug} ...", flush=True)
        kb, q, still = render_one(slug, n=args.frames, size=args.size, preview=args.preview)
        if args.preview:
            print(f"  still {still}")
        else:
            print(f"  {kb:.0f}KB q={q} still={still.name}")
    if args.sheet:
        contact_sheet(slugs, Path(args.sheet))
        print("sheet", args.sheet)


if __name__ == "__main__":
    main()
