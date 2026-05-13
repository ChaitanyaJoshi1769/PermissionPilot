# Deployment Guide

Installation and deployment procedures for organizations, system administrators, and IT teams.

---

## Overview

This guide covers:
- **Single Machine Deployment** - Manual installation
- **Mass Deployment** - Deploying to multiple machines
- **MDM Integration** - Mobile Device Management (Apple Business Manager)
- **Configuration Management** - Ansible, Puppet, Chef
- **Monitoring & Support** - Managing deployed instances
- **Troubleshooting** - Common deployment issues
- **Compliance** - Security and privacy considerations

---

## Single Machine Installation

### Method 1: DMG Installation (Easiest)

```bash
# 1. Download latest release
# Go to: https://github.com/ChaitanyaJoshi1769/PermissionPilot/releases
# Download: PermissionPilot.dmg

# 2. Mount DMG
open PermissionPilot.dmg

# 3. Drag PermissionPilot.app to Applications folder
# Finder will appear, drag app to /Applications

# 4. Unmount DMG
hdiutil detach "/Volumes/PermissionPilot"

# 5. Launch app
open /Applications/PermissionPilot.app

# 6. Grant accessibility permission when prompted
# System Preferences → Security & Privacy → Accessibility
```

### Method 2: Homebrew Installation

```bash
# Install via Homebrew
brew install permissionpilot

# Launch
open /Applications/PermissionPilot.app

# Uninstall
brew uninstall permissionpilot
```

### Method 3: Build from Source

```bash
# Clone repository
git clone https://github.com/ChaitanyaJoshi1769/PermissionPilot.git
cd PermissionPilot

# Build release
./Scripts/build.sh release

# Sign & Notarize
./Scripts/sign-and-notarize.sh \
  build/PermissionPilot.xcarchive \
  your@appleid.com \
  "app-specific-password" \
  "TEAMID"

# Copy to Applications
cp build/PermissionPilot.app /Applications/
```

---

## Mass Deployment

### Option 1: Bash Script Distribution

Create a deployment script:

```bash
#!/bin/bash
# deploy-permissionpilot.sh

set -e

VERSION="1.0.0"
DMG_URL="https://github.com/ChaitanyaJoshi1769/PermissionPilot/releases/download/v${VERSION}/PermissionPilot.dmg"
DMG_PATH="/tmp/PermissionPilot.dmg"
APP_PATH="/Applications/PermissionPilot.app"

echo "Installing PermissionPilot v${VERSION}..."

# 1. Download DMG
echo "Downloading..."
curl -L "$DMG_URL" -o "$DMG_PATH"

# 2. Mount DMG
echo "Mounting..."
MOUNT_POINT=$(hdiutil attach "$DMG_PATH" | grep Applications | awk '{print $3}')

# 3. Copy app
echo "Installing to /Applications..."
cp -r "$MOUNT_POINT/PermissionPilot.app" "$APP_PATH"

# 4. Unmount
echo "Cleaning up..."
hdiutil detach "$MOUNT_POINT"
rm "$DMG_PATH"

# 5. Set permissions
chmod -R 755 "$APP_PATH"
chown -R $(whoami) "$APP_PATH"

# 6. Grant accessibility permission (requires user interaction)
echo "PermissionPilot installed!"
echo "Next: Open /Applications/PermissionPilot.app and grant accessibility permission"
echo "System Preferences → Security & Privacy → Accessibility → Add PermissionPilot"

echo "Done!"
```

**Deploy to multiple machines:**

```bash
# Create distribution script
cat > deploy.sh << 'EOF'
#!/bin/bash
for mac in mac1.company.com mac2.company.com mac3.company.com; do
  echo "Deploying to $mac..."
  ssh admin@$mac < deploy-permissionpilot.sh
  echo "✓ Deployed to $mac"
done
echo "Done! Deployed to all machines"
EOF

chmod +x deploy.sh
./deploy.sh
```

### Option 2: Enterprise Deployment via Package Manager

**Create .pkg installer:**

```bash
# Using pkgbuild
pkgbuild \
  --root /tmp/PermissionPilot.app \
  --install-location /Applications \
  --identifier com.permissionpilot.app \
  --version 1.0.0 \
  PermissionPilot.pkg

# Distribute .pkg file to users or via MDM
```

---

## MDM Integration (Apple Business Manager)

### Pre-requisites

