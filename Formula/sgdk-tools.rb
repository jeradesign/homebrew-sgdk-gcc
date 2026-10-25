class SgdkTools < Formula
  desc "Native macOS toolchain for SGDK: GCC 13 for m68k-elf, sjasm, bintos and xgmtool"
  homepage "https://github.com/Stephane-D/SGDK"
  url "https://ftpmirror.gnu.org/gcc/gcc-13.4.0/gcc-13.4.0.tar.xz"
  mirror "https://ftp.gnu.org/gnu/gcc/gcc-13.4.0/gcc-13.4.0.tar.xz"
  sha256 "9c4ce6dbb040568fdc545588ac03c5cbc95a8dbf0c7aa490170843afb59ca8f5"
  license all_of: [
    { "GPL-3.0-or-later" => { with: "GCC-exception-3.1" } },
    "MIT",
    "Zlib",
  ]
  # versions were SGDK commit dates (20261001) before GCC was merged in
  version_scheme 1

  livecheck do
    url "https://ftpmirror.gnu.org/gcc/"
    regex(%r{href=["']?gcc[._-]v?(13(?:\.\d+)+)/?["' >]}i)
  end

  bottle do
    root_url "https://github.com/jeradesign/homebrew-sgdk-tools/releases/download/sgdk-tools-13.4.0"
    sha256 arm64_tahoe: "7ad0834a1d12fcfaa7ac6888b8e7ee574d5ee212b7d3dd190048e1bc8b958324"
  end

  depends_on "cmake" => :build
  depends_on "gmp"
  depends_on "isl"
  depends_on "libmpc"
  depends_on "m68k-elf-binutils"
  depends_on :macos
  depends_on "mpfr"
  depends_on "zstd"

  uses_from_macos "zlib"

  # GCC 16 miscompiles SGDK's Z80_upload (no sound), so this provides GCC 13
  # under the plain m68k-elf-gcc name instead
  conflicts_with "m68k-elf-gcc", because: "both install m68k-elf-gcc"

  # SGDK tool sources (sjasm, bintos, xgmtool); bump `revision` when updating
  resource "sgdk" do
    url "https://github.com/Stephane-D/SGDK/archive/ee6870a6010b1e341ca36078f581a68a26c9a543.tar.gz"
    sha256 "a701107a206d021f8ad0d31cb8f2c51091ec9d1c68fc1a0890db57dc25fccd15"
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

    resource("sgdk").stage do
      %w[sjasm bintos xgmtool].each do |tool|
        system "cmake", "-S", "tools/#{tool}", "-B", "build-#{tool}", *std_cmake_args
        system "cmake", "--build", "build-#{tool}"
        bin.install "build-#{tool}/#{tool}"
      end
    end
  end

  def caveats
    <<~EOS
      rescomp looks for xgmtool next to rescomp.jar, so link it into your
      SGDK checkout:
        ln -sf #{opt_bin}/xgmtool $SGDK/bin/xgmtool

      SGDK's prebuilt lib/libmd.a contains LTO data from a different GCC
      version. Rebuild it once:
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

    (testpath/"t.s80").write <<~ASM
      \tld a,0x42
      \tret
    ASM
    system bin/"sjasm", "t.s80", "t.o80", "t.lst"
    assert_equal "\x3e\x42\xc9".b, (testpath/"t.o80").binread

    system bin/"bintos", "t.o80", "t.s"
    assert_match "dc.w    0x3E42,0xC900", (testpath/"t.s").read

    assert_match "XGMTool", shell_output("#{bin}/xgmtool 2>&1", 1)
  end
end
