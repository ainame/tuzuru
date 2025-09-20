class Tuzuru < Formula
  desc "Simple static blog generator"
  homepage "https://github.com/ainame/Tuzuru"
  url "https://github.com/ainame/tuzuru/releases/download/0.3.5-test/tuzuru-0.3.5-test-macos-universal.tar.gz"
  version "0.3.5-test"
  sha256 "a01b594abb28eed7e7bede827b7ebdd7572a0047fd042a8a44394b962138377b"
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
