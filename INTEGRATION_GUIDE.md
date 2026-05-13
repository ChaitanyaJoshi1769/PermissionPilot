# Integration Guide

Integrate PermissionPilot with other macOS tools, scripts, and workflows.

---

## Overview

This guide covers:
- **System Integration** - LaunchAgent, system events, file watching
- **Automation Tools** - Automator, AppleScript, shortcuts
- **Development Tools** - Xcode, build scripts, CI/CD
- **Monitoring Tools** - Splunk, Datadog, CloudWatch
- **Scripting Integration** - Bash, Python, Node.js
- **API Integration** - JSON, webhooks, remote APIs
- **Third-party Apps** - Slack, Discord, email notifications

---

## System Integration

### LaunchAgent Configuration

PermissionPilot runs as a LaunchAgent. Customize it:

```bash
# Edit daemon configuration
nano ~/Library/LaunchAgents/com.permissionpilot.daemon.plist
```

**Configuration Options:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <!-- Run on login -->
  <key>RunAtLoad</key>
  <true/>
  
  <!-- Keep running even if crashes -->
  <key>KeepAlive</key>
  <true/>
  
  <!-- Auto-restart on failure -->
  <key>SuccessfulExit</key>
  <integer>0</integer>
  
  <!-- Process name -->
  <key>Label</key>
  <string>com.permissionpilot.daemon</string>
  
  <!-- Path to executable -->
  <key>ProgramArguments</key>
  <array>
    <string>/Applications/PermissionPilot.app/Contents/MacOS/PermissionPilot</string>
  </array>
  
  <!-- Standard output/error redirection -->
  <key>StandardOutPath</key>
  <string>/tmp/permissionpilot.log</string>
  
  <key>StandardErrorPath</key>
  <string>/tmp/permissionpilot.error.log</string>
  
  <!-- Environment variables -->
  <key>EnvironmentVariables</key>
  <dict>
    <key>DEBUG</key>
    <string>1</string>
  </dict>
  
  <!-- Resource limits -->
  <key>SoftResourceLimits</key>
  <dict>
    <key>NumberOfFiles</key>
    <integer>1024</integer>
  </dict>
</dict>
</plist>
```

### Post-Login Hooks

Run scripts after PermissionPilot starts:

```bash
#!/bin/bash
# post-login-hook.sh - Run after daemon starts

# 1. Verify daemon is running
if pgrep -f "PermissionPilot" > /dev/null; then
  echo "PermissionPilot daemon started"
fi

# 2. Load custom policies
if [ -f ~/.permissionpilot/custom-policies.json ]; then
  cp ~/.permissionpilot/custom-policies.json \
    ~/Library/Application\ Support/PermissionPilot/policies.json
fi

# 3. Log startup event
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "INSERT INTO audit_log (event_type, reason, severity) VALUES ('DAEMON_STARTED', 'Login hook', 'LOW');"

# 4. Send notification
osascript -e 'display notification "PermissionPilot started" with title "System"'
```

### System Event Monitoring

Monitor system events and respond:

```bash
#!/bin/bash
# monitor-system-events.sh - React to system events

# Monitor for sleep/wake
while true; do
  pmset -g log | tail -1 | grep -q "Wake" && {
    echo "System woke up - restarting daemon"
    launchctl stop com.permissionpilot.daemon
    sleep 1
    launchctl start com.permissionpilot.daemon
  }
  sleep 10
done

# Or detect via log streaming
log stream --predicate 'process == "loginwindow"' | while read line; do
  echo "$line" | grep -q "Logging in" && {
    launchctl start com.permissionpilot.daemon
  }
done
```

---

## Automation Tools

### Automator Workflow Integration

**Create Automator Workflow:**

1. Open Automator
2. File → New → Workflow
3. Add Actions:
   - "Run Shell Script"
   - "Ask for text"
   - "Send notification"

**Example Workflow - Reload Policies:**

```bash
#!/bin/bash
# Reload PermissionPilot policies

# Kill current daemon
launchctl stop com.permissionpilot.daemon

# Wait
sleep 2

# Restart
launchctl start com.permissionpilot.daemon

# Notify
osascript << EOF
display notification "Policies reloaded" with title "PermissionPilot"
EOF
```

### AppleScript Integration

```applescript
-- permissionpilot-control.applescript

-- Check if PermissionPilot is running
tell application "System Events"
  if (name of processes) contains "PermissionPilot" then
    display notification "PermissionPilot is running"
  else
    display notification "PermissionPilot is not running"
  end if
end tell

-- Launch PermissionPilot
tell application "PermissionPilot"
  activate
end tell

-- Get PermissionPilot process info
tell application "System Events"
  tell process "PermissionPilot"
    -- Get window properties
    tell windows
      set window_name to name of window 1
    end tell
  end tell
