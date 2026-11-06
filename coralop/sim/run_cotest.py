#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Run features/coralop in the Blackfin simulator.

    run_cotest.py           (composes coralop alone; no firmware needed)

driver.c plays TE: on_key, on_knob, the Seq tick and the frame hook, and logs what TE's voice code (stubs at
0x01a85750 / 0x01a85840) and its USB-MIDI queue (stub at 0x019e0d18) would get. Checks: off = stock, shift + insert,
a latched chord on channel 1 with its bass on channel 2 and on the voices, chord buttons combined, HOLD on T4, the
MIDI page (channel, LOCAL), drum playmode left to TE, off with a chord held, packet format; the remote on channel
16 (off: only CC 20 / 110 taken; the host's notes as keys, OP-1 + host keys together, settings and their echo, HOLD,
panic); two screenshots.
HLT = exit 0 = pass, ABORT = exit 1 = fail (R7 = failed-check bits, see driver.c)."""

import os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
SDK = os.environ.get("OP1_SDK") or os.path.normpath(os.path.join(HERE, "..", "..", ".."))
OUT = os.path.join(SDK, "build", "bench", "cotest")
os.makedirs(OUT, exist_ok=True)
sys.path.insert(0, os.path.join(SDK, "sim"))
from simtest import asm_bin, c_bin, run_model, run_gdb, composed  # noqa: E402
from build import compile_project  # noqa: E402

FEATURES, APP = ["coralop"], "cotest"
DRIVER_AT, STACK = 0x01F00000, 0x01F7FFFC
STUBS = {0x01A85750: 0, 0x01A85840: 1, 0x01A0D2C0: 2, 0x019B6C74: 3, 0x019B2674: 4, 0x019B6C0C: 5, 0x019E0D18: 6,
         0x01A85C20: 7}
FB, FB2 = 0x03000000, 0x03040000


def main():
    proj, cfg = composed(FEATURES, APP)
    code, syms, elf = compile_project(proj, cfg)
    print(f"project: {len(code)} bytes ({elf})")
    hooks = {"hook_tick": "01a431aa", "hook_key": "019b6c74", "hook_frame": "019ab8b2", "hook_knob": "019b6c0c",
             "hook_midi": "01a85c20"}
    driver, dsyms = c_bin(
        [os.path.join(HERE, "crt.S"), os.path.join(HERE, "driver.c")],
        DRIVER_AT, os.path.join(OUT, "driver"),
        {"STACK": STACK, "_FB": FB, "_FB2": FB2,
         **{s: syms[s] for s in ("_co_s", "_co_p", "_co_pinned", "_co_page")},
         **{"_" + k: syms[f"__sdk_hook_{v}"] for k, v in hooks.items()}},
    )
    segs = [(0x01E00000, code), (DRIVER_AT, driver), (FB, bytes(320 * 512)), (FB2, bytes(320 * 512))]
    for addr, which in STUBS.items():
        stub, _ = asm_bin(
            os.path.join(HERE, "te_stubs.S"), addr, os.path.join(OUT, f"stub{which}"),
            {"WHICH": which, "LOG_ON": dsyms["_log_on"], "LOG_OFF": dsyms["_log_off"],
             "LOG_KEY": dsyms["_log_key"], "LOG_KNOB": dsyms["_log_knob"], "LOG_MIDI": dsyms["_log_midi"],
             "LOG_MIDIIN": dsyms["_log_midiin"]},
            entry="_stub",
        )
        segs.append((addr, stub))
    elf_run = os.path.join(OUT, "cotest_run.elf")
    r = run_model(elf_run, segs, dsyms["_start"], timeout=180)
    print(f"model run: exit {r.returncode}")
    vals = run_gdb(elf_run, [f"/x *(unsigned*){dsyms['_fails']:#x}"],
                   shots=[("coralop_chord", FB), ("coralop_play", FB2)], timeout=180)
    if r.returncode and vals:
        print(f"failed check bits: {vals[0]}")
    print("PASS" if r.returncode == 0 else f"FAIL (exit {r.returncode}; R7 = failed check bits)")
    sys.exit(r.returncode)


if __name__ == "__main__":
    main()
