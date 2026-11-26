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
  version "0.6.13"
  sha256 "de59ce51d862be88a55803a7b1a136af6176e79b9477d45838075791c7cb0e8e"

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
  # the /usr/local/bin link. The launchd plists are NOT in the receipt: the app
  # writes them (the service and its two agents) when the user turns
  # unattended access on, so remove them by hand.
  uninstall launchctl: [
              "me.gurupras.partner.partnerd",
              "me.gurupras.partner.loginwindow",
              "me.gurupras.partner.session",
            ],
            quit:      "me.gurupras.partner.app",
            pkgutil:   "me.gurupras.partner.partnerd",
            delete:    [
              "/etc/partner/install-kind",
              "/etc/partner/install-origin",
              "/Library/LaunchDaemons/me.gurupras.partner.partnerd.plist",
              "/Library/LaunchAgents/me.gurupras.partner.loginwindow.plist",
              "/Library/LaunchAgents/me.gurupras.partner.session.plist",
            ]

  # A plain uninstall keeps the service's identity in /Library/Application
  # Support/Partner so a reinstall is the same computer (as the TeamViewer and
  # AnyDesk casks do). --zap forgets the machine: the next install gets a new ID.
  # `delete`, not `trash`: it holds the machine's private key.
  zap delete: "/Library/Application Support/Partner",
      trash:  [
        "~/Library/Application Support/me.gurupras.partner.app",
        "~/Library/Caches/me.gurupras.partner.app",
        "~/Library/Preferences/me.gurupras.partner.app.plist",
      ],
      rmdir:  [
        "/etc/partner",
        "/var/run/partner",
      ]

  caveats <<~EOS
    Partner does not run as a service until you ask it to: open the app and turn
    on unattended access (one administrator prompt).

    The app updates itself. To remove the app and the service:
      brew uninstall --cask partner
    That keeps this computer's Partner ID for a later reinstall. To erase it too:
      brew uninstall --zap --cask partner
  EOS
end
