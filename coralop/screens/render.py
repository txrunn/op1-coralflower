#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""CoralOP's screen, rendered on a PC from the code that runs on the OP-1 (as op1r's screenshots are).

    render.py [out dir, default docs/images]

Builds screens/host.c (coralop.c for the host, TE stubbed), runs each scene and draws what the frame drew, at 3x:
rectangles as they are, strings in DejaVu Sans Condensed Bold at the OP-1 font's height (the device draws them in
its 3x5 pixel font, so letter shapes differ; positions are the device's). Needs cc and Pillow."""

import os, subprocess, sys, tempfile

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
CO = os.path.dirname(HERE)
ROOT = os.path.dirname(CO)
Z = 3                                           # pixels per OP-1 pixel
W, H = 320, 156
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed-Bold.ttf"
SCENES = ["play", "play_dorian", "chord", "side", "bass", "midi"]


def rgb(c):
    c = int(c)
    r, g, b = c >> 11 & 31, c >> 5 & 63, c & 31
    return (r * 255 // 31, g * 255 // 63, b * 255 // 31)


def runs(raw):
    """(text, raised) runs: 0x10..0x19 are raised digits (an added degree on a key label)"""
    out, cur, up = [], "", False
    for b in raw:
        r = 0x10 <= b <= 0x19
        ch = chr(0x30 + b - 0x10) if r else {0xB0: "°", 0xF8: "ø"}.get(b, chr(b))
        if r != up and cur:
            out.append((cur, up))
            cur = ""
        cur += ch
        up = r
    if cur:
        out.append((cur, up))
    return out


_fonts = {}


def font(px):
    if px not in _fonts:
        _fonts[px] = ImageFont.truetype(FONT, px)
    return _fonts[px]


def draw_text(im, x, y, sc, c, raw):
    cap = 5 * sc * Z                             # the OP-1 font's cap height, in output pixels
    f = font(round(cap / 0.729))                 # (DejaVu's cap height: 0.729 em)
    fs = font(round(cap * 0.72 / 0.729))
    room = (len(raw) * 4 * sc - sc) * Z          # the width the device gives it
    parts, total = [], 0
    for t, up in runs(raw):
        ff = fs if up else f
        w = ff.getlength(t)
        parts.append((t, ff, up, w))
        total += w
    pad = cap                                    # (room for descenders and the raised digits)
    lay = Image.new("RGBA", (int(total) + 4, cap * 2 + pad), (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    base, px = pad + cap, 0.0
    for t, ff, up, w in parts:
        d.text((px, base - (sc * Z if up else 0)), t, font=ff, fill=rgb(c) + (255,), anchor="ls")
        px += w
    if total > room > 0:                         # wider than the device's: narrow it to fit
        lay = lay.resize((max(1, int(room) + 4), lay.height), Image.LANCZOS)
    im.alpha_composite(lay, (x * Z, (y + 5 * sc) * Z - base))


def render(ops, out):
    im = Image.new("RGBA", (W * Z, H * Z), (0, 0, 0, 255))
    d = ImageDraw.Draw(im)
    for op in ops:
        if op[0] == "R":
            x, y, w, h, c = map(int, op[1:6])
            if w > 0 and h > 0:
                d.rectangle([x * Z, y * Z, (x + w) * Z - 1, (y + h) * Z - 1], fill=rgb(c))
        elif op[0] == "T":
            x, y, sc, c = map(int, op[1:5])
            draw_text(im, x, y, sc, c, bytes.fromhex(op[5]) if len(op) > 5 else b"")
            d = ImageDraw.Draw(im)
    im.convert("RGB").save(out, optimize=True)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "docs", "images")
    os.makedirs(out, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        exe = os.path.join(tmp, "host")
        src = [os.path.join(HERE, "host.c")] + [os.path.join(CO, f) for f in
                                                   ("co_play.c", "co_remote.c", "cf_chord.c", "cf_theory.c")]
        subprocess.run(["cc", "-std=gnu99", "-O1", "-Wall", "-Wextra", "-Werror",
                        "-I", os.path.join(ROOT, "sdk", "include"),
                        "-DCF_SCALES=cf_SCALES", "-DCF_ADDS=cf_ADDS", "-o", exe] + src, check=True)
        for s in SCENES:
            ops = [l.split(" ") for l in subprocess.run([exe, s], check=True, capture_output=True,
                                                        text=True).stdout.splitlines()]
            path = os.path.join(out, f"screen_{s}.png")
            render(ops, path)
            print("wrote", path)


if __name__ == "__main__":
    main()
