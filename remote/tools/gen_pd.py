#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Generate CoralOP's Pd / plugdata patches (vanilla objects only, Pd 0.52+ / plugdata):

    coralop-core.pd     the protocol (no GUI): left inlet  messages from the panel or your patch
                                               right inlet "val cc" from the OP-1 (channel 16, already filtered)
                                               left outlet  "ctl val cc" / "note pitch vel" for channel 16
                                               right outlet the OP-1's state: "<param> v", "btn i b", "chord name"...
    coralop-remote.pd   the panel: GUIs + [ctlin]/[ctlout 16]/[noteout 16] around the core; also usable as an
                        abstraction (graph on parent), with an inlet / outlet mirroring the core's left side

Run from anywhere: writes next to this script's parent folder (remote/pd/)."""

import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "pd"))

# name, cc, kind ("tgl": 0/1 <-> 0/127, "boct": -2..2 <-> 62..66, else as is)
PARAMS = [
    ("enable", 20, "tgl"), ("quant", 21, ""), ("tonic", 22, ""), ("scale", 23, ""), ("layout", 24, ""),
    ("retrig", 25, ""), ("bass", 26, "tgl"), ("boct", 27, "boct"), ("octaver", 28, "tgl"), ("chordch", 29, ""),
    ("bassch", 30, ""), ("local", 31, "tgl"), ("vel", 102, ""), ("sel", 104, ""), ("type", 105, ""),
    ("add", 106, ""), ("inv", 107, ""), ("bdeg", 108, ""),
]
SCALES = ["Major", "Natural_Minor", "Major_Pentatonic", "Minor_Pentatonic", "Dorian", "Mixolydian", "Lydian",
          "Phrygian", "Locrian", "Harmonic_Minor", "Melodic_Minor", "Blues", "Major_Blues", "Harmonic_Major",
          "Phrygian_Dominant", "Lydian_Dominant", "Altered", "Whole_Tone", "Diminished_W-H", "Diminished_H-W",
          "Hungarian_Minor", "Double_Harmonic", "Hirajoshi", "In_Sen", "Iwato", "Kumoi", "Chromatic"]
TYPES = ["None", "Major", "Minor", "Diminished", "Augmented", "Sus2", "Sus4", "Power"]
# (as symbols: a bare "7" would reach the label as a number, which Pd's [cnv] refuses)
ADDS = ["None", "7th", "Maj7", "6th", "Add9", "9th", "Maj9", "6/9", "Add2", "Add4", "11th", "13th", "7_Add11",
        "Maj7+11", "7b9", "7+9", "Add11", "Dim7", "Maj13"]
NOTES = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]


def esc(s):
    """a label with spaces ("_" in this file): Pd saves them escaped"""
    return s if s == "empty" else s.replace("_", "\\ ")


class Patch:
    def __init__(self, w=700, h=500, font=12):
        self.head = f"#N canvas 40 60 {w} {h} {font};"
        self.lines, self.conns, self.n = [], [], 0
        self.tail = []

    def add(self, kind, x, y, text):
        text = text.replace("$", "\\$").replace(",", " \\,").replace(";", " \\;")
        self.lines.append(f"#X {kind} {x} {y} {text};")
        self.n += 1
        return self.n - 1

    def obj(self, x, y, text):
        return self.add("obj", x, y, text)

    def msg(self, x, y, text):
        return self.add("msg", x, y, text)

    def text(self, x, y, text):
        return self.add("text", x, y, text)

    def c(self, a, o, b, i=0):
        self.conns.append(f"#X connect {a} {o} {b} {i};")

    def write(self, path):
        with open(path, "w") as f:
            f.write("\n".join([self.head] + self.lines + self.conns + self.tail) + "\n")


