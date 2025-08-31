class Tuzuru < Formula
  desc "Static site generator for Swift developers"
  homepage "https://github.com/ainame/Tuzuru"
  url "https://github.com/ainame/Tuzuru/releases/download/0.0.3/tuzuru-0.0.3-macos-universal.tar.gz"
  sha256 "4089936c3fc4ce702eb9fb294b0d6ef665006ca5297c7cfeb73a23f0aced472f"
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