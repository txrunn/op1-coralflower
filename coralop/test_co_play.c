/* SPDX-License-Identifier: GPL-3.0-only
 * Host tests for CoralOP's player (co_play.c) on CoralFlower's verbatim model. Built by tools/test_all.py as
 * cc test_co_play.c co_play.c; the model comes in here. */
#include <stdio.h>
#include <string.h>
#include "cf_theory.c"
#include "cf_chord.c"
#include "co_play.h"

static int fails, checks;
#define CHECK(c) do { checks++; if (!(c)) { fails++; printf("FAIL %s:%d: %s\n", __FILE__, __LINE__, #c); } } while (0)

/* what each part sounds, as the other end of the MIDI cable sees it; errors: an on for a note already on, an off for
 * one that is not */
static uint8_t on[2][128];
static int errors, events;
static void out(void *ctx, int part, int note, int o, int vel)
{
    (void)ctx;
    events++;
    if (part < 0 || part > 1 || note < 0 || note > 127 || vel < 1 || vel > 127) {
        errors++;
        return;
    }
    if (o) {
        if (on[part][note])
            errors++;
        on[part][note] = 1;
    } else {
        if (!on[part][note])
            errors++;
        on[part][note] = 0;
    }
}

static int count(int part)
{
    int i, n = 0;
    for (i = 0; i < 128; i++)
        n += on[part][i];
    return n;
}
/* the pitch classes a part sounds, as a 12-bit mask */
static int pcs(int part)
{
    int i, m = 0;
    for (i = 0; i < 128; i++)
        if (on[part][i])
            m |= 1 << (i % 12);
    return m;
}
static int lowest(int part)
{
    int i;
    for (i = 0; i < 128; i++)
        if (on[part][i])
            return i;
    return -1;
}
#define PC(a) (1 << (a))

/* CoralFlower's key numbers on the OP-1: F3 = 0 ... E5 = 23 */
enum { K_F3 = 0, K_C4 = 7, K_CS4 = 8, K_D4 = 9, K_DS4 = 10, K_G4 = 14, K_A4 = 16, K_CS5 = 20, K_DS5 = 22, K_E5 = 23 };

static co_play_t p;
static cf_chord_cfg_t cfg;
static co_opts_t opt;
static uint32_t ms = 1000;

static void key(int k, int d) { co_key(&p, k, d, ms); ms += 100; }
static void tap(int k) { key(k, 1); key(k, 0); }

