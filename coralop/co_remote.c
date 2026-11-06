/* SPDX-License-Identifier: GPL-3.0-only
 * CoralOP remote control (co_remote.h). */
#include "co_remote.h"

const uint8_t co_algo_order[CF_NALGS] = {CF_ALG_TOP_LOCK, CF_ALG_TOP, CF_ALG_SIDE_LOCK, CF_ALG_SIDE};

const uint8_t co_knob_cc[4][4] = {
    {CO_CC_QUANT, CO_CC_KEY, CO_CC_SCALE, CO_CC_LAYOUT},        /* PLAY */
    {CO_CC_TYPE, CO_CC_ADD, CO_CC_INV, CO_CC_BDEG},             /* CHORD */
    {CO_CC_BASS, CO_CC_BOCT, CO_CC_OCTAVER, CO_CC_RETRIG},      /* BASS */
    {CO_CC_CHCH, CO_CC_BCH, CO_CC_LOCAL, CO_CC_VEL},            /* MIDI */
};

void co_state_defaults(co_state_t *s)
{
    co_defaults(&s->cfg, &s->opt);
    s->ch[0] = 0;
    s->ch[1] = 1;
    s->local = 1;
    s->sel = 0;
    s->on = 0;
}

int co_is_side(const co_state_t *s)
{
    return s->cfg.algo == CF_ALG_SIDE || s->cfg.algo == CF_ALG_SIDE_LOCK;
}

cf_form_t *co_sel_form(co_state_t *s)
{
    if (co_is_side(s))
        return s->sel < CF_SIDE_NBTN ? &s->cfg.side[s->sel] : 0;
    return s->sel < CF_TOP_NBTN && !cf_is_off(&s->cfg, s->sel) ? &s->cfg.top[s->sel] : 0;
}

static int algo_pos(int a)
{
    int i;
    for (i = 0; i < CF_NALGS; i++)
        if (co_algo_order[i] == a)
            return i;
    return 0;
}

static int is_toggle(int cc)
{
    return cc == CO_CC_ENABLE || cc == CO_CC_BASS || cc == CO_CC_OCTAVER || cc == CO_CC_LOCAL;
}
static int wraps(int cc)
{
    return !(cc == CO_CC_BOCT || cc == CO_CC_VEL || cc == CO_CC_SEL);
}

int co_param_kind(int cc)
{
    switch (cc) {
    case CO_CC_ENABLE:
        return CO_K_POWER;
    case CO_CC_QUANT: case CO_CC_KEY: case CO_CC_SCALE: case CO_CC_LAYOUT: case CO_CC_RETRIG:
    case CO_CC_BASS: case CO_CC_BOCT: case CO_CC_OCTAVER: case CO_CC_VEL:
    case CO_CC_TYPE: case CO_CC_ADD: case CO_CC_INV: case CO_CC_BDEG:
        return CO_K_APPLY;
    case CO_CC_CHCH: case CO_CC_BCH: case CO_CC_LOCAL:
        return CO_K_ROUTE;
    case CO_CC_SEL:
        return CO_K_SEL;
    default:
        return -1;
    }
}

static int form_tones(const cf_form_t *f)
{
    int8_t tones[12];
    int n = cf_mask_tones(cf_form_mask(f), tones);
    return n > 0 ? n : 1;
}

int co_param_range(const co_state_t *s, int cc, int *lo, int *hi)
{
    const cf_form_t *f;
    *lo = 0;
    switch (cc) {
    case CO_CC_ENABLE: case CO_CC_BASS: case CO_CC_OCTAVER: case CO_CC_LOCAL: *hi = 1; return 1;
    case CO_CC_QUANT: *hi = 2; return 1;
    case CO_CC_KEY: *hi = 11; return 1;
    case CO_CC_SCALE: *hi = CF_NSCALES - 1; return 1;
    case CO_CC_LAYOUT: *hi = CF_NALGS - 1; return 1;
    case CO_CC_RETRIG: *hi = CO_NRT - 1; return 1;
    case CO_CC_BOCT: *lo = 62; *hi = 66; return 1;
    case CO_CC_CHCH: case CO_CC_BCH: *hi = 16; return 1;
    case CO_CC_VEL: *lo = 1; *hi = 127; return 1;
    case CO_CC_SEL: *hi = (co_is_side(s) ? CF_SIDE_NBTN : CF_TOP_NBTN) - 1; return 1;
    case CO_CC_TYPE: case CO_CC_ADD: case CO_CC_INV: case CO_CC_BDEG:
        f = co_sel_form((co_state_t *)s);
        if (!f)
            return 0;
        *hi = cc == CO_CC_TYPE ? CF_NTYPES - 1 : cc == CO_CC_ADD ? CF_NADDS - 1 : cc == CO_CC_INV ? 3 - CF_INV_AUTO
                                                                                  : form_tones(f) - 1;
        return 1;
    default:
        return 0;
    }
}