- Apple Business Manager account
- Apple Developer ID with code signing certificate
- macOS devices enrolled in MDM

### Deployment Steps

#### Step 1: Code Sign and Notarize

```bash
# Sign the app
codesign --force --verify --verbose \
  --sign "Developer ID Application" \
  /Applications/PermissionPilot.app

# Notarize
xcrun altool --notarize-app \
  --file PermissionPilot.dmg \
  --primary-bundle-id com.permissionpilot.app \
  --username your@appleid.com \
  --password "app-specific-password"

# Check status
xcrun altool --notarization-info UUID \
  --username your@appleid.com \
  --password "app-specific-password"
```

#### Step 2: Upload to Apple Business Manager

1. Go to: https://business.apple.com
2. Sign in with Apple Business Account
3. Navigate: Apps and Books → Mac Apps
4. Click: Add (↓)
5. Upload: PermissionPilot.dmg
6. Fill metadata (name, description, category)
7. Click: Save & Add to Catalog
8. Assign to users/devices

#### Step 3: Deploy via Profile Manager

```bash
# Create MDM profile
# In Profile Manager:
# 1. Devices → Apps
# 2. Add App → Select PermissionPilot
# 3. Configure deployment options:
#    - Automatic updates: ON
#    - Force install: YES
#    - Remove on unenroll: NO

# Configure settings:
# 4. Create configuration profile:
#    - Add Accessibility permission
#    - Deploy config.json
```

**Sample MDM Profile (XML):**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>PayloadContent</key>
  <array>
    <dict>
      <key>PayloadType</key>
      <string>com.apple.managed.app</string>
      <key>PayloadIdentifier</key>
      <string>com.permissionpilot.mdm</string>
      <key>PayloadDisplayName</key>
      <string>PermissionPilot</string>
      <key>AppIdentifier</key>
      <string>com.permissionpilot.app</string>
      <key>BundleId</key>
      <string>com.permissionpilot.app</string>
    </dict>
  </array>
  <key>PayloadDescription</key>
  <string>Deploy PermissionPilot</string>
  <key>PayloadType</key>
  <string>Configuration</string>
  <key>PayloadVersion</key>
  <integer>1</integer>
</dict>
</plist>
```

---

## Configuration Management Tools

### Ansible Deployment

**Create playbook:**

```yaml
---
- name: Deploy PermissionPilot
  hosts: all_macs
  gather_facts: yes
  
  tasks:
    - name: Create support directory
      file:
        path: "{{ ansible_user_dir }}/Library/Application Support/PermissionPilot"
        state: directory
        mode: '0755'
    
    - name: Download DMG
      get_url:
        url: "https://github.com/ChaitanyaJoshi1769/PermissionPilot/releases/download/v1.0.0/PermissionPilot.dmg"
        dest: "/tmp/PermissionPilot.dmg"
        checksum: "sha256:{{ dmg_sha256 }}"
    
    - name: Mount DMG
      shell: |
        hdiutil attach /tmp/PermissionPilot.dmg
      register: mount_result
    
    - name: Copy app
      shell: |
        cp -r /Volumes/PermissionPilot/PermissionPilot.app /Applications/
      become: yes
    
    - name: Unmount DMG
      shell: |
        hdiutil detach /Volumes/PermissionPilot
    
    - name: Deploy configuration
      template:
        src: config.json.j2
        dest: "{{ ansible_user_dir }}/Library/Application Support/PermissionPilot/config.json"
        mode: '0644'
    
    - name: Deploy policies
      template:
        src: policies.json.j2
        dest: "{{ ansible_user_dir }}/Library/Application Support/PermissionPilot/policies.json"
        mode: '0644'
    
    - name: Grant Accessibility permission
      shell: |
        sqlite3 ~/Library/Application\ Support/com.apple.LaunchServices.QuarantineResolver/QuarantineEvents.db \
          "INSERT INTO LSQuarantineEvent VALUES ('0;...');"
      ignore_errors: yes
```

**Deploy:**

```bash
ansible-playbook deploy-permissionpilot.yml -i inventory.ini
```

### Chef Deployment

**Create cookbook:**

```ruby
# recipes/default.rb

# Download and install PermissionPilot
remote_file "/tmp/PermissionPilot.dmg" do
  source "https://github.com/ChaitanyaJoshi1769/PermissionPilot/releases/download/v1.0.0/PermissionPilot.dmg"
  action :create
