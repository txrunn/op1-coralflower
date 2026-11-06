#!/bin/bash
# CoralOP remote: the Pd patches (golden outputs), the Max core (node), the fretboard's logic (lua 5.4).
# Needs pd (vanilla 0.52+), node, lua5.4. Run from anywhere.
cd "$(dirname "$0")" || exit 1
fail=0
for t in core panel glue; do
    out=$(timeout 30 pd -nogui -noaudio -nomidi -batch -path ../pd -open test-$t.pd 2>&1)
    if [ "$out" == "$(cat expected-$t.txt)" ]; then echo "PASS  pd $t"; else echo "FAIL  pd $t"; diff <(echo "$out") expected-$t.txt | head; fail=1; fi
done
node test_max_core.js && echo "PASS  max core" || { echo "FAIL  max core"; fail=1; }
lua5.4 test_coralfret.lua && echo "PASS  coralfret" || { echo "FAIL  coralfret"; fail=1; }
exit $fail
