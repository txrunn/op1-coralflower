#!/usr/bin/env bash
# Put CoralOP into the op1-sdk submodule: sdk/features/coralop and sdk/recipes/coralop-*.json as symlinks.
# Idempotent; the submodule's own files are untouched (.gitmodules ignores the untracked links).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDK="$ROOT/sdk"
[[ -f "$SDK/tools/compose.py" ]] || git -C "$ROOT" submodule update --init sdk
ln -sfn ../../coralop "$SDK/features/coralop"
for r in "$ROOT"/recipes/*.json; do ln -sfn "../../recipes/$(basename "$r")" "$SDK/recipes/$(basename "$r")"; done
echo "linked coralop into $SDK"