int co_param_get(const co_state_t *s, int cc)
{
    const cf_form_t *f;
    int i;
    switch (cc) {
    case CO_CC_ENABLE: return s->on ? 1 : 0;
    case CO_CC_QUANT: return s->cfg.quantize;
    case CO_CC_KEY: return s->cfg.tonic;
    case CO_CC_SCALE: return s->cfg.scale;
    case CO_CC_LAYOUT: return algo_pos(s->cfg.algo);
    case CO_CC_RETRIG: return s->opt.retrig;
    case CO_CC_BASS: return s->opt.bass_on ? 1 : 0;
    case CO_CC_BOCT: return 64 + s->opt.bass_oct;
    case CO_CC_OCTAVER: return s->opt.octaver ? 1 : 0;
    case CO_CC_CHCH: return s->ch[0] > 15 ? 0 : s->ch[0] + 1;
    case CO_CC_BCH: return s->ch[1] > 15 ? 0 : s->ch[1] + 1;
    case CO_CC_LOCAL: return s->local ? 1 : 0;
    case CO_CC_VEL: return s->opt.vel;
    case CO_CC_SEL: return s->sel;
    case CO_CC_TYPE: case CO_CC_ADD: case CO_CC_INV: case CO_CC_BDEG:
        f = co_sel_form((co_state_t *)s);
        if (!f)
            return -1;
        if (cc == CO_CC_TYPE)
            return f->type;
        if (cc == CO_CC_ADD)
            return (i = cf_adds_index(f->add)) < 0 ? 0 : i;
        if (cc == CO_CC_INV)
            return f->inv - CF_INV_AUTO;
        return f->bass;
    default:
        return -1;
    }
}

int co_param_set(co_state_t *s, int cc, int raw)
{
    int lo, hi, kind = co_param_kind(cc);
    cf_form_t *f;
    if (kind < 0 || !co_param_range(s, cc, &lo, &hi))
        return -1;
    raw = raw < lo ? lo : raw > hi ? hi : raw;
    switch (cc) {
    case CO_CC_ENABLE: s->on = (uint8_t)raw; break;
    case CO_CC_QUANT: s->cfg.quantize = (uint8_t)raw; break;
    case CO_CC_KEY: s->cfg.tonic = (uint8_t)raw; break;
    case CO_CC_SCALE: s->cfg.scale = (uint8_t)raw; break;
    case CO_CC_LAYOUT:
        if (co_algo_order[raw] != s->cfg.algo)
            s->sel = 0;
        s->cfg.algo = co_algo_order[raw];
        break;
    case CO_CC_RETRIG: s->opt.retrig = (uint8_t)raw; break;
    case CO_CC_BASS: s->opt.bass_on = (uint8_t)raw; break;
    case CO_CC_BOCT: s->opt.bass_oct = (int8_t)(raw - 64); break;
    case CO_CC_OCTAVER: s->opt.octaver = (uint8_t)raw; break;
    case CO_CC_CHCH: s->ch[0] = (uint8_t)(raw ? raw - 1 : 16); break;
    case CO_CC_BCH: s->ch[1] = (uint8_t)(raw ? raw - 1 : 16); break;
    case CO_CC_LOCAL: s->local = (uint8_t)raw; break;
    case CO_CC_VEL: s->opt.vel = (uint8_t)raw; break;
    case CO_CC_SEL: s->sel = (uint8_t)raw; break;
    default:
        f = co_sel_form(s);
        if (cc == CO_CC_TYPE)
            f->type = (uint8_t)raw;
        else if (cc == CO_CC_ADD)
            f->add = CF_ADDS[raw];
        else if (cc == CO_CC_INV)
            f->inv = (int8_t)(raw + CF_INV_AUTO);
        else
            f->bass = (uint8_t)raw;
        if (f->bass >= form_tones(f))   /* (a type with fewer tones: the bass degree stays in it) */
            f->bass = (uint8_t)(form_tones(f) - 1);
    }
    return kind;
}

