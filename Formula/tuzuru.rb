class Tuzuru < Formula
  desc "Simple static blog generator"
  homepage "https://github.com/ainame/Tuzuru"
  url "https://github.com/ainame/tuzuru/archive/refs/tags/0.4.0.tar.gz"
  version "0.3.4"
  sha256 "2ae9df86d6212897e12aba48219d1858aecdbf544d8e1119eb239523c363c711"
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
