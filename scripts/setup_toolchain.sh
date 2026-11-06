#!/usr/bin/env bash
# The bfin-elf toolchain (binutils, GCC, GDB + Blackfin simulator) into sdk/toolchain/bfin.
#   macOS: op1-sdk's own setup_toolchain.sh (Homebrew)
#   Linux / WSL: the same GNU releases and checksums, built here (needs: build-essential libgmp-dev
#                libmpfr-dev libmpc-dev zlib1g-dev texinfo flex bison xz-utils curl)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
"$ROOT/scripts/link_sdk.sh" >/dev/null
SDK="$ROOT/sdk"
if [[ "$(uname)" == Darwin ]]; then exec "$SDK/setup_toolchain.sh" "$@"; fi

TC="$SDK/toolchain"; SRC="$TC/src"; PREFIX="$TC/bfin"
JOBS="$(nproc 2>/dev/null || echo 4)"
declare -A URL=(
  [binutils-2.43.1]=https://ftp.gnu.org/gnu/binutils/binutils-2.43.1.tar.xz
  [gcc-14.2.0]=https://ftp.gnu.org/gnu/gcc/gcc-14.2.0/gcc-14.2.0.tar.xz
  [gdb-16.3]=https://ftp.gnu.org/gnu/gdb/gdb-16.3.tar.xz
)
declare -A SHA=(   # (op1-sdk's pins)
  [binutils-2.43.1]=13f74202a3c4c51118b797a39ea4200d3f6cfbe224da6d1d95bb938480132dfd
  [gcc-14.2.0]=a7b39bc69cbf9e25826c5a60ab26477001f7c08d85cec04bc0e29cabed6f3cc9
  [gdb-16.3]=bcfcd095528a987917acf9fff3f1672181694926cc18d609c99d0042c00224c5
)
say() { printf '\n==> %s\n' "$*"; }
mkdir -p "$SRC"
for pkg in binutils-2.43.1 gcc-14.2.0 gdb-16.3; do
  t="$SRC/$pkg.tar.xz"
  [[ -f "$t" ]] || { say "downloading $pkg"; curl -fL --retry 3 -o "$t.part" "${URL[$pkg]}"; mv "$t.part" "$t"; }
  [[ "$(sha256sum "$t" | cut -d' ' -f1)" == "${SHA[$pkg]}" ]] || { echo "$t: sha256 mismatch" >&2; exit 1; }
  [[ -d "$SRC/$pkg" ]] || tar -xJf "$t" -C "$SRC"
done
MK=(make MAKEINFO=true)
export PATH="$PREFIX/bin:$PATH"
if [[ ! -x "$PREFIX/bin/bfin-elf-ld" ]]; then
  say "binutils"; mkdir -p "$TC/build" && cd "$TC/build"
  "$SRC/binutils-2.43.1/configure" --target=bfin-elf --prefix="$PREFIX" --disable-nls --disable-werror \
    --disable-gdb --disable-gdbserver --disable-gprofng --disable-sim --with-system-zlib --without-zstd
  "${MK[@]}" -j"$JOBS" all-binutils all-gas all-ld && "${MK[@]}" install-binutils install-gas install-ld
fi
if [[ -z "$(find "$PREFIX/lib/gcc/bfin-elf" -name libgcc.a 2>/dev/null)" ]]; then
  say "gcc (the long one)"; mkdir -p "$TC/build-gcc" && cd "$TC/build-gcc"
  [[ -f Makefile ]] || "$SRC/gcc-14.2.0/configure" --target=bfin-elf --prefix="$PREFIX" --enable-languages=c \
    --disable-nls --disable-werror --disable-multilib --disable-shared --disable-threads --disable-lto \
    --disable-plugin --disable-libssp --disable-libquadmath --disable-libgomp --disable-libatomic \
    --without-headers --with-newlib --with-system-zlib --without-zstd
  "${MK[@]}" -j"$JOBS" all-gcc && "${MK[@]}" install-gcc
  "${MK[@]}" -j"$JOBS" all-target-libgcc && "${MK[@]}" install-target-libgcc
fi
if [[ ! -x "$PREFIX/bin/bfin-elf-run" || ! -x "$PREFIX/bin/bfin-elf-gdb" ]]; then
  say "gdb + simulator (simulator at -O0)"; mkdir -p "$TC/build-gdb" && cd "$TC/build-gdb"
  [[ -f Makefile ]] || "$SRC/gdb-16.3/configure" --target=bfin-elf --prefix="$PREFIX" --disable-nls \
    --disable-werror --with-system-zlib --without-zstd --disable-binutils --disable-ld --disable-gas \
    --disable-gprof --disable-gprofng --without-python --without-guile --disable-tui --with-expat=no
  "${MK[@]}" -j"$JOBS" CFLAGS="-g -O0" all-sim && "${MK[@]}" install-sim
  "${MK[@]}" -j"$JOBS" all-gdb && "${MK[@]}" install-gdb
fi
for t in as ld gcc objcopy objdump nm run gdb; do [[ -x "$PREFIX/bin/bfin-elf-$t" ]] || { echo "missing bfin-elf-$t" >&2; exit 1; }; done
say "toolchain ready: $PREFIX"
