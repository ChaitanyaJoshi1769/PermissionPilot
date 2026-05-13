# Quick Reference Guide

Fast lookup for common PermissionPilot tasks and commands.

---

## Installation

### Users
```bash
# Download and install
open https://github.com/ChaitanyaJoshi1769/PermissionPilot/releases
# → Download PermissionPilot.dmg
# → Drag to Applications folder
# → Open app and grant accessibility permission
```

### Developers
```bash
git clone https://github.com/ChaitanyaJoshi1769/PermissionPilot.git
cd PermissionPilot
./Scripts/setup-dev.sh
make build
```

### Homebrew
```bash
brew install permissionpilot
```

---

## Essential Commands

### Daemon Control
```bash
# Start daemon
launchctl start com.permissionpilot.daemon

# Stop daemon
launchctl stop com.permissionpilot.daemon

# Restart daemon
launchctl stop com.permissionpilot.daemon && sleep 2 && launchctl start com.permissionpilot.daemon

# Check status
launchctl list | grep permissionpilot
```

### Configuration
```bash
# Edit main config
nano ~/Library/Application\ Support/PermissionPilot/config.json

# Edit policies
nano ~/Library/Application\ Support/PermissionPilot/policies.json

# View configuration
cat ~/Library/Application\ Support/PermissionPilot/config.json | jq
```

### Database Queries
```bash
# Get event count (last 24 hours)
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "SELECT COUNT(*) FROM automation_events WHERE timestamp > datetime('now', '-24 hours');"

# Get success rate
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "SELECT ROUND(100.0 * SUM(CASE WHEN automation_success = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) FROM automation_events WHERE timestamp > datetime('now', '-24 hours');"

# Get top apps
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "SELECT app_name, COUNT(*) FROM automation_events WHERE timestamp > datetime('now', '-7 days') GROUP BY app_name ORDER BY COUNT(*) DESC LIMIT 10;"

# Export to CSV
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db ".mode csv" ".output events.csv" "SELECT * FROM automation_events LIMIT 1000;"
```

### Logging
```bash
# View real-time logs
log stream --predicate 'process == "PermissionPilot"' --level debug

# View recent logs (last 1 hour)
log show --predicate 'process == "PermissionPilot"' --last 1h

# Save logs to file
log show --predicate 'process == "PermissionPilot"' --last 24h > pp_logs.txt

# Check for errors
log show --predicate 'process == "PermissionPilot" AND level == error' --last 24h
```

---

## Quick Diagnostics

### Check If Running
```bash
pgrep -f "PermissionPilot" && echo "Running" || echo "Not running"
```

### Performance Check
```bash
ps aux | grep "[P]ermissionPilot" | awk '{print "CPU: " $3 "%, Memory: " $6 "MB"}'
```

### Database Health
```bash
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db "PRAGMA integrity_check;"
```

### Grant Accessibility Permission
```bash
# System Preferences → Security & Privacy → Accessibility → Add PermissionPilot
# Or check with:
defaults read com.apple.universalaccess | grep -i permission
```

---

## Configuration Snippets

### High Performance
```json
{
  "daemon": {"polling_interval_ms": 250},
  "detection": {"method": "hybrid", "ocr_enabled": true},
  "automation": {"click_delay_ms": 50}
}
```

### Power Saver
```json
{
  "daemon": {"polling_interval_ms": 2000},
  "detection": {"method": "accessibility_api", "ocr_enabled": false},
  "automation": {"click_delay_ms": 300}
}
```

### Privacy Mode
```json
{
  "automation": {"enabled": false},
  "screenshots": {"capture_enabled": false},
  "logging": {"debug_mode": false}
}
```

### Enterprise
```json
{
  "security": {
    "require_notarization": true,
    "block_dangerous_keywords": true,
    "verify_code_signature": true
  }
}
```

---

## Common Policies

### Allow Chrome
```json
{
  "name": "Allow Chrome",
  "type": "whitelist",
  "target_type": "app",
  "target_values": ["com.google.Chrome"],
  "action": "allow"
}
```

### Block Deletions
```json
{
  "name": "Block Deletions",
  "type": "rule",
  "target_type": "dialog_text",
  "target_pattern": "(?i)(delete|erase|reset)",
  "action": "block"
}
```

### Allow Notifications
```json
{
  "name": "Allow Notifications",
  "type": "rule",
  "target_type": "dialog_text",
  "target_pattern": "(?i)(notification|notify)",
  "action": "allow"
}
```

---

## File Locations

