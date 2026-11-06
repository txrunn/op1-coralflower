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
"$ROOT/remote/tests/run_tests.sh"
if [[ "${1:-}" == "--bench" ]]; then
  "$ROOT/scripts/link_sdk.sh" >/dev/null
  cd "$ROOT/sdk"
  python3 tools/features.py check coralop
  OP1_SDK="$ROOT/sdk" python3 features/coralop/sim/run_cotest.py
fi
