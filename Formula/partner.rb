# Partner — macOS command-line/server distribution (Homebrew formula template).
#
# THIS IS A TEMPLATE. packaging/homebrew/publish-tap.sh substitutes the URL,
# SHA256 and VERSION placeholders below from the values that
# tooling/ci/macos/build-homebrew-archive.sh emits, then commits the result to
# the official tap. (This comment avoids writing a placeholder token verbatim:
# publish-tap.sh refuses to publish a formula in which any remains.) It is kept in
# this repository so the formula is reviewed and tested alongside the code it
# installs, rather than being hand-edited in the tap.
#
# SCOPE (FR-009): this formula installs the headless `partnerd` daemon — the
# command-line/server distribution. It is NOT the graphical Partner app, and a
# Cask for that will not exist until the GUI has its own signing and
# notarization path. Homebrew is not a way to route around that.
#
# TRUST: the archive is pinned by URL and SHA-256. The URL is immutable (it
# names an exact version, never `latest`), so the checksum below stays valid
# for the lifetime of this revision. The archive itself is Developer ID
# Application-signed and notarized before it is ever published.
class Partner < Formula
  desc "Partner remote-desktop host daemon (command-line/server distribution)"
  homepage "https://partner.gurupras.me"
  url "https://partner.gurupras.me/download/0.6.0/partner-0.6.0-darwin-arm64.tar.gz"
  sha256 "617edb29b6e97f9ab43a3e334165bf4c978f6332fe0bef0b3fe75b89bd48b1f6"
  version "0.6.0"
  license :cannot_represent

  # The published archive is built for Apple Silicon only. Declaring it keeps
  # `brew install` on an Intel Mac from downloading an arm64 binary and failing
  # at exec time with something unhelpful.
  depends_on arch: :arm64
  # The codec libraries are linked statically from Sequoia-built archives, so
  # the binary requires macOS 15 or newer. Declaring it makes brew refuse an
  # older Mac up front instead of installing a binary that will not launch.
  depends_on macos: :sequoia

  def install
    bin.install "bin/partnerd"
    # Notices for the codec libraries statically linked into partnerd.
    prefix.install "licenses" if File.directory?("licenses")
    (prefix/"VERSION").write("0.6.0\n") if File.exist?("VERSION")
  end

  # `brew services start partner` runs the daemon under the invoking user.
  #
  # It is deliberately NOT started on install and NOT run as root: unattended
  # reachability is opt-in (feature 008), and the user-level launchd job here
  # is the attended, unprivileged shape of that. The system-wide root daemon
  # remains the .pkg installer's job.
  service do
    run [opt_bin/"partnerd", "run"]
    keep_alive true
    run_type :immediate
    log_path var/"log/partnerd.log"
    error_log_path var/"log/partnerd.err.log"
  end

  def caveats
    <<~EOS
      This formula installs the Partner command-line/server daemon only.
      It is not the graphical Partner app; Homebrew does not distribute an
      unsigned or unnotarized macOS application.

      Partner does not start automatically. To enable unattended access:
        brew services start partner

      Upgrades are managed by Homebrew:
        brew update && brew upgrade partner
      Partner's own self-update is disabled for this installation so that it
      never writes over files Homebrew owns.
    EOS
  end

  test do
    # `partnerd version`, not `--version`. There is no --version flag: main.go
    # dispatches subcommands and anything unrecognised falls through to
    # usage() + exit 2, so this assertion failed on every genuine release
    # archive. It only ever "passed" against the harness's shell stub.
    assert_match "0.6.0", shell_output("#{bin}/partnerd version 2>&1")
  end
end
