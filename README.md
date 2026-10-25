# jeradesign/sgdk-tools

A Homebrew tap with one formula, `sgdk-tools`: everything [SGDK](https://github.com/Stephane-D/SGDK) (Sega Mega Drive / Genesis development) needs on a Mac, apart from Java.

## What's in it

| Tool | Needed for |
|---|---|
| `m68k-elf-gcc` (GCC 13.4, C and LTO) | Compiling SGDK and your game for the 68000. It uses Homebrew's `m68k-elf-binutils`. |
| `sjasm` | Z80 assembler: builds the sound drivers in `libmd.a`, and any project `.s80` files |
| `bintos` | Converts the assembled Z80 binaries into 68000 source to link in |
| `xgmtool` | Converts XGM/VGM music in `XGM` resources (called by `rescomp`) |

SGDK only ships the last three as Windows `.exe` files; these are built from SGDK's own `tools/` sources.

**Why GCC 13:** Homebrew's own `m68k-elf-gcc` is GCC 16, and GCC 16 miscompiles SGDK's `Z80_upload()` at `-O3`. The Z80 sound driver ends up one byte off in Z80 RAM, so ROMs have no sound. SGDK's official toolchain is GCC 13.

## Install

```sh
brew uninstall m68k-elf-gcc        # if installed; both provide m68k-elf-gcc
brew install jeradesign/sgdk-tools/sgdk-tools
brew install openjdk               # rescomp and sizebnd need Java; follow its caveats
```

The tools are linked into Homebrew's `bin`, so SGDK's makefiles find them with no PATH changes. If you need GCC 16 as well, build GCC 13 by hand into its own prefix instead.

## After installing

Link `xgmtool` into your SGDK checkout, because `rescomp` only looks for it next to `rescomp.jar`:

```sh
ln -sf "$(brew --prefix)/bin/xgmtool" "$SGDK/bin/xgmtool"
```

`libmd.a` contains LTO data, which only the GCC version that wrote it can read. Rebuild SGDK's library once:

```sh
cd $SGDK
make -f makelib.gen clean && make -f makelib.gen
```

Then build projects as usual with `make -f $SGDK/makefile.gen`.

## Versions

The formula's version is the GCC version. The SGDK tools are pinned to a specific SGDK commit; updating them bumps the formula's `revision`.
