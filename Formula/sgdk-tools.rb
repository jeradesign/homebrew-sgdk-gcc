class SgdkTools < Formula
  desc "Native SGDK build tools: sjasm (Z80 assembler), bintos and xgmtool"
  homepage "https://github.com/Stephane-D/SGDK"
  url "https://github.com/Stephane-D/SGDK/archive/ee6870a6010b1e341ca36078f581a68a26c9a543.tar.gz"
  version "20261001"
  sha256 "a701107a206d021f8ad0d31cb8f2c51091ec9d1c68fc1a0890db57dc25fccd15"
  license all_of: ["MIT", "Zlib"]

  livecheck do
    skip "Pinned to an SGDK commit; update by hand"
  end

  depends_on "cmake" => :build

  def install
    %w[sjasm bintos xgmtool].each do |tool|
      system "cmake", "-S", "tools/#{tool}", "-B", "build-#{tool}", *std_cmake_args
      system "cmake", "--build", "build-#{tool}"
      bin.install "build-#{tool}/#{tool}"
    end
  end

  # rescomp runs xgmtool from SGDK's own bin directory, not from PATH
  def caveats
    <<~EOS
      sjasm and bintos are found on PATH. rescomp looks for xgmtool next to
      rescomp.jar, so link it into your SGDK checkout:
        ln -sf #{opt_bin}/xgmtool $SGDK/bin/xgmtool
    EOS
  end

  test do
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
