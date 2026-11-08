# CoralOP — CoralFlower's chord instrument on the OP-1

Status: **0.2, experimental** (host-tested and simulator-tested; not yet played on a device). 0.2 adds remote
control over MIDI channel 16 (`../remote/`: plugdata / Pd / Max panels and a guitar fretboard).

CoralOP puts [CoralFlower](https://github.com/FicusFicusov/CoralFlower)'s chord engine — the FM-1 firmware
inspired by the Telepathic Instruments Orchid — on the original OP-1 (firmware R246). The chord model
(`cf_chord.c`, `cf_theory.c`) is CoralFlower's, copied verbatim from commit `272cad9`; `co_play.c` is a port of
its player without glide, arpeggiator and sequencer; `co_remote.c` the channel-16 protocol; `coralop.c` is the OP-1
shell (keys, knobs, screen, USB MIDI). The model and every note belong to TE's Seq thread: keys, knobs and incoming
MIDI are queued to it, so the OP-1's keys and the computer's can play together.

The OP-1's keyboard starts on F like the FM-1's, so CoralFlower's layout fits as is: its 11 upper keys become the
OP-1's 10 black keys, its 16 roots the OP-1's 14 white keys. The 11th button (HOLD) moves to **T4**.

## Turn it on

The keys are named as printed on the OP-1. **drop** is the middle of lift / drop / split (TE's code calls it
"insert"). The [top-level README](../README.md#playing-it) has the same in pictures.

**Shift + drop** (synth mode): on, the panel opens. Shift + drop again with the panel closed opens it; with the
panel showing it turns CoralOP **off**. **Drop** while the panel shows pins it (no 5 s timeout; drop again unpins and
closes it). T1–T3 open the panel on their page.

While on, the 24 note keys belong to CoralOP (TE plays nothing of its own) and T1–T4 are CoralOP's. Everything else
stays TE's: the octave arrows (they set CoralFlower's octave), the synth's sound, tape, mixer. Drum playmode and
the sequencer's screen are untouched (the keys program TE's sequencers there as usual). Turn CoralOP off to use T1–T4 for TE's synth pages again.

## Playing (Top + Lock, the default)

- **Black keys = chord buttons**, CoralFlower's default set: `M6 M7 M9 | s2 s4 | m6 m7 m9 | M m`. Tap one and it
  latches; tap several together and they combine (M + M7 = Maj7, M6 + M9 = 6/9). Tap the latched one alone to
  unlatch: the white keys then play single notes.
- **White keys = roots.** With Quantize Basic/Full they are the key's scale degrees, the tonic on C
  (F G A B **C** D E … reads IV V vi vii° **I** ii iii … in C major); Quantize Off: chromatic.
- **T4 = HOLD**: roots keep sounding after you let go; a new root alone replaces them, one with others held joins.
- RETRIG **Wait** (default): a chord button under a held root changes the chord on the next root (or with a root
  pressed within 50 ms). **Notes**: the chord moves under the held root, only the tones that change strike.
  **Chord**: the whole new chord strikes.

Side and Side + Lock work as on CoralFlower: upper F# G# A# = `M m d`, lower F G A B = `s2 s4 7 9`, the rest are
roots as a piano. Side has no HOLD.

## Pages (knobs while the panel shows)

| page | blue | green | white | orange |
|---|---|---|---|---|
| **T1 PLAY** | QUANTIZE Off / Basic / Full | KEY C … B | SCALE (27) | LAYOUT Top Lock / Top / Side Lock / Side |
| **T2 CHORD** (the last chord button pressed) | TYPE | ADD (19 combinations) | INVERSION Auto, 0–3 | BASS DEGREE |
| **T3 BASS** | BASS On / Off | OCTAVE −2…+2 | OCTAVER | RETRIG Wait / Notes / Chord |
| **T3 again: MIDI** | CHORD CH 1–16 / Off | BASS CH 1–16 / Off | LOCAL On / Off | VELOCITY |

