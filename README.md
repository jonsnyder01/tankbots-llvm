# tankbots-llvm

LLVM built for one target, RISC-V, for [tankbots](https://github.com/jonsnyder01/tankbots4) to
compile its guest programs with. Each release is one pinned LLVM version, built from the
official source by this repository's CI, for:

| Archive | Runs on |
|---|---|
| `tankbots-llvm-<version>-Darwin-universal.tar.xz` | macOS 11 and later, Apple Silicon and Intel |
| `tankbots-llvm-<version>-Linux-x86_64.tar.xz` | Linux x86_64, glibc 2.35 and later |
| `tankbots-llvm-<version>-Linux-aarch64.tar.xz` | Linux arm64, glibc 2.35 and later |

Each holds `bin/clang`, `bin/lld` (and `ld.lld`), `bin/llvm-objcopy`, `bin/llvm-nm`,
`lib/clang/<major>/include`, LLVM's `LICENSE.TXT`, and a `version` file. `clang` targets
`riscv32-unknown-elf` by default and can target nothing else. The binaries load nothing
from the system beyond its C library.

## Why not the official release

LLVM's own archives are a gigabyte each, build every target, and have no Intel macOS
build. These are a fraction of the size and run on every Mac.

## Releasing

1. Change `pin.json` to the new version's source tarball and its sha256 (the release
   page lists a digest for each asset).
2. Open a pull request; CI builds and tests all three. A universal macOS build takes a
   few hours.
3. Merge, then tag `main` with `<version>-1` and push the tag. CI builds again and
   publishes the archives and `SHA256SUMS` as a release under that tag.

A rebuild of the same LLVM, because something here changed, is the next revision:
`23.1.4-2`.

## Building locally

    ./build.sh /tmp/llvm-work

Needs CMake, Ninja, jq, curl and a C++ compiler. `test/run.sh <unpacked archive>` is the
check CI runs on what it built.

## License

The archives are LLVM, under the Apache License 2.0 with LLVM Exceptions; each carries
`LICENSE.TXT`.
