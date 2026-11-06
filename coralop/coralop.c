/* SPDX-License-Identifier: GPL-3.0-only
 * CoralOP (spec: README.md): CoralFlower's chord instrument on the OP-1. Black keys are chord buttons, white keys
 * roots (Top layouts), or three qualities + four extensions and the rest roots (Side); a chord goes out as two parts,
 * CHORD and BASS, on USB MIDI channels of their own, and on the OP-1's own synth when LOCAL is on. MIDI channel 16
 * remote-controls it (co_remote.h): its keys, every setting, and the state and chord name sent back.
 *
 * co_on_key   on_key (filter, first), KeyHandler thread: shift + insert on / panel / off (as CHORD+); while on, in
 *             synth playmode: the 24 note keys (consumed: TE plays nothing of its own), T1 PLAY, T2 CHORD, T3 BASS /
 *             MIDI pages, T4 HOLD; insert while the panel shows pins it
 * co_on_knob  on_knob (filter, first) while the panel shows: the page's four values
 * co_midi     midi_in (filter): channel 16 is CoralOP's (while off: only CC 20 enable and CC 110 dump)
 * co_tick     Seq thread, once per 64-frame block: the clock, then every queued event, then the feedback
 * co_frame    after TE's frame (last): the chord badge while on, the panel while it shows
 * The model, the settings and the notes belong to the Seq thread: the KeyHandler and the MIDI side only queue
 * events (one queue each) and keep their own UI state (page, panel, the keys they took); the GUI thread only reads.
 * Settings live in RAM: after a boot CoralOP is off, Top + Lock, Quantize Basic, C major, chord on MIDI channel 1,
 * bass on 2, LOCAL on. */
#include <op1/te246.h>
#include <op1/gfx.h>
#include "co_play.h"
#include "co_remote.h"

#define PANEL_TIME  (TE_SAMPLE_RATE * 5)
#define MS(samples) ((samples) / (TE_SAMPLE_RATE / 1000))

/* usbmidi_tx_enqueue(cable, packets, count) in R246 (found by op1r: devupd/du_fw.c, seqdev/ms_fw.c TX_ENQ): queues
 * 4-byte USB-MIDI event packets {CIN, status, d1, d2} for the host; masks interrupts itself, does nothing while
 * USB is not up */
#define CO_USBMIDI_TX ((void (*)(int, const void *, unsigned))0x019E0D18)

enum { PG_PLAY = 0, PG_CHORD, PG_BASS, PG_MIDI, PG_N };

/* ------------------------------------------------------------------------------- state --- */
co_state_t co_s;                                /* settings (Seq thread writes; bench, GUI read) */
co_play_t co_p;                                 /* the model + player (Seq thread) */
#define co_cfg co_s.cfg
#define co_opt co_s.opt
#define co_ch co_s.ch
#define co_local co_s.local
#define co_sel co_s.sel
#define co_on co_s.on
volatile uint8_t co_pinned;                     /* KeyHandler: the panel */
volatile uint8_t co_page;
volatile uint8_t co_remote;                     /* a host has spoken on channel 16: the feedback flows */
static volatile uint32_t now;                   /* samples (co_tick) */
static volatile uint32_t panel_until;
static volatile uint8_t panel;
static uint32_t eaten;                          /* KeyHandler: note keys (bit = index) whose down CoralOP took */
static uint16_t eaten_fn;                       /* insert, T1..T4 likewise (bit = key id) */
static volatile uint8_t inited;
static uint8_t local_n[128];                    /* Seq: local voices per note (CHORD and BASS may share one) */
static uint32_t down_src[2];                    /* Seq: keys down (bit k, HOLD = bit 25) from the OP-1 / the host */
static co_fb_t fb;
static volatile char name[16];                  /* the last chord's name (the badge, the panel, the feedback) */

static const uint8_t note_ids[CO_NKEYS] = TE_NOTE_KEY_IDS;

/* ------------------------------------------------------------------------------ queues --- */
enum { EV_KEY = 1, EV_KNOB, EV_OFF, EV_CC };   /* KEY: a = key (0..23, CO_KEY_HOLD), b = down; KNOB: a = cc, b = dir;
                                                 * CC: a = cc, b = value (the host's) */
