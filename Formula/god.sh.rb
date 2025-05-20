class GodSh < Formula
  desc "In the beginning God created the heaven and the earth..."
  homepage "https://github.com/adelynnmckay/god.sh"
  url "https://github.com/adelynnmckay/god.sh/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "<FILL THIS IN>"
  version "1.0.0"
  license "MIT"

  def install
    bin.install "god.sh"
  end

  def caveats
    <<~EOS
      To complete installation, run:
        god.sh let-there-be-light
    EOS
  end

  test do
    system "#{bin}/god.sh", "--help"
  end
end
