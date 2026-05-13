# Monitoring & Debugging Guide

Complete guide to monitoring PermissionPilot in production, diagnosing issues, and profiling performance.

---

## Overview

This guide covers:
- **System Monitoring** - CPU, memory, disk usage
- **Daemon Health** - LaunchAgent status, logs, crashes
- **Feature Monitoring** - Dialog detection, automation success
- **Performance Profiling** - Bottleneck identification
- **Debugging Techniques** - Log analysis, breakpoints, traces
- **Incident Response** - Handling errors and failures

---

## System Monitoring

### Activity Monitor

Monitor PermissionPilot process in macOS Activity Monitor:

```bash
# Launch Activity Monitor
open -a "Activity Monitor"

# Or view via command line
ps aux | grep PermissionPilot
```

**Expected Values (Idle State):**
- **CPU:** <0.5% (occasionally spikes to 5-8%)
- **Memory:** 80-100 MB
- **Threads:** 8-12 threads
- **File Descriptors:** 15-20

**Investigation Checklist:**
- [ ] CPU >5% for >2 minutes consistently = possible infinite loop
- [ ] Memory growing = possible memory leak
- [ ] High thread count = possible resource leak
- [ ] Threads stuck = possible deadlock

### System Logs

View system-level logs:

```bash
# Real-time system logs
log stream --predicate 'process == "PermissionPilot"' --level debug

# Historical logs (last 1 hour)
log show --predicate 'process == "PermissionPilot"' --last 1h

# Errors only
log show --predicate 'process == "PermissionPilot" AND level == error' --last 24h

# Save to file
log show --predicate 'process == "PermissionPilot"' --last 24h > permissions_logs.txt
```

### Disk Usage

Monitor local data storage:

```bash
# Check total app data size
du -sh ~/Library/Application\ Support/PermissionPilot

# Check database size
ls -lh ~/Library/Application\ Support/PermissionPilot/audit.db

# Check logs directory
ls -lh ~/Library/Logs/PermissionPilot/

# Check cache size
du -sh ~/Library/Caches/com.permissionpilot.app

# Expected sizes:
# - Database (90 days): 10-15 MB
# - Logs: 5-10 MB
# - Cache: 2-5 MB
# - Total: <30 MB
```

---

## Daemon Health Monitoring

### LaunchAgent Status

Check if the daemon is running:

```bash
# Check if daemon is loaded
launchctl list | grep permissionpilot

# Check daemon status
launchctl print system/com.permissionpilot.daemon

# View daemon property list
cat ~/Library/LaunchAgents/com.permissionpilot.daemon.plist

# Expected output should show:
# - pid: process ID (running) or none (stopped)
# - LastExitStatus: 0 (success) or error code
```

### Start/Stop Daemon

```bash
# Manually start daemon
launchctl load ~/Library/LaunchAgents/com.permissionpilot.daemon.plist

# Or unload to stop
launchctl unload ~/Library/LaunchAgents/com.permissionpilot.daemon.plist

# Restart daemon
launchctl unload ~/Library/LaunchAgents/com.permissionpilot.daemon.plist
launchctl load ~/Library/LaunchAgents/com.permissionpilot.daemon.plist

# Enable auto-start on login
launchctl enable user/$(id -u)/com.permissionpilot.daemon

# Disable auto-start
launchctl disable user/$(id -u)/com.permissionpilot.daemon
```

### Daemon Logs

View daemon-specific logs:

```bash
# View daemon logs
tail -f /tmp/permissionpilot-daemon*.log

# Follow specific log file
log stream --level debug --predicate 'process == "permissionpilotd"'

# Check for crashes
log show --predicate 'process == "permissionpilotd" AND level == error' --last 24h

# View daemon start/stop events
log show --predicate 'eventMessage contains "daemon"' --last 24h
```

### Daemon Crashes

If daemon keeps crashing:

