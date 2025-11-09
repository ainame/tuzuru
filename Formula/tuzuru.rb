class Tuzuru < Formula
  desc "Simple static blog generator"
  homepage "https://github.com/ainame/Tuzuru"
  url "https://github.com/ainame/tuzuru/archive/refs/tags/0.5.0.tar.gz"
  version "0.4.0"
  sha256 "ba924e0927e4700ac9bfe708b24f56287a2e4e32ab881d6ee13c4e533b5ea0d0"
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
