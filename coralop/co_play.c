/* SPDX-License-Identifier: GPL-3.0-only
 * CoralOP: the player (co_play.h). After CoralFlower's cf_play.c (Felucca / ChoralRoot / CoralFlower, GPL-3.0). */
#include "co_play.h"

#define CO_GATHER_MS 50u        /* a button this soon after a root is still that root's chord (cf_play.c) */

void co_defaults(cf_chord_cfg_t *cfg, co_opts_t *o)
{
    cf_chord_defaults(cfg);     /* Top + Lock, Quantize Basic, C major, CoralFlower's ten chord buttons */
    o->bass_on = 1;
    o->bass_oct = 0;
    o->octaver = 0;
    o->retrig = CO_RT_WAIT;
    o->vel = 100;
}

void co_init(co_play_t *p, const cf_chord_cfg_t *cfg, const co_opts_t *o, co_out_fn out, void *ctx)
{
    cf_chord_init(&p->c, cfg);
    p->o = *o;
    p->out = out;
    p->ctx = ctx;
    p->n = p->nb = 0;
    p->vel[0] = p->vel[1] = o->vel;
    p->root_ms = 0;
    p->strikes = 0;
}

static int has(const uint8_t *a, int n, int v)
{
    int i;
    for (i = 0; i < n; i++)
        if (a[i] == v)
            return 1;
    return 0;
}

static int same(const uint8_t *a, int n, const uint8_t *b, int m)
{
    int i;
    if (n != m)
        return 0;
    for (i = 0; i < n; i++)
        if (!has(b, m, a[i]))
            return 0;
    return 1;
}

/* cf_play.c cfp_bass_calc: an octave under the root as played, the bass degree's nearest note to it */
int co_bass_notes(const co_opts_t *o, const cf_chord_out_t *out, uint8_t notes[2])
{
    int n = 0, b;
    if (!o->bass_on || !out->sounding || out->single || out->bass_pc < 0)
        return 0;
    b = (int)out->root_note - 12 + 12 * o->bass_oct;
    b += ((out->bass_pc - (b % 12 + 12) % 12 + 18) % 12) - 6;
    while (b < 12)
        b += 12;
    while (b > 96)
        b -= 12;
    notes[n++] = (uint8_t)b;
    if (o->octaver && b + 12 <= 120)
        notes[n++] = (uint8_t)(b + 12);
    return n;
}

/* a part goes from old (*pn notes) to nw (m notes): strike = every old note off, every new one on (the shared ones
 * again); else only the notes that change. Offs before ons (a mono synth on the other end gets its legato right). */
static void change(co_play_t *p, int part, uint8_t *old, uint8_t *pn, const uint8_t *nw, int m, int strike)
{
    int i, n = *pn;
    for (i = 0; i < n; i++)
        if (strike || !has(nw, m, old[i]))
            p->out(p->ctx, part, old[i], 0, p->vel[part]);
    for (i = 0; i < m; i++)
        if (strike || !has(old, n, nw[i]))
            p->out(p->ctx, part, nw[i], 1, p->o.vel);
    for (i = 0; i < m; i++)
        old[i] = nw[i];
    *pn = (uint8_t)m;
    if (m)
        p->vel[part] = p->o.vel;
}

/* the parts follow the model. how: 0 a fresh strike (a root key went down), 1 a change under held keys */
static void sync(co_play_t *p, int how)
{
    const cf_chord_out_t *o = &p->c.out;
    uint8_t nb[2];
    int m = o->sounding ? o->n : 0;
    int mb = co_bass_notes(&p->o, o, nb);
    /* single notes (HOLD's Off, Side with no button): the held ones stay, only a new one strikes */
    int strike = !o->single && m && (how == 0 || (p->o.retrig == CO_RT_CHORD && !same(p->note, p->n, o->note, m)));
    int bstrike = mb && (how == 0 || (p->o.retrig == CO_RT_CHORD && !same(p->bass, p->nb, nb, mb)));
    if (strike)
        p->strikes++;
    change(p, CO_PART_CHORD, p->note, &p->n, o->note, m, strike);
    change(p, CO_PART_BASS, p->bass, &p->nb, nb, mb, bstrike);
}

int co_key(co_play_t *p, int key, int down, uint32_t now_ms)
{
    int idx, role = cf_key_role(p->c.cfg.algo, key, &idx);
    if (key == CO_KEY_HOLD && (p->c.cfg.algo == CF_ALG_SIDE || p->c.cfg.algo == CF_ALG_SIDE_LOCK))
        return 0;               /* (Side has no HOLD: the 11th upper key would be a root the OP-1 has not got) */
    /* RETRIG Wait: a button under held roots waits for the next root, unless it came with that root */
    p->c.keep = p->o.retrig == CO_RT_WAIT &&
                (role != CF_ROLE_BUTTON || (uint32_t)(now_ms - p->root_ms) >= CO_GATHER_MS);
    if (role == CF_ROLE_ROOT && down)
        p->root_ms = now_ms;
    if (!cf_chord_key(&p->c, key, down))
        return 0;
    sync(p, role == CF_ROLE_ROOT && down ? 0 : 1);
    return 1;
}

void co_config(co_play_t *p, const cf_chord_cfg_t *cfg, const co_opts_t *o)
{
    p->o = *o;
    p->c.keep = 0;              /* (an edit is heard at once, on the chord that sounds) */
    cf_chord_config(&p->c, cfg);
    sync(p, 1);
}

void co_silence(co_play_t *p)
{
    change(p, CO_PART_CHORD, p->note, &p->n, 0, 0, 1);
    change(p, CO_PART_BASS, p->bass, &p->nb, 0, 0, 1);
}

void co_reset(co_play_t *p)
{
    cf_chord_t *c = &p->c;
    cf_chord_reset(c);
    c->keep = 0;
    cf_chord_config(c, &c->cfg);    /* (cf_chord_reset leaves c->out: the latches, HOLD and the chord it shows) */
    co_silence(p);
}