typedef struct { uint8_t type, a; int8_t b, src; } co_ev;
#define QN 64
typedef struct { co_ev ev[QN]; volatile uint8_t head, tail; } co_q;
static co_q kq, mq;                             /* KeyHandler -> Seq, MIDI -> Seq (one producer, one consumer) */

static void push(co_q *q, int type, int a, int b)
{
    uint8_t h = q->head, n = (uint8_t)((h + 1) % QN);
    if (n == q->tail)
        return;                                 /* (full: 64 events in 1.5 ms, never) */
    q->ev[h].type = (uint8_t)type;
    q->ev[h].a = (uint8_t)a;
    q->ev[h].b = (int8_t)b;
    q->ev[h].src = q == &mq;
    __asm__ volatile("" ::: "memory");
    q->head = n;
}

static int panel_shown(void)
{
    return panel && (co_pinned || (int32_t)(now - panel_until) < 0);
}

/* ------------------------------------------------------------------- output (Seq thread) --- */
static void midi(int status, int ch, int d1, int d2)
{
    uint32_t pk;
    if (ch > 15)
        return;
    pk = (uint32_t)(status >> 4) | (uint32_t)(status | ch) << 8 | (uint32_t)(d1 & 127) << 16 |
         (uint32_t)(d2 & 127) << 24;
    CO_USBMIDI_TX(0, &pk, 1);
}

static void voice(int note, int on, int vel)
{
    te_note m;
    m.note = note;
    m.vel = vel;
    m.midi_out = 0;                             /* (TE would echo it on the OP-1's own channel: CoralOP sends) */
    m.pad[0] = m.pad[1] = m.pad[2] = 0;
    m.extra = 0;
    if (on)
        TE_VOICE_NOTE_ON(&m, 0);
    else
        TE_VOICE_NOTE_OFF(&m);
}

static void out(void *ctx, int part, int note, int on, int vel)
{
    (void)ctx;
    if (co_local) {
        if (on) {
            if (local_n[note]++ == 0)
                voice(note, 1, vel);
        } else if (local_n[note] && --local_n[note] == 0) {
            voice(note, 0, vel);
        }
    }
    midi(on ? 0x90 : 0x80, co_ch[part & 1], note, on ? vel : 0);
}

static void all_off(void)
{
    int i;
    co_silence(&co_p);
    for (i = 0; i < 128; i++)                   /* (nothing left, unless TE missed one) */
        if (local_n[i]) {
            local_n[i] = 0;
            voice(i, 0, 0);
        }
    midi(0xB0, co_ch[0], 123, 0);               /* all notes off */
    if (co_ch[1] != co_ch[0])
        midi(0xB0, co_ch[1], 123, 0);
}

static void update_name(void)
{
    const cf_chord_out_t *o = &co_p.c.out;
    cf_spell_t sp;
    char b[16];
    int i;
    if (!o->sounding)
        return;                                 /* (the last chord stays on the badge) */
    cf_key_spell(co_cfg.tonic, co_cfg.scale, &sp);
    if (o->single) {
        cf_pc_name(o->root_pc, &sp, b);
    } else {
        int bass = co_opt.bass_on && o->bass_pc >= 0 && o->bass_pc != o->root_pc ? o->bass_pc : -1;
        cf_chord_name(o->root_pc, o->mask, bass, &sp, b);
    }
    for (i = 0; i < 15 && b[i]; i++)
        name[i] = b[i];
    name[i] = 0;
}

/* ------------------------------------------------------------------------ the Seq thread --- */
static void apply(void)
{
    co_config(&co_p, &co_cfg, &co_opt);
    update_name();
}

/* TE's octave for the current synth sound (its arrows stay TE's) is CoralFlower's OCT */
static void follow_octave(void)
{
    int o = TE_SYNTH_OCTAVE[*TE_SYNTH_SLOT & 7];
    o = o < -3 ? -3 : o > 3 ? 3 : o;
    if (o != co_cfg.octave) {
        co_cfg.octave = (int8_t)o;
        apply();
    }
}

static void release_all(void)
{
    all_off();
    co_reset(&co_p);
    down_src[0] = down_src[1] = 0;
}

