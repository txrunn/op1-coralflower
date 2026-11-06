# op1-coralflower

**CoralOP**: [CoralFlower](https://github.com/FicusFicusov/CoralFlower)'s chord instrument (after the Telepathic
Instruments Orchid) on the original OP-1, with chords and bass out over USB MIDI, a plugdata / Pd / Max remote, and
a guitar fretboard that shows every chord on the neck in any tuning.

![The plugdata panel with the fretboard](docs/images/coralop-guitar.png)

> **Status: 0.2, experimental.** All host and Blackfin-simulator tests pass, but nothing has been played on a
> real OP-1 yet, inside plugdata in FL Studio, or in Max. Read [Safe first flash](#safe-first-flash) first.

| folder | what |
|---|---|
| [`coralop/`](coralop/README.md) | the firmware feature: how to play it, the pages, MIDI, the tests |
| [`remote/`](remote/README.md) | plugdata / Pd / Max panels, the fretboard, FL Studio setup, the channel-16 protocol |
| `recipes/` | `coralop-min` (stock R246 + CoralOP) and `coralop-full` (op1-sdk's op1plus features + CoralOP) |
| `sdk/` | [op1-sdk](https://github.com/BertBrandstifter/op1-sdk) as a submodule, pinned to `ae1945a` |
| `scripts/` | toolchain setup, build, tests |

**No firmware in this repo.** The OP-1's firmware is teenage engineering's, and so is most of every image built
from it. This repo holds only CoralOP's sources, the remote and the tests; you build the image yourself from your
own copy of `op1_246.op1`. Don't publish built `.op1` files.

## Build

Needs macOS, Linux or WSL, python3, git, and about 2 GB and 30–60 minutes once for the toolchain.

```sh
git clone --recursive https://github.com/txrunn/op1-coralflower
cd op1-coralflower
scripts/setup_toolchain.sh      # once: bfin-elf binutils, GCC, GDB + simulator into sdk/toolchain/
                                #   macOS: op1-sdk's script (Homebrew); Linux/WSL first:
                                #   sudo apt install build-essential libgmp-dev libmpfr-dev libmpc-dev \
                                #        zlib1g-dev texinfo flex bison xz-utils curl
scripts/build.sh /path/to/op1_246.op1 min    # or: full
```

`build.sh` refuses any file that isn't TE's R246 (SHA-256 `c5315218…13a9`; get it from teenage engineering's OP-1
support page) and prints the image's path. Images are reproducible: the same commit and the same R246 always give
the same bytes, so two people can compare SHA-256s.

## Safe first flash

The OP-1's bootloader (te-boot) is never modified, and that's what installs firmware. So whatever CoralOP does, the
Firmware Upload mode below still starts, and flashing your original `op1_246.op1` the same way puts you back on
stock.

1. **Keep `op1_246.op1`** somewhere you'll find it: it's your way back.
2. **Back up** your tapes and sounds: the OP-1's disk mode (COM menu), copy everything off.
3. **Flash `coralop-min` first** (stock plus CoralOP only, so anything odd is CoralOP's): OP-1 off, hold **COM**
   while switching on, choose **Firmware Upload**, copy the `.op1` onto the small disk named `OP-1`, eject. The OP-1
   shows `Found firmware package…` then `Done!`; restart. (On a Mac, `cd sdk && python3 tools/flash.py <image>
   --eject` does the copy, and refuses the wrong disk.)
4. **CoralOP off = stock.** After boot CoralOP is off: check synth, drums, tape, sequencers and USB MIDI behave as
   before.
5. **Turn it on**: shift + insert in synth playmode. Work through the [device test](coralop/README.md#device-test):
   chord buttons, roots, T4 HOLD, the T1–T3 pages, then shift + insert again to turn it off with nothing hanging.
6. **MIDI**: with a MIDI monitor on the computer, chords arrive on channel 1, the bass on 2, and CoralOP's state on
   16 once it's on.
7. **The remote**: plugdata in FL, [`remote/README.md`](remote/README.md). Click SYNC; the panel should follow
   the OP-1.
8. Then try `coralop-full` the same way.

**If anything goes wrong** (a hang, a crash at boot, odd sound): switch off, hold COM while switching on, Firmware
Upload, copy `op1_246.op1`. Please open an issue with what you did and what the screen showed.

## Tests

```sh
scripts/test.sh            # host C tests (200,000+ checks), Pd patches, Max core, fretboard (needs pd, node, lua5.4)
scripts/test.sh --bench    # + op1-sdk's feature check and the Blackfin simulator bench (needs the toolchain)
```

Neither needs TE's firmware: the bench runs CoralOP on the simulated Blackfin with TE's functions stubbed. CI runs
both on every push (the toolchain is cached after the first run).

To change the panels, edit `remote/tools/gen_pd.py` / `gen_max.py` and rerun them; CI checks the committed patches
match.

## Credits and licence

GPL-3.0-only ([`LICENSE`](LICENSE)), as CoralFlower, whose chord model `coralop/cf_*.c` is copied verbatim
(commit `272cad9`). CoralFlower is by FicusFicusov, a fork of ChoralRoot FM-1 by Quixotic7, a fork of Felucca by
Leo Kuroshita (Hügelton Instruments). op1-sdk (MIT) is by BertBrandstifter; the USB-MIDI send address comes from
op1r by pcppcp (GPL-3.0). OP-1 is teenage engineering's and Orchid is Telepathic Instruments'. This project isn't
affiliated with any of them.

OP-1 port: Tarun Gunaseelan ([@txrunn](https://github.com/txrunn)).
