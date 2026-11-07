#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Screenshots of the plugdata panel for the docs, in plugdata itself, fed what the OP-1 would send.

    shots.py /path/to/plugdata/Standalone/plugdata [out dir, default docs/images]

Needs Xvfb, xdotool and ImageMagick (import, convert). For each scene it writes a copy of coralop-guitar.pd next to
the real one with a [loadbang] that feeds the panel CoralOP's channel-16 feedback (the same "value cc" pairs
[ctlin] would give it) and the chord's notes (as [notein] would), opens it in plugdata's plugin mode and saves the
window. The copies are deleted afterwards."""

import os, subprocess, sys, time

HERE = os.path.dirname(os.path.abspath(__file__))
PD = os.path.normpath(os.path.join(HERE, "..", "pd"))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))

# CC numbers (co_remote.h)
EN, QUANT, KEY, SCALE, LAYOUT, RETRIG, BASS, BOCT, OCT, CHCH, BSCH, LOCAL = 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31
VEL, SEL, TYPE, ADD, INV, BDEG = 102, 104, 105, 106, 107, 108
LIT_LO, LIT_HI, HOLD, ROOT_, SOUNDING, NAMELEN, NAMECH = 112, 113, 114, 115, 116, 117, 118

SCENES = [
    # name, key, scale, chord button, type, add, lit buttons (bit = button), root pc, chord name,
    # chord notes (ch 1), bass note (ch 2), tuning (None = the patch's default), radio row/cell for it
    dict(file="coralop-guitar.png", key=4, scale=1, sel=7, type=2, add=5, lit=1 << 7, root=4, name="Em9",
         notes=[52, 55, 59, 62, 66], bass=40, tuning=None),
    dict(file="coralop-guitar-facgce.png", key=5, scale=0, sel=2, type=1, add=6, lit=1 << 2, root=5,
         name="Fmaj9", notes=[53, 57, 60, 64, 67], bass=41, tuning=("tunsel2", 10)),
]


def feedback(sc):
    cc = [(127, EN), (1, QUANT), (sc["key"], KEY), (sc["scale"], SCALE), (0, LAYOUT), (0, RETRIG), (127, BASS),
          (64, BOCT), (0, OCT), (1, CHCH), (2, BSCH), (127, LOCAL), (100, VEL), (sc["sel"], SEL),
          (sc["type"], TYPE), (sc["add"], ADD), (0, INV), (0, BDEG), (sc["lit"] & 127, LIT_LO),
          (sc["lit"] >> 7, LIT_HI), (0, HOLD), (sc["root"], ROOT_), (127, SOUNDING), (len(sc["name"]), NAMELEN)]
    cc += [(ord(ch), NAMECH) for ch in sc["name"]]
    return cc


def scene_patch(sc):
    src = open(os.path.join(PD, "coralop-guitar.pd")).read().rstrip("\n").split("\n")
    objs = [i for i, l in enumerate(src) if l.startswith(("#X obj", "#X msg", "#X text", "#X floatatom", "#X symbolatom", "#X listbox"))]
    n = len(objs)
    panel = next(k for k, i in enumerate(objs) if src[i].startswith("#X obj 10 10 coralop-remote"))
    first_conn = next(i for i, l in enumerate(src) if l.startswith("#X connect"))
    add, conns = [], []
    # (at load, no [delay]: without an audio device plugdata's clock doesn't run)
    add.append("#X obj 900 20 loadbang;")               # n
    add.append("#X obj 900 45 t b b;")                  # n+1
    add.append("#X msg 900 70 " + " \\, ".join(f"{v} {c}" for v, c in feedback(sc)) + ";")   # n+2
    notes = [f"{p} 100 1" for p in sc["notes"]] + [f"{sc['bass']} 100 2"]
    add.append("#X msg 900 95 " + " ".join(f"\\; coralop-notes {x}" for x in notes) + ";")  # n+3
    conns += [f"#X connect {n} 0 {n + 1} 0;", f"#X connect {n + 1} 1 {n + 2} 0;", f"#X connect {n + 1} 0 {n + 3} 0;",
              f"#X connect {n + 2} 0 {panel} 1;"]
    if sc["tuning"]:
        name, cell = sc["tuning"]
        radio = next(k for k, i in enumerate(objs) if f" \\$0-{name} " in src[i] and "hradio" in src[i])
        add.append(f"#X msg 900 120 {cell};")           # n+4: (as if clicked)
        conns += [f"#X connect {n} 0 {n + 4} 0;", f"#X connect {n + 4} 0 {radio} 0;"]
    return "\n".join(src[:first_conn] + add + src[first_conn:-1] + conns + src[-1:]) + "\n"


def sh(*a, **k):
    return subprocess.run(a, check=True, capture_output=True, text=True, **k).stdout


ZOOM = 2                                   # plugdata's global scale: 2x screenshots


def settings(home):
    """plugdata's settings in a home of our own: scale, and nothing reopened from before"""
    f = os.path.join(home, "Documents", "plugdata", ".settings")
    if os.path.exists(f):
        s = open(f).read()
        s = s.replace('global_scale="1.0"', f'global_scale="{ZOOM}.0"').replace('theme="light"', 'theme="dark"')
        open(f, "w").write(s)
    return os.path.exists(f)