/* a key from the OP-1 (src 0) or the host (src 1): the model hears it when the first goes down / the last up */
static void key_ev(int k, int down, int src)
{
    uint32_t bit = 1u << k, was = (down_src[0] | down_src[1]) & bit, is;
    if (down)
        down_src[src] |= bit;
    else
        down_src[src] &= ~bit;
    is = (down_src[0] | down_src[1]) & bit;
    if (was == is)
        return;
    if (is) {
        int role, b;
        follow_octave();
        role = cf_key_role(co_cfg.algo, k, &b);
        if (role == CF_ROLE_BUTTON && !(!co_is_side(&co_s) && cf_is_off(&co_cfg, b)))
            co_sel = (uint8_t)b;                /* (the CHORD page edits the button pressed last) */
    }
    if (co_key(&co_p, k, is != 0, MS(now)))
        update_name();
}

static void set_param(int cc, int raw)
{
    int kind = co_param_kind(cc), algo = co_cfg.algo;
    if (kind == CO_K_ROUTE)
        all_off();                              /* (a change of where notes go: what sounds stops first) */
    if (kind == CO_K_POWER) {
        if (!raw) {
            release_all();
            co_on = 0;
            panel = 0;
            co_pinned = 0;
        }
        co_on = (uint8_t)(raw != 0);
        return;
    }
    if (co_param_set(&co_s, cc, raw) < 0)
        return;
    if (co_cfg.algo != algo)
        down_src[0] = down_src[1] = 0;          /* (a new layout drops the keys in the model) */
    if (kind == CO_K_APPLY || kind == CO_K_ROUTE)
        apply();
}

static void event(const co_ev *e)
{
    switch (e->type) {
    case EV_KEY:
        if (co_on || !e->b)
            key_ev(e->a, e->b, e->src);
        break;
    case EV_KNOB: {
        int v = co_param_knob(&co_s, e->a, e->b);
        if (v >= 0)
            set_param(e->a, v);
        break;
    }
    case EV_OFF:                                /* (the KeyHandler has turned it off already) */
        release_all();
        co_on = 0;
        break;
    case EV_CC:
        if (e->a == CO_CC_PANIC)
            release_all();
        else if (e->a == CO_CC_DUMP)
            co_fb_invalidate(&fb);
        else if (co_param_kind(e->a) >= 0)
            set_param(e->a, co_wire_in(e->a, (uint8_t)e->b));
        break;
    }
}

static void drain(co_q *q)
{
    while (q->tail != q->head) {
        co_ev e = q->ev[q->tail];
        __asm__ volatile("" ::: "memory");
        q->tail = (uint8_t)((q->tail + 1) % QN);
        event(&e);
    }
}

void co_tick(void)
{
    uint8_t pairs[48][2];
    int i, n;
    now += TE_AUDIO_FRAMES;
    if (!inited) {
        co_state_defaults(&co_s);
        co_init(&co_p, &co_cfg, &co_opt, out, 0);
        co_fb_invalidate(&fb);
        inited = 1;
    }
    drain(&kq);
    drain(&mq);
    if (!co_remote && !co_on)
        return;                                 /* (no one to tell: stock behaviour, nothing on the wire) */
    n = co_fb_collect(&fb, &co_s, &co_p, (const char *)name, pairs, 48);
    for (i = 0; i < n; i++)
        midi(0xB0, CO_CTRL_CH, pairs[i][0], pairs[i][1]);
}

/* ------------------------------------------------------------------ the MIDI side (queue) --- */
int co_midi(const te_bytes *msg)
{
    const uint8_t *m = msg->begin;
    int st, d1, d2;
    if (te_bytes_size(msg) < 3 || (m[0] & 15) != CO_CTRL_CH)
        return 0;
    st = m[0] & 0xF0;
    d1 = m[1] & 127;
    d2 = m[2] & 127;
    if (st == 0xB0 && (d1 == CO_CC_ENABLE || d1 == CO_CC_DUMP)) {
        co_remote = 1;
        push(&mq, EV_CC, d1, d2);
        return 1;
    }
    if (!co_on)
        return 0;                               /* (off: channel 16 is TE's, but for those two) */
    co_remote = 1;
    if (st == 0xB0) {
        push(&mq, EV_CC, d1, d2);
    } else if (st == 0x90 || st == 0x80) {
        int k = d1 - CO_NOTE_KEY0;
        if (k == CO_KEY_HOLD || (k >= 0 && k < CO_NKEYS))
            push(&mq, EV_KEY, k, st == 0x90 && d2 > 0);
    }
    return 1;                                   /* (the rest of channel 16 too: it is CoralOP's) */
}

