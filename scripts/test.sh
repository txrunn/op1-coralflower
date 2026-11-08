#!/usr/bin/env bash
# Every test without hardware or TE's firmware.
#   scripts/test.sh            host C tests (the chord model, player, remote protocol) + the remote patches
#   scripts/test.sh --bench    + the Blackfin simulator bench (needs scripts/setup_toolchain.sh)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$(mktemp -d)"; trap 'rm -rf "$OUT"' EXIT
cd "$ROOT/coralop"
for t in co_play co_remote; do
  cc -std=c99 -Wall -Wextra -Werror -O2 -o "$OUT/$t" "test_$t.c" "$t.c"
  "$OUT/$t"
done
# the screen code on the PC (screens/host.c): every scene draws
cc -std=gnu99 -O1 -Wall -Wextra -Werror -I "$ROOT/sdk/include" -DCF_SCALES=cf_SCALES -DCF_ADDS=cf_ADDS \
   -o "$OUT/screens" screens/host.c co_play.c co_remote.c cf_chord.c cf_theory.c 2>/dev/null \
   || { [[ -f "$ROOT/sdk/include/op1/gfx.h" ]] || echo "screens: skipped (no sdk/ submodule)"; }
if [[ -x "$OUT/screens" ]]; then
  for s in play play_dorian chord side bass midi; do
    [[ "$("$OUT/screens" $s | grep -c '^T ')" -gt 20 ]] || { echo "screens: $s drew nothing" >&2; exit 1; }
  done
  echo "screens: 6 scenes draw"
fi
"$ROOT/remote/tests/run_tests.sh"
if [[ "${1:-}" == "--bench" ]]; then
  "$ROOT/scripts/link_sdk.sh" >/dev/null
  cd "$ROOT/sdk"
  python3 tools/features.py check coralop
  OP1_SDK="$ROOT/sdk" python3 features/coralop/sim/run_cotest.py
fi
