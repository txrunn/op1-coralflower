/* Stand-ins at TE addresses, each forwarding to the C logger in driver.c (same ABI; P1 is scratch).
 * Assembled per address by run_cotest.py with -defsym WHICH=n. */
        .section .text
        .global _stub
_stub:
.if WHICH == 0                  /* 0x01a85750 voice note-on(note*, extra) */
        P1.L = LOG_ON;  P1.H = LOG_ON;
        JUMP (P1);
.endif
.if WHICH == 1                  /* 0x01a85840 voice note-off(note*) */
        P1.L = LOG_OFF;  P1.H = LOG_OFF;
        JUMP (P1);
.endif
.if WHICH == 2                  /* 0x01a0d2c0 TE seq tick */
        RTS;
.endif
.if WHICH == 4                  /* 0x019b2674 TE frame render(buf): nothing to draw */
        RTS;
.endif
.if WHICH == 5                  /* 0x019b6c0c on_knob: real entry bytes, the hook replays them */
        LINK 0x0;
        UNLINK;
        P1.L = LOG_KNOB;  P1.H = LOG_KNOB;
        JUMP (P1);
.endif
.if WHICH == 3                  /* 0x019b6c74 on_key: real entry bytes, the hook replays them */
        LINK 0x0;
        UNLINK;
        P1.L = LOG_KEY;  P1.H = LOG_KEY;
        JUMP (P1);
.endif
.if WHICH == 6                  /* 0x019e0d18 usbmidi_tx_enqueue(cable, packets, n) */
        P1.L = LOG_MIDI;  P1.H = LOG_MIDI;
        JUMP (P1);
.endif
.if WHICH == 7                  /* 0x01a85c20 MIDI dispatcher: real entry bytes (LINK 0x10), the hook replays them */
        LINK 0x10;
        UNLINK;
        P1.L = LOG_MIDIIN;  P1.H = LOG_MIDIIN;
        JUMP (P1);
.endif
