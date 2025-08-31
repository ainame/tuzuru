class Tuzuru < Formula
  desc "Static site generator for Swift developers"
  homepage "https://github.com/ainame/Tuzuru"
  url "https://github.com/ainame/Tuzuru/releases/download/0.0.5/tuzuru-0.0.5-macos-universal.tar.gz"
  sha256 "539532e399d4a7629e450c6c4a1de405d359c3874874fb3e977dbdcd3772254f"
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