end tell
```

### macOS Shortcuts Integration

**Create Shortcut for PermissionPilot Control:**

```
Shortcut: "Control PermissionPilot"

1. Ask for choice: "Start", "Stop", "Reload Policies"

2. If choice = "Start"
   - Run shell script:
     launchctl start com.permissionpilot.daemon
   - Show notification: "PermissionPilot started"

3. If choice = "Stop"
   - Run shell script:
     launchctl stop com.permissionpilot.daemon
   - Show notification: "PermissionPilot stopped"

4. If choice = "Reload Policies"
   - Run shell script:
     launchctl stop com.permissionpilot.daemon
     sleep 2
     launchctl start com.permissionpilot.daemon
   - Show notification: "Policies reloaded"
```

---

## Development Tool Integration

### Xcode Build Scripts

Automatically grant permissions during development:

```bash
#!/bin/bash
# build-post-action.sh - Post-build action

# Check if PermissionPilot is installed
if [ ! -d "/Applications/PermissionPilot.app" ]; then
  echo "Installing PermissionPilot..."
  # Build and copy to Applications
  xcodebuild -scheme PermissionPilot
  cp -r build/PermissionPilot.app /Applications/
fi

# Grant accessibility permission
sqlite3 ~/Library/Application\ Support/com.apple.LaunchServices.QuarantineResolver/QuarantineEvents.db \
  "INSERT OR IGNORE INTO LSQuarantineEvent VALUES ('0;...');"
```

### Build System Integration

**Makefile target for PermissionPilot integration:**

```makefile
.PHONY: setup-pp deploy-pp

setup-pp:
	@echo "Setting up PermissionPilot for development..."
	@xcodebuild build -scheme PermissionPilot
	@cp -r build/PermissionPilot.app /Applications/
	@open /Applications/PermissionPilot.app

deploy-pp:
	@echo "Deploying PermissionPilot..."
	@./Scripts/build.sh release
	@./Scripts/sign-and-notarize.sh build/PermissionPilot.xcarchive
	@cp build/PermissionPilot.dmg ~/Desktop/

test-with-pp: setup-pp
	@echo "Running tests with PermissionPilot..."
	@xcodebuild test -scheme MyApp
```

### Continuous Integration (GitHub Actions)

```yaml
name: Install PermissionPilot

on: [push, pull_request]

jobs:
  setup:
    runs-on: macos-latest
    steps:
      - name: Download PermissionPilot
        run: |
          curl -L https://github.com/ChaitanyaJoshi1769/PermissionPilot/releases/download/v1.0.0/PermissionPilot.dmg -o /tmp/PP.dmg
          hdiutil attach /tmp/PP.dmg
          cp -r /Volumes/PermissionPilot/PermissionPilot.app /Applications/
          hdiutil detach /Volumes/PermissionPilot
      
      - name: Grant accessibility permission
        run: |
          # Add to accessibility list
          sqlite3 ~/Library/Preferences/com.apple.accessibility.plist \
            "INSERT OR IGNORE INTO whitelist VALUES ('/Applications/PermissionPilot.app');"
      
      - name: Verify installation
        run: |
          if [ -d "/Applications/PermissionPilot.app" ]; then
            echo "✓ PermissionPilot installed"
          fi
      
      - name: Run tests
        run: xcodebuild test -scheme MyApp
```

---

## Monitoring Integration

### Splunk Integration

**Forward PermissionPilot logs to Splunk:**

```bash
#!/bin/bash
# splunk-forward.sh

SPLUNK_HEC_TOKEN="your-token"
SPLUNK_HEC_URL="https://splunk.company.com:8088"

# Get recent events
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "SELECT timestamp, app_name, action_taken, trust_score FROM automation_events WHERE timestamp > datetime('now', '-1 hour');" \
  | while IFS='|' read timestamp app action trust; do
    
    # Format as JSON
    json="{
      \"host\": \"$(hostname)\",
      \"source\": \"permissionpilot\",
      \"sourcetype\": \"json\",
      \"time\": \"$(date -f %s)\",
      \"event\": {
        \"timestamp\": \"$timestamp\",
        \"app\": \"$app\",
        \"action\": \"$action\",
        \"trust_score\": \"$trust\"
      }
    }"
    
    # Send to Splunk HEC
    curl -k -H "Authorization: Splunk $SPLUNK_HEC_TOKEN" \
      -d "$json" \
      "$SPLUNK_HEC_URL/services/collector"
  done
```

### Datadog Integration

```bash
#!/bin/bash
# datadog-metrics.sh - Send metrics to Datadog

API_KEY="your-datadog-api-key"
DATADOG_URL="https://api.datadoghq.com/api/v1/series"

