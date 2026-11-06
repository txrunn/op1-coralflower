/* SPDX-License-Identifier: GPL-3.0-only
 * Host tests for CoralOP's remote protocol (co_remote.c). Built by tools/test_all.py as cc test_co_remote.c
 * co_remote.c; the model and the player come in here. */
#include <stdio.h>
#include <string.h>
#include "cf_theory.c"
#include "cf_chord.c"
#include "co_play.c"
#include "co_remote.h"

static int fails, checks;
#define CHECK(c) do { checks++; if (!(c)) { fails++; printf("FAIL %s:%d: %s\n", __FILE__, __LINE__, #c); } } while (0)

static void out(void *ctx, int part, int note, int on, int vel) { (void)ctx; (void)part; (void)note; (void)on; (void)vel; }

static uint8_t pairs[64][2];
static int find(int n, int cc)          /* the last value sent for cc, -1: not sent */
{
    int i, v = -1;
    for (i = 0; i < n; i++)
        if (pairs[i][0] == cc)
            v = pairs[i][1];
    return v;
}

int main(void)
{
    co_state_t s;
    co_play_t p;
    co_fb_t fb;
    char w[24], nm[16];
    int n, i, cc, lo, hi;
    static const int PARAMS[] = {20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 102, 104, 105, 106, 107, 108};

    co_state_defaults(&s);
    co_init(&p, &s.cfg, &s.opt, out, 0);

    /* defaults as the README says */
    CHECK(co_param_get(&s, CO_CC_ENABLE) == 0);
    CHECK(co_param_get(&s, CO_CC_QUANT) == CF_Q_BASIC);
    CHECK(co_param_get(&s, CO_CC_KEY) == 0);
    CHECK(co_param_get(&s, CO_CC_LAYOUT) == 0);                 /* Top Lock */
    CHECK(co_param_get(&s, CO_CC_CHCH) == 1 && co_param_get(&s, CO_CC_BCH) == 2);
    CHECK(co_param_get(&s, CO_CC_BOCT) == 64 && co_param_get(&s, CO_CC_VEL) == 100);
    CHECK(co_param_get(&s, CO_CC_INV) == 0 - CF_INV_AUTO + s.cfg.top[0].inv);

    /* every parameter: in range, a set of every value in range reads back, out of range clamps */
    for (i = 0; i < (int)(sizeof PARAMS / sizeof PARAMS[0]); i++) {
        int v;
        cc = PARAMS[i];
        CHECK(co_param_kind(cc) >= 0);
        CHECK(co_param_range(&s, cc, &lo, &hi));
        for (v = lo; v <= hi; v++) {
            CHECK(co_param_set(&s, cc, v) >= 0);
            if (cc == CO_CC_BDEG || cc == CO_CC_SEL)
                CHECK(co_param_get(&s, cc) == v);
            else if (co_param_get(&s, cc) != v) {
                printf("  cc %d: set %d read %d\n", cc, v, co_param_get(&s, cc));
                CHECK(0);
            }
        }
        co_param_set(&s, cc, hi + 50);
        CHECK(co_param_get(&s, cc) == hi || cc == CO_CC_SEL);
        co_param_set(&s, cc, lo - 50);
        CHECK(co_param_get(&s, cc) == lo || cc == CO_CC_SEL);
    }
    CHECK(co_param_kind(CO_CC_PANIC) < 0 && co_param_kind(7) < 0 && co_param_get(&s, 64) < 0);

    /* wire: toggles 0/127, in: >= 64 */
    CHECK(co_wire_out(CO_CC_BASS, 1) == 127 && co_wire_out(CO_CC_BASS, 0) == 0);
    CHECK(co_wire_in(CO_CC_BASS, 64) == 1 && co_wire_in(CO_CC_BASS, 63) == 0 && co_wire_in(CO_CC_KEY, 7) == 7);

    /* channels: 0 = off, 1..16 */
    co_state_defaults(&s);
    co_param_set(&s, CO_CC_CHCH, 0);
    CHECK(s.ch[0] == 16 && co_param_get(&s, CO_CC_CHCH) == 0);
    co_param_set(&s, CO_CC_CHCH, 16);
    CHECK(s.ch[0] == 15);
    CHECK(co_param_kind(CO_CC_CHCH) == CO_K_ROUTE && co_param_kind(CO_CC_KEY) == CO_K_APPLY);

    /* layout: Top Lock / Top / Side Lock / Side; a change resets the selection */
    co_param_set(&s, CO_CC_SEL, 5);
    co_param_set(&s, CO_CC_LAYOUT, 3);
    CHECK(s.cfg.algo == CF_ALG_SIDE && s.sel == 0);
    co_param_range(&s, CO_CC_SEL, &lo, &hi);
    CHECK(hi == CF_SIDE_NBTN - 1);
    co_param_set(&s, CO_CC_LAYOUT, 0);
    CHECK(s.cfg.algo == CF_ALG_TOP_LOCK);

    /* forms: HOLD's (button 10) has no form, its CCs read -1 */
    co_param_set(&s, CO_CC_SEL, 10);
    CHECK(co_sel_form(&s) == 0 && co_param_get(&s, CO_CC_TYPE) < 0 && co_param_set(&s, CO_CC_TYPE, 1) < 0);
    co_param_set(&s, CO_CC_SEL, 8);                             /* M */
    CHECK(co_param_set(&s, CO_CC_ADD, 4) == CO_K_APPLY && co_param_get(&s, CO_CC_ADD) == 4);
    co_param_set(&s, CO_CC_BDEG, 99);
    CHECK(co_param_get(&s, CO_CC_BDEG) < 12);

    /* knobs: wrap (key B -> C), clamp (bass octave, velocity by 5) */
    co_param_set(&s, CO_CC_KEY, 11);
    CHECK(co_param_knob(&s, CO_CC_KEY, 1) == 0);
    co_param_set(&s, CO_CC_BOCT, 66);
    CHECK(co_param_knob(&s, CO_CC_BOCT, 1) == 66);
    co_param_set(&s, CO_CC_VEL, 100);
    CHECK(co_param_knob(&s, CO_CC_VEL, 1) == 105 && co_param_knob(&s, CO_CC_VEL, -1) == 95);
    CHECK(co_param_knob(&s, CO_CC_BASS, 1) == !co_param_get(&s, CO_CC_BASS));
    for (i = 0; i < 4; i++) {
        int k;
        for (k = 0; k < 4; k++)
            CHECK(co_param_kind(co_knob_cc[i][k]) >= 0);
    }

    /* names: 7-bit, the ring and the half-diminished spelled out */
    co_wire_name("C\xB0" "7", w, sizeof w);
    CHECK(!strcmp(w, "Cdim7"));
    co_wire_name("B\xF8" "7", w, sizeof w);
    CHECK(!strcmp(w, "Bm7b5"));
    co_wire_name("Eb/G", w, sizeof w);
    CHECK(!strcmp(w, "Eb/G"));
    co_wire_name("M\x17", w, sizeof w);
    CHECK(!strcmp(w, "M7"));
    co_wire_name("ABCDEFGHIJKLMNOPQRSTUVWXYZ", w, 8);
    CHECK(strlen(w) == 7);

    /* feedback: the first collect sends every parameter, the status and the name; the second nothing */
    co_state_defaults(&s);
    co_init(&p, &s.cfg, &s.opt, out, 0);
    co_fb_invalidate(&fb);
    n = co_fb_collect(&fb, &s, &p, "", pairs, 64);
    CHECK(n == 18 + 5 + 1);
    CHECK(find(n, CO_CC_CHCH) == 1 && find(n, CO_CC_ENABLE) == 0 && find(n, CO_CC_ROOT) == 127);
    CHECK(find(n, CO_CC_NAME_LEN) == 0);
    CHECK(co_fb_collect(&fb, &s, &p, "", pairs, 64) == 0);

    /* a chord: the lit button, the root, sounding, the name */
    co_key(&p, 20, 1, 0);                                       /* M */
    co_key(&p, 20, 0, 0);
    co_key(&p, 7, 1, 100);                                      /* C4 */
    strcpy(nm, "C");
    n = co_fb_collect(&fb, &s, &p, nm, pairs, 64);
    CHECK(find(n, CO_CC_BTN_HI) == 1 << (8 - 7) && find(n, CO_CC_ROOT) == 0 && find(n, CO_CC_SOUNDING) == 127);
    CHECK(find(n, CO_CC_NAME_LEN) == 1 && find(n, CO_CC_NAME_CHR) == 'C');
    /* the name follows its length in order */
    for (i = 0; i < n && pairs[i][0] != CO_CC_NAME_LEN; i++)
        ;
    CHECK(i + 1 < n && pairs[i + 1][0] == CO_CC_NAME_CHR);
    /* a change of setting: only that CC */
    co_param_set(&s, CO_CC_SCALE, 4);
    n = co_fb_collect(&fb, &s, &p, nm, pairs, 64);
    CHECK(n == 1 && pairs[0][0] == CO_CC_SCALE && pairs[0][1] == 4);
    /* too little room for a name: it waits whole, it is never cut */
    strcpy(nm, "Cmaj7");
    n = co_fb_collect(&fb, &s, &p, nm, pairs, 3);
    CHECK(n == 0 || find(n, CO_CC_NAME_LEN) < 0);
    n = co_fb_collect(&fb, &s, &p, nm, pairs, 64);
    CHECK(n == 6 && find(n, CO_CC_NAME_LEN) == 5);

    printf("co_remote: %d checks, %d failures\n", checks, fails);
    return fails != 0;
}
