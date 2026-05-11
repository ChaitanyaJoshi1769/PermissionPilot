---
title: Installation
description: How to install PermissionPilot
---

# Installation Guide

## 🚀 Quick Install (Recommended)

### 1. Download DMG
Get the latest release from [GitHub Releases](https://github.com/ChaitanyaJoshi1769/PermissionPilot/releases):
- `PermissionPilot.dmg` (Latest stable)

### 2. Install App
1. Open `PermissionPilot.dmg`
2. Drag **PermissionPilot.app** to your Applications folder
3. Wait for copy to complete (~30 seconds)
4. Eject the DMG

### 3. Launch & Authorize
1. Open Applications folder
2. Double-click **PermissionPilot.app**
3. Grant **Accessibility permission** when prompted:
   - System Settings → Privacy & Security → Accessibility
   - Add PermissionPilot to the list
   - Toggle ON
4. ✅ Ready to use!

---

## 🍺 Homebrew (Coming Soon)

Once available, you'll be able to install via:

```bash
brew install permissionpilot
```

Then authorize:
```bash
open /Applications/PermissionPilot.app
```

---

## 🛠️ Build from Source

### Prerequisites
- macOS 13.0+
- Xcode 15.0+
- Swift 5.9+
- Command Line Tools

### Step 1: Install Dev Tools
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Install SwiftFormat and SwiftLint
brew install swiftformat swiftlint
```

### Step 2: Clone Repository
```bash
git clone https://github.com/ChaitanyaJoshi1769/PermissionPilot.git
cd PermissionPilot
```

### Step 3: Build
```bash
# Debug build (for development)
./Scripts/build.sh debug

# Or, release build (for distribution)
./Scripts/build.sh release
```

### Step 4: Install
```bash
# Install to /Applications
make install

# Or manually
cp -r build/Export/PermissionPilot.app /Applications/
```

### Step 5: Launch & Authorize
```bash
open /Applications/PermissionPilot.app
```

Grant Accessibility permission when prompted.

---

## 🔐 Code Signing & Notarization

If you want to code sign and notarize for distribution:

### Requirements
- Apple Developer ID (paid developer account)
- Developer ID Application certificate
- App-specific password for Apple ID

### Sign & Notarize
```bash
./Scripts/sign-and-notarize.sh \
    build/PermissionPilot.xcarchive \
    your@appleid.com \
    "app-specific-password" \
    "TEAMID"
```

This will:
1. Extract the archive
2. Code sign with your Developer ID
3. Create a ZIP for notarization
4. Submit to Apple's notary service
5. Staple the notarization ticket
6. Create a distribution DMG

---

## ✅ Verify Installation

### Check App is Installed
```bash
ls -la /Applications/PermissionPilot.app
```

### Check Accessibility Permission
System Settings → Privacy & Security → Accessibility

Should show:
```
✓ PermissionPilot (enabled)
```

### Test Daemon
```bash
# Check if daemon is running
ps aux | grep -i permissionpilot

# View logs
tail -f ~/Library/Logs/PermissionPilot/daemon.log
```

### Launch at Login
The app automatically enables Launch at Login. To disable:
1. Open PermissionPilot
2. Settings → Launch at Login (toggle OFF)

---

## 🐛 Troubleshooting Installation

### App Won't Launch
```bash
# Check for crash logs
log stream --predicate 'process == "PermissionPilot"' --level debug

# Verify code signature
codesign -dv /Applications/PermissionPilot.app
```

### Accessibility Permission Not Granted
1. Open System Settings
2. Privacy & Security → Accessibility
3. Click the lock icon to unlock
4. Click "+" and select PermissionPilot.app from Applications
5. Confirm the prompt
6. Toggle ON

### Daemon Not Starting
```bash
# Manually start daemon
~/Library/LaunchAgents/com.permissionpilot.daemon.plist
launchctl load ~/Library/LaunchAgents/com.permissionpilot.daemon.plist

# Check logs
cat ~/Library/Logs/PermissionPilot/daemon.log
```

### Permission Denied
If you get "Permission denied" errors:
```bash
# Fix permissions
chmod +x /Applications/PermissionPilot.app/Contents/MacOS/PermissionPilot

# Re-grant accessibility
System Settings → Privacy & Security → Accessibility
# Remove PermissionPilot, add it again, toggle ON
```

---

## 📍 File Locations

After installation, files are stored at:

```
~/Library/Application Support/PermissionPilot/
├── audit.db                 # SQLite audit log
├── preferences.plist        # User settings
└── policies.json           # Custom policies

~/Library/Logs/PermissionPilot/
├── daemon.log              # Daemon activity
├── actions.log             # Automation actions
└── debug.log               # Debug output

~/Library/LaunchAgents/
└── com.permissionpilot.daemon.plist  # LaunchAgent config
```

---

## 🔄 Updating

### From DMG
1. Download latest `PermissionPilot.dmg`
2. Open the DMG
3. Drag to Applications (replaces old version)
4. Eject DMG
5. Restart app

### From Homebrew (future)
```bash
brew upgrade permissionpilot
```

### From Source
```bash
cd PermissionPilot
git pull origin main
make clean build install
open /Applications/PermissionPilot.app
```

---

## 🗑️ Uninstall

### Complete Removal
```bash
# Remove app
rm -rf /Applications/PermissionPilot.app

# Remove data and logs
rm -rf ~/Library/Application\ Support/PermissionPilot
rm -rf ~/Library/Logs/PermissionPilot
rm -rf ~/Library/Preferences/com.permissionpilot*

# Remove LaunchAgent
rm ~/Library/LaunchAgents/com.permissionpilot.daemon.plist

# Remove from Accessibility
# System Settings → Privacy & Security → Accessibility
# Remove PermissionPilot from list
```

Or use the Makefile:
```bash
make uninstall
```

---

## 📞 Need Help?

- **[FAQ](https://chaitanyajoshi1769.github.io/PermissionPilot/faq.html)** — Common questions
- **[Troubleshooting](https://github.com/ChaitanyaJoshi1769/PermissionPilot/blob/main/TROUBLESHOOTING.md)** — Diagnostic guides
- **[Discussions](https://github.com/ChaitanyaJoshi1769/PermissionPilot/discussions)** — Ask the community
- **[Report Issue](https://github.com/ChaitanyaJoshi1769/PermissionPilot/issues/new?template=bug_report.md)** — File a bug

---

**[Back to Home](/) | [View Features](/features) | [View on GitHub](https://github.com/ChaitanyaJoshi1769/PermissionPilot)**
