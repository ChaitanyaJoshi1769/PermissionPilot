class Permissionpilot < Formula
  desc "Intelligent macOS permission dialog automation"
  homepage "https://github.com/ChaitanyaJoshi1769/PermissionPilot"
  url "https://github.com/ChaitanyaJoshi1769/PermissionPilot/releases/download/v1.0.0/PermissionPilot.dmg"
  sha256 "placeholder_sha256_hash_replace_with_actual"
  version "1.0.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on macos: ">= :ventura"

  def install
    # Mount the DMG
    system "hdiutil", "attach", cached_download, "-mountpoint", "mnt"

    # Copy app to /Applications
    app_path = "mnt/PermissionPilot.app"
    destination = prefix/"Applications/PermissionPilot.app"
    cp_r app_path, destination

    # Unmount DMG
    system "hdiutil", "detach", "mnt", "-force"
  end

  def post_install
    # Register app with LaunchAgent
    plist_path = File.expand_path("~/Library/LaunchAgents/com.permissionpilot.daemon.plist")

    # Create LaunchAgents directory if it doesn't exist
    FileUtils.mkdir_p File.dirname(plist_path)

    # Write plist
    plist_content = <<~PLIST
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>com.permissionpilot.daemon</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{prefix}/Applications/PermissionPilot.app/Contents/MacOS/PermissionPilot</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
        <key>Nice</key>
        <integer>10</integer>
        <key>StandardOutPath</key>
        <string>#{File.expand_path("~/Library/Logs/PermissionPilot/daemon.log")}</string>
        <key>StandardErrorPath</key>
        <string>#{File.expand_path("~/Library/Logs/PermissionPilot/daemon.log")}</string>
      </dict>
      </plist>
    PLIST

    File.write(plist_path, plist_content)

    # Load LaunchAgent
    system "launchctl", "load", plist_path

    puts "✅ PermissionPilot installed!"
    puts "📍 Application: #{prefix}/Applications/PermissionPilot.app"
    puts "🔐 Grant Accessibility permission: System Settings → Privacy & Security → Accessibility"
    puts "🚀 The daemon will start at login automatically"
  end

  def uninstall_postflight
    # Remove LaunchAgent
    plist_path = File.expand_path("~/Library/LaunchAgents/com.permissionpilot.daemon.plist")
    if File.exist?(plist_path)
      system "launchctl", "unload", plist_path
      FileUtils.rm plist_path
    end

    # Remove app data
    app_support = File.expand_path("~/Library/Application Support/PermissionPilot")
    FileUtils.rm_rf app_support if Dir.exist?(app_support)

    puts "✅ PermissionPilot uninstalled"
  end

  caveats do
    <<~EOS
      PermissionPilot requires Accessibility permission to function.

      After installation, grant permission:
        1. Open System Settings
        2. Go to Privacy & Security → Accessibility
        3. Add PermissionPilot.app to the list
        4. Toggle the permission ON

      The daemon will start automatically at login.

      For more information, visit:
        https://github.com/ChaitanyaJoshi1769/PermissionPilot
    EOS
  end

  test do
    # Simple test to verify installation
    assert_path_exists "#{prefix}/Applications/PermissionPilot.app"
  end
end