/* ------------------------------------------------------------------- the KeyHandler thread --- */
static void show(void)
{
    panel = 1;
    panel_until = now + PANEL_TIME;
}

static int note_index(int key)
{
    int i;
    for (i = 0; i < CO_NKEYS; i++)
        if (note_ids[i] == key)
            return i;
    return -1;
}

int co_on_key(int key, int down)
{
    int idx = note_index(key), fn = key == TE_KEY_INSERT || (key >= TE_KEY_T1 && key <= TE_KEY_T4);

    /* an up whose down CoralOP took is CoralOP's, whatever happened since (off, another playmode) */
    if (!down) {
        if (idx >= 0 && (eaten >> idx & 1)) {
            eaten &= ~(1u << idx);
            push(&kq, EV_KEY, idx, 0);
            return 1;
        }
        if (fn && (eaten_fn >> key & 1)) {
            eaten_fn &= (uint16_t)~(1u << key);
            if (key == TE_KEY_T4)
                push(&kq, EV_KEY, CO_KEY_HOLD, 0);
            return 1;
        }
        return 0;
    }
    if (!*TE_KEYS_ENABLED || !inited)
        return 0;                               /* (TE drops it: so does CoralOP) */

    if (key == TE_KEY_INSERT) {                 /* as CHORD+: shift + insert on / panel / off; insert pins */
        if (*TE_SHIFT_HELD) {
            if (!co_on) {
                co_on = 1;
                co_page = PG_PLAY;
                show();
            } else if (!panel_shown()) {
                show();
            } else {
                co_on = 0;                      /* (keys from now on are TE's; the Seq thread lets go) */
                panel = 0;
                co_pinned = 0;
                push(&kq, EV_OFF, 0, 0);
            }
        } else {
            if (!co_on || !panel_shown())
                return 0;
            co_pinned = !co_pinned;
            if (!co_pinned)
                panel = 0;
        }
        eaten_fn |= (uint16_t)(1u << key);
        return 1;
    }
    if (!co_on || *TE_PLAYMODE != 0 || *TE_EDIT_MODE == TE_EDIT_MODE_SEQ)
        return 0;                               /* (drum playmode, the sequencer's screen: TE's) */

    if (idx >= 0) {
        eaten |= 1u << idx;
        push(&kq, EV_KEY, idx, 1);
        return 1;
    }
    if (key == TE_KEY_T4) {                     /* HOLD (Top layouts; Side has none) */
        push(&kq, EV_KEY, CO_KEY_HOLD, 1);
        eaten_fn |= (uint16_t)(1u << key);
        return 1;
    }
    if (key >= TE_KEY_T1 && key <= TE_KEY_T3) {
        int pg = key == TE_KEY_T1 ? PG_PLAY : key == TE_KEY_T2 ? PG_CHORD : PG_BASS;
        if (pg == PG_BASS && panel_shown() && (co_page == PG_BASS || co_page == PG_MIDI))
            pg = co_page == PG_BASS ? PG_MIDI : PG_BASS;    /* T3 again: the other of the two */
        co_page = (uint8_t)pg;
        show();
        eaten_fn |= (uint16_t)(1u << key);
        return 1;
    }
    return 0;
}

int co_on_knob(int knob, int16_t *diff)
{
    int d = *diff;
    if ((unsigned)knob > 3 || !co_on || !panel_shown() || !d)
        return 0;
    push(&kq, EV_KNOB, co_knob_cc[co_page & 3][knob], d > 0 ? 1 : -1);
    panel_until = now + PANEL_TIME;
    return 1;
}

/* the GUI's names for the shared ones */
static int is_side(void) { return co_is_side(&co_s); }
static cf_form_t *sel_form(void) { return co_sel_form(&co_s); }

/* ---------------------------------------------------------------------------- GUI thread --- */
/* gfx_text's 3x5 font has upper case only: CoralFlower's names need m (minor) apart from M (major), b (flat) apart
 * from B, the Roman numerals' case, the diminished ring and the raised digits of its key labels */