```bash
# 1. Check system crash reports
open ~/Library/Logs/DiagnosticMessages/

# 2. Look for PermissionPilot crash logs
ls ~/Library/Logs/DiagnosticMessages/ | grep -i permission

# 3. View crash log details
cat ~/Library/Logs/DiagnosticMessages/PermissionPilot_*.crash

# 4. Enable verbose logging
defaults write com.permissionpilot.app DebugLogging -bool true

# 5. Check logs again
log stream --predicate 'process == "PermissionPilot"' --level debug

# 6. Report issue with crash log
# Attach crash log to GitHub issue: 
# https://github.com/ChaitanyaJoshi1769/PermissionPilot/issues
```

---

## Feature Monitoring

### Dialog Detection Metrics

Monitor detection performance:

```bash
# Query recent detection times
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db << 'EOF'
SELECT 
    COUNT(*) as total_dialogs,
    ROUND(AVG(detection_time_ms), 2) as avg_detection_ms,
    MIN(detection_time_ms) as min_ms,
    MAX(detection_time_ms) as max_ms,
    ROUND(AVG(detection_confidence), 3) as avg_confidence
FROM automation_events
WHERE timestamp > datetime('now', '-24 hours');
EOF

# Example output:
# total_dialogs|avg_detection_ms|min_ms|max_ms|avg_confidence
# 42           |215.34          |47    |789   |0.923
```

**Target Values:**
- Average detection: <300ms
- Min: 50ms (cached)
- Max: <1000ms (rare)
- Confidence: >0.90

### Detection Method Breakdown

```bash
# Compare Accessibility API vs OCR usage
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db << 'EOF'
SELECT 
    detection_method,
    COUNT(*) as count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM automation_events), 1) as percentage,
    ROUND(AVG(detection_time_ms), 2) as avg_time_ms,
    ROUND(AVG(detection_confidence), 3) as avg_confidence
FROM automation_events
WHERE timestamp > datetime('now', '-24 hours')
GROUP BY detection_method
ORDER BY count DESC;
EOF

# Expected: ~80% Accessibility API, ~20% OCR fallback
```

### Automation Success Rate

Monitor automation success:

```bash
# Calculate success rate
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db << 'EOF'
SELECT 
    COUNT(*) as total_attempted,
    SUM(CASE WHEN automation_success = 1 THEN 1 ELSE 0 END) as successful,
    SUM(CASE WHEN automation_success = 0 THEN 1 ELSE 0 END) as failed,
    ROUND(100.0 * SUM(CASE WHEN automation_success = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) as success_rate
FROM automation_events
WHERE automation_triggered = 1 AND timestamp > datetime('now', '-24 hours');
EOF

# Expected: >95% success rate
```

### Action Distribution

See what PermissionPilot is doing:

```bash
# Get action breakdown
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db << 'EOF'
SELECT 
    action_taken,
    COUNT(*) as count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM automation_events), 1) as percentage
FROM automation_events
WHERE timestamp > datetime('now', '-24 hours')
GROUP BY action_taken
ORDER BY count DESC;
EOF

# Example output:
# ALLOW_ONCE    |27  |64.3%
# BLOCK         |8   |19.0%
# MANUAL        |6   |14.3%
# BLOCKED_POLICY|1   |2.4%
```

**Expected Distribution:**
- ALLOW_ONCE: 60-70% (normal, safe approvals)
- BLOCK: 15-25% (blocked by policy)
- MANUAL: 5-15% (user intervention)
- BLOCKED_POLICY: <5% (dangerous keywords)
- TIMEOUT: <1% (rare)

### Policy Effectiveness

Monitor which policies are working:

```bash
# See policy application frequency
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db << 'EOF'
SELECT 
    applied_policy_name as policy,
    COUNT(*) as times_applied,
    SUM(CASE WHEN automation_success = 1 THEN 1 ELSE 0 END) as successful_automations,
    COUNT(DISTINCT app_name) as unique_apps
FROM automation_events
WHERE applied_policy_name IS NOT NULL 
  AND timestamp > datetime('now', '-24 hours')
GROUP BY applied_policy_name
ORDER BY times_applied DESC
LIMIT 10;
EOF
```

### Top Apps

Monitor which apps trigger the most dialogs:

```bash
# Top 10 apps by dialog count
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db << 'EOF'
SELECT 
    app_name,
    COUNT(*) as dialog_count,
    SUM(CASE WHEN automation_success = 1 THEN 1 ELSE 0 END) as auto_success,
    COUNT(DISTINCT DATE(timestamp)) as days_active
FROM automation_events
WHERE timestamp > datetime('now', '-7 days')
GROUP BY app_name
ORDER BY dialog_count DESC
LIMIT 10;
EOF

# Example output:
# Chrome       |145  |140      |7
# Zoom         |87   |85       |5
# VSCode       |52   |51       |7
```

---

## Performance Profiling

### CPU Profiling

Identify CPU bottlenecks:

```bash
# 1. Start Instruments
open -a Instruments

# 2. Select "Time Profiler"
# 3. Launch PermissionPilot
# 4. Wait for detection to occur
# 5. Stop recording
# 6. Analyze call tree

# Or via command line:
xcrun xctrace record --template "Time Profiler" --output profile.trace \
  --launch /Applications/PermissionPilot.app
```

**Expected Profile:**
- Main thread: <50% of CPU (not busy-waiting)
- Detection: <5% sustained
- OCR: <15% during processing
- Returns to idle: <2 seconds

### Memory Profiling

Identify memory leaks:

```bash
# 1. Open Instruments with Allocations
open -a Instruments

# 2. Select "Allocations" template
# 3. Launch PermissionPilot
# 4. Let it run for 30 minutes
# 5. Check for steady growth

# Key metrics:
# - Live Bytes: should stay constant (~85MB)
# - Persistent Bytes: should not grow
# - Allocations: check for unreleased objects
```

**Investigation Steps:**
1. If memory grows over time → potential leak
2. Look at "Allocations List" for growing types
3. Check "Call Tree" to find allocation sites
4. Use "Generations" to isolate recent leaks

### Database Performance

Monitor database query performance:

```bash
# Enable query profiling
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db << 'EOF'
PRAGMA query_only = OFF;
PRAGMA cache_size = -64000;
PRAGMA temp_store = MEMORY;

-- Enable timing
.timer on

-- Run slow query
SELECT * FROM automation_events WHERE timestamp > datetime('now', '-30 days');
EOF

# Output includes execution time:
# CPU: user 0.024534 sys 0.008934, 32.458 MB
```

---

## Debugging Techniques

### Enable Debug Logging

```bash
# Enable verbose logging
defaults write com.permissionpilot.app DebugLogging -bool true

# Disable debug logging
defaults write com.permissionpilot.app DebugLogging -bool false

# Check current setting
defaults read com.permissionpilot.app DebugLogging
```

### View Debug Logs

```bash
# Follow logs in real-time
log stream --predicate 'process == "PermissionPilot"' --level debug --max-wait 1

# Show logs with process info
log stream --predicate 'process == "PermissionPilot"' --format "[%d{HH:mm:ss.SSS}] %level %process %category: %message"

# Filter for specific events
log stream --predicate 'message contains "detection"' --level debug

# Save to file for analysis
log stream --predicate 'process == "PermissionPilot"' > debug_logs.txt &
```

### Breakpoint Debugging in Xcode

```swift
// Add in Swift code
if let dialog = await detector.detectDialog() {
    // Set breakpoint here
    debugPrint("Dialog detected: \(dialog.title)")
}

// Or use LLDB commands
(lldb) breakpoint set --name "detectDialog()"
(lldb) continue
(lldb) frame variable // inspect variables
(lldb) p dialog.title // print expression
```

### Screenshot Analysis

Analyze detected dialogs visually:

```bash
# Enable screenshot capture
defaults write com.permissionpilot.app CaptureScreenshots -bool true

# View recent screenshots
ls -ltr ~/Library/Application\ Support/PermissionPilot/screenshots/ | tail -5

# Open latest screenshot
open ~/Library/Application\ Support/PermissionPilot/screenshots/latest.png

# Check image metadata
file ~/Library/Application\ Support/PermissionPilot/screenshots/*.png
```

