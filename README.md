# jeradesign/sgdk-gcc

Homebrew formulae for [SGDK](https://github.com/Stephane-D/SGDK) (Sega Mega Drive / Genesis development) on macOS.

## m68k-elf-gcc@13

GCC 13.4 cross compiler for the 68000, with C and LTO. It uses Homebrew's `m68k-elf-binutils`.

Homebrew's own `m68k-elf-gcc` is GCC 16, and GCC 16 miscompiles SGDK's `Z80_upload()` at `-O3`. The Z80 sound driver ends up one byte off in Z80 RAM, so ROMs have no sound. SGDK's official toolchain is GCC 13.

### Install

```sh
brew uninstall m68k-elf-gcc        # if installed; both provide m68k-elf-gcc
brew install jeradesign/sgdk-gcc/m68k-elf-gcc@13
```

This formula is linked into Homebrew's `bin`, so SGDK's makefiles find it with no PATH changes. If you need GCC 16 too, build GCC 13 by hand into its own prefix instead.

### After installing

`libmd.a` contains LTO data, which only the GCC version that wrote it can read. Rebuild SGDK's library once:

```sh
cd $SGDK
make -f makelib.gen clean && make -f makelib.gen
```

Then build projects as usual with `make -f $SGDK/makefile.gen`.