end

execute "install_permissionpilot" do
  command <<-BASH
    hdiutil attach /tmp/PermissionPilot.dmg
    cp -r /Volumes/PermissionPilot/PermissionPilot.app /Applications/
    hdiutil detach /Volumes/PermissionPilot
    rm /tmp/PermissionPilot.dmg
  BASH
  action :run
end

# Deploy configuration
directory ::File.expand_path("~/Library/Application Support/PermissionPilot") do
  action :create
end

cookbook_file ::File.expand_path("~/Library/Application Support/PermissionPilot/config.json") do
  source "config.json"
  action :create
end
```

### Puppet Deployment

**Create manifest:**

```puppet
class permissionpilot::install {
  exec { 'download_permissionpilot':
    command => 'curl -L https://github.com/ChaitanyaJoshi1769/PermissionPilot/releases/download/v1.0.0/PermissionPilot.dmg -o /tmp/PermissionPilot.dmg',
    unless  => 'test -d /Applications/PermissionPilot.app',
  }
  
  exec { 'install_permissionpilot':
    command => 'hdiutil attach /tmp/PermissionPilot.dmg && cp -r /Volumes/PermissionPilot/PermissionPilot.app /Applications/ && hdiutil detach /Volumes/PermissionPilot && rm /tmp/PermissionPilot.dmg',
    unless  => 'test -d /Applications/PermissionPilot.app',
    require => Exec['download_permissionpilot'],
  }
}

class permissionpilot::config {
  file { '/Library/Application Support/PermissionPilot/config.json':
    ensure  => file,
    content => template('permissionpilot/config.json.erb'),
  }
}

class permissionpilot {
  include permissionpilot::install
  include permissionpilot::config
}

include permissionpilot
```

---

## Monitoring Deployed Instances

### Health Check Script

Check deployment status across machines:

```bash
#!/bin/bash
# check-deployment.sh

MACHINES=(mac1 mac2 mac3)

