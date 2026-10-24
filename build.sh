#!/bin/sh
# Builds the pinned LLVM for this host, RISC-V only, and packages what a guest build
# needs: clang, lld, llvm-objcopy, llvm-nm and clang's own headers.
#
#   ./build.sh <work directory>
#
# Leaves dist/tankbots-llvm-<version>-<host>.tar.xz and its .sha256 beside this script.
# <host> is `uname -s`-`uname -m`, except on macOS, where the build is universal (arm64
# and x86_64 in one binary) and the host is Darwin-universal, and on Windows, where it is
# Windows-x86_64 and the archive is a .zip, because that is what Explorer opens.
#
# On Windows it runs under Git Bash, with the Visual Studio compiler already on PATH (a
# Developer Command Prompt's environment, which vcvars64.bat sets).
set -eu

here=$(cd "$(dirname "$0")" && pwd)
work=${1:?usage: ./build.sh <work directory>}
mkdir -p "$work"
work=$(cd "$work" && pwd)

version=$(jq -r .llvm "$here/pin.json")
source=$(jq -r .source "$here/pin.json")
sum=$(jq -r .sha256 "$here/pin.json")

case "$(uname -s)" in
Darwin)
  host=Darwin-universal
  platform="-DCMAKE_OSX_ARCHITECTURES=arm64;x86_64 -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0"
  sha256="shasum -a 256"
  ;;
Linux)
  host="Linux-$(uname -m)"
  # libstdc++ inside the binaries, so they run on any glibc at least as new as the
  # runner's, with no C++ runtime of the same age to go looking for.
  platform="-DLLVM_STATIC_LINK_CXX_STDLIB=ON"
  sha256="sha256sum"
  ;;
MINGW* | MSYS*)
  host=Windows-x86_64
  # The C runtime inside the binaries, so a player needs no Visual C++ redistributable.
  # cl by name, because Git Bash puts a gcc of its own on PATH ahead of it.
  platform="-DCMAKE_C_COMPILER=cl -DCMAKE_CXX_COMPILER=cl -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded"
  sha256="sha256sum"
  ;;
*)
  echo "no build for $(uname -s)" >&2
  exit 1
  ;;
esac
name="tankbots-llvm-$version-$host"

# The source, checked against the pin before a byte of it is unpacked.
tarball="$work/$(basename "$source")"
[ -f "$tarball" ] || curl -fsSL -o "$tarball" "$source"
echo "$sum  $tarball" | $sha256 -c -
rm -rf "$work/src"
mkdir "$work/src"
# Less the two folders that hold symlinks, which Git Bash's tar cannot make on Windows and
# fails over: clang's test inputs and mlgo-utils, neither of which this build reads.
tar -xJf "$tarball" -C "$work/src" --strip-components=1 \
  --exclude='*/clang/test' --exclude='*/llvm/utils/mlgo-utils'

# One target, two projects, and nothing the binaries would have to find at run time:
# no zlib, zstd, libxml2 or libedit, so the archive is the whole of what they load.
# `$platform` is word split on purpose.
# shellcheck disable=SC2086
cmake -G Ninja -S "$work/src/llvm" -B "$work/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$work/stage/$name" \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_TARGETS_TO_BUILD=RISCV \
  -DLLVM_DEFAULT_TARGET_TRIPLE=riscv32-unknown-elf \
  -DLLVM_DISTRIBUTION_COMPONENTS="clang;clang-resource-headers;lld;llvm-objcopy;llvm-nm" \
  -DLLVM_PARALLEL_LINK_JOBS=1 \
  -DLLVM_ENABLE_ASSERTIONS=OFF \
  -DLLVM_ENABLE_ZLIB=OFF \
  -DLLVM_ENABLE_ZSTD=OFF \
  -DLLVM_ENABLE_LIBXML2=OFF \
  -DLLVM_ENABLE_LIBEDIT=OFF \
  -DLLVM_ENABLE_LIBPFM=OFF \
  -DLLVM_INCLUDE_TESTS=OFF \
  -DLLVM_INCLUDE_EXAMPLES=OFF \
  -DLLVM_INCLUDE_BENCHMARKS=OFF \
  -DLLVM_INCLUDE_DOCS=OFF \
  -DCLANG_ENABLE_STATIC_ANALYZER=OFF \
  $platform

rm -rf "$work/stage"
ninja -C "$work/build" install-distribution-stripped
cp "$work/src/llvm/LICENSE.TXT" "$work/stage/$name/"
echo "$version" >"$work/stage/$name/version"

"$here/test/run.sh" "$work/stage/$name"

mkdir -p "$here/dist"
case "$host" in
Windows-*)
  archive="$name.zip"
  rm -f "$here/dist/$archive"
  (cd "$work/stage" && 7z a -tzip -bd "$here/dist/$archive" "$name" >/dev/null)
  ;;
*)
  archive="$name.tar.xz"
  tar -cJf "$here/dist/$archive" -C "$work/stage" "$name"
  ;;
esac
(cd "$here/dist" && $sha256 "$archive" >"$archive.sha256")
cat "$here/dist/$archive.sha256"