int co_wire_in(int cc, int wire)
{
    return is_toggle(cc) ? wire >= 64 : wire;
}

int co_wire_out(int cc, int raw)
{
    return is_toggle(cc) ? (raw ? 127 : 0) : raw & 127;
}

int co_param_knob(const co_state_t *s, int cc, int dir)
{
    int lo, hi, v = co_param_get(s, cc), stepv = cc == CO_CC_VEL ? 5 : 1;
    if (v < 0 || !co_param_range(s, cc, &lo, &hi))
        return -1;
    v += dir > 0 ? stepv : -stepv;
    if (wraps(cc))
        return v < lo ? hi : v > hi ? lo : v;
    return v < lo ? lo : v > hi ? hi : v;
}

void co_wire_name(const char *in, char *out, int max)
{
    int n = 0;
    for (; *in && n < max - 1; in++) {
        unsigned char c = (unsigned char)*in;
        const char *sub = 0;
        if (c == 0xB0)
            sub = "dim";
        else if (c == 0xF8)
            sub = "m7b5";
        if (sub) {
            if (c == 0xF8 && in[1] == '7')
                in++;           /* (Cø7 is Cm7b5, not Cm7b57) */
            while (*sub && n < max - 1)
                out[n++] = *sub++;
        } else if (c >= 0x10 && c <= 0x19) {
            out[n++] = (char)('0' + c - 0x10);
        } else if (c >= 0x20 && c < 0x7F) {
            out[n++] = (char)c;
        }
    }
    out[n] = 0;
}

void co_fb_invalidate(co_fb_t *f)
{
    int i;
    for (i = 0; i < 128; i++)
        f->sent[i] = 0xFF;
    f->name_ok = 0;
}

static const uint8_t FB_PARAMS[] = {
    CO_CC_ENABLE, CO_CC_QUANT, CO_CC_KEY, CO_CC_SCALE, CO_CC_LAYOUT, CO_CC_RETRIG, CO_CC_BASS, CO_CC_BOCT,
    CO_CC_OCTAVER, CO_CC_CHCH, CO_CC_BCH, CO_CC_LOCAL, CO_CC_VEL, CO_CC_SEL, CO_CC_TYPE, CO_CC_ADD, CO_CC_INV,
    CO_CC_BDEG,
};

int co_fb_collect(co_fb_t *f, const co_state_t *s, const co_play_t *p, const char *name, uint8_t (*pairs)[2],
                  int max)
{
    const cf_chord_out_t *o = &p->c.out;
    int n = 0, i, v;
    char w[24];
    uint8_t st[5];
#define PUT(cc, val) do { if (n < max) { pairs[n][0] = (uint8_t)(cc); pairs[n][1] = (uint8_t)(val); n++; } } while (0)
    for (i = 0; i < (int)sizeof FB_PARAMS; i++) {
        int cc = FB_PARAMS[i];
        v = co_param_get(s, cc);
        if (v < 0)
            v = 127;            /* (no form selected: the form's CCs read 127) */
        else
            v = co_wire_out(cc, v);
        if (f->sent[cc] != v && n < max) {
            f->sent[cc] = (uint8_t)v;
            PUT(cc, v);
        }
    }
    st[0] = (uint8_t)(o->buttons & 127);
    st[1] = (uint8_t)(o->buttons >> 7 & 15);
    st[2] = o->hold ? 127 : 0;
    st[3] = o->sounding ? (uint8_t)o->root_pc : 127;
    st[4] = o->sounding ? 127 : 0;
    for (i = 0; i < 5; i++)
        if (f->sent[CO_CC_BTN_LO + i] != st[i] && n < max) {
            f->sent[CO_CC_BTN_LO + i] = st[i];
            PUT(CO_CC_BTN_LO + i, st[i]);
        }
    co_wire_name(name, w, sizeof w);
    for (i = 0; f->name_ok && w[i] == f->name[i] && w[i]; i++)
        ;
    if (!f->name_ok || w[i] != f->name[i]) {
        int len = 0;
        while (w[len])
            len++;
        if (n + 1 + len <= max) {
            PUT(CO_CC_NAME_LEN, len);
            for (i = 0; i < len; i++)
                PUT(CO_CC_NAME_CHR, w[i]);
            for (i = 0; i <= len; i++)
                f->name[i] = w[i];
            f->name_ok = 1;
        }
    }
#undef PUT
    return n;
}