def crop(raw, out):
    """the panel only: the box of the panel's background colour"""
    from PIL import Image
    im = Image.open(raw).convert("RGB")
    w, h = im.size
    px = im.load()
    bg = (0x1c, 0x1a, 0x20)
    near = lambda c: all(abs(c[i] - bg[i]) <= 3 for i in range(3))   # noqa: E731
    xs = [x for x in range(0, w, 2) if near(px[x, h // 2])]
    ys = [y for y in range(0, h, 2) if near(px[xs[len(xs) // 2], y])]
    box = (xs[0], ys[0], xs[-1] + 2, ys[-1] + 2)
    im.crop(box).save(out, optimize=True)
    return box


def main():
    plugdata = os.path.abspath(sys.argv[1])
    out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(ROOT, "docs", "images")
    os.makedirs(out, exist_ok=True)
    home = os.path.join(out, "_home")
    env = dict(os.environ, DISPLAY=":87", HOME=home)
    procs = [subprocess.Popen(["Xvfb", ":87", "-screen", "0", "3000x2600x24"], stdout=subprocess.DEVNULL,
                              stderr=subprocess.DEVNULL),
             subprocess.Popen(["jackd", "-d", "dummy", "-r", "48000", "-p", "256"], stdout=subprocess.DEVNULL,
                              stderr=subprocess.DEVNULL, env=env)]   # (plugdata draws pdlua objects on its audio tick)
    time.sleep(3)
    try:
        if not settings(home):              # first start: plugdata unpacks itself and writes its settings
            first = subprocess.Popen([plugdata], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            time.sleep(20)
            first.kill()
            time.sleep(1)
            settings(home)
        for sc in SCENES:
            demo = os.path.join(PD, "_shot.pd")
            open(demo, "w").write(scene_patch(sc))
            app = subprocess.Popen([plugdata, demo], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            try:
                time.sleep(15)
                wid = sh("xdotool", "search", "--onlyvisible", "--name", "plugdata", env=env).split()[-1]
                geo = dict(l.strip().split(": ", 1) for l in sh("xdotool", "getwindowgeometry", wid, env=env)
                           .splitlines()[1:])
                x, y = map(int, geo["Position"].split(" ")[0].split(","))
                w, h = map(int, geo["Geometry"].split("x"))
                # plugin mode: the plug button, top right (116 px in from the right edge at scale 1)
                sh("xdotool", "mousemove", str(x + w - 116 * ZOOM), str(y + 19 * ZOOM), "click", "1", env=env)
                time.sleep(4)
                sh("xdotool", "mousemove", "0", "0", env=env)
                raw = os.path.join(out, "_raw.png")
                sh("import", "-window", "root", raw, env=env)
                print(sc["file"], crop(raw, os.path.join(out, sc["file"])))
                os.remove(raw)
            finally:
                app.kill()
                os.remove(demo)
    finally:
        for p_ in procs:
            p_.kill()


if __name__ == "__main__":
    main()
