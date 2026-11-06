/* SPDX-License-Identifier: GPL-3.0-only
 * CoralOP bench in the bf524 simulator: the driver plays TE's KeyHandler, Seq and GUI threads through the generated
 * hooks and logs what TE's voice code and its USB-MIDI queue would get. Returns a bitmask of failed checks. */
#include <op1/te246.h>
#include "../co_remote.h"

extern void hook_tick(void);
extern void hook_key(int key, int down);
extern void hook_frame(uint16_t *buf);
extern void hook_knob(int knob, int16_t *diff);
extern int hook_midi(const te_bytes *msg);
extern co_state_t co_s;
extern co_play_t co_p;
extern volatile uint8_t co_pinned, co_page;
#define co_on co_s.on
#define co_local co_s.local
extern char FB[], FB2[];

#define MAXLOG 2048
struct ev { uint8_t kind, ch, note, vel; };     /* kind: 1 voice on, 2 voice off, 9 MIDI on, 8 MIDI off, 11 CC */
static struct ev log[MAXLOG];
static int nlog, keys_seen, knobs_seen, midi_seen, fails, bad_packets;
static const uint8_t ids[24] = TE_NOTE_KEY_IDS;

static void put(int kind, int ch, int note, int vel)
{
    if (nlog < MAXLOG)
        log[nlog++] = (struct ev){(uint8_t)kind, (uint8_t)ch, (uint8_t)note, (uint8_t)vel};
}
void log_on(te_note *n, int extra) { (void)extra; put(1, 0, n->note, n->vel); if (n->midi_out) bad_packets++; }
void log_off(te_note *n) { put(2, 0, n->note, 0); }
void log_key(int key, int down) { (void)key; (void)down; keys_seen++; }
void log_knob(int knob, int16_t *diff) { (void)knob; (void)diff; knobs_seen++; }
void log_midiin(const te_bytes *m) { (void)m; midi_seen++; }
void log_midi(int cable, const uint32_t *pk, unsigned n)
{
    unsigned i;
    for (i = 0; i < n; i++) {
        uint32_t p = pk[i];
        int cin = p & 15, st = (p >> 8) & 0xF0, ch = (p >> 8) & 15, d1 = (p >> 16) & 0xFF, d2 = (p >> 24) & 0xFF;
        if (cable != 0 || cin != st >> 4 || d1 > 127 || d2 > 127)
            bad_packets++;
        put(st >> 4, ch, d1, d2);
    }
}

static void tick(int n) { while (n-- > 0) hook_tick(); }
static void key(int id, int down) { hook_key(id, down); tick(40); }    /* (~58 ms between events) */
static void note(int idx, int down) { key(ids[idx], down); }
static void press(int id, int shift)
{
    *TE_SHIFT_HELD = (uint8_t)shift;
    key(id, 1);
    key(id, 0);
    *TE_SHIFT_HELD = 0;
}
static void turn(int knob, int steps)
{
    int16_t d = steps > 0 ? 1024 : -1024;
    int i;
    for (i = 0; i < (steps > 0 ? steps : -steps); i++) {
        int16_t x = d;
        hook_knob(knob, &x);
        tick(2);
    }
}

#define CHECK(bit, c) do { if (!(c)) fails |= 1 << (bit); } while (0)