### Accessibility API Debugging

Debug detection issues:

```bash
# 1. Verify Accessibility permission is granted
defaults read com.apple.universalaccess; echo "Check for PermissionPilot"

# 2. Test accessibility API directly
swift << 'EOF'
import AppKit
let app = NSRunningApplication.runningApplications(withBundleIdentifier: "com.google.Chrome").first
let axi = AXUIElementCreateApplication(app!.processIdentifier)
var windows: CFArray?
AXUIElementCopyAttributeValue(axi, kAXWindowsAttribute as CFString, &windows)
print("Windows: \(windows ?? [] as CFArray)")
EOF

# 3. Use accessibility inspector
open /System/Library/CoreServices/Accessibility\ Inspector.app

# In Accessibility Inspector:
# - Enable "Enable inspection" checkbox
# - Hover over UI elements to see attributes
# - Check if dialogs expose correct accessibility info
```

---

## Incident Response

### High CPU Usage (>20%)

**Diagnosis:**
```bash
# 1. Check what's using CPU
ps aux | grep PermissionPilot | grep -v grep

# 2. Profile with Time Profiler
xcrun instruments -t "Time Profiler" -l 10 -s 5 /Applications/PermissionPilot.app

# 3. Check for OCR stuck
log stream --predicate 'message contains "OCR"' --level debug | head -20

# 4. Check for infinite loops
log stream --predicate 'process == "PermissionPilot"' --level debug | grep -c "loop"
```

**Solutions:**
1. Disable OCR: Settings → OCR → Toggle off
2. Increase detection interval: Settings → Polling Frequency
3. Restart daemon: `launchctl stop/start ...`
4. Report issue with debug logs

### High Memory Usage (>200MB)

**Diagnosis:**
```bash
# 1. Check memory usage
ps aux | grep PermissionPilot | awk '{print $6}'

# 2. Profile memory allocations
instruments -t "Allocations" -l 30 /Applications/PermissionPilot.app

# 3. Check screenshot cache
du -sh ~/Library/Application\ Support/PermissionPilot/screenshots/

# 4. Check database size
du -sh ~/Library/Application\ Support/PermissionPilot/audit.db
```

**Solutions:**
1. Clear screenshots: Settings → Screenshot Storage → Clear
2. Trim old logs: Settings → Database Cleanup → Delete >60 days
3. Disable screenshots: Settings → Capture Screenshots → Off
4. Restart daemon

### Daemon Crashes (Repeatedly)

**Diagnosis:**
```bash
# 1. Check crash logs
cat ~/Library/Logs/DiagnosticMessages/PermissionPilot_*.crash

# 2. Enable debug logging
defaults write com.permissionpilot.app DebugLogging -bool true

# 3. Check system logs
log show --predicate 'process == "PermissionPilot"' --last 1h

# 4. Get crash stack trace
log show --predicate 'eventMessage contains "Exception"' --last 24h
```

**Solutions:**
1. Report crash with full log and stack trace
2. Try safe mode: Remove policies, restart
3. Clear database: Reset to defaults
4. Reinstall application

### Dialogs Not Being Detected

**Diagnosis:**
```bash
# 1. Check if detection is running
log stream --predicate 'message contains "detection"' --level debug

# 2. Verify accessibility permission
defaults read com.apple.universalaccess | grep PermissionPilot

# 3. Check OCR status
log stream --predicate 'message contains "OCR"' --level debug

# 4. Monitor for dialogs
for i in {1..60}; do
  sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
    "SELECT COUNT(*) FROM automation_events WHERE timestamp > datetime('now', '-1 minute');"
  sleep 1
done
```

**Solutions:**
1. Grant Accessibility permission: System Preferences → Security & Privacy
2. Restart daemon
3. Enable OCR: Settings → OCR → On
4. Lower confidence threshold: Settings → Sensitivity
5. Check app is in known apps list

### Wrong Buttons Being Clicked

