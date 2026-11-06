/* SPDX-License-Identifier: GPL-3.0-only
 * CoralOP: CoralFlower's chord model (cf_chord.c, verbatim) played by the OP-1's keys.
 *
 * Pure logic, no TE addresses: the keys go in as CoralFlower key numbers (0..23 = the OP-1's 24 keys, F upwards,
 * key k = MIDI 53 + k at octave 0, the same numbering as the FM-1's 27; 25 = the HOLD button, which the OP-1 has no
 * key for and gets from T4), the notes come out through a callback on two parts:
 *   part 0 CHORD  the chord's notes (or the single notes of HOLD's Off form)
 *   part 1 BASS   the chord's bass degree an octave under the root as played (+ octave), with the octaver on top
 * Ported from CoralFlower's cf_play.c (cfp_key, cfp_sync, cfp_bass_calc) without the glide, the arpeggiator and the
 * sequencer: RETRIG Wait / Notes / Chord as there (Wait: a chord button under held roots waits for the next root).
 * Host-tested by test_co_play.c. */
#ifndef CO_PLAY_H
#define CO_PLAY_H

#include <stdint.h>
#include "cf_chord.h"

#define CO_NKEYS 24             /* the OP-1's note keys: CoralFlower keys 0..23 */
#define CO_KEY_HOLD 25          /* CoralFlower's 11th upper key (F#5), the Top layouts' Off form = HOLD */

enum { CO_RT_WAIT = 0, CO_RT_NOTES, CO_RT_CHORD, CO_NRT };
enum { CO_PART_CHORD = 0, CO_PART_BASS = 1 };

typedef struct {
    uint8_t bass_on;            /* the bass part plays */
    int8_t bass_oct;            /* -2..+2 octaves (0: an octave under the root as played) */
    uint8_t octaver;            /* a second bass note an octave higher */
    uint8_t retrig;             /* CO_RT_* */
    uint8_t vel;                /* 1..127: the OP-1's keys have no velocity */
} co_opts_t;

/* a note on (on = 1) or off on a part */
typedef void (*co_out_fn)(void *ctx, int part, int note, int on, int vel);

typedef struct {
    cf_chord_t c;               /* CoralFlower's model (c.out: what the hands ask for) */
    co_opts_t o;
    co_out_fn out;
    void *ctx;
    uint8_t n, note[CF_MAX_NOTES];      /* the chord part's notes that sound */
    uint8_t nb, bass[2];                /* the bass part's */
    uint8_t vel[2];                     /* the velocity each part's notes went on with (their offs) */
    uint32_t root_ms;           /* when the last root went down (RETRIG Wait's gather window) */
    uint32_t strikes;           /* chords struck (tests, the screen) */
} co_play_t;

void co_defaults(cf_chord_cfg_t *cfg, co_opts_t *o);
void co_init(co_play_t *p, const cf_chord_cfg_t *cfg, const co_opts_t *o, co_out_fn out, void *ctx);
/* a key down / up (0..23, CO_KEY_HOLD); now_ms: any running clock. Returns 1 when something changed (notes,
 * buttons, HOLD) */
int co_key(co_play_t *p, int key, int down, uint32_t now_ms);
/* new settings: held keys stay, the chord is resolved again and what sounds moves to it */
void co_config(co_play_t *p, const cf_chord_cfg_t *cfg, const co_opts_t *o);
/* everything that sounds stops (the model keeps its keys: a change of output, LOCAL, channels) */
void co_silence(co_play_t *p);
/* every key up, every latch and HOLD cleared, everything stops */
void co_reset(co_play_t *p);
/* the bass notes of a chord output under o (exposed for the tests) */
int co_bass_notes(const co_opts_t *o, const cf_chord_out_t *out, uint8_t notes[2]);

#endif
