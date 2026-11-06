#!/usr/bin/env bash
# Build a CoralOP firmware image from YOUR copy of TE's firmware (nothing of TE's is in this repo).
#   scripts/build.sh /path/to/op1_246.op1 [min|full]
#     min   stock R246 + CoralOP only (the first thing to flash)
#     full  op1-sdk's op1plus features (engines, FX, rolls) without CHORD+, + CoralOP
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FW="${1:?usage: scripts/build.sh /path/to/op1_246.op1 [min|full]}"
KIND="${2:-min}"
R246=c5315218f825f143b415ca554516541898abee843d3a236df0b54c04e1fb13a9
got="$( (sha256sum "$FW" 2>/dev/null || shasum -a 256 "$FW") | cut -d' ' -f1)"
[[ "$got" == "$R246" ]] || { echo "$FW is not TE's op1_246.op1 (sha256 $got)" >&2; exit 1; }
"$ROOT/scripts/link_sdk.sh" >/dev/null
[[ -x "$ROOT/sdk/toolchain/bfin/bin/bfin-elf-gcc" ]] || { echo "no toolchain yet: run scripts/setup_toolchain.sh" >&2; exit 1; }
cd "$ROOT/sdk"
python3 tools/compose.py "recipes/coralop-$KIND.json" "$FW"
out="build/apps/coralop-$KIND/build/coralop-$KIND.op1"
echo
echo "built: $ROOT/sdk/$out"
echo "flash: OP-1 off, hold COM while switching on, Firmware Upload, copy the file to the small 'OP-1' disk, eject"
