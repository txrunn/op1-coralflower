/* SPDX-License-Identifier: GPL-3.0-only
 * CoralOP remote control: the MIDI protocol on channel 16 (README.md, "Remote control") without TE addresses.
 *
 * In (host -> OP-1), channel 16:
 *   notes 53..76 (F3..E5)   the OP-1's 24 keys, as if pressed (CoralFlower's numbering: key k = note 53 + k)
 *   note 78 (F#5)           HOLD (T4)
 *   CC 20..31, 102, 104..108  set a parameter (co_param_*: the value as the wire carries it)
 *   CC 109                  panic: every note off, every latch and HOLD cleared
 *   CC 110                  send the whole state back
 * Out (OP-1 -> host), channel 16, on every change once a host has spoken (or CoralOP is on):
 *   the parameters' CCs, CC 112/113 the lit chord buttons (bits 0..6 / 7..10), CC 114 HOLD, CC 115 the chord's
 *   root pitch class (127: none), CC 116 sounding, CC 117 the chord name's length then CC 118 one character each
 *   (7-bit ASCII: CoralFlower's degree ring and half-diminished sign spelled out).
 * Host-tested by test_co_remote.c. */
#ifndef CO_REMOTE_H
#define CO_REMOTE_H

#include <stdint.h>
#include "co_play.h"

#define CO_CTRL_CH 15           /* channel 16 */
#define CO_NOTE_KEY0 53         /* key 0 (the OP-1's lowest F) */

enum {                          /* the parameters' CC numbers */
    CO_CC_ENABLE = 20, CO_CC_QUANT, CO_CC_KEY, CO_CC_SCALE, CO_CC_LAYOUT, CO_CC_RETRIG,
    CO_CC_BASS, CO_CC_BOCT, CO_CC_OCTAVER, CO_CC_CHCH, CO_CC_BCH, CO_CC_LOCAL,
    CO_CC_VEL = 102,
    CO_CC_SEL = 104, CO_CC_TYPE, CO_CC_ADD, CO_CC_INV, CO_CC_BDEG,
    CO_CC_PANIC = 109, CO_CC_DUMP = 110,
    CO_CC_BTN_LO = 112, CO_CC_BTN_HI, CO_CC_HOLD, CO_CC_ROOT, CO_CC_SOUNDING, CO_CC_NAME_LEN, CO_CC_NAME_CHR,
};

/* what a parameter change asks of the caller */
enum { CO_K_NONE = 0, CO_K_APPLY, CO_K_ROUTE, CO_K_POWER, CO_K_SEL };

typedef struct {
    cf_chord_cfg_t cfg;
    co_opts_t opt;
    uint8_t ch[2];              /* channels 0..15 of CHORD and BASS, 16 = off */
    uint8_t local;
    uint8_t sel;                /* the chord button the CHORD page and CC 105..108 edit */
    uint8_t on;
} co_state_t;

/* the algorithms in the knob's and the wire's order (CoralFlower's: the Lock variants first) */
extern const uint8_t co_algo_order[CF_NALGS];

void co_state_defaults(co_state_t *s);
/* the kind of change a parameter makes (CO_K_*), -1 for a CC that is not a parameter */
int co_param_kind(int cc);
/* a parameter's value, its range (raw: toggles 0/1, BOCT 62..66, INV 0 = auto, 1..4 = 0..3); -1: no such
 * parameter or no form selected */
int co_param_get(const co_state_t *s, int cc);
int co_param_range(const co_state_t *s, int cc, int *lo, int *hi);
/* sets it (clamped into range); returns its kind, -1 when nothing was set */
int co_param_set(co_state_t *s, int cc, int raw);
/* raw <-> wire (toggles 0 / 127 out, >= 64 in; the rest as is) */
int co_wire_in(int cc, int wire);
int co_wire_out(int cc, int raw);
/* the panel's knobs: the CC each of the four turns on each page; a turn's new raw value (-1: nothing to turn) */
extern const uint8_t co_knob_cc[4][4];
int co_param_knob(const co_state_t *s, int cc, int dir);
/* the chord button form CC 105..108 edit (0: none, e.g. HOLD's) */
cf_form_t *co_sel_form(co_state_t *s);
int co_is_side(const co_state_t *s);

/* a chord name in 7-bit ASCII (C° -> Cdim, Cø7 -> Cm7b5) */
void co_wire_name(const char *in, char *out, int max);

/* the feedback: what changed since the last call, as (cc, value) pairs */
typedef struct {
    uint8_t sent[128];          /* the value last sent per CC, 0xFF: send */
    char name[24];              /* the name last sent (wire form) */
    uint8_t name_ok;
} co_fb_t;
void co_fb_invalidate(co_fb_t *f);
/* pairs: room for max (cc, value) pairs; returns how many (a name takes 1 + its length) */
int co_fb_collect(co_fb_t *f, const co_state_t *s, const co_play_t *p, const char *name, uint8_t (*pairs)[2],
                  int max);

#endif