# Get statistics
TOTAL_EVENTS=$(sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "SELECT COUNT(*) FROM automation_events WHERE timestamp > datetime('now', '-24 hours');")

SUCCESS_RATE=$(sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "SELECT ROUND(100.0 * SUM(CASE WHEN automation_success = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) FROM automation_events WHERE timestamp > datetime('now', '-24 hours');")

# Format and send metrics
METRICS=$(cat <<EOF
{
  "series": [
    {
      "metric": "permissionpilot.dialogs.total",
      "points": [["$(date +%s)", $TOTAL_EVENTS]],
      "type": "gauge",
      "tags": ["host:$(hostname)"]
    },
    {
      "metric": "permissionpilot.automation.success_rate",
      "points": [["$(date +%s)", $SUCCESS_RATE]],
      "type": "gauge",
      "tags": ["host:$(hostname)"]
    }
  ]
}
EOF
)

curl -X POST "$DATADOG_URL?api_key=$API_KEY" \
  -H "Content-Type: application/json" \
  -d "$METRICS"
```

### CloudWatch Integration

```bash
#!/bin/bash
# cloudwatch-logs.sh - Send logs to AWS CloudWatch

LOG_GROUP="/aws/permissionpilot"
LOG_STREAM="$(hostname)"

# Create log group/stream if needed
aws logs create-log-group --log-group-name "$LOG_GROUP" 2>/dev/null || true
aws logs create-log-stream --log-group-name "$LOG_GROUP" --log-stream-name "$LOG_STREAM" 2>/dev/null || true

# Get recent events from database
EVENTS=$(sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "SELECT json_object('timestamp', timestamp, 'app', app_name, 'action', action_taken) FROM automation_events WHERE timestamp > datetime('now', '-1 hour');")

# Send to CloudWatch
aws logs put-log-events \
  --log-group-name "$LOG_GROUP" \
  --log-stream-name "$LOG_STREAM" \
  --log-events "[{\"message\": \"$EVENTS\", \"timestamp\": $(date +%s)000}]"
```

---

## Scripting Integration

### Bash Integration

```bash
#!/bin/bash
# permissionpilot-lib.sh - Library for PermissionPilot integration

# Check if running
pp_is_running() {
  launchctl list | grep -q "com.permissionpilot.daemon"
}

# Start daemon
pp_start() {
  launchctl start com.permissionpilot.daemon
  sleep 2
}

# Stop daemon
pp_stop() {
  launchctl stop com.permissionpilot.daemon
  sleep 2
}

# Get recent event count
pp_recent_events() {
  sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
    "SELECT COUNT(*) FROM automation_events WHERE timestamp > datetime('now', '-$1 minutes');"
}

# Get success rate
pp_success_rate() {
  sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
    "SELECT ROUND(100.0 * SUM(CASE WHEN automation_success = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) FROM automation_events WHERE timestamp > datetime('now', '-$1 hours');"
}

# Get top apps
pp_top_apps() {
  sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
    "SELECT app_name, COUNT(*) as count FROM automation_events WHERE timestamp > datetime('now', '-$1 days') GROUP BY app_name ORDER BY count DESC LIMIT 10;"
}

# Usage examples:
# pp_is_running && echo "Running" || echo "Not running"
# pp_recent_events 60
# pp_success_rate 24
# pp_top_apps 7
```

### Python Integration

```python
#!/usr/bin/env python3
# permissionpilot_client.py - Python library for PermissionPilot

import sqlite3
import json
import os
from pathlib import Path