static const struct { char c; uint8_t row[5]; } GLYPH[] = {
    {'a', {0, 0, 3, 5, 3}}, {'b', {4, 4, 6, 5, 6}}, {'d', {1, 1, 3, 5, 3}}, {'g', {3, 5, 3, 1, 6}},
    {'i', {2, 0, 2, 2, 2}}, {'j', {1, 0, 1, 1, 6}}, {'m', {0, 0, 7, 7, 5}}, {'s', {0, 0, 3, 2, 6}},
    {'u', {0, 0, 5, 5, 3}}, {'v', {0, 0, 5, 5, 2}}, {'(', {2, 4, 4, 4, 2}}, {')', {2, 1, 1, 1, 2}},
    {(char)0xB0, {2, 5, 2, 0, 0}}, {(char)0xF8, {0, 1, 7, 5, 4}},
};

static int text(int x, int y, const char *s, uint16_t c, int sc)
{
    char one[2] = {0, 0};
    for (; *s; s++) {
        unsigned char ch = (unsigned char)*s;
        unsigned g;
        for (g = 0; g < sizeof GLYPH / sizeof GLYPH[0] && (unsigned char)GLYPH[g].c != ch; g++)
            ;
        if (g < sizeof GLYPH / sizeof GLYPH[0]) {
            int r, k;
            for (r = 0; r < 5; r++)
                for (k = 0; k < 3; k++)
                    if (GLYPH[g].row[r] >> (2 - k) & 1)
                        gfx_rect(x + k * sc, y + r * sc, sc, sc, c);
            x += 4 * sc;
        } else if (ch >= 0x10 && ch <= 0x19) {  /* a raised digit: an added degree on a key label */
            one[0] = (char)('0' + ch - 0x10);
            x = gfx_text(x, y - (sc > 1 ? sc : 1), one, c, sc);
        } else {
            one[0] = (char)ch;
            x = gfx_text(x, y, one, c, sc);
        }
    }
    return x;
}
static int text_w(const char *s, int sc)
{
    int n = 0;
    while (s[n])
        n++;
    return n * 4 * sc - sc;
}

#define C_BLUE   GFX_RGB(0x69, 0x8e, 0xff)
#define C_GREEN  GFX_RGB(0x00, 0xed, 0x95)
#define C_WHITE  GFX_RGB(0xe6, 0xe6, 0xe6)
#define C_ORANGE GFX_RGB(0xff, 0x6a, 0x3d)
#define C_CORAL  GFX_RGB(0xff, 0x7f, 0x6a)
#define C_DIM    GFX_RGB(0x5a, 0x58, 0x66)
#define C_FRAME  GFX_RGB(0x35, 0x32, 0x38)
#define C_KEY    GFX_RGB(0x1c, 0x1a, 0x20)

static const char *const QUANT_NAME[3] = {"OFF", "BASIC", "FULL"};
static const char *const ALGO_NAME[CF_NALGS] = {"TOP", "TOP LOCK", "SIDE", "SIDE LOCK"};
static const char *const RT_NAME[CO_NRT] = {"WAIT", "NOTES", "CHORD"};
static const char *const PAGE_NAME[PG_N] = {"PLAY", "CHORD", "BASS", "MIDI"};

/* a knob's column; its value in capitals (CoralFlower's "Major", "Maj7"), unless its case means something (keep: a
 * note name's flat, "mPENT") */
static void value_k(int col, const char *label, const char *v, int keep)
{
    static const uint16_t kc[4] = {C_BLUE, C_GREEN, C_WHITE, C_ORANGE};
    char up[16];
    int x = 8 + col * 78, i;
    for (i = 0; i < 15 && v[i]; i++)
        up[i] = !keep && v[i] >= 'a' && v[i] <= 'z' ? (char)(v[i] - 32) : v[i];
    up[i] = 0;
    gfx_rect(x, 24, 70, 2, kc[col]);
    text(x, 29, label, kc[col], 1);
    text(x, 37, up, GFX_WHITE, 2);
}
static void value(int col, const char *label, const char *v) { value_k(col, label, v, 0); }
static void num(char *b, int v)                 /* 1..3 digits, with a sign when negative */
{
    int i = 0, d;
    if (v < 0) {
        b[i++] = '-';
        v = -v;
    }
    if (v >= 100) {
        d = v / 100;
        b[i++] = (char)('0' + d);
        v -= d * 100;
        b[i++] = (char)('0' + v / 10);
    } else if (v >= 10) {
        b[i++] = (char)('0' + v / 10);
    }
    b[i++] = (char)('0' + v % 10);
    b[i] = 0;
}

