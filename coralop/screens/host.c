/* SPDX-License-Identifier: GPL-3.0-only
 * CoralOP's screen on a PC: coralop.c compiled for the host, TE's addresses replaced by variables here, played
 * through the same entry points the OP-1 calls (co_on_key, co_on_knob, co_tick, co_frame), with gfx_* recording
 * what the frame draws instead of writing pixels:
 *     R x y w h rgb565            a rectangle
 *     T x y scale rgb565 hex      a string (text() in coralop.c, whole: render.py sets it in a smooth font)
 * in the OP-1's 320 x 156 UI coordinates. render.py turns that into PNGs. Usage: host <scene>  (scenes below) */
#include <stdio.h>
#include <string.h>
#include <op1/te246.h>
#include <op1/gfx.h>

static uint8_t h_shift, h_keys_on = 1;
static int32_t h_playmode, h_edit, h_slot, h_octave[8];
#undef TE_SHIFT_HELD
#define TE_SHIFT_HELD (&h_shift)
#undef TE_KEYS_ENABLED
#define TE_KEYS_ENABLED (&h_keys_on)
#undef TE_PLAYMODE
#define TE_PLAYMODE (&h_playmode)
#undef TE_EDIT_MODE
#define TE_EDIT_MODE (&h_edit)
#undef TE_SYNTH_SLOT
#define TE_SYNTH_SLOT (&h_slot)
#undef TE_SYNTH_OCTAVE
#define TE_SYNTH_OCTAVE h_octave
static void h_voice_on(te_note *n, int extra) { (void)n; (void)extra; }
static void h_voice_off(te_note *n) { (void)n; }
#undef TE_VOICE_NOTE_ON
#define TE_VOICE_NOTE_ON h_voice_on
#undef TE_VOICE_NOTE_OFF
#define TE_VOICE_NOTE_OFF h_voice_off
static void h_usbmidi(int cable, const void *pk, unsigned n) { (void)cable; (void)pk; (void)n; }
#define CO_USBMIDI_TX h_usbmidi

static void put_text(int x, int y, const char *s, uint16_t c, int sc)
{
    printf("T %d %d %d %u ", x, y, sc, c);
    for (; *s; s++)
        printf("%02x", (unsigned char)*s);
    printf("\n");
}
static int h_text(int x, int y, const char *s, uint16_t c, int sc)
{
    int n = (int)strlen(s);
    put_text(x, y, s, c, sc);
    return x + n * 4 * sc;                       /* (the OP-1 font's advance: the layout stays the device's) */
}
#define CO_HOST_TEXT h_text

#include "../coralop.c"

int gfx_w = 320, gfx_h = 156;
void gfx_begin(uint16_t *buf) { (void)buf; }
void gfx_rect(int x, int y, int w, int h, uint16_t c) { printf("R %d %d %d %d %u\n", x, y, w, h, c); }
int gfx_text(int x, int y, const char *s, uint16_t c, int scale) { return h_text(x, y, s, c, scale); }

/* --------------------------------------------------------------------------------- playing --- */
static const uint8_t ids[CO_NKEYS] = TE_NOTE_KEY_IDS;
enum { F3, FS3, G3, GS3, A3, AS3, B3, C4, CS4, D4, DS4, E4, F4, FS4, G4, GS4, A4, AS4, B4, C5, CS5, D5, DS5, E5 };

static void tick(int n) { while (n-- > 0) co_tick(); }
static void key(int id, int down) { co_on_key(id, down); tick(40); }
static void note(int k, int down) { key(ids[k], down); }
static void tap(int k) { note(k, 1); note(k, 0); }
static void press(int id, int shift)
{
    h_shift = (uint8_t)shift;
    key(id, 1);
    key(id, 0);
    h_shift = 0;
}
static void turn(int knob, int steps)
{
    int i;
    for (i = 0; i < (steps > 0 ? steps : -steps); i++) {
        int16_t d = steps > 0 ? 1024 : -1024;
        co_on_knob(knob, &d);
        tick(2);
    }
}
static void on_pinned(void)
{
    tick(1);
    press(TE_KEY_INSERT, 1);                     /* shift + insert (the key printed "drop"): on, the panel */
    press(TE_KEY_INSERT, 0);                     /* insert while it shows: pinned */
}

int main(int argc, char **argv)
{
    const char *s = argc > 1 ? argv[1] : "";
    uint16_t fb[1];
    on_pinned();
    if (!strcmp(s, "play")) {                    /* Top + Lock, Quantize Basic, C major: M latched, the I chord */
        tap(CS5);
        note(C4, 1);
    } else if (!strcmp(s, "play_dorian")) {      /* D dorian, Quantize Full: degrees follow the key */
        turn(0, 1);
        turn(1, 2);
        turn(2, 4);
        tap(DS5);
        note(C4, 1);                             /* (the tonic is always on C: Dm, i) */
    } else if (!strcmp(s, "chord")) {            /* M7 latched (the button being edited): Cmaj7 */
        press(TE_KEY_T2, 0);
        tap(GS3);
        note(C4, 1);
    } else if (!strcmp(s, "side")) {             /* Side, Quantize Off: hold m + 7, play A: Am7 (the Orchid's way) */
        turn(3, 3);                              /* LAYOUT: Top Lock, Top, Side Lock, Side */
        turn(0, -1);                             /* QUANTIZE: Basic -> Off */
        note(GS3, 1);
        note(A3, 1);
        note(A4, 1);
    } else if (!strcmp(s, "bass")) {             /* the BASS page, HOLD on T4: a held Am */
        press(TE_KEY_T3, 0);
        tap(DS5);
        press(TE_KEY_T4, 0);
        note(A3, 1);
        note(A3, 0);
    } else if (!strcmp(s, "midi")) {             /* T3 twice: the MIDI page */
        press(TE_KEY_T3, 0);
        press(TE_KEY_T3, 0);
        tap(CS5);
        note(G3, 1);
    } else {
        fprintf(stderr, "usage: host play|play_dorian|chord|side|bass|midi\n");
        return 2;
    }
    tick(44100 * 6 / 64);                        /* past the 5 s: pinned, the panel stays */
    co_frame(fb);
    return 0;
}