class PermissionPilotClient:
    def __init__(self):
        self.db_path = Path.home() / "Library/Application Support/PermissionPilot/audit.db"
    
    def get_events(self, hours=24, limit=100):
        """Get recent automation events"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        query = f"""
            SELECT id, timestamp, app_name, action_taken, trust_score 
            FROM automation_events 
            WHERE timestamp > datetime('now', '-{hours} hours')
            ORDER BY timestamp DESC
            LIMIT {limit}
        """
        
        cursor.execute(query)
        events = cursor.fetchall()
        conn.close()
        
        return [
            {
                'id': e[0],
                'timestamp': e[1],
                'app': e[2],
                'action': e[3],
                'trust_score': e[4]
            }
            for e in events
        ]
    
    def get_statistics(self, days=30):
        """Get usage statistics"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute(f"""
            SELECT 
                COUNT(*) as total_dialogs,
                SUM(CASE WHEN automation_success = 1 THEN 1 ELSE 0 END) as successful,
                ROUND(100.0 * SUM(CASE WHEN automation_success = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) as success_rate,
                AVG(trust_score) as avg_trust_score
            FROM automation_events
            WHERE timestamp > datetime('now', '-{days} days')
        """)
        
        result = cursor.fetchone()
        conn.close()
        
        return {
            'total_dialogs': result[0],
            'successful': result[1],
            'success_rate': result[2],
            'avg_trust_score': result[3]
        }
    
    def get_top_apps(self, days=7, limit=10):
        """Get apps with most dialogs"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute(f"""
            SELECT app_name, COUNT(*) as count
            FROM automation_events
            WHERE timestamp > datetime('now', '-{days} days')
            GROUP BY app_name
            ORDER BY count DESC
            LIMIT {limit}
        """)
        
        apps = cursor.fetchall()
        conn.close()
        
        return [{'app': a[0], 'count': a[1]} for a in apps]

# Usage
if __name__ == "__main__":
    pp = PermissionPilotClient()
    
    # Get recent events
    events = pp.get_events(hours=24, limit=10)
    print(json.dumps(events, indent=2))
    
    # Get statistics
    stats = pp.get_statistics(days=30)
    print(json.dumps(stats, indent=2))
    
    # Get top apps
    top_apps = pp.get_top_apps(days=7, limit=5)
    print(json.dumps(top_apps, indent=2))
```

### Node.js Integration

```javascript
// permissionpilot-client.js - Node.js library

const Database = require('better-sqlite3');
const path = require('path');
const os = require('os');

class PermissionPilotClient {
  constructor() {
    const dbPath = path.join(
      os.homedir(),
      'Library/Application Support/PermissionPilot/audit.db'
    );
    this.db = new Database(dbPath);
  }

  getEvents(hours = 24, limit = 100) {
    const query = `
      SELECT id, timestamp, app_name, action_taken, trust_score 
      FROM automation_events 
      WHERE timestamp > datetime('now', '-${hours} hours')
      ORDER BY timestamp DESC
      LIMIT ${limit}
    `;
    
    return this.db.prepare(query).all();
  }

  getStatistics(days = 30) {
    const query = `
      SELECT 
        COUNT(*) as total_dialogs,
        SUM(CASE WHEN automation_success = 1 THEN 1 ELSE 0 END) as successful,
        ROUND(100.0 * SUM(CASE WHEN automation_success = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) as success_rate
      FROM automation_events
      WHERE timestamp > datetime('now', '-${days} days')
    `;
    
    return this.db.prepare(query).get();
  }

  getTopApps(days = 7, limit = 10) {
    const query = `
      SELECT app_name, COUNT(*) as count
      FROM automation_events
      WHERE timestamp > datetime('now', '-${days} days')
      GROUP BY app_name
      ORDER BY count DESC
      LIMIT ${limit}
    `;
    
    return this.db.prepare(query).all();
  }

  close() {
    this.db.close();
  }
}

module.exports = PermissionPilotClient;
```

---

## Notification Integration

### Slack Notifications

```bash
#!/bin/bash
# slack-notify.sh - Send alerts to Slack

SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

# Get statistics
EVENTS=$(sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "SELECT COUNT(*) FROM automation_events WHERE timestamp > datetime('now', '-1 hour');")

SUCCESS=$(sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "SELECT ROUND(100.0 * SUM(CASE WHEN automation_success = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) FROM automation_events WHERE timestamp > datetime('now', '-1 hour');")

# Send Slack message
curl -X POST "$SLACK_WEBHOOK" \
  -H 'Content-type: application/json' \
  -d "{
    \"text\": \"PermissionPilot Update\",
    \"blocks\": [
      {
        \"type\": \"section\",
        \"text\": {
          \"type\": \"mrkdwn\",
          \"text\": \"*PermissionPilot Statistics*\n\nDialogs detected: $EVENTS\nSuccess rate: $SUCCESS%\"
        }
      }
    ]
  }"
```

### Email Notifications

```bash
#!/bin/bash
# email-notify.sh - Send daily digest email

RECIPIENT="admin@company.com"
SUBJECT="PermissionPilot Daily Report"

STATS=$(sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db << 'EOF'
SELECT 
  'Total Dialogs: ' || COUNT(*) ||
  E'\n' ||
  'Success Rate: ' || ROUND(100.0 * SUM(CASE WHEN automation_success = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) || '%'
FROM automation_events
WHERE timestamp > datetime('now', '-24 hours');
EOF
)

echo "$STATS" | mail -s "$SUBJECT" "$RECIPIENT"
```

---

## Questions & Support

- **Integration Help:** [GitHub Discussions](https://github.com/ChaitanyaJoshi1769/PermissionPilot/discussions)
- **Report Issues:** [GitHub Issues](https://github.com/ChaitanyaJoshi1769/PermissionPilot/issues)
- **Email:** dev@permissionpilot.app

---

**Last updated:** May 13, 2024  
**Version:** 1.0.0