**Diagnosis:**
```bash
# 1. Get recent events with button info
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db << 'EOF'
SELECT 
    timestamp,
    app_name,
    dialog_title,
    button_clicked,
    button_safety_score,
    action_taken
FROM automation_events
WHERE timestamp > datetime('now', '-1 hour')
ORDER BY timestamp DESC;
EOF

# 2. Check button safety analysis
log stream --predicate 'message contains "button"' --level debug | head -30

# 3. Review screenshots
ls ~/Library/Application\ Support/PermissionPilot/screenshots/ | head -5
```

**Solutions:**
1. Add app to blacklist: Settings → Policies → Blacklist
2. Create custom rule: Settings → Policies → Create Rule
3. Lower button confidence: Settings → Sensitivity
4. Review and approve/reject manually: Logs tab

---

## Monitoring Dashboards

### Real-time Monitoring Script

Create a monitoring dashboard:

```bash
#!/bin/bash
# monitor-permissionpilot.sh

watch -n 2 'echo "=== PermissionPilot Status ===" && \
  ps aux | grep PermissionPilot | grep -v grep && \
  echo && \
  echo "=== Recent Dialogs (Last 1 hour) ===" && \
  sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
    "SELECT COUNT(*) FROM automation_events WHERE timestamp > datetime(\"now\", \"-1 hour\");" && \
  echo && \
  echo "=== Success Rate (Last 24h) ===" && \
  sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
    "SELECT ROUND(100.0 * SUM(CASE WHEN automation_success = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) FROM automation_events WHERE timestamp > datetime(\"now\", \"-24 hours\");" && \
  echo && \
  echo "=== Disk Usage ===" && \
  du -sh ~/Library/Application\ Support/PermissionPilot/
'
```

Run it:
```bash
chmod +x monitor-permissionpilot.sh
./monitor-permissionpilot.sh
```

### Web Dashboard (Future)

Planned for v2.0: Web-based dashboard with:
- Real-time metrics
- Historical charts
- Alert configuration
- Remote monitoring

---

## Health Check Script

Automated health verification:

```bash
#!/bin/bash
# health-check.sh

echo "PermissionPilot Health Check"
echo "============================"

# 1. Daemon running
DAEMON_RUNNING=$(launchctl list | grep -c permissionpilot)
echo "[$([ $DAEMON_RUNNING -eq 1 ] && echo '✓' || echo '✗')] Daemon Running"

# 2. Accessibility Permission
ACC_PERM=$(defaults read com.apple.universalaccess | grep -c PermissionPilot)
echo "[$([ $ACC_PERM -eq 1 ] && echo '✓' || echo '✗')] Accessibility Permission"

# 3. Database Health
DB_HEALTH=$(sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db "PRAGMA integrity_check;" 2>&1)
echo "[$([ "$DB_HEALTH" = "ok" ] && echo '✓' || echo '✗')] Database Integrity"

# 4. Recent Activity (last 24h)
RECENT=$(sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "SELECT COUNT(*) FROM automation_events WHERE timestamp > datetime('now', '-24 hours');")
echo "[✓] Recent Activity: $RECENT dialogs (24h)"

# 5. Success Rate (last 24h)
SUCCESS=$(sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "SELECT ROUND(100.0 * SUM(CASE WHEN automation_success = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) FROM automation_events WHERE timestamp > datetime('now', '-24 hours');")
echo "[$([ $(echo "$SUCCESS > 90" | bc) -eq 1 ] && echo '✓' || echo '✗')] Success Rate: $SUCCESS%"

# 6. Disk Usage
DISK=$(du -sh ~/Library/Application\ Support/PermissionPilot/ | awk '{print $1}')
echo "[✓] Disk Usage: $DISK"

echo ""
echo "Health check complete!"
```

---

## Questions & Support

- **Monitoring Questions:** [GitHub Discussions](https://github.com/ChaitanyaJoshi1769/PermissionPilot/discussions)
- **Report Issues:** [GitHub Issues](https://github.com/ChaitanyaJoshi1769/PermissionPilot/issues)
- **Contact:** dev@permissionpilot.app

---

**Last updated:** May 13, 2024  
**Version:** 1.0.0
