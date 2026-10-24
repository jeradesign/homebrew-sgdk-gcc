class M68kElfGccAT13 < Formula
  desc "GNU compiler collection m68k-elf (GCC 13, for SGDK)"
  homepage "https://gcc.gnu.org"
  url "https://ftpmirror.gnu.org/gcc/gcc-13.4.0/gcc-13.4.0.tar.xz"
  mirror "https://ftp.gnu.org/gnu/gcc/gcc-13.4.0/gcc-13.4.0.tar.xz"
  sha256 "9c4ce6dbb040568fdc545588ac03c5cbc95a8dbf0c7aa490170843afb59ca8f5"
  license "GPL-3.0-or-later" => { with: "GCC-exception-3.1" }

  livecheck do
    url "https://ftpmirror.gnu.org/gcc/"
    regex(%r{href=["']?gcc[._-]v?(13(?:\.\d+)+)/?["' >]}i)
  end

  bottle do
    root_url "https://github.com/jeradesign/homebrew-sgdk-gcc/releases/download/m68k-elf-gcc@13-13.4.0"
    rebuild 1
    sha256 arm64_tahoe:  "03f6f252c5c562a55bb9d4b9a0c57b87a7acb5a8929ba83dc3d5d8cc1082f9e3"
    sha256 x86_64_linux: "ff1f1c042d305c51046fa63429be104c95bd5e26a1a582dd70156b6e87598348"
  end

  depends_on "gmp"
  depends_on "isl"
  depends_on "libmpc"
  depends_on "m68k-elf-binutils"
  depends_on "mpfr"
  depends_on "zstd"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    target = "m68k-elf"
    mkdir "m68k-elf-build" do
      system "../configure", "--target=#{target}",
                             "--prefix=#{prefix}",
                             "--infodir=#{info}/#{target}",
                             "--disable-nls",
                             "--without-headers",
                             "--with-as=#{formula_opt_bin("m68k-elf-binutils")}/m68k-elf-as",
                             "--with-ld=#{formula_opt_bin("m68k-elf-binutils")}/m68k-elf-ld",
                             "--enable-languages=c,lto",
                             "--enable-lto",
                             "--with-gmp=#{formula_opt_prefix("gmp")}",
                             "--with-mpfr=#{formula_opt_prefix("mpfr")}",
                             "--with-mpc=#{formula_opt_prefix("libmpc")}",
                             "--with-isl=#{formula_opt_prefix("isl")}",
                             "--with-zstd=#{formula_opt_prefix("zstd")}",
                             "--with-system-zlib",
                             *std_configure_args
      system "make", "all-gcc"
      system "make", "install-gcc"
      system "make", "all-target-libgcc"
      system "make", "install-target-libgcc"

      # FSF-related man pages may conflict with native gcc
      rm_r(share/"man/man7")
    end
  end

  # Deliberately linked (not keg-only): SGDK finds m68k-elf-gcc on PATH.
  # GCC 16 miscompiles SGDK's Z80_upload (no sound), so this replaces it.
  def caveats
    <<~EOS
      This formula installs m68k-elf-gcc into Homebrew's bin directory, so it
      can't be linked while Homebrew's m68k-elf-gcc (GCC 16) is linked. Run
        brew uninstall m68k-elf-gcc
      (or `brew unlink m68k-elf-gcc`) and then `brew link m68k-elf-gcc@13`.

      After installing, rebuild SGDK's library once:
        cd $SGDK && make -f makelib.gen clean && make -f makelib.gen
    EOS
  end

  test do
    (testpath/"test-c.c").write <<~C
      int main(void)
      {
        int i=0;
        while(i<10) i++;
        return i;
      }
    C
    system bin/"m68k-elf-gcc", "-m68000", "-O3", "-flto", "-c", "-o", "test-c.o", "test-c.c"
    assert_match "file format elf32-m68k",
                 shell_output("#{formula_opt_bin("m68k-elf-binutils")}/m68k-elf-objdump -a test-c.o")
    assert_match "13.4.0", shell_output("#{bin}/m68k-elf-gcc --version")
  end
end
