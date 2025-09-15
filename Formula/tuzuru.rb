class Tuzuru < Formula
  desc "Simple static blog generator"
  homepage "https://github.com/ainame/Tuzuru"
  url "https://github.com/ainame/Tuzuru/archive/refs/tags/0.3.0.tar.gz"
  sha256 "8e1330be2c98f3d01c892a874162437d88147c8f499b4144a517f11ee964cd3d"
  license "MIT"
  head "https://github.com/ainame/Tuzuru.git", branch: "main"

  depends_on :macos

  def install
    # Install the binary in libexec instead of bin
    libexec.install "tuzuru"

    # Install bundle resources in pkgshare
    pkgshare.install "tuzuru_TuzuruLib.bundle"

    # Create wrapper script in bin that sets TUZURU_RESOURCES environment variable
    (bin/"tuzuru").write_env_script libexec/"tuzuru", TUZURU_RESOURCES: pkgshare
  end

  test do
    system "#{bin}/tuzuru", "--help"
  end
end