```
~/Library/Application Support/PermissionPilot/
  ├── config.json                 # Main configuration
  ├── policies.json               # Policy definitions
  ├── audit.db                    # SQLite database
  └── screenshots/                # Screenshot cache

~/Library/LaunchAgents/
  └── com.permissionpilot.daemon.plist  # Daemon config

~/Library/Logs/PermissionPilot/
  └── *.log                       # Application logs
```

---

## Troubleshooting Quick Fixes

### Daemon Not Starting
```bash
launchctl stop com.permissionpilot.daemon
launchctl start com.permissionpilot.daemon
```

### High CPU Usage
```bash
# Edit config.json, change:
"polling_interval_ms": 500    # Increase to 1000
"ocr_enabled": false          # Disable OCR
```

### High Memory Usage
```bash
# Clear old events
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "DELETE FROM automation_events WHERE timestamp < datetime('now', '-30 days'); VACUUM;"
```

### Dialogs Not Detected
```bash
# Check accessibility permission in System Preferences
# Verify daemon is running: pgrep -f "PermissionPilot"
# Check logs: log stream --predicate 'process == "PermissionPilot"' --level debug
```

### Wrong Button Clicked
```bash
# Add app to blacklist in policies.json
# Or create specific rule blocking dangerous keywords
```

---

## Monitoring Quick Checks

```bash
# All-in-one health check
./Scripts/health-check.sh

# Performance benchmark
./Scripts/benchmark.sh

# Watch real-time activity
watch -n 1 'sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "SELECT COUNT(*) FROM automation_events WHERE timestamp > datetime(\"now\", \"-1 minute\");"'

# Monitor CPU/Memory
top -o cpu -R -F | grep -i permission
```

---

## Development Quick Commands

```bash
# Build
make build

# Test
make test

# Format code
make format

# Lint
make lint

# Clean
make clean

# Install locally
make install

# Run tests with coverage
make coverage
```

---

## Git Workflow Quick Reference

```bash
# Create feature branch
git checkout -b feature/my-feature

# Stage and commit
git add .
git commit -m "feature: add cool feature"

# Format commit message template
cat .gitmessage

# Push branch
git push origin feature/my-feature

# Create pull request
gh pr create

# View status
git status

# View diff
git diff
```

---

## API Quick Examples

### Detect Dialog
```swift
let detector = AccessibilityDialogDetector()
if let dialog = await detector.detectDialog() {
  print("Found: \(dialog.title)")
}
```

### Score Application
```swift
let scorer = DefaultTrustScorer()
let score = await scorer.scoreApplication(appInfo)
print("Trust: \(score)")
```

### Evaluate Policy
```swift
let engine = DefaultPolicyEngine()
let decision = await engine.evaluate(dialog: detectedDialog)
// .allow, .block, or .ask
```

### Click Button
```swift
let automation = DefaultAutomationEngine()
let result = await automation.clickButton(safeButton)
```

### Query Events
```swift
let manager = DefaultLogManager()
let events = await manager.getEvents(filter: EventFilter(limit: 100))
```

---

## Regular Maintenance

### Daily
```bash
# Check system health
./Scripts/health-check.sh

# Review recent activity
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "SELECT COUNT(*) FROM automation_events WHERE timestamp > datetime('now', '-24 hours');"
```

### Weekly
```bash
# Run performance benchmark
./Scripts/benchmark.sh

# Check logs for errors
log show --predicate 'process == "PermissionPilot" AND level == error' --last 7d
```

### Monthly
```bash
# Backup database
cp ~/Library/Application\ Support/PermissionPilot/audit.db \
   ~/Library/Application\ Support/PermissionPilot/audit.db.backup.$(date +%Y%m%d)

# Clean old events (keep 60 days)
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "DELETE FROM automation_events WHERE timestamp < datetime('now', '-60 days'); VACUUM;"

# Review and update policies
nano ~/Library/Application\ Support/PermissionPilot/policies.json
```

---

## Useful Links

| Resource | Link |
|----------|------|
| Installation | [QUICK_START.md](QUICK_START.md) |
| Configuration | [CONFIGURATION_GUIDE.md](CONFIGURATION_GUIDE.md) |
| Troubleshooting | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) |
| Performance | [PERFORMANCE_TUNING.md](PERFORMANCE_TUNING.md) |
| API Reference | [API_REFERENCE.md](API_REFERENCE.md) |
| Database | [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) |
| Monitoring | [MONITORING.md](MONITORING.md) |
| Full Index | [DOCS_INDEX.md](DOCS_INDEX.md) |
| GitHub | https://github.com/ChaitanyaJoshi1769/PermissionPilot |

---

**Print this guide for quick reference!**

Last updated: May 13, 2024