def core():
    p = Patch(1300, 900)
    p.text(10, 5, "CoralOP remote core: CoralFlower on the OP-1 over MIDI channel 16. See ../README.md")
    inl = p.obj(10, 30, "inlet")
    inr = p.obj(700, 30, "inlet")
    outl = p.obj(10, 860, "outlet")
    outr = p.obj(700, 860, "outlet")
    # ---- left side: the panel's / your messages -> "ctl val cc" / "note pitch vel"
    names = [n for n, _, _ in PARAMS]
    rt = p.obj(10, 60, "route " + " ".join(names) + " press hold sync panic")
    p.c(inl, 0, rt)
    ctl = p.obj(10, 820, "list prepend ctl")
    trim_l = p.obj(10, 840, "list trim")
    p.c(ctl, 0, trim_l)
    p.c(trim_l, 0, outl)
    for i, (name, cc, kind) in enumerate(PARAMS):
        x, y = 10 + (i % 6) * 110, 120 + (i // 6) * 90
        src = (rt, i)
        if kind == "tgl":
            a = p.obj(x, y, "!= 0")
            b = p.obj(x, y + 20, "* 127")
            p.c(*src, a)
            p.c(a, 0, b)
            src = (b, 0)
        elif kind == "boct":
            a = p.obj(x, y, "+ 64")
            p.c(*src, a)
            src = (a, 0)
        else:
            a = p.obj(x, y, "int")
            p.c(*src, a)
            src = (a, 0)
        cl = p.obj(x, y + 40, "clip 0 127")
        pk = p.obj(x, y + 60, f"pack f {cc}")
        p.c(*src, cl)
        p.c(cl, 0, pk)
        p.c(pk, 0, ctl)
    k = len(PARAMS)
    note = p.obj(300, 820, "list prepend note")
    p.c(note, 0, trim_l)
    # press k v
    up = p.obj(10, 420, "unpack f f")
    p.c(rt, k, up)
    vel = p.obj(80, 445, "!= 0")
    vel2 = p.obj(80, 465, "* 100")
    pitch = p.obj(10, 465, "+ 53")
    pkn = p.obj(10, 490, "pack f f")
    p.c(up, 1, vel)
    p.c(vel, 0, vel2)
    p.c(vel2, 0, pkn, 1)
    p.c(up, 0, pitch)
    p.c(pitch, 0, pkn)
    p.c(pkn, 0, note)
    # hold v (note 78)
    tb = p.obj(200, 420, "t b f")
    p.c(rt, k + 1, tb)
    hv = p.obj(260, 445, "!= 0")
    hv2 = p.obj(260, 465, "* 100")
    h78 = p.msg(200, 465, "78")
    pkh = p.obj(200, 490, "pack f f")
    p.c(tb, 1, hv)
    p.c(hv, 0, hv2)
    p.c(hv2, 0, pkh, 1)
    p.c(tb, 0, h78)
    p.c(h78, 0, pkh)
    p.c(pkh, 0, note)
    sync = p.msg(360, 420, "ctl 0 110")
    panic = p.msg(450, 420, "ctl 0 109")
    p.c(rt, k + 2, sync)
    p.c(rt, k + 3, panic)
    p.c(sync, 0, outl)
    p.c(panic, 0, outl)

    # ---- right side: "val cc" from the OP-1 -> state messages
    un = p.obj(700, 60, "unpack f f")
    sw = p.obj(700, 85, "swap")
    pk = p.obj(700, 110, "pack f f")
    p.c(inr, 0, un)
    p.c(un, 1, sw, 1)
    p.c(un, 0, sw)
    p.c(sw, 1, pk, 1)
    p.c(sw, 0, pk)
    ccs = [cc for _, cc, _ in PARAMS] + [112, 113, 114, 115, 116, 117, 118]
    rr = p.obj(700, 135, "route " + " ".join(map(str, ccs)))
    p.c(pk, 0, rr)
    trim_r = p.obj(700, 840, "list trim")
    p.c(trim_r, 0, outr)
    for i, (name, cc, kind) in enumerate(PARAMS):
        x, y = 700 + (i % 6) * 100, 180 + (i // 6) * 70
        if kind == "tgl":
            a = p.obj(x, y, ">= 64")
        elif kind == "boct":
            a = p.obj(x, y, "- 64")
        else:
            a = p.obj(x, y, "int")
        b = p.obj(x, y + 25, f"list prepend {name}")
        p.c(rr, i, a)
        p.c(a, 0, b)
        p.c(b, 0, trim_r)
    k = len(PARAMS)
    # 112 / 113: the lit chord buttons, one "btn i b" each
    for half, base, bits in ((0, 0, 7), (1, 7, 4)):
        for j in range(bits):
            x, y = 700 + j * 85, 400 + half * 70
            a = p.obj(x, y, f">> {j}")
            b = p.obj(x, y + 20, "& 1")
            c = p.obj(x, y + 40, f"list prepend btn {base + j}")
            p.c(rr, k + half, a)
            p.c(a, 0, b)
            p.c(b, 0, c)
            p.c(c, 0, trim_r)
    hold = p.obj(700, 550, ">= 64")
    holdp = p.obj(700, 575, "list prepend holding")
    p.c(rr, k + 2, hold)
    p.c(hold, 0, holdp)
    p.c(holdp, 0, trim_r)
    root = p.obj(800, 550, "sel 127")
    rm1 = p.msg(800, 575, "-1")
    rp = p.obj(800, 600, "list prepend root")
    p.c(rr, k + 3, root)
    p.c(root, 0, rm1)
    p.c(rm1, 0, rp)
    p.c(root, 1, rp)
    p.c(rp, 0, trim_r)
    snd = p.obj(900, 550, ">= 64")
    sndp = p.obj(900, 575, "list prepend sounding")
    p.c(rr, k + 4, snd)
    p.c(snd, 0, sndp)
    p.c(sndp, 0, trim_r)
    # 117 length, then 118 one character each -> "chord <name>" ("chord -" for none)
    ln = p.obj(1000, 550, "t f b")
    p.c(rr, k + 5, ln)
    lenf = p.obj(1060, 575, "f")             # (cold: the length)
    clear = p.msg(1000, 575, "list")         # empty list: the accumulator restarts
    acc = p.obj(1000, 650, "list prepend")
    p.c(ln, 1, clear)
    p.c(ln, 0, lenf, 1)
    zero = p.obj(1120, 575, "sel 0")
    dash = p.msg(1120, 600, "symbol -")
    p.c(ln, 0, zero)
    p.c(zero, 0, dash)
    p.c(clear, 0, acc, 1)
    chars = p.obj(1000, 625, "int")
    p.c(rr, k + 6, chars)
    p.c(chars, 0, acc)
    t3 = p.obj(1000, 675, "t l l l")
    p.c(acc, 0, t3)
    p.c(t3, 2, acc, 1)
    hold_l = p.obj(1000, 760, "list")
    p.c(t3, 1, hold_l, 1)
    llen = p.obj(1060, 700, "list length")
    p.c(t3, 0, llen)
    # compare: length == stored length -> bang the stored list
    tl = p.obj(1060, 720, "t f b")
    p.c(llen, 0, tl)
    p.c(tl, 1, lenf)
    eq = p.obj(1060, 745, "==")
    p.c(lenf, 0, eq, 1)
    p.c(tl, 0, eq)
    sel1 = p.obj(1060, 770, "sel 1")
    p.c(eq, 0, sel1)
    p.c(sel1, 0, hold_l)
    tos = p.obj(1000, 795, "list tosymbol")
    p.c(hold_l, 0, tos)
    chord = p.obj(1000, 820, "list prepend chord")
    p.c(tos, 0, chord)
    p.c(dash, 0, chord)
    p.c(chord, 0, trim_r)
    p.write(os.path.join(OUT, "coralop-core.pd"))


# ------------------------------------------------------------------------------------------- the panel ---
BG, FG, CORAL, BLUE, GREEN, WHITE, ORANGE, DIM = ("#1c1a20", "#e6e6e6", "#ff7f6a", "#698eff", "#00ed95",
                                                   "#e6e6e6", "#ff6a3d", "#5a5866")
CELL = 22


def tgl(x, y, label="empty", fg=CORAL, size=CELL, lx=None, ly=None):
    lx = size + 5 if lx is None else lx
    ly = size // 2 if ly is None else ly
    return x, y, f"tgl {size} 0 empty empty {esc(label)} {lx} {ly} 0 10 {BG} {fg} {FG} 0 1"


def hradio(x, y, n, label, fg, size=CELL):
    return x, y, f"hradio {size} 1 0 {n} empty empty {esc(label)} 0 -8 0 10 {BG} {fg} {fg} 0"


def nbx(x, y, w, lo, hi, label, fg):
    return x, y, f"nbx {w} {CELL - 4} {lo} {hi} 0 0 empty empty {esc(label)} 0 -8 0 10 {BG} {FG} {fg} 0 256"


def bng(x, y, label, fg=CORAL, size=CELL):
    return x, y, f"bng {size} 150 50 0 empty empty {esc(label)} {size + 5} {size // 2} 0 10 {BG} {fg} {FG}"


def cnv(x, y, w, h, recv, label, bg, lbl, font=12, lx=6, ly=10):
    return x, y, f"cnv 1 {w} {h} empty {recv} {esc(label)} {lx} {ly} 0 {font} {bg} {lbl} 0"


def lbl(x, y, text, color=DIM, size=10):
    """a coloured label (a 1x1 canvas carrying it: Pd's comments take no colour)"""
    return x, y, f"cnv 1 1 1 empty empty {esc(text)} 0 0 0 {size} {BG} {color} 0"


def cells(p, x, y, names, color=DIM, cell=CELL):
    for i, nm in enumerate(names):
        w = 6 * len(nm)
        p.obj(*lbl(x + i * cell + max(0, (cell - w) // 2), y + cell + 7, nm, color))


def panel():
    W, H = 760, 400
    p = Patch(1500, 1500)
    g = lambda spec: p.obj(*spec)           # noqa: E731
    g(cnv(0, 0, W, H, "empty", "empty", BG, FG))
    g(cnv(10, 8, 120, 24, "empty", "CORALOP", BG, CORAL, 18, 0, 12))
    g(lbl(122, 20, "remote_over_MIDI_channel_16", DIM, 10))
    core = p.obj(800, 600, "coralop-core")
    to_core = p.obj(800, 570, "t a")         # everything the panel says goes through here
    p.c(to_core, 0, core)
    state = p.obj(1100, 640, "route " + " ".join(n for n, _, _ in PARAMS) + " btn holding root sounding chord")
    p.c(core, 1, state)
    # MIDI: [ctlin] channel 16 -> core right inlet; core left outlet -> [ctlout 16] / [noteout 16] + the outlet
    ci = p.obj(800, 470, "ctlin")
    ch16 = p.obj(900, 495, "== 16")
    sp = p.obj(800, 520, "spigot")
    pk = p.obj(800, 545, "pack f f")
    p.c(ci, 2, ch16)
    p.c(ch16, 0, sp, 1)
    p.c(ci, 1, pk, 1)
    p.c(ci, 0, sp)
    p.c(sp, 0, pk)
    p.c(pk, 0, core, 1)
    # abstraction use: inlet 1 = the core's left side, inlet 2 = "val cc" as if from the OP-1
    inl = p.obj(1000, 470, "inlet")
    inr = p.obj(1060, 470, "inlet")
    p.c(inl, 0, to_core)
    p.c(inr, 0, core, 1)
    rout = p.obj(800, 640, "route ctl note")
    p.c(core, 0, rout)
    u1 = p.obj(800, 665, "unpack f f")
    co = p.obj(800, 690, "ctlout 0 16")     # (args: controller, channel)
    p.c(rout, 0, u1)
    p.c(u1, 1, co, 1)
    p.c(u1, 0, co)
    u2 = p.obj(900, 665, "unpack f f")
    no = p.obj(900, 690, "noteout 16")
    p.c(rout, 1, u2)
    p.c(u2, 1, no, 1)
    p.c(u2, 0, no)
    outl = p.obj(1000, 690, "outlet")
    p.c(core, 0, outl)
    outr = p.obj(1060, 690, "outlet")
    p.c(core, 1, outr)

    names = [n for n, _, _ in PARAMS]
    gx, gy = 800, 1100                      # where the rest of the glue goes

    slot = [0]

    def spot():
        i = slot[0]
        slot[0] += 1
        return 800 + (i % 7) * 95, 760 + (i // 7) * 110

    def wire(gui, name, out_conv=None, in_conv=None):
        """gui outlet -> [out_conv] -> "<name> $1" -> core; state "<name> v" -> [in_conv] -> "set $1" -> gui"""
        x, y = spot()
        src = gui
        if out_conv:
            src = p.obj(x, y - 25, out_conv)
            p.c(gui, 0, src)
        m_out = p.msg(x, y, f"{name} $1")
        p.c(src, 0, m_out)
        p.c(m_out, 0, to_core)
        m_in = p.msg(x, y + 50, "set $1")
        if in_conv:
            conv = p.obj(x, y + 25, in_conv)
            p.c(state, names.index(name), conv)
            p.c(conv, 0, m_in)
        else:
            p.c(state, names.index(name), m_in)
        p.c(m_in, 0, gui)

    # --- header: on/off, sync, panic, the chord
    en = g(tgl(330, 10, "ON", GREEN))
    wire(en, "enable")
    sy = g(bng(390, 10, "SYNC", BLUE))
    m = p.msg(1200, 960, "sync")
    p.c(sy, 0, m)
    p.c(m, 0, to_core)
    pa = g(bng(460, 10, "PANIC", ORANGE))
    m = p.msg(1260, 960, "panic")
    p.c(pa, 0, m)
    p.c(m, 0, to_core)
    lb = p.obj(1200, 900, "loadbang")
    m = p.msg(1200, 925, "sync")
    p.c(lb, 0, m)
    p.c(m, 0, to_core)
    # the chord name, large
    g(cnv(540, 6, 210, 34, "$0-chord", "-", "#2a2730", FG, 22, 8, 17))
    sc = p.obj(1300, 700, "s $0-chord")
    sy_ = p.obj(1300, 650, "symbol")        # ("chord Cmaj7" leaves route as the message Cmaj7)
    m = p.msg(1300, 675, "label $1")
    p.c(state, len(names) + 4, sy_)
    p.c(sy_, 0, m)
    p.c(m, 0, sc)

    # --- PLAY
    y = 62
    g(cnv(10, y - 16, 230, 14, "empty", "PLAY", BG, BLUE, 11, 0, 6))
    q = g(hradio(10, y + 10, 3, "QUANTIZE", BLUE))
    cells(p, 10, y + 10, ["OFF", "BAS", "FUL"])
    wire(q, "quant")
    t = g(hradio(10, y + 62, 12, "KEY", BLUE))
    wire(t, "tonic")
    cells(p, 10, y + 62, NOTES)
    s = g(nbx(10, y + 122, 3, 0, 26, "SCALE", BLUE))
    wire(s, "scale")
    g(cnv(55, y + 120, 200, 22, "$0-scalename", "Major", BG, FG, 12, 4, 11))
    ls = p.obj(1300, 760, "list store " + " ".join(esc(n) for n in SCALES))
    gs = p.msg(1300, 735, "get $1 1")
    p.c(state, names.index("scale"), gs)
    p.c(gs, 0, ls)
    m = p.msg(1300, 785, "label $1")
    p.c(ls, 0, m)
    snm = p.obj(1300, 810, "s $0-scalename")
    p.c(m, 0, snm)
    lay = g(hradio(10, y + 168, 4, "LAYOUT", BLUE, 28))
    cells(p, 10, y + 168, ["T+L", "TOP", "S+L", "SID"], cell=28)
    wire(lay, "layout")

    # --- CHORD (the selected chord button's form)
    x0 = 290
    g(cnv(x0, y - 16, 230, 14, "empty", "CHORD_BUTTON", BG, GREEN, 11, 0, 6))
    sel = g(hradio(x0, y + 10, 11, "EDIT_BUTTON", GREEN))
    wire(sel, "sel")
    cells(p, x0, y + 10, ["M6", "M7", "M9", "s2", "s4", "m6", "m7", "m9", "M", "m", "HD"])
    ty = g(nbx(x0, y + 62, 2, 0, len(TYPES) - 1, "TYPE", GREEN))
    wire(ty, "type")
    g(cnv(x0 + 32, y + 60, 110, 22, "$0-typename", "Major", BG, FG, 12, 4, 11))
    lt = p.obj(1300, 860, "list store " + " ".join(TYPES))
    gt = p.msg(1300, 835, "get $1 1")
    p.c(state, names.index("type"), gt)
    p.c(gt, 0, lt)
    m = p.msg(1300, 885, "label $1")
    p.c(lt, 0, m)
    p.c(m, 0, p.obj(1300, 910, "s $0-typename"))
    ad = g(nbx(x0, y + 110, 2, 0, len(ADDS) - 1, "ADD", GREEN))
    wire(ad, "add")
    g(cnv(x0 + 32, y + 108, 110, 22, "$0-addname", "None", BG, FG, 12, 4, 11))
    la = p.obj(1300, 960, "list store " + " ".join(esc(n) for n in ADDS))
    ga = p.msg(1300, 935, "get $1 1")
    p.c(state, names.index("add"), ga)
    p.c(ga, 0, la)
    m = p.msg(1300, 985, "label $1")
    p.c(la, 0, m)
    p.c(m, 0, p.obj(1300, 1010, "s $0-addname"))
    inv = g(hradio(x0, y + 158, 5, "INVERSION", GREEN))
    cells(p, x0, y + 158, ["A", "0", "1", "2", "3"])
    wire(inv, "inv")
    bd = g(nbx(x0 + 140, y + 158, 2, 0, 11, "BASS_DEGREE", GREEN))
    wire(bd, "bdeg")

    # --- BASS / MIDI
    x1 = 570
    g(cnv(x1, y - 16, 180, 14, "empty", "BASS_/_MIDI", BG, ORANGE, 11, 0, 6))
    b = g(tgl(x1, y + 4, "BASS", ORANGE))
    wire(b, "bass")
    o = g(tgl(x1 + 80, y + 4, "OCTAVER", ORANGE))
    wire(o, "octaver")
    bo = g(hradio(x1, y + 52, 5, "BASS_OCTAVE", ORANGE))
    cells(p, x1, y + 52, ["-2", "-1", "0", "+1", "+2"])
    wire(bo, "boct", "- 2", "+ 2")          # (the hradio is 0..4, the parameter -2..+2)
    rt = g(hradio(x1, y + 112, 3, "RETRIG", ORANGE))
    cells(p, x1, y + 112, ["WT", "NT", "CH"])
    wire(rt, "retrig")
    cc_ = g(nbx(x1, y + 170, 2, 0, 16, "CHORD_CH", ORANGE))
    wire(cc_, "chordch")
    bc = g(nbx(x1 + 70, y + 170, 2, 0, 16, "BASS_CH", ORANGE))
    wire(bc, "bassch")
    lo = g(tgl(x1 + 130, y + 168, "LOCAL", ORANGE))
    wire(lo, "local")
    ve = g(nbx(x1, y + 212, 3, 1, 127, "VELOCITY", ORANGE))
    g(lbl(x1 + 40, y + 218, "(channel_0_=_off)", DIM, 10))
    wire(ve, "vel")

    # --- the keyboard: 14 white keys (roots, latched: a new one replaces the held one), 10 black (held while on)
    ky = 300
    g(cnv(10, ky - 16, 100, 14, "empty", "KEYS", BG, CORAL, 11, 0, 6))
    g(lbl(60, ky - 9, "white:_roots_(latched_until_REL)___black:_chord_buttons_(held_while_lit)", DIM, 10))
    held = p.obj(gx, gy + 140, "f -1")      # the white key held
    rel_sel = p.obj(gx, gy + 165, "moses 0")
    rel_msg = p.msg(gx, gy + 190, "press $1 0")
    p.c(held, 0, rel_sel)
    p.c(rel_sel, 1, rel_msg)
    p.c(rel_msg, 0, to_core)
    white_k = [i for i in range(24) if i not in (1, 3, 5, 8, 10, 13, 15, 17, 20, 22)]
    black_k = [1, 3, 5, 8, 10, 13, 15, 17, 20, 22]
    wx = {}
    for j, k in enumerate(white_k):
        x = 10 + j * 34
        wx[k] = x
        kb = g(bng(x, ky + 40, "empty", CORAL, 30))
        g(lbl(x + 12, ky + 80, "FGABCDEFGABCDE"[j], DIM, 10))
        t = p.obj(gx + 100 + j * 40, gy + 140, f"t b b")
        p.c(kb, 0, t)
        p.c(t, 1, held)                     # first let the old one go
        m1 = p.msg(gx + 100 + j * 40, gy + 165, f"press {k} 1")
        p.c(t, 0, m1)
        p.c(m1, 0, to_core)
        st = p.msg(gx + 100 + j * 40, gy + 190, f"{k}")
        p.c(t, 0, st)
        p.c(st, 0, held, 1)
    rb = g(bng(10 + 14 * 34 + 6, ky + 40, "REL", WHITE, 30))
    t = p.obj(gx, gy + 215, "t b b")
    p.c(rb, 0, t)
    p.c(t, 1, held)
    m = p.msg(gx + 40, gy + 240, "-1")
    p.c(t, 0, m)
    p.c(m, 0, held, 1)
    labels = ["M6", "M7", "M9", "s2", "s4", "m6", "m7", "m9", "M", "m"]
    lit_on, lit_off = f"color {GREEN} {GREEN}", "color #2e2b34 #2e2b34"
    for j, k in enumerate(black_k):
        # a button, not a toggle (plugdata draws an off toggle's cross under the label): a click flips the
        # key's held state, and a light below shows it, set by the click and by the OP-1's "btn j b"
        x = wx[k - 1] + 20
        kb = g(bng(x, ky + 4, "empty", CORAL, 26))
        g(lbl(x + 13 - 3 * len(labels[j]), ky + 17, labels[j], FG, 10))
        held_k = p.obj(gx + 100 + j * 40, gy + 235, "f")
        flip = p.obj(gx + 100 + j * 40, gy + 260, "== 0")
        p.c(kb, 0, held_k)
        p.c(held_k, 0, flip)
        p.c(flip, 0, held_k, 1)
        m = p.msg(gx + 100 + j * 40, gy + 285, f"press {k} $1")
        p.c(flip, 0, m)
        p.c(m, 0, to_core)
        light = g(cnv(x + 8, ky + 34, 10, 4, f"$0-lit{j}", "empty", "#2e2b34", FG, 10, 0, 0))
        sel_ = p.obj(gx + 100 + j * 40, gy + 335, "sel 0")
        p.c(flip, 0, sel_)
        m_off = p.msg(gx + 100 + j * 40, gy + 360, lit_off)
        m_on = p.msg(gx + 100 + j * 40, gy + 385, lit_on)
        p.c(sel_, 0, m_off)
        p.c(sel_, 1, m_on)
        snd = p.obj(gx + 100 + j * 40, gy + 410, f"s $0-lit{j}")
        p.c(m_off, 0, snd)
        p.c(m_on, 0, snd)
        sl = p.obj(gx + 100 + j * 40, gy + 310, f"route {j}")   # the OP-1's word: the light, and the state
        p.c(state, len(names), sl)
        p.c(sl, 0, sel_)
        p.c(sl, 0, held_k, 1)
    hb = g(tgl(10 + 14 * 34 + 6, ky + 4, "HOLD", GREEN, 26))
    m = p.msg(gx, gy + 290, "hold 1, hold 0")
    p.c(hb, 0, m)
    p.c(m, 0, to_core)
    m = p.msg(gx, gy + 315, "set $1")
    p.c(state, len(names) + 1, m)
    p.c(m, 0, hb)

    p.tail.append(f"#X coords 0 -1 1 1 {W} {H} 2 0 0;")
    p.write(os.path.join(OUT, "coralop-remote.pd"))


# the tuning presets on the panel (coralfret.pd_lua has them all), two rows
TUNINGS = [("standard", "STD"), ("halfdown", "Eb"), ("fulldown", "D"), ("dropd", "DrD"), ("dropc", "DrC"),
           ("dropb", "DrB"), ("nashville", "NSH"), ("7string", "7st"), ("8string", "8st"), ("bass", "BAS")]
TUNINGS2 = [("openg", "opG"), ("opend", "opD"), ("opene", "opE"), ("opena", "opA"), ("openc", "opC"),
            ("openf", "opF"), ("opendm", "Dm"), ("opencm", "Cm"), ("opengm", "Gm"), ("dadgad", "DAD"),
            ("facgce", "FAC"), ("cgcgce", "CGC"), ("facfcf", "FCF"), ("dadead", "DAE"), ("cgdgbd", "CGD"),
            ("eadeae", "EAE")]


def guitar():
    """coralop-guitar.pd: the panel, the fretboard (pdlua: built into plugdata) and its controls; the wiring lives
    in coralop-guitar-glue.pd (given $0), so no patch cords cross the fretboard"""
    # ---- the glue (an abstraction: $1 is the main patch's $0)
    q = Patch(900, 600)
    q.text(10, 5, "CoralOP guitar glue: the OP-1's notes and CoralOP's state into [coralfret], its voicing out")
    fr_s = q.obj(10, 560, "s $1-fret")
    ni = q.obj(10, 40, "notein")
    pk = q.obj(10, 70, "pack f f f")
    for k in range(3):
        q.c(ni, k, pk, k)
    q.c(pk, 0, fr_s)
    rn = q.obj(150, 70, "r coralop-notes")          # (other patches: "pitch vel ch" lists, as from [notein])
    q.c(rn, 0, fr_s)
    st = q.obj(10, 120, "route chord root chordch bassch")
    q.c(q.obj(10, 95, "r $1-state"), 0, st)
    q.c(q.obj(250, 95, "r coralop-state"), 0, st)   # (other patches: the core's state messages)
    sy = q.obj(10, 150, "symbol")
    m = q.msg(10, 175, "chord $1")
    q.c(st, 0, sy)
    q.c(sy, 0, m)
    q.c(m, 0, fr_s)
    m = q.msg(90, 175, "root $1")
    q.c(st, 1, m)
    q.c(m, 0, fr_s)
    chp = q.obj(170, 200, "pack f 2")
    q.c(st, 2, chp)
    tb = q.obj(250, 150, "t b f")
    q.c(st, 3, tb)
    q.c(tb, 1, chp, 1)
    q.c(tb, 0, chp)
    m = q.msg(170, 225, "channels $1 $2")
    q.c(chp, 0, m)
    q.c(m, 0, fr_s)
    # the controls (iemgui send names) into the fretboard
    for i, nm in enumerate(["capo", "frets", "span", "strum", "outch", "out", "lefty"]):
        r = q.obj(400 + (i % 4) * 110, 40 + (i // 4) * 60, f"r $1-{nm}")
        m = q.msg(400 + (i % 4) * 110, 65 + (i // 4) * 60, f"{nm} $1")
        q.c(r, 0, m)
        q.c(m, 0, fr_s)
    r = q.obj(400, 280, "r $1-bassmode")    # 0 strict, 1 any
    sl = q.obj(400, 305, "sel 0 1")
    q.c(r, 0, sl)
    for k, word in enumerate(("strict", "any")):
        m = q.msg(400 + k * 80, 330, f"bass {word}")
        q.c(sl, k, m)
        q.c(m, 0, fr_s)
    for row, (name, presets) in enumerate((("tunsel", TUNINGS), ("tunsel2", TUNINGS2))):
        x = 400 + row * 300
        r = q.obj(x, 170, f"r $1-{name}")
        ls = q.obj(x, 220, "list store " + " ".join(n for n, _ in presets))
        g_ = q.msg(x, 195, "get $1 1")
        q.c(r, 0, g_)
        q.c(g_, 0, ls)
        m = q.msg(x, 245, "tuning $1")
        q.c(ls, 0, m)
        q.c(m, 0, fr_s)
    m = q.msg(700, 40, "tuning $1")          # typed into the symbol box
    q.c(q.obj(700, 15, "r $1-owntuning"), 0, m)
    q.c(m, 0, fr_s)
    # one tuning selected across the two rows: the other row's mark goes the background's colour
    on, off = f"color {BG} {GREEN} {GREEN}", f"color {BG} {BG} {GREEN}"
    for row, (name, other) in enumerate((("tunsel", "tunsel2"), ("tunsel2", "tunsel"))):
        x = 400 + row * 300
        tb_ = q.obj(x, 270, "t b b")
        q.c(q.obj(x + 100, 170, f"r $1-{name}"), 0, tb_)
        m = q.msg(x, 295, on)
        q.c(tb_, 1, m)
        q.c(m, 0, q.obj(x, 320, f"s $1-{name}-in"))
        m = q.msg(x + 150, 295, off)
        q.c(tb_, 0, m)
        q.c(m, 0, q.obj(x + 150, 320, f"s $1-{other}-in"))
    lb = q.obj(700, 360, "loadbang")        # the first row starts selected (standard)
    m = q.msg(700, 385, off)
    q.c(lb, 0, m)
    q.c(m, 0, q.obj(700, 410, "s $1-tunsel2-in"))
    # the voicing out: strummed through [pipe], on its own channel
    ro = q.obj(10, 300, "route note ch clear")
    q.c(q.obj(10, 275, "r $1-fretout"), 0, ro)
    un = q.obj(10, 325, "unpack f f f")
    pi = q.obj(10, 350, "pipe f f 0")
    q.c(ro, 0, un)
    q.c(un, 2, pi, 2)
    q.c(un, 1, pi, 1)
    q.c(un, 0, pi)
    no = q.obj(10, 380, "noteout 3")
    q.c(pi, 1, no, 1)
    q.c(pi, 0, no)
    q.c(ro, 1, no, 2)
    cl = q.msg(150, 325, "clear")
    q.c(ro, 2, cl)
    q.c(cl, 0, pi)
    q.write(os.path.join(OUT, "coralop-guitar-glue.pd"))

    for with_panel in (True, False):
        guitar_patch(with_panel)


def guitar_patch(with_panel):
    """coralop-guitar.pd: panel + fretboard; coralop-voicing.pd: the fretboard alone, listening to the OP-1 (its
    state on channel 16, its notes) with its voicing going out: a second plugdata whose MIDI goes to a guitar
    instrument, not to the OP-1.

    Both are graph-on-parent, so plugdata's plugin mode shows just the panel. The plumbing is created first and a
    background canvas over it, so only the controls show; the panel, the fretboard and the controls come after."""
    W = 760
    top = 420 if with_panel else 10
    y = top + 220                           # the guitar controls
    H = y + 220
    p = Patch(W + 200, H + 40)
    g = lambda spec: p.obj(*spec)           # noqa: E731
    # --- plumbing (hidden under the background)
    r = p.obj(20, top + 40, "r $0-fret")
    o2 = p.obj(120, top + 40, "s $0-fretout")
    p.obj(20, top + 70, "coralop-guitar-glue $0")
    if with_panel:
        s_state = p.obj(20, top + 100, "s $0-state")
    else:                                   # the OP-1's state, decoded (nothing goes back to it)
        ci = p.obj(250, top + 40, "ctlin")
        ch16 = p.obj(330, top + 60, "== 16")
        sp_ = p.obj(250, top + 80, "spigot")
        pk = p.obj(250, top + 100, "pack f f")
        core = p.obj(250, top + 120, "coralop-core")
        st = p.obj(350, top + 140, "s $0-state")
        p.c(ci, 2, ch16)
        p.c(ch16, 0, sp_, 1)
        p.c(ci, 1, pk, 1)
        p.c(ci, 0, sp_)
        p.c(sp_, 0, pk)
        p.c(pk, 0, core, 1)
        p.c(core, 1, st)
    # --- the background, then what shows
    g(cnv(0, 0, W + 20, H, "empty", "empty", BG, FG))
    if with_panel:
        panel = p.obj(10, 10, "coralop-remote")
        p.c(panel, 1, s_state)
    fr = p.obj(10, top, "coralfret")
    p.c(r, 0, fr)
    p.c(fr, 1, o2)
    g(cnv(16, y, 200, 14, "empty", "GUITAR", BG, CORAL, 12, 0, 7))
    g(lbl(80, y + 7, "standard_/_down_/_drop_/_re-entrant_/_more_strings", DIM, 10))
    TC = 30
    g((16, y + 20, f"hradio {TC} 1 0 {len(TUNINGS)} $0-tunsel $0-tunsel-in empty 0 -8 0 10 {BG} {GREEN} {GREEN} 0"))
    cells(p, 16, y + 20, [l for _, l in TUNINGS], cell=TC)
    g(lbl(16, y + 74, "open_/_modal_/_math_rock", DIM, 10))
    g((16, y + 84, f"hradio {TC} 1 0 {len(TUNINGS2)} $0-tunsel2 $0-tunsel2-in empty 0 -8 0 10 {BG} {GREEN} {GREEN} 0"))
    cells(p, 16, y + 84, [l for _, l in TUNINGS2], cell=TC)
    # your own: a symbol box (shown in plugin mode, unlike message boxes): "FACGCE" or "E3 A3 D4 G4 B3 E4", Enter
    g(lbl(400, y + 7, "your_own:_type_FACGCE_or_E3_A3_D4_G4_B3_E4_then_Enter", DIM, 10))
    p.add("symbolatom", 400, y + 20, "28 0 0 0 - - $0-owntuning")
    yy = y + 154
    for i, (nm, lo, hi, x, v) in enumerate([("capo", 0, 12, 16, 0), ("frets", 12, 24, 76, 15),
                                            ("span", 2, 5, 136, 3), ("strum", 0, 200, 206, 25),
                                            ("outch", 1, 16, 286, 3)]):
        label = {"outch": "OUT_CH", "strum": "STRUM_MS", "span": "STRETCH"}.get(nm, nm.upper())
        p.obj(x, yy, f"nbx 3 {CELL - 4} {lo} {hi} 0 1 $0-{nm} empty {esc(label)} 0 -8 0 10 {BG} {FG} {ORANGE} {v} 256")
    g((356, yy - 2, f"hradio {CELL} 1 1 2 $0-bassmode empty BASS\\ NOTE 0 -8 0 10 {BG} {ORANGE} {ORANGE} 0"))
    cells(p, 356, yy - 2, ["low", "any"])
    for nm, label, x in [("out", "VOICING_TO_MIDI", 450), ("lefty", "LEFTY", 620)]:
        on = 1 if (nm == "out" and not with_panel) else 0
        p.obj(x, yy - 2, f"tgl {CELL} {on} $0-{nm} empty {esc(label)} {CELL + 5} {CELL // 2} 0 10 {BG} {GREEN} {FG} {on} 1")
    g(lbl(16, yy + 38, "<_>_above_the_neck:_next_shape.___STRETCH:_frets_past_the_first_(3_=_a_four-fret_hand).",
          DIM, 10))
    g(lbl(16, yy + 52, "BASS_NOTE_low:_the_chord's_bass_is_the_lowest_note.___any:_open_strings_may_ring_under_it.",
          DIM, 10))
    p.tail.append(f"#X coords 0 -1 1 1 {W + 20} {H} 1 0 0;")
    p.write(os.path.join(OUT, "coralop-guitar.pd" if with_panel else "coralop-voicing.pd"))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    core()
    panel()
    guitar()
    print("wrote", OUT)
