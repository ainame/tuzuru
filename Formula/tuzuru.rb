class Tuzuru < Formula
  desc "Simple static blog generator"
  homepage "https://github.com/ainame/Tuzuru"
  url "https://github.com/ainame/Tuzuru/releases/download/0.3.0/tuzuru-0.3.0-macos-universal.tar.gz"
  sha256 "d68bb12d755361e9b1fd14ebacdd6695ccf4e3b6bcba39ba8fdbe3be845d8093"
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