for mac in "${MACHINES[@]}"; do
  echo "=== Checking $mac ==="
  
  # Check if installed
  ssh admin@$mac "test -d /Applications/PermissionPilot.app" && \
    echo "✓ App installed" || echo "✗ App missing"
  
  # Check daemon status
  ssh admin@$mac "launchctl list | grep -q permissionpilot" && \
    echo "✓ Daemon running" || echo "✗ Daemon not running"
  
  # Check recent activity
  EVENTS=$(ssh admin@$mac "sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
    'SELECT COUNT(*) FROM automation_events WHERE timestamp > datetime(\"now\", \"-24 hours\");' 2>/dev/null")
  echo "✓ Recent events: $EVENTS (24h)"
  
  echo ""
done
```

**Run monitoring:**

```bash
chmod +x check-deployment.sh
./check-deployment.sh

# Or schedule periodically
(crontab -l; echo "0 9 * * * /path/to/check-deployment.sh") | crontab -
```

### Remote Logging Collection

Centralize logs from deployed machines:

```bash
#!/bin/bash
# collect-logs.sh

MACHINES=(mac1 mac2 mac3)
LOG_DIR="./logs-$(date +%Y%m%d)"
mkdir -p "$LOG_DIR"

for mac in "${MACHINES[@]}"; do
  echo "Collecting logs from $mac..."
  
  # Create machine directory
  mkdir -p "$LOG_DIR/$mac"
  
  # Collect logs
  scp admin@$mac:~/Library/Logs/PermissionPilot/*.log "$LOG_DIR/$mac/" 2>/dev/null || true
  
  # Collect audit database
  scp admin@$mac:~/Library/Application\ Support/PermissionPilot/audit.db "$LOG_DIR/$mac/" 2>/dev/null || true
  
  echo "✓ Collected logs from $mac"
done

echo "Logs saved to: $LOG_DIR"
```

---

## Uninstallation

### User Uninstallation

```bash
# 1. Stop daemon
launchctl unload ~/Library/LaunchAgents/com.permissionpilot.daemon.plist

# 2. Delete app
rm -rf /Applications/PermissionPilot.app

# 3. Delete data (optional)
rm -rf ~/Library/Application\ Support/PermissionPilot
rm -rf ~/Library/Caches/com.permissionpilot.app
rm -rf ~/Library/Logs/PermissionPilot
```

### Admin Uninstallation (via MDM)

1. In Apple Business Manager
2. Devices → Device Management
3. Select PermissionPilot
4. Click: "Remove from Devices"
5. Confirm

---

## Troubleshooting Deployment

### App Won't Launch

**Diagnosis:**

```bash
# Check code signature
codesign -v /Applications/PermissionPilot.app
# Result: valid on macOS 13.0+

# Check notarization
spctl -a -v /Applications/PermissionPilot.app
# Result: accepted (notarized)
```

**Solutions:**

1. Verify code signature: `codesign -v /Applications/PermissionPilot.app`
2. Check notarization status
3. Grant accessibility permission
4. Check System Preferences → Security & Privacy

### Daemon Not Starting

**Diagnosis:**

```bash
# Check LaunchAgent
cat ~/Library/LaunchAgents/com.permissionpilot.daemon.plist

# Check daemon status
launchctl list | grep permissionpilot

# Check system logs
log show --predicate 'process == "permissionpilotd"' --last 1h
```

**Solutions:**

1. Verify LaunchAgent exists
2. Reload LaunchAgent: `launchctl load ~/Library/LaunchAgents/com.permissionpilot.daemon.plist`
3. Check permissions: `ls -l ~/Library/LaunchAgents/com.permissionpilot.daemon.plist`
4. Review system logs for errors

### Configuration Not Applied

**Diagnosis:**

```bash
# Check config file exists
ls -la ~/Library/Application\ Support/PermissionPilot/config.json

# Validate JSON
jq . ~/Library/Application\ Support/PermissionPilot/config.json

# Check permissions
ls -la ~/Library/Application\ Support/PermissionPilot/
```

**Solutions:**

1. Verify file exists and is readable
2. Validate JSON syntax
3. Restart daemon: `launchctl stop/start ...`
4. Check logs for configuration errors

---

## Compliance & Security

### Data Privacy

PermissionPilot stores data locally:

```
~/Library/Application Support/PermissionPilot/
├── audit.db              # SQLite database (encrypted at rest)
├── config.json           # Configuration
├── policies.json         # Policies
└── screenshots/          # Optional dialog screenshots
```

**Compliance Notes:**
- ✅ All data stored locally on user's machine
- ✅ No data sent to servers (by default)
- ✅ GDPR compliant (user owns data)
- ✅ CCPA compliant (user can delete anytime)
- ✅ HIPAA compatible (no sensitive data transmission)

### Security Best Practices

**For Administrators:**

1. **Code Signing** - Verify app signature before deployment
2. **Configuration** - Use strong patterns in security rules
3. **Monitoring** - Regularly review logs for anomalies
4. **Updates** - Keep app updated to latest version
5. **Permissions** - Grant only Accessibility permission (required)
6. **Database** - Backup audit.db regularly
7. **Encryption** - Consider FileVault for additional protection

**For IT/Admins:**

```bash
# Backup production database before update
cp ~/Library/Application\ Support/PermissionPilot/audit.db \
   ~/Library/Application\ Support/PermissionPilot/audit.db.backup

# Verify app signature
codesign -v /Applications/PermissionPilot.app

# Monitor for unauthorized changes
sudo fs_usage | grep PermissionPilot
```

---

## Support & Escalation

### Getting Help

**For Deployment Issues:**
- [GitHub Issues](https://github.com/ChaitanyaJoshi1769/PermissionPilot/issues)
- [GitHub Discussions](https://github.com/ChaitanyaJoshi1769/PermissionPilot/discussions)
- Email: dev@permissionpilot.app

**Commercial Support (Future):**
- Enterprise support plans
- Priority issue resolution
- Custom integration help

---

## Version Upgrade

### Safe Upgrade Process

```bash
#!/bin/bash
# upgrade-permissionpilot.sh

# 1. Backup existing installation
cp -r /Applications/PermissionPilot.app /Applications/PermissionPilot.app.backup

# 2. Backup database
cp ~/Library/Application\ Support/PermissionPilot/audit.db \
   ~/Library/Application\ Support/PermissionPilot/audit.db.backup

# 3. Stop daemon
launchctl stop com.permissionpilot.daemon

# 4. Replace app
rm -rf /Applications/PermissionPilot.app
# ... install new version ...

# 5. Restart daemon
launchctl start com.permissionpilot.daemon

# 6. Verify
open /Applications/PermissionPilot.app
```

---

**Last updated:** May 13, 2024  
**Version:** 1.0.0