int main(void)
{
    int i, role, idx;

    /* the OP-1's keys under CoralFlower's numbering: 10 chord buttons (upper 0..9) and 14 roots in Top; F#5 = HOLD */
    for (i = 0, idx = 0; i < CO_NKEYS; i++)
        if (cf_key_role(CF_ALG_TOP_LOCK, i, &role) == CF_ROLE_BUTTON)
            idx++;
    CHECK(idx == 10);
    CHECK(cf_key_role(CF_ALG_TOP_LOCK, CO_KEY_HOLD, &idx) == CF_ROLE_BUTTON && idx == 10);
    co_defaults(&cfg, &opt);
    CHECK(cf_is_off(&cfg, 10));

    co_init(&p, &cfg, &opt, out, 0);

    /* 1. Top + Lock: tap M (C#5 = upper 8, latches), then the root C4: C major, the bass C under it */
    tap(K_CS5);
    CHECK(count(0) == 0 && count(1) == 0);       /* a chord button alone makes no sound */
    key(K_C4, 1);
    CHECK(pcs(0) == (PC(0) | PC(4) | PC(7)));
    CHECK(count(1) == 1 && pcs(1) == PC(0) && lowest(1) < lowest(0));
    CHECK(p.c.out.root_pc == 0);
    key(K_C4, 0);
    CHECK(count(0) == 0 && count(1) == 0);

    /* 2. the latch stays: G4 alone is G major (V) */
    key(K_G4, 1);
    CHECK(pcs(0) == (PC(7) | PC(11) | PC(2)));
    key(K_G4, 0);

    /* 3. RETRIG Wait: m (D#5) tapped under a held root changes nothing; the next root takes it */
    key(K_A4, 1);
    CHECK(pcs(0) == (PC(9) | PC(1) | PC(4)));    /* A major (M latched) */
    i = events;
    ms += 200;
    tap(K_DS5);
    CHECK(events == i);                          /* nothing struck, nothing let go */
    key(K_A4, 0);
    key(K_A4, 1);
    CHECK(pcs(0) == (PC(9) | PC(0) | PC(4)));    /* A minor */
    key(K_A4, 0);

    /* 4. a button with its root (within 50 ms) is that root's chord, Wait or not */
    co_key(&p, K_C4, 1, ms);
    co_key(&p, K_CS5, 1, ms + 10);               /* M back */
    co_key(&p, K_CS5, 0, ms + 20);
    CHECK(pcs(0) == (PC(0) | PC(4) | PC(7)));
    key(K_C4, 0);

    /* 5. RETRIG Notes: the button moves the chord under the held root; only the changed tone strikes */
    opt.retrig = CO_RT_NOTES;
    co_config(&p, &cfg, &opt);
    key(K_C4, 1);
    i = events;
    tap(K_DS5);                                  /* m: E -> Eb */
    CHECK(pcs(0) == (PC(0) | PC(3) | PC(7)));
    CHECK(events - i == 2);                      /* E off, Eb on */
    key(K_C4, 0);

    /* 6. RETRIG Chord: the whole chord strikes again */
    opt.retrig = CO_RT_CHORD;
    co_config(&p, &cfg, &opt);
    key(K_C4, 1);                                /* C minor (m latched) */
    i = events;
    tap(K_CS5);                                  /* M */
    CHECK(pcs(0) == (PC(0) | PC(4) | PC(7)));
    CHECK(events - i == 6);                      /* three off, three on */
    key(K_C4, 0);
    opt.retrig = CO_RT_WAIT;
    co_config(&p, &cfg, &opt);

    /* 7. combining: M + M7 (A#3 = upper 1) held together latch as Cmaj7 */
    key(K_CS5, 1);
    key(1 + 2, 1);                               /* G#3 = upper 1: M7 */
    key(1 + 2, 0);
    key(K_CS5, 0);
    key(K_C4, 1);
    CHECK(pcs(0) == (PC(0) | PC(4) | PC(7) | PC(11)));
    key(K_C4, 0);

    /* 8. bass options: off, octaver, octave */
    opt.bass_on = 0;
    co_config(&p, &cfg, &opt);
    key(K_C4, 1);
    CHECK(count(1) == 0);
    opt.bass_on = 1;
    opt.octaver = 1;
    co_config(&p, &cfg, &opt);                   /* turned on under the held root: the bass joins */
    CHECK(count(1) == 2 && pcs(1) == PC(0));
    key(K_C4, 0);
    opt.octaver = 0;
    co_config(&p, &cfg, &opt);

    /* 9. HOLD (T4 = key 25): the chord stays after the root goes up; a new root alone replaces it */
    tap(CO_KEY_HOLD);
    CHECK(p.c.out.hold);
    tap(K_C4);
    CHECK(count(0) == 4);                        /* Cmaj7 held */
    tap(K_D4);
    CHECK(count(0) == 4 && (pcs(0) & PC(2)));    /* Dmaj7 (Quantize Basic keeps the button's type) */
    tap(CO_KEY_HOLD);
    CHECK(!p.c.out.hold && count(0) == 0 && count(1) == 0);

    /* 10. Quantize Full in D dorian: C#5 (M) on the root E5 becomes the scale's chord on E (E minor) */
    cfg.quantize = CF_Q_FULL;
    cfg.tonic = 2;
    cfg.scale = CF_SC_DORIAN;
    co_config(&p, &cfg, &opt);
    tap(K_CS5);
    key(K_E5, 1);
    CHECK(count(0) >= 3);
    CHECK(!(pcs(0) & ~(PC(2) | PC(4) | PC(5) | PC(7) | PC(9) | PC(11) | PC(0))));   /* in D dorian */
    key(K_E5, 0);

    /* 11. Side: quality on upper 0..2, extensions on lower 0..3; key 25 does nothing there */
    cfg = (cf_chord_cfg_t){0};
    co_defaults(&cfg, &opt);
    cfg.algo = CF_ALG_SIDE;
    co_config(&p, &cfg, &opt);
    CHECK(co_key(&p, CO_KEY_HOLD, 1, ms) == 0);
    key(1, 1);                                   /* F#3 = upper 0: M (held) */
    key(K_C4, 1);                                /* C4 is a root in Side */
    CHECK(pcs(0) == (PC(0) | PC(4) | PC(7)));
    key(K_C4, 0);
    key(1, 0);
    key(K_C4, 1);                                /* no button: the key alone is one note */
    CHECK(count(0) == 1 && count(1) == 0);
    key(K_C4, 0);

    /* 12. reset with keys down: everything stops, nothing hangs */
    cfg.algo = CF_ALG_TOP;
    co_config(&p, &cfg, &opt);
    key(K_CS5, 1);
    key(K_C4, 1);
    key(K_D4, 1);
    co_reset(&p);
    CHECK(count(0) == 0 && count(1) == 0);
    CHECK(!p.c.out.sounding && !p.c.out.buttons && !p.c.out.hold);    /* (what the remote and the panel show) */
    co_key(&p, K_C4, 0, ms);                     /* the releases after a reset change nothing */
    co_key(&p, K_D4, 0, ms);
    co_key(&p, K_CS5, 0, ms);
    CHECK(count(0) == 0 && count(1) == 0);

    /* 13. a random hammering of every key, layout and setting: never an on twice or an off without an on, and all
     * notes off after a release of everything */
    {
        uint32_t r = 12345;
        int down[CO_NKEYS + 2] = {0}, step;
        for (step = 0; step < 200000; step++) {
            int k;
            r = r * 1103515245u + 12345u;
            k = (int)(r >> 16) % (CO_NKEYS + 1);
            if (k == CO_NKEYS)
                k = CO_KEY_HOLD;
            if ((r >> 8) % 997 == 0) {
                cfg.algo = (uint8_t)((r >> 3) % CF_NALGS);
                cfg.quantize = (uint8_t)((r >> 5) % 3);
                cfg.scale = (uint8_t)((r >> 7) % CF_NSCALES);
                cfg.tonic = (uint8_t)((r >> 11) % 12);
                cfg.octave = (int8_t)((int)((r >> 13) % 7) - 3);
                opt.retrig = (uint8_t)((r >> 17) % CO_NRT);
                opt.octaver = (uint8_t)((r >> 19) & 1);
                opt.bass_oct = (int8_t)((int)((r >> 20) % 5) - 2);
                co_config(&p, &cfg, &opt);
                if (cfg.algo >= CF_ALG_SIDE)
                    for (i = 0; i < CO_NKEYS + 2; i++)
                        down[i] = 0;    /* (a change of layout drops the keys in the model) */
            }
            down[k == CO_KEY_HOLD ? CO_NKEYS : k] ^= 1;
            co_key(&p, k, down[k == CO_KEY_HOLD ? CO_NKEYS : k], ms);
            ms += (r >> 24) % 80;
            CHECK(count(0) <= CF_MAX_NOTES && count(1) <= 2);
            if (errors)
                break;
        }
        CHECK(errors == 0);
        co_reset(&p);
        CHECK(count(0) == 0 && count(1) == 0);
    }

    CHECK(errors == 0);
    printf("co_play: %d checks, %d failures\n", checks, fails);
    return fails != 0;
}
