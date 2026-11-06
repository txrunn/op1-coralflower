#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Generate CoralOP's Max panel, remote/max/coralop-remote.maxpat, around [js coralop-core.js].

The patch opens in presentation mode: menus, toggles and numbers for every setting, a 3-octave [kslider] in
polyphonic mode for the OP-1's 24 keys (F3..E5; F#5 is HOLD; a click holds a key, another lets it go), the chord
name and the lit chord buttons. MIDI goes through [ctlin] / [ctlout 0 16] / [noteout 16]: pick the OP-1 in Max's
MIDI Setup (or set the objects' port)."""

import json, os

from gen_pd import PARAMS, SCALES, TYPES, NOTES

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "max"))
ADDS = ["None", "7", "Maj7", "6", "Add9", "9", "Maj9", "6/9", "Add2", "Add4", "11", "13", "7 Add11", "Maj7#11",
        "7b9", "7#9", "Add11", "Dim7", "Maj13"]

boxes, lines, nid = [], [], [0]


def items(names):
    out = []
    for i, n in enumerate(names):
        if i:
            out.append(",")
        out += [int(w) if w.lstrip("-+").isdigit() and not w.startswith("+") else w for w in n.split(" ")]
    return out


def box(maxclass, rect, pres=None, text=None, nin=1, nout=1, outtype=None, **attrs):
    nid[0] += 1
    b = {"id": f"obj-{nid[0]}", "maxclass": maxclass, "numinlets": nin, "numoutlets": nout,
         "outlettype": outtype if outtype is not None else [""] * nout, "patching_rect": list(rect)}
    if text is not None:
        b["text"] = text
    if pres:
        b["presentation"] = 1
        b["presentation_rect"] = list(pres)
    b.update(attrs)
    boxes.append({"box": b})
    return b["id"]


def obj(x, y, text, nin=1, nout=1, w=None, outtype=None):
    return box("newobj", (x, y, w or max(40, 7 * len(text) + 12), 22), text=text, nin=nin, nout=nout,
               outtype=outtype)


def msg(x, y, text):
    return box("message", (x, y, max(40, 7 * len(text) + 12), 22), text=text, nin=2, nout=1)


def comment(text, pres, size=11, color=None, rect=None):
    a = {"fontsize": size}
    if color:
        a["textcolor"] = color
    return box("comment", rect or (pres[0] + 1000, pres[1] + 600, pres[2], pres[3]), pres, text=text, nin=1,
               nout=0, **a)


def c(a, o, b, i=0):
    lines.append({"patchline": {"source": [a, o], "destination": [b, i]}})


CORAL, BLUE, GREEN, ORANGE, DIM = [1.0, 0.5, 0.42, 1.0], [0.41, 0.56, 1.0, 1.0], [0.0, 0.93, 0.58, 1.0], \
    [1.0, 0.42, 0.24, 1.0], [0.55, 0.54, 0.6, 1.0]