/* what has been logged since from: kind on channel, as a 12-bit mask of pitch classes and a count */
static int pcs(int from, int kind, int ch, int *count)
{
    int i, m = 0, c = 0;
    for (i = from; i < nlog; i++)
        if (log[i].kind == kind && (kind < 8 || log[i].ch == ch)) {
            m |= 1 << (log[i].note % 12);
            c++;
        }
    if (count)
        *count = c;
    return m;
}
static int lowest(int from, int kind, int ch)
{
    int i, l = 999;
    for (i = from; i < nlog; i++)
        if (log[i].kind == kind && log[i].ch == ch && log[i].note < l)
            l = log[i].note;
    return l;
}
/* note events (voices, MIDI notes) logged since from */
static int notes_since(int from)
{
    int i, c = 0;
    for (i = from; i < nlog; i++)
        if (log[i].kind != 11)
            c++;
    return c;
}
/* the last value sent on CC cc on channel 16 since from, -1: none */
static int fb_cc(int from, int cc)
{
    int i, v = -1;
    for (i = from; i < nlog; i++)
        if (log[i].kind == 11 && log[i].ch == CO_CTRL_CH && log[i].note == cc)
            v = log[i].vel;
    return v;
}
static int last_vel(void)
{
    int i;
    for (i = nlog - 1; i >= 0; i--)
        if (log[i].kind == 9)
            return log[i].vel;
    return -1;
}
/* a 3-byte message from the host through the midi_in hook; returns what the hook said (1: CoralOP took it) */
static int host(int st, int d1, int d2)
{
    static uint8_t buf[3];
    static te_bytes b;
    int r;
    buf[0] = (uint8_t)st;
    buf[1] = (uint8_t)d1;
    buf[2] = (uint8_t)d2;
    b.reserved = 0;
    b.begin = buf;
    b.end = buf + 3;
    b.cap = buf + 3;
    r = midi_seen;
    hook_midi(&b);
    tick(4);
    return midi_seen == r;
}
/* every note-on has its note-off by now (per kind pair and channel) */
static int balanced(void)
{
    static int8_t on[3][128];
    int i, j, k;
    for (k = 0; k < 3; k++)
        for (j = 0; j < 128; j++)
            on[k][j] = 0;
    for (i = 0; i < nlog; i++) {
        struct ev *e = &log[i];
        int slot = e->kind <= 2 ? 0 : e->ch == 0 ? 1 : e->ch == 1 ? 2 : -1;
        if (slot < 0 || e->kind == 11)
            continue;
        on[slot][e->note] += e->kind == 1 || e->kind == 9 ? 1 : -1;
    }
    for (k = 0; k < 3; k++)
        for (j = 0; j < 128; j++)
            if (on[k][j])
                return 0;
    return 1;
}
#define PC(a) (1 << (a))
enum { C4 = 7, D4 = 9, G4 = 14, CS5 = 20, DS5 = 22, GS3 = 3 };