static void draw_values(void)
{
    char a[16], b[16], c[16];
    cf_spell_t sp;
    cf_key_spell(co_cfg.tonic, co_cfg.scale, &sp);
    switch (co_page) {
    case PG_PLAY:
        cf_pc_name(co_cfg.tonic, &sp, a);
        value(0, "QUANTIZE", QUANT_NAME[co_cfg.quantize % 3]);
        value_k(1, "KEY", a, 1);
        value_k(2, "SCALE", CF_SCALES[co_cfg.scale % CF_NSCALES].shrt, 1);
        value(3, "LAYOUT", ALGO_NAME[co_cfg.algo % CF_NALGS]);
        break;
    case PG_CHORD: {
        const cf_form_t *f = sel_form();
        if (!f) {
            text(8, 34, "PRESS A CHORD BUTTON TO EDIT IT", C_DIM, 1);
            break;
        }
        cf_form_label(f, a);
        value(0, "TYPE", cf_type_name(f->type));
        { int i = cf_adds_index(f->add); value(1, "ADD", i < 0 ? "OTHER" : cf_adds_name(i)); }
        if (f->inv == CF_INV_AUTO)
            value(2, "INVERSION", "AUTO");
        else {
            num(b, f->inv);
            value(2, "INVERSION", b);
        }
        if (f->bass == 0)
            value(3, "BASS DEG", "ROOT");
        else {
            num(c, f->bass + 1);
            value(3, "BASS DEG", c);
        }
        break;
    }
    case PG_BASS:
        num(b, co_opt.bass_oct);
        value(0, "BASS", co_opt.bass_on ? "ON" : "OFF");
        value(1, "OCTAVE", b);
        value(2, "OCTAVER", co_opt.octaver ? "ON" : "OFF");
        value(3, "RETRIG", RT_NAME[co_opt.retrig % CO_NRT]);
        break;
    default:
        if (co_ch[0] > 15) a[0] = 'O', a[1] = 'F', a[2] = 'F', a[3] = 0; else num(a, co_ch[0] + 1);
        if (co_ch[1] > 15) b[0] = 'O', b[1] = 'F', b[2] = 'F', b[3] = 0; else num(b, co_ch[1] + 1);
        num(c, co_opt.vel);
        value(0, "CHORD CH", a);
        value(1, "BASS CH", b);
        value(2, "LOCAL", co_local ? "ON" : "OFF");
        value(3, "VELOCITY", c);
    }
}

/* the keyboard: 14 white keys (roots in Top), 10 black ones (the chord buttons), each with its label */
static void draw_keys(void)
{
    const cf_chord_out_t *o = &co_p.c.out;
    cf_spell_t sp;
    int k, w = 0, i, x0 = 6, kw = 22, yb = 92, yw = 116;
    uint32_t roots = 0;
    cf_key_spell(co_cfg.tonic, co_cfg.scale, &sp);
    for (i = 0; i < co_p.c.nroots; i++)
        if (co_p.c.root_key[i] < CO_NKEYS)
            roots |= 1u << co_p.c.root_key[i];
    for (k = 0; k < CO_NKEYS; k++) {            /* white keys first, the black ones over them */
        int up = cf_key_is_upper(k);
        if (!up) {
            int x = x0 + w * kw;
            w++;
            gfx_rect(x, yw, kw - 2, 38, C_KEY);
            (void)x;
        }
    }
    for (w = 0, k = 0; k < CO_NKEYS; k++) {
        int up = cf_key_is_upper(k), idx, role = cf_key_role(co_cfg.algo, k, &idx);
        char l[8];
        uint16_t fill = C_KEY, col = C_WHITE;
        int x, y, bw;
        if (role == CF_ROLE_BUTTON) {
            const cf_form_t *f = cf_button_form(&co_cfg, idx);
            cf_form_label(f, l);
            if (o->buttons >> idx & 1)
                fill = C_CORAL, col = GFX_BLACK;
            else if (co_page == PG_CHORD && idx == co_sel)
                col = C_CORAL;
        } else {
            int n = cf_key_root_note(&co_cfg, k);
            if (n < 0)
                l[0] = 0;
            else if (co_cfg.quantize != CF_Q_OFF)
                cf_numeral(co_cfg.scale, co_cfg.tonic, n % 12, l);
            else
                cf_pc_name(n % 12, &sp, l);
            if (roots >> k & 1)
                fill = C_GREEN, col = GFX_BLACK;
        }
        if (up) {
            x = x0 + w * kw - 10;
            y = yb;
            bw = 20;
            gfx_rect(x - 1, y - 1, bw + 2, 24, GFX_BLACK);
            gfx_rect(x, y, bw, 22, fill == C_KEY ? C_FRAME : fill);
            text(x + (bw - text_w(l, 1)) / 2, y + 9, l, col, 1);
        } else {
            x = x0 + w * kw;
            w++;
            y = yw;
            bw = kw - 2;
            if (fill != C_KEY)
                gfx_rect(x, y, bw, 38, fill);
            text(x + (bw - text_w(l, 1)) / 2, y + 28, l, col, 1);
        }
    }
}

