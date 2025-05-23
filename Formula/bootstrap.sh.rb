class BootstrapSh < Formula
  desc "ade's bootstrap script. aka the bootrap.sh build system. have fun."
  homepage "https://github.com/adelynnmckay/bootstrap.sh"
  license "MIT"
  sha256 "7f8a8292ee54e99e1705ed0448ad48e453eeef513c06d5ec93fe4d3e14933ff6"
  url "https://github.com/adelynnmckay/bootstrap.sh/archive/refs/tags/v0.0.13.tar.gz"
  version "0.0.13"

  def install
    bin.install "bootstrap.sh" => "bootstrap.sh"
  end

  test do
    system "#{bin}/bootstrap", "--help"
  end
end