def main():
    core = obj(400, 700, "js coralop-core.js", 2, 2)
    to_core = obj(400, 670, "t l", 1, 1)
    c(to_core, 0, core)
    # MIDI in: [ctlin] -> "val cc ch" -> right inlet; out: [route ctl note] -> [ctlout 0 16] / [noteout 16]
    ci = obj(700, 600, "ctlin", 1, 3, outtype=["int", "int", "int"])
    pk = obj(700, 640, "pack 0 0 0", 3, 1)
    for k in range(3):
        c(ci, k, pk, k)
    c(pk, 0, core, 1)
    rt = obj(400, 740, "route ctl note", 2, 3)
    c(core, 0, rt)
    u1 = obj(400, 770, "unpack 0 0", 1, 2, outtype=["int", "int"])
    u2 = obj(520, 770, "unpack 0 0", 1, 2, outtype=["int", "int"])
    co = obj(400, 800, "ctlout 0 16", 3, 0)
    no = obj(520, 800, "noteout 16", 3, 0)
    c(rt, 0, u1)
    c(rt, 1, u2)
    c(u1, 0, co)
    c(u1, 1, co, 1)
    c(u2, 0, no)
    c(u2, 1, no, 1)
    names = [n for n, _, _ in PARAMS]
    extra = ["btn", "holding", "root", "sounding", "chord", "lit"]
    state = obj(700, 740, "route " + " ".join(names + extra), 2, len(names) + len(extra) + 1, w=900)
    c(core, 1, state)

    gx = [20]

    def wire(gui, name, out_conv=None, in_conv=None):
        x = gx[0]
        gx[0] += 110
        src = gui
        if out_conv:
            src = obj(x, 900, out_conv, 2, 1)
            c(gui, 0, src)
        p = obj(x, 930, f"prepend {name}", 2, 1)
        c(src, 0, p)
        c(p, 0, to_core)
        s = obj(x, 990, "prepend set", 2, 1)
        if in_conv:
            ic = obj(x, 960, in_conv, 2, 1)
            c(state, names.index(name), ic)
            c(ic, 0, s)
        else:
            c(state, names.index(name), s)
        c(s, 0, gui)

    def menu(name, labels, pres, out_conv=None, in_conv=None):
        u = box("umenu", (gx[0], 860, pres[2], 22), pres, nin=1, nout=3, outtype=["int", "", ""],
                items=items(labels), parameter_enable=0)
        wire(u, name, out_conv, in_conv)
        return u

    def toggle(name, pres):
        t = box("toggle", (gx[0], 860, 24, 24), pres, nin=1, nout=1, outtype=["int"], parameter_enable=0)
        wire(t, name)
        return t

    def number(name, lo, hi, pres):
        n = box("number", (gx[0], 860, 50, 22), pres, nin=1, nout=2, outtype=["", "bang"], minimum=lo,
                maximum=hi, parameter_enable=0)
        wire(n, name)
        return n

    def section(title, x, y, color):
        comment(title, (x, y, 200, 20), 13, color)

    def label(text, x, y, w=120):
        comment(text, (x, y, w, 18), 10, DIM)

    box("panel", (900, 20, 760, 360), (0, 0, 760, 360), nin=1, nout=0, bgcolor=[0.11, 0.1, 0.125, 1.0],
        background=1)
    comment("CORALOP", (14, 8, 160, 30), 22, CORAL)
    label("remote - MIDI channel 16", 170, 18, 200)
    chord = comment("-", (560, 6, 190, 40), 26, [0.9, 0.9, 0.9, 1.0])
    s = obj(1200, 990, "prepend set", 2, 1)
    c(state, len(names) + 4, s)
    c(s, 0, chord)
    lit = comment("-", (560, 46, 190, 18), 11, GREEN)
    s = obj(1300, 990, "prepend set", 2, 1)
    c(state, len(names) + 5, s)
    c(s, 0, lit)
    toggle("enable", (380, 12, 24, 24))
    label("ON", 408, 16, 30)
    for i, (txt, m) in enumerate((("SYNC", "sync"), ("PANIC", "panic"))):
        b = box("button", (1400 + i * 60, 860, 24, 24), (440 + i * 60, 12, 24, 24), nin=1, nout=1,
                outtype=["bang"], parameter_enable=0)
        label(txt, 466 + i * 60, 16, 40)
        mm = msg(1400 + i * 60, 900, m)
        c(b, 0, mm)
        c(mm, 0, to_core)

    section("PLAY", 14, 50, BLUE)
    label("quantize", 14, 72)
    menu("quant", ["Off", "Basic", "Full"], (14, 88, 110, 22))
    label("key", 134, 72)
    menu("tonic", NOTES, (134, 88, 70, 22))
    label("scale", 14, 116)
    menu("scale", [s.replace("_", " ") for s in SCALES], (14, 132, 190, 22))
    label("layout", 14, 160)
    menu("layout", ["Top Lock", "Top", "Side Lock", "Side"], (14, 176, 190, 22))

    section("CHORD BUTTON", 230, 50, GREEN)
    label("edit button (or press it on the OP-1)", 230, 72, 250)
    menu("sel", ["M6", "M7", "M9", "s2", "s4", "m6", "m7", "m9", "M", "m", "HOLD"], (230, 88, 110, 22))
    label("type", 230, 116)
    menu("type", TYPES, (230, 132, 110, 22))
    label("add", 350, 116)
    menu("add", ADDS, (350, 132, 120, 22))
    label("inversion", 230, 160)
    menu("inv", ["Auto", "0", "1", "2", "3"], (230, 176, 110, 22))
    label("bass degree (0 = root)", 350, 160, 140)
    number("bdeg", 0, 11, (350, 176, 50, 22))

    section("BASS / MIDI", 500, 72, ORANGE)
    toggle("bass", (500, 96, 24, 24))
    label("bass", 528, 100, 40)
    toggle("octaver", (580, 96, 24, 24))
    label("octaver", 608, 100, 60)
    label("bass octave", 500, 124)
    menu("boct", ["-2", "-1", "0", "+1", "+2"], (500, 140, 70, 22), "- 2", "+ 2")
    label("retrig", 590, 124)
    menu("retrig", ["Wait", "Notes", "Chord"], (590, 140, 90, 22))
    label("chord ch (0 = off)", 500, 168)
    number("chordch", 0, 16, (500, 184, 50, 22))
    label("bass ch", 620, 168)
    number("bassch", 0, 16, (620, 184, 50, 22))
    toggle("local", (500, 216, 24, 24))
    label("local (OP-1 sound)", 528, 220, 120)
    label("velocity", 660, 216, 60)
    number("vel", 1, 127, (690, 232, 50, 22))

    section("KEYS", 14, 214, CORAL)
    label("F3-E5 = the OP-1's keys (white roots, black chord buttons), F#5 = HOLD. Click holds, click again lets go.",
          60, 216, 440)
    ks = box("kslider", (1400, 940, 336, 53), (14, 236, 470, 80), nin=2, nout=2, outtype=["int", "int"],
             mode=1, offset=48, range=36, parameter_enable=0)
    kp = obj(1400, 1010, "pack 0 0", 2, 1)
    kpp = obj(1400, 1040, "prepend kslider", 2, 1)
    c(ks, 0, kp)
    c(ks, 1, kp, 1)
    c(kp, 0, kpp)
    c(kpp, 0, to_core)
    hold = box("toggle", (1500, 860, 24, 24), (500, 262, 24, 24), nin=1, nout=1, outtype=["int"],
               parameter_enable=0)
    label("HOLD", 528, 266, 40)
    tb = obj(1500, 900, "t b", 1, 1)
    hm = msg(1500, 930, "hold 1, hold 0")
    c(hold, 0, tb)
    c(tb, 0, hm)
    c(hm, 0, to_core)
    s = obj(1500, 990, "prepend set", 2, 1)
    c(state, len(names) + 1, s)
    c(s, 0, hold)
    comment("chord buttons lit:", (500, 46, 60, 18), 10, DIM, rect=(1600, 640, 100, 18))

    patch = {"patcher": {
        "fileversion": 1,
        "appversion": {"major": 8, "minor": 6, "revision": 0, "architecture": "x64", "modernui": 1},
        "classnamespace": "box", "rect": [80, 80, 780, 400], "openinpresentation": 1, "default_fontsize": 12.0,
        "boxes": boxes, "lines": lines, "dependency_cache": [
            {"name": "coralop-core.js", "bootpath": ".", "type": "TEXT", "implicit": 1}],
    }}
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "coralop-remote.maxpat"), "w") as f:
        json.dump(patch, f, indent=1)
    print("wrote", OUT, len(boxes), "boxes", len(lines), "lines")


if __name__ == "__main__":
    main()