void co_frame(uint16_t *buf)
{
    char nm[16];
    int i, x;
    if (!co_on)
        return;
    for (i = 0; i < 15 && name[i]; i++)
        nm[i] = name[i];
    nm[i] = 0;
    gfx_begin(buf);
    if (!panel_shown()) {                       /* the badge: between TE's page titles and its top-right marks */
        gfx_rect(196, 0, 76, 9, GFX_BLACK);
        x = text(198, 2, "CF", C_CORAL, 1);
        if (co_p.c.out.hold)
            x = text(x + 3, 2, "HOLD", C_GREEN, 1);
        text(x + 4, 2, nm, GFX_WHITE, 1);
        return;
    }
    gfx_rect(0, 0, gfx_w ? gfx_w : 320, gfx_h ? gfx_h : 156, C_FRAME);
    gfx_rect(2, 2, (gfx_w ? gfx_w : 320) - 4, (gfx_h ? gfx_h : 156) - 4, GFX_BLACK);
    x = text(8, 6, "CORALFLOWER", C_CORAL, 2);
    for (i = 0; i < PG_N; i++) {                /* T1 PLAY  T2 CHORD  T3 BASS/MIDI  T4 HOLD */
        static const char *const tk[PG_N] = {"T1", "T2", "T3", "T3"};
        if (i == PG_MIDI && co_page != PG_MIDI)
            continue;
        if (i == PG_BASS && co_page == PG_MIDI)
            continue;
        x = text(x + 8, 9, tk[i], C_DIM, 1);
        x = text(x + 3, 9, PAGE_NAME[i], co_page == i ? GFX_WHITE : C_DIM, 1);
    }
    if (!is_side()) {
        x = text(x + 8, 9, "T4", C_DIM, 1);
        text(x + 3, 9, "HOLD", co_p.c.out.hold ? C_GREEN : C_DIM, 1);
    }
    if (co_pinned)
        text(290, 9, "PIN", C_ORANGE, 1);
    draw_values();
    /* the chord: its name, and where it sits in the key */
    x = text(8, 58, nm[0] ? nm : "-", co_p.c.out.sounding ? GFX_WHITE : C_DIM, 3);
    if (co_p.c.out.sounding && !co_p.c.out.single && co_cfg.quantize != CF_Q_OFF) {
        char rn[8];
        cf_numeral(co_cfg.scale, co_cfg.tonic, co_p.c.out.root_pc, rn);
        text(x + 10, 64, rn, C_DIM, 2);
    }
    {
        char k[8];
        cf_spell_t sp;
        cf_key_spell(co_cfg.tonic, co_cfg.scale, &sp);
        cf_pc_name(co_cfg.tonic, &sp, k);
        x = text(220, 60, k, C_DIM, 1);
        text(x + 4, 60, CF_SCALES[co_cfg.scale % CF_NSCALES].shrt, C_DIM, 1);
        text(220, 70, ALGO_NAME[co_cfg.algo % CF_NALGS], C_DIM, 1);
    }
    draw_keys();
}
