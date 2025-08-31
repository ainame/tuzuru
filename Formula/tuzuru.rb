class Tuzuru < Formula
  desc "Static site generator for Swift developers"
  homepage "https://github.com/ainame/Tuzuru"
  url "https://github.com/ainame/Tuzuru/releases/download/0.0.2/tuzuru-0.0.2-macos-universal.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license "MIT"
  head "https://github.com/ainame/Tuzuru.git", branch: "main"

  depends_on :macos

  def install
    bin.install "tuzuru"
  end

  test do
    system "#{bin}/tuzuru", "--help"
  end
end