#!/bin/sh
# Compiles and links test/program.c with an unpacked toolchain, the way tankbots builds a
# guest, and checks the result is rv32 code. On macOS it also checks both halves of the
# universal binary, the x86_64 half under Rosetta.
#
#   test/run.sh <unpacked toolchain>
set -eu

here=$(cd "$(dirname "$0")" && pwd)
llvm=${1:?usage: test/run.sh <unpacked toolchain>}
out=$(mktemp -d)

flags="--target=riscv32-unknown-elf -march=rv32im_zicsr -mabi=ilp32 -ffreestanding
  -nostdlib -fno-builtin -Os -Wall -Wextra -Werror"

# shellcheck disable=SC2086
"$llvm/bin/clang" $flags -fuse-ld=lld -Wl,-e,_start -o "$out/program.elf" "$here/program.c"
"$llvm/bin/llvm-objcopy" -O binary "$out/program.elf" "$out/program.bin"
"$llvm/bin/llvm-nm" "$out/program.elf" | grep -q ' T _start'
"$llvm/bin/llvm-objcopy" --version >/dev/null
"$llvm/bin/ld.lld" --version
test -f "$llvm/lib/clang/$(cut -d. -f1 "$llvm/version")/include/stdint.h"

# The ELF header says what machine the code is for: 0xf3 is RISC-V, class 1 is 32 bit.
header=$(od -An -tx1 -N20 "$out/program.elf" | tr -d ' \n')
case "$header" in
7f454c4601*) ;;
*)
  echo "not a 32 bit ELF: $header" >&2
  exit 1
  ;;
esac
[ "$(echo "$header" | cut -c37-38)" = f3 ] || {
  echo "not RISC-V: $header" >&2
  exit 1
}

if [ "$(uname -s)" = Darwin ]; then
  for binary in clang lld llvm-objcopy llvm-nm; do
    archs=$(lipo -archs "$llvm/bin/$binary")
    [ "$archs" = "x86_64 arm64" ] || [ "$archs" = "arm64 x86_64" ] || {
      echo "$binary is $archs, not universal" >&2
      exit 1
    }
  done
  arch -x86_64 "$llvm/bin/clang" --version
fi

"$llvm/bin/clang" --version
rm -rf "$out"
echo "ok: $llvm"
