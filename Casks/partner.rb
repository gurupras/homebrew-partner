# Partner — the macOS app and service (Homebrew Cask template).
#
# THIS IS A TEMPLATE. packaging/homebrew/publish-tap.sh substitutes the URL,
# SHA256 and VERSION placeholders below and commits the result to the official
# tap, after checking that the installer it names is already published.
#
# SCOPE: this is the full Partner, the same thing the .deb/.rpm/.pkg.tar.zst
# packages and the Windows installer give you: the graphical app AND the
# service. It installs the signed, notarized .pkg from the download page, byte
# for byte; there is no Homebrew-specific build. The headless daemon on its own
# is the `partnerd` formula in the same tap.
#
# UPDATES: the .pkg updates itself (feature 009), so this cask says
# `auto_updates true` and `brew upgrade` leaves it alone instead of fighting the
# updater for /Applications/Partner.app. `brew upgrade --greedy` reinstalls the
# current .pkg, which is harmless.
cask "partner" do
  version "0.6.11"
  sha256 "6a2f43841e2668b725728332476cba1db68d6c191d6e215eb8d5c26f172898b5"

  url "https://partner.gurupras.me/download/#{version}/Partner-#{version}-darwin-arm64.pkg"
  name "Partner"
  desc "Remote desktop app and service"
  homepage "https://partner.gurupras.me/"

  livecheck do
    url "https://partner.gurupras.me/download/latest.json"
    strategy :json do |json|
      json["version"]
    end
  end

  # The .pkg updates itself.
  auto_updates true
  # The release ships for Apple Silicon only, and its codec libraries are built
  # on Sequoia, so refuse anything else up front.
  depends_on arch: :arm64
  depends_on macos: :sequoia

  pkg "Partner-#{version}-darwin-arm64.pkg"

  # The pkg receipt covers the app, /Library/PrivilegedHelperTools/partnerd and
  # the /usr/local/bin link. The launchd plist is NOT in the receipt: the app
  # writes it when the user turns unattended access on, so remove it by hand.
  uninstall launchctl: "xyz.partner.partnerd",
            quit:      "xyz.partner.partnerController",
            pkgutil:   "xyz.partner.partnerd",
            delete:    [
              "/etc/partner/install-kind",
              "/etc/partner/install-origin",
              "/Library/LaunchDaemons/xyz.partner.partnerd.plist",
            ]

  zap trash: [
    "~/Library/Application Support/xyz.partner.partnerController",
    "~/Library/Caches/xyz.partner.partnerController",
    "~/Library/Preferences/xyz.partner.partnerController.plist",
  ]

  caveats <<~EOS
    Partner does not run as a service until you ask it to: open the app and turn
    on unattended access (one administrator prompt).

    The app updates itself. To remove everything, including the service:
      brew uninstall --cask partner
  EOS
end