The panel draws the keyboard with each black key's chord label and each white key's degree; latched buttons light
coral, sounding roots green. With the panel closed a badge top right shows `CF` and the last chord's name.

## MIDI

Chord notes go out on **channel 1**, the bass on **channel 2** (USB MIDI, the OP-1's only MIDI), as note on / off
with a fixed velocity (the OP-1's keys have none). They are sent with R246's `usbmidi_tx_enqueue` (`0x019E0D18`,
found by op1r), not through TE's keyboard echo, so the two parts can have their own channels. CoralOP sends all
notes off (CC 123) on both channels when it is turned off or the routing changes.

With **LOCAL** on, the same notes also play the OP-1's current synth sound (6 voices: a big chord plus bass can
steal). TE's own engines are the safe choice for LOCAL: the SDK's MONO 3, WHEEL and STATION 1 watch the physical
keys for their envelopes and voice order, which CoralOP's chords do not follow.

## Remote control (channel 16)

A computer can drive CoralOP over USB MIDI channel 16: notes 53–76 are the 24 keys, 78 is HOLD, CCs set every
value on the pages, and CoralOP sends its state and the chord name back. While CoralOP is off, only CC 20 (enable)
and CC 110 (send state) are taken; the rest of channel 16 stays TE's. The protocol, the plugdata / Pd / Max panels,
FL Studio routing and the guitar fretboard are in [`../remote/README.md`](../remote/README.md).

## Settings

RAM only: after a boot CoralOP is off, Top + Lock, Quantize Basic, C major, RETRIG Wait, bass on, channels 1 / 2,
LOCAL on, velocity 100.

## Tests

1. `test_co_play.c` (host, with CoralFlower's model compiled in): the OP-1's key roles, latching, Wait / Notes /
   Chord, combining, bass and octaver, HOLD, Quantize Full in a mode, Side, reset, and 200,000 random key events
   across every layout and setting with no stuck or doubled note.
2. `sim/run_cotest.py` (Blackfin simulator, TE stubbed): off = stock, shift + drop, a latched chord on channel 1
   with its bass on channel 2 and on the voices, combining, HOLD on T4, the MIDI page (channel, LOCAL), drum
   playmode and the sequencer's screen left to TE, off with a chord held (balanced note-offs, the held key's release swallowed), the USB-MIDI
   packet format; the remote (off: only CC 20 / 110 taken; the host's notes as keys, OP-1 and host keys together,
   settings and their echo, HOLD, panic); screenshots of the PLAY and CHORD pages.
4. `screens/`: the panel drawn on a PC from this code (`render.py`: the README's screen images; `host.c` runs in
   `scripts/test.sh`).
3. `test_co_remote.c` (host): every parameter's range and wire form, knob steps, the feedback (only changes, the name
   never cut), ASCII chord names. `../remote/tests/run_tests.sh`: the Pd patches, the Max core, the fretboard.

## Device test

1. Shift + drop; tap the `M` black key (C#, upper octave), play white keys: triads in C major on MIDI ch 1, the
   bass on ch 2 (check with a MIDI monitor on the computer).
2. Hold `M` and `M7` together, release, play: maj7 chords. T4, play, let go: HOLD.
3. T1: KEY / SCALE / QUANTIZE Full; T2: edit a button; T3 twice: channels, LOCAL off.
4. Octave arrows: chords move by octaves. Drum key: drums play as usual.
5. Shift + drop with the panel showing: off, nothing hangs on the synth or the MIDI side.

## Credits and licence

GPL-3.0-only (`LICENSE`), as CoralFlower. CoralFlower by FicusFicusov, a fork of ChoralRoot FM-1 by Quixotic7, a
fork of Felucca by Leo Kuroshita (Hügelton Instruments). The OP-1 shell follows CHORD+'s structure in op1-sdk
(MIT); the USB-MIDI send address comes from op1r by pcppcp (GPL-3.0). Orchid is a product of Telepathic
Instruments; OP-1 is teenage engineering's. CoralOP is not affiliated with any of them.