int main(void)
{
    int m, n, nb;

    *TE_PLAYMODE = 0;
    *TE_KEYS_ENABLED = 1;
    *TE_SYNTH_SLOT = 0;
    TE_SYNTH_OCTAVE[0] = 0;
    tick(4);

    /* 0: off = stock: a note key and T1 go to TE, nothing is sent */
    m = nlog;
    note(C4, 1);
    note(C4, 0);
    press(TE_KEY_T1, 0);
    CHECK(0, keys_seen == 4 && nlog == m && !co_on);   /* (no feedback either: no host yet) */

    /* 1: shift + insert turns CoralOP on, consumed; the panel shows the PLAY page */
    press(TE_KEY_INSERT, 1);
    CHECK(1, co_on && keys_seen == 4 && co_page == 0);

    /* 2: Top + Lock: tap M (C#5), then C4: C major on channel 1, the bass C under it on channel 2, the same notes
     * on the OP-1's voices (LOCAL), nothing reaches TE's own key handling */
    note(CS5, 1);
    note(CS5, 0);
    CHECK(2, notes_since(m) == 0);               /* a button alone sounds nothing */
    note(C4, 1);
    CHECK(2, pcs(m, 9, 0, &n) == (PC(0) | PC(4) | PC(7)) && n == 3);
    CHECK(2, pcs(m, 9, 1, &nb) == PC(0) && nb == 1 && lowest(m, 9, 1) < lowest(m, 9, 0));
    CHECK(2, pcs(m, 1, 0, &n) == (PC(0) | PC(4) | PC(7)) && n == 4);    /* chord + bass on the synth */
    CHECK(2, last_vel() == 100 && keys_seen == 4);
    note(C4, 0);
    CHECK(2, balanced());

    /* 3: chord buttons combine: M + M7 (G#3) held together latch Cmaj7 */
    note(CS5, 1);
    note(GS3, 1);
    note(GS3, 0);
    note(CS5, 0);
    m = nlog;
    note(C4, 1);
    CHECK(3, pcs(m, 9, 0, &n) == (PC(0) | PC(4) | PC(7) | PC(11)) && n == 4);
    note(C4, 0);

    /* 4: T4 = HOLD: the chord rings on after the key; HOLD again lets it go */
    press(TE_KEY_T4, 0);
    m = nlog;
    note(G4, 1);
    note(G4, 0);
    CHECK(4, pcs(m, 9, 0, &n) == (PC(7) | PC(11) | PC(2) | PC(6)) && n == 4);     /* Gmaj7 */
    CHECK(4, pcs(m, 8, 0, 0) == 0);              /* still sounding */
    press(TE_KEY_T4, 0);
    CHECK(4, pcs(m, 8, 0, &n) && n == 4 && balanced());

    /* 5: T3 BASS, then T3 again MIDI: the chord's channel to 3; LOCAL off: MIDI only */
    press(TE_KEY_T3, 0);
    CHECK(5, co_page == 2);
    press(TE_KEY_T3, 0);
    CHECK(5, co_page == 3);
    turn(0, 2);                                  /* CHORD CH 1 -> 3 */
    turn(2, 1);                                  /* LOCAL off */
    CHECK(5, !co_local && knobs_seen == 0);
    m = nlog;
    note(D4, 1);
    CHECK(5, pcs(m, 9, 2, &n) && n == 4 && pcs(m, 1, 0, 0) == 0);           /* Dmaj7 on channel 3, no voices */
    note(D4, 0);
    turn(0, -2);
    turn(2, 1);                                  /* back: channel 1, LOCAL on */

    /* 6: drum playmode, and the sequencer's screen: the keys (and T1..T4) are TE's again */
    *TE_PLAYMODE = 1;
    m = nlog;
    n = keys_seen;
    note(C4, 1);
    note(C4, 0);
    CHECK(6, keys_seen == n + 2 && notes_since(m) == 0);
    *TE_PLAYMODE = 0;
    *TE_EDIT_MODE = TE_EDIT_MODE_SEQ;
    note(C4, 1);
    note(C4, 0);
    press(TE_KEY_T2, 0);
    CHECK(6, keys_seen == n + 6 && notes_since(m) == 0 && co_page == 3);
    *TE_EDIT_MODE = 0;

    /* 7: off while a chord is held: everything stops (and all notes off goes out), the held key's release is
     * swallowed, then keys are TE's */
    note(C4, 1);
    press(TE_KEY_T1, 0);                         /* (panel showing) */
    press(TE_KEY_INSERT, 1);
    CHECK(7, !co_on && balanced());
    n = keys_seen;
    note(C4, 0);
    CHECK(7, keys_seen == n);
    note(C4, 1);
    note(C4, 0);
    CHECK(7, keys_seen == n + 2);
    CHECK(7, bad_packets == 0);

    /* 9: remote while off: channel 16 notes are TE's; CC 110 (dump) is CoralOP's and starts the feedback */
    m = nlog;
    CHECK(9, host(0x9F, 60, 100) == 0 && host(0x8F, 60, 0) == 0);
    CHECK(9, host(0xB0, 110, 0) == 0);           /* (another channel: TE's) */
    CHECK(9, host(0xBF, 110, 0) == 1);
    CHECK(9, fb_cc(m, 20) == 0 && fb_cc(m, 29) == 1 && fb_cc(m, 30) == 2 && fb_cc(m, 115) == 127);

    /* 10: CC 20 on; the host's notes are the OP-1's keys: M (note 73 = C#5), then C4 (note 60): C major on ch 1,
     * its name and root sent back */
    m = nlog;
    CHECK(10, host(0xBF, 20, 127) == 1 && co_on && fb_cc(m, 20) == 127);
    m = nlog;
    host(0x9F, 73, 100);
    host(0x8F, 73, 0);
    CHECK(10, fb_cc(m, 113) == 2 && fb_cc(m, 104) == 8);     /* M = button 8 = bit 1 of CC 113, selected */
    m = nlog;
    CHECK(10, host(0x9F, 60, 100) == 1);
    CHECK(10, pcs(m, 9, 0, &n) == (PC(0) | PC(4) | PC(7)) && n == 3);
    CHECK(10, fb_cc(m, 115) == 0 && fb_cc(m, 116) == 127 && fb_cc(m, 117) == 1 && fb_cc(m, 118) == 'C');
    host(0x9F, 60, 0);                           /* (a note-on at velocity 0 is an off) */
    CHECK(10, balanced());

    /* 11: the OP-1's key and the host's held together: the chord lasts until both are up */
    m = nlog;
    note(C4, 1);
    host(0x9F, 60, 100);
    note(C4, 0);
    CHECK(11, pcs(m, 9, 0, &n) && n == 3 && pcs(m, 8, 0, 0) == 0);
    host(0x8F, 60, 0);
    CHECK(11, balanced());

    /* 12: settings from the host, echoed back; a knob on the OP-1 is echoed too */
    m = nlog;
    host(0xBF, 22, 2);                           /* KEY D */
    host(0xBF, 23, 4);                           /* SCALE Dorian */
    host(0xBF, 27, 63);                          /* BASS OCT -1 */
    CHECK(12, co_s.cfg.tonic == 2 && co_s.cfg.scale == 4 && co_s.opt.bass_oct == -1);
    CHECK(12, fb_cc(m, 22) == 2 && fb_cc(m, 23) == 4 && fb_cc(m, 27) == 63);
    press(TE_KEY_T1, 0);                         /* (the panel) */
    m = nlog;
    turn(1, 1);                                  /* KEY on the OP-1: D -> D# */
    CHECK(12, fb_cc(m, 22) == 3);
    host(0xBF, 22, 0);
    host(0xBF, 23, 0);
    host(0xBF, 27, 64);
    m = nlog;
    host(0xBF, 29, 3);                           /* CHORD CH 3 */
    host(0x9F, 60, 100);
    CHECK(12, pcs(m, 9, 2, &n) && n == 3);
    host(0x8F, 60, 0);
    host(0xBF, 29, 1);
    CHECK(12, balanced());

    /* 13: HOLD from the host (note 78), then panic (CC 109): everything stops, HOLD cleared */
    host(0x9F, 78, 100);
    host(0x8F, 78, 0);
    host(0x9F, 62, 100);                         /* D4 */
    host(0x8F, 62, 0);
    CHECK(13, co_p.c.out.hold && !balanced());
    host(0xBF, 109, 0);
    CHECK(13, !co_p.c.out.hold && balanced());

    /* 14: CC 20 off: channel 16 notes are TE's again */
    host(0xBF, 20, 0);
    CHECK(14, !co_on && host(0x9F, 60, 100) == 0 && host(0x8F, 60, 0) == 0);
    CHECK(14, balanced());

    /* 8: screenshots: PLAY page (D dorian, Quantize Full) over FB2; CHORD page pinned with Cmaj7 held over FB */
    press(TE_KEY_INSERT, 1);                     /* on again: PLAY page */
    turn(0, 1);                                  /* QUANTIZE Full */
    turn(1, 2);                                  /* KEY D */
    turn(2, 4);                                  /* SCALE Dorian */
    note(C4, 1);
    hook_frame((uint16_t *)FB2);
    note(C4, 0);
    turn(1, -2);
    turn(2, -4);
    turn(0, -1);
    press(TE_KEY_T2, 0);
    press(TE_KEY_INSERT, 0);                     /* pin */
    CHECK(8, co_pinned && co_page == 1);
    note(GS3, 1);
    note(CS5, 1);
    note(C4, 1);
    tick(44100 * 6 / 64);                        /* past the 5 s: pinned, it stays */
    hook_frame((uint16_t *)FB);
    return fails | (bad_packets ? 1 << 15 : 0);
}
