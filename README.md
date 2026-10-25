# tankbots-llvm

LLVM built for one target, RISC-V, for [tankbots](https://github.com/jonsnyder01/tankbots4) to
compile its guest programs with. Each release is one pinned LLVM version, built from the
official source by this repository's CI, for:

| Archive | Runs on |
|---|---|
| `tankbots-llvm-<version>-Darwin-universal.tar.xz` | macOS 11 and later, Apple Silicon and Intel |
| `tankbots-llvm-<version>-Linux-x86_64.tar.xz` | Linux x86_64, glibc 2.35 and later |
| `tankbots-llvm-<version>-Linux-aarch64.tar.xz` | Linux arm64, glibc 2.35 and later |
| `tankbots-llvm-<version>-Windows-x86_64.zip` | Windows 10 and later, x86_64 and ARM (emulated) |

Each holds `bin/clang`, `bin/ld.lld`, `bin/llvm-objcopy` and `bin/llvm-nm` (with `.exe`
on Windows), `lib/clang/<major>/include`, LLVM's `LICENSE.TXT`, and a `version` file.
`bin/` holds those four and nothing else, each a real file: no `clang++`, `clang-cl`,
`lld-link` or `wasm-ld`, which LLVM installs as extra names for the same two binaries
(on Windows, as full copies of them). `clang` targets `riscv32-unknown-elf` by default
and can target nothing else. The binaries load nothing
from the system beyond its C library.

## Why not the official release

LLVM's own archives are a gigabyte each, build every target, and have no Intel macOS
build. These are a fraction of the size and run on every Mac.

## Releasing

1. Change `pin.json` to the new version's source tarball and its sha256 (the release
   page lists a digest for each asset).
2. Open a pull request and merge it. Neither builds anything.
3. Run the `build` workflow on `main`, from the Actions tab or with
   `gh workflow run build.yml --ref main`. It names the next revision of the pinned LLVM
   itself -- `<version>-1` for a new one -- builds and tests all four, and once all four
   pass, tags `main` with it and publishes the archives and `SHA256SUMS` as a release
   under that tag. A universal macOS build takes a few hours; if one fails, nothing is
   tagged or released, so fix it and run it again.

A rebuild of the same LLVM, because something here changed, is the next revision:
`23.1.4-2`. Pushing a tag yourself still works and releases that tag, which must be
`<version>-<revision>`.

## Building locally

    ./build.sh /tmp/llvm-work

Needs CMake, Ninja, jq, curl and a C++ compiler. On Windows: Git Bash, 7-Zip, and a
Developer Command Prompt's environment for Visual Studio's compiler. `test/run.sh <unpacked archive>` is the
check CI runs on what it built.

## License

The archives are LLVM, under the Apache License 2.0 with LLVM Exceptions; each carries
`LICENSE.TXT`.
