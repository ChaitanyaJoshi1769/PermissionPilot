# Configuration Guide

Advanced configuration for power users, system administrators, and organizations.

---

## Overview

PermissionPilot is highly configurable. This guide covers:
- **Configuration Files** - Where and how to edit settings
- **Policy System** - Creating and managing policies
- **Advanced Rules** - Regex patterns and conditional logic
- **Settings Reference** - All available options
- **Deployment** - Multi-machine setup and management
- **Integration** - Connecting with other tools

---

## Configuration File Locations

### Main Configuration File

```
~/Library/Application Support/PermissionPilot/config.json
```

**Location Breakdown:**
- `~` = User home directory
- `Library/Application Support` = Standard macOS app data location
- Accessible via Finder: Cmd+Shift+G → paste path

### Policy Files

```
~/Library/Application Support/PermissionPilot/policies.json
~/Library/Application Support/PermissionPilot/policies-custom.json (optional)
```

### Audit Database

```
~/Library/Application Support/PermissionPilot/audit.db
```

### Daemon Configuration

```
~/Library/LaunchAgents/com.permissionpilot.daemon.plist
```

---

## Configuration File Structure

### Main Config (config.json)

```json
{
  "version": "1.0.0",
  
  "daemon": {
    "enabled": true,
    "auto_start": true,
    "polling_interval_ms": 500,
    "debounce_ms": 100,
    "timeout_seconds": 30
  },
  
  "detection": {
    "method": "hybrid",
    "accessibility_api_enabled": true,
    "ocr_enabled": true,
    "ocr_fallback_enabled": true,
    "confidence_threshold": 0.85,
    "max_detection_retries": 3,
    "detection_cache_ttl_seconds": 60
  },
  
  "automation": {
    "enabled": true,
    "human_like_behavior": true,
    "mouse_speed_ms": 100,
    "mouse_curve": "bezier",
    "click_delay_ms": 150,
    "type_speed_wpm": 60,
    "reaction_time_ms": 200
  },
  
  "trust": {
    "default_threshold": 0.5,
    "auto_allow_threshold": 0.8,
    "auto_block_threshold": 0.3,
    "require_user_confirmation_threshold": 0.5
  },
  
  "security": {
    "require_accessibility_permission": true,
    "block_dangerous_keywords": true,
    "require_notarization": false,
    "verify_code_signature": true,
    "max_failed_attempts_before_lockout": 5
  },
  
  "database": {
    "max_retention_days": 90,
    "auto_vacuum_enabled": true,
    "auto_vacuum_interval_hours": 24,
    "backup_enabled": true,
    "backup_interval_hours": 168
  },
  
  "screenshots": {
    "capture_enabled": false,
    "capture_for_ocr": true,
    "retention_days": 7,
    "compression": "png",
    "quality": 95
  },
  
  "logging": {
    "debug_mode": false,
    "log_level": "info",
    "console_output": false,
    "file_output": true,
    "log_rotation_mb": 100
  },
  
  "ui": {
    "theme": "system",
    "notification_style": "badge",
    "show_statistics": true,
    "auto_hide_dashboard": true,
    "update_check_enabled": true
  }
}
```

### Policies File (policies.json)

```json
{
  "version": "1.0.0",
  "policies": [
    {
      "id": "whitelist-apple",
      "name": "Apple Applications",
      "description": "Auto-allow dialogs from Apple apps",
      "enabled": true,
      "type": "whitelist",
      "target_type": "app",
      "target_values": [
        "com.apple.systempreferences",
        "com.apple.finder",
        "com.apple.mail",
        "com.apple.Safari"
      ],
      "action": "allow",
      "priority": 10,
      "created_at": "2024-05-13T10:00:00Z"
    },
    {
      "id": "blacklist-deletions",
      "name": "Block Deletion Dialogs",
      "description": "Never auto-click delete/erase/reset buttons",
      "enabled": true,
      "type": "rule",
      "target_type": "dialog_text",
      "target_pattern": "(?i)(delete|erase|reset|remove|permanent)",
      "action": "block",
      "priority": 5,
      "created_at": "2024-05-13T10:15:00Z"
    },
    {
      "id": "rule-notifications",
      "name": "Allow Browser Notifications",
      "description": "Auto-approve notification permission requests",
      "enabled": true,
      "type": "rule",
      "target_type": "dialog_title",
      "target_pattern": "(?i)(notification|notifications)",
      "action": "allow",
      "confidence_threshold": 0.8,
      "priority": 50,
      "created_at": "2024-05-13T10:30:00Z"
    }
  ]
}
```

---

## Policy System

### Policy Types

#### 1. Whitelist Policies

Auto-approve all dialogs from specified apps.

```json
{
  "id": "whitelist-dev-tools",
  "name": "Development Tools",
  "type": "whitelist",
  "target_type": "app",
  "target_values": [
    "com.apple.dt.Xcode",
    "com.cursormaven.cursor",
    "com.microsoft.VSCode"
  ],
  "action": "allow",
  "priority": 20
}
```

**Target Options:**
- `app` - Bundle ID or app name
- `app_developer` - Developer ID or organization
- `app_category` - Type of app (browser, development, productivity)

#### 2. Blacklist Policies

Auto-block all dialogs from specified apps.

```json
{
  "id": "blacklist-unknown-apps",
  "name": "Block Unknown Applications",
  "type": "blacklist",
  "target_type": "app",
  "target_values": ["com.unknown.*"],
  "action": "block",
  "priority": 5
}
```

#### 3. Rule Policies

Conditional rules with pattern matching.

```json
{
  "id": "rule-camera",
  "name": "Allow Camera Access",
  "type": "rule",
  "target_type": "dialog_text",
  "target_pattern": "(?i)(camera|webcam|video|microphone|audio)",
  "action": "allow",
  "confidence_threshold": 0.85,
  "excluded_apps": ["com.unknown.app"],
  "priority": 50
}
```

---

## Advanced Pattern Matching

### Regex Pattern Syntax

PermissionPilot uses Swift's standard regex syntax (ISO 22028-1).

#### Common Patterns

**Allow notification requests:**
```regex
(?i)(notification|notify|alert)
```

**Block dangerous operations:**
```regex
(?i)(delete|erase|format|remove|uninstall|reset|discard|destroy|wipe)
```

**Specific app pattern:**
```regex
^com\.google\.Chrome$
```

**Partial bundle ID match:**
```regex
com\.google\..*
```

**Dialog with multiple keywords:**
```regex
(?i)(allow|permit).*(camera|microphone|location)
```

**Negative lookahead (NOT delete):**
```regex
(?i)^(?!.*delete).*(allow|permit).*
```

#### Pattern Testing

Test patterns before deploying:

```bash
# Create test policy with pattern
# Add to policies.json, then test by triggering dialog

# Or use online regex tester:
# https://regex101.com/
# Mode: PCRE, Multiline ON, Case Insensitive ON
```

---

## Settings Reference

### Daemon Settings

```json
"daemon": {
  "enabled": true,                    // Enable/disable daemon
  "auto_start": true,                 // Auto-start with macOS login
  "polling_interval_ms": 500,         // Check for dialogs every Xms
  "debounce_ms": 100,                 // Ignore repeated dialogs <100ms
  "timeout_seconds": 30               // Max time to wait for dialog
}
```

**Recommended Values:**
- **High performance mode** (max CPU): polling_interval_ms: 250
- **Balanced**: polling_interval_ms: 500 (default)
- **Low power mode** (max battery): polling_interval_ms: 1000

### Detection Settings

```json
"detection": {
  "method": "hybrid",                 // "accessibility_api", "ocr", or "hybrid"
  "accessibility_api_enabled": true,  // Use Accessibility API
  "ocr_enabled": true,                // Use Vision Framework OCR
  "ocr_fallback_enabled": true,       // Fall back to OCR if Accessibility fails
  "confidence_threshold": 0.85,       // Minimum confidence (0-1)
  "max_detection_retries": 3,         // Retry detection N times
  "detection_cache_ttl_seconds": 60   // Cache detection results for N seconds
}
```

**Detection Method Comparison:**

| Method | Speed | Accuracy | CPU | Coverage |
|--------|-------|----------|-----|----------|
| Accessibility API | <100ms | 95% | Low | 80% (standard UIs) |
| OCR | 200-350ms | 90% | High | 99% (any UI) |
| Hybrid | 100-350ms | 98% | Medium | 99% (best of both) |

### Automation Settings

```json
"automation": {
  "enabled": true,                    // Enable/disable automation
  "human_like_behavior": true,        // Use natural-looking mouse movement
  "mouse_speed_ms": 100,              // Time to move mouse (ms)
  "mouse_curve": "bezier",            // "linear" or "bezier"
  "click_delay_ms": 150,              // Delay before clicking (ms)
  "type_speed_wpm": 60,               // Typing speed (words per minute)
  "reaction_time_ms": 200             // Reaction time before action (ms)
}
```

**Performance Tuning:**
- **Fast clicking** (less human-like): click_delay_ms: 50, mouse_speed_ms: 50
- **Normal** (default): click_delay_ms: 150, mouse_speed_ms: 100
- **Slow/sneaky** (very human-like): click_delay_ms: 300, mouse_speed_ms: 200

### Trust Settings

```json
"trust": {
  "default_threshold": 0.5,           // Default decision threshold
  "auto_allow_threshold": 0.8,        // Auto-allow if score ≥ this
  "auto_block_threshold": 0.3,        // Auto-block if score ≤ this
  "require_user_confirmation_threshold": 0.5  // Ask user if score between auto thresholds
}
```

**Decision Matrix:**

```
Score ≥ 0.8:  AUTO ALLOW (ALLOW_ONCE)
Score 0.5-0.8: ASK USER (MANUAL)
Score ≤ 0.3:  AUTO BLOCK
```

### Security Settings

```json
"security": {
  "require_accessibility_permission": true,   // Require Accessibility (always true)
  "block_dangerous_keywords": true,           // Block delete/erase dialogs
  "require_notarization": false,              // Only trust notarized apps
  "verify_code_signature": true,              // Verify app is code-signed
  "max_failed_attempts_before_lockout": 5    // Lock daemon after N failures
}
```

### Database Settings

```json
"database": {
  "max_retention_days": 90,           // Keep events for 90 days
  "auto_vacuum_enabled": true,        // Auto-clean database
  "auto_vacuum_interval_hours": 24,   // Clean daily
  "backup_enabled": true,             // Create backup files
  "backup_interval_hours": 168        // Backup weekly
}
```

### Logging Settings

```json
"logging": {
  "debug_mode": false,                // Enable debug logs
  "log_level": "info",                // "debug", "info", "warning", "error"
  "console_output": false,            // Log to console (verbose)
  "file_output": true,                // Log to file
  "log_rotation_mb": 100              // Rotate logs at 100MB
}
```

---

## Advanced Configuration Examples

### Enterprise Deployment

Configuration for organizations with strict security requirements:

```json
{
  "daemon": {
    "auto_start": true,
    "polling_interval_ms": 1000
  },
  
  "detection": {
    "method": "accessibility_api",
    "ocr_enabled": false,
    "confidence_threshold": 0.95
  },
  
  "automation": {
    "human_like_behavior": true,
    "click_delay_ms": 300
  },
  
  "security": {
    "require_notarization": true,
    "block_dangerous_keywords": true,
    "verify_code_signature": true
  },
  
  "logging": {
    "debug_mode": true,
    "log_level": "info",
    "file_output": true
  }
}
```

**Policy for Enterprise:**

```json
{
  "policies": [
    {
      "name": "Apple & Microsoft Only",
      "type": "whitelist",
      "target_type": "app",
      "target_values": [
        "com.apple.*",
        "com.microsoft.*"
      ],
      "action": "allow",
      "priority": 5
    },
    {
      "name": "Block Any Unknown",
      "type": "blacklist",
      "target_type": "app",
      "target_values": ["*"],
      "action": "block",
      "priority": 100
    }
  ]
}
```

### Developer Mode

Configuration for developers with many tools and dialogs:

```json
{
  "daemon": {
    "polling_interval_ms": 250
  },
  
  "detection": {
    "method": "hybrid",
    "confidence_threshold": 0.75
  },
  
  "automation": {
    "click_delay_ms": 50,
    "mouse_speed_ms": 50
  },
  
  "security": {
    "block_dangerous_keywords": true
  }
}
```

**Policies for Developers:**

```json
{
  "policies": [
    {
      "name": "Development Tools Whitelist",
      "type": "whitelist",
      "target_type": "app",
      "target_values": [
        "com.apple.dt.Xcode",
        "com.cursormaven.cursor",
        "com.microsoft.VSCode",
        "com.jetbrains.pycharm",
        "com.github.github"
      ],
      "action": "allow",
      "priority": 20
    },
    {
      "name": "Browser Whitelist",
      "type": "whitelist",
      "target_type": "app",
      "target_values": [
        "com.google.Chrome",
        "com.apple.Safari",
        "org.mozilla.firefox"
      ],
      "action": "allow",
      "priority": 25
    },
    {
      "name": "Allow Permissions",
      "type": "rule",
      "target_type": "dialog_text",
      "target_pattern": "(?i)(permission|allow|permit|camera|microphone|notification)",
      "action": "allow",
      "priority": 50
    }
  ]
}
```

### Privacy Mode

Configuration for privacy-conscious users:

```json
{
  "detection": {
    "ocr_enabled": false,
    "confidence_threshold": 0.95
  },
  
  "security": {
    "require_notarization": true,
    "block_dangerous_keywords": true
  },
  
  "screenshots": {
    "capture_enabled": false
  },
  
  "automation": {
    "enabled": false
  },
  
  "logging": {
    "debug_mode": false
  }
}
```

**Policy for Privacy:**

```json
{
  "policies": [
    {
      "name": "Manual Review Only",
      "type": "rule",
      "target_type": "dialog_title",
      "target_pattern": ".*",
      "action": "ask",
      "priority": 1
    }
  ]
}
```

---

## Multi-Machine Deployment

### Deploying to Multiple Macs

**Option 1: Configuration Management (Recommended)**

Use MDM or configuration management:

```bash
# Copy configuration to all Macs
for mac in mac1 mac2 mac3; do
  ssh $mac "mkdir -p ~/Library/Application\ Support/PermissionPilot"
  scp config.json $mac:~/Library/Application\ Support/PermissionPilot/
  scp policies.json $mac:~/Library/Application\ Support/PermissionPilot/
done
```

**Option 2: Cloud Sync (Future)**

Planned for v2.0: iCloud or cloud-based configuration sync.

### Template Configuration Files

Create standard configurations:

```bash
# development.json - For development machines
# production.json - For production machines
# privacy.json - For privacy-focused machines
# enterprise.json - For enterprise deployments

# Deploy with:
cp templates/development.json ~/Library/Application\ Support/PermissionPilot/config.json
```

---

## Monitoring Configuration

### Verify Current Configuration

```bash
# Check active configuration
cat ~/Library/Application\ Support/PermissionPilot/config.json | jq .

# Check active policies
cat ~/Library/Application\ Support/PermissionPilot/policies.json | jq '.policies[] | {name, enabled, priority}'

# Check daemon configuration
cat ~/Library/LaunchAgents/com.permissionpilot.daemon.plist
```

### Configuration Validation

```bash
# Validate JSON syntax
jq empty < ~/Library/Application\ Support/PermissionPilot/config.json && echo "Valid" || echo "Invalid"

# Validate policies
jq '.policies[] | select(.priority == null)' \
  ~/Library/Application\ Support/PermissionPilot/policies.json && echo "Warning: Missing priorities"
```

---

## Troubleshooting Configuration

### Configuration Not Applied

1. Check file format: Ensure JSON is valid
2. Restart daemon: `launchctl stop/start ...`
3. Check permissions: `ls -l config.json` (should be readable)
4. Check logs: `log stream --predicate 'message contains "config"'`

### Policies Not Working

1. Verify policy is enabled: `"enabled": true`
2. Check pattern syntax: Test regex on regex101.com
3. Check priority: Lower priority = higher precedence
4. Review logs for policy evaluation

### Performance Issues

1. Reduce polling_interval_ms (increase check frequency)
2. Increase confidence_threshold (stricter detection)
3. Disable OCR: Set ocr_enabled: false
4. Profile with Activity Monitor

---

## Configuration File Editing

### Using GUI Text Editor

```bash
# Open in default editor
open ~/Library/Application\ Support/PermissionPilot/config.json

# Or specific editor
open -a "Visual Studio Code" ~/Library/Application\ Support/PermissionPilot/config.json
```

### Using Command Line

```bash
# Edit with nano
nano ~/Library/Application\ Support/PermissionPilot/config.json

# Edit with vim
vim ~/Library/Application\ Support/PermissionPilot/config.json

# View and edit in one command (nano)
nano ~/Library/Application\ Support/PermissionPilot/config.json
```

### Using jq for JSON Manipulation

```bash
# Update single value
jq '.daemon.polling_interval_ms = 1000' \
  ~/Library/Application\ Support/PermissionPilot/config.json > config.tmp && \
  mv config.tmp ~/Library/Application\ Support/PermissionPilot/config.json

# Add new policy
jq '.policies += [{name: "New Policy", type: "whitelist"}]' \
  ~/Library/Application\ Support/PermissionPilot/policies.json > policies.tmp && \
  mv policies.tmp ~/Library/Application\ Support/PermissionPilot/policies.json
```

---

## Configuration Backup & Recovery

### Backup Configuration

```bash
# Create backup
cp -r ~/Library/Application\ Support/PermissionPilot \
      ~/Library/Application\ Support/PermissionPilot.backup.$(date +%Y%m%d)

# Or with tarball
tar czf PermissionPilot-config-$(date +%Y%m%d).tar.gz \
  ~/Library/Application\ Support/PermissionPilot
```

### Restore Configuration

```bash
# Restore from backup
cp -r ~/Library/Application\ Support/PermissionPilot.backup.20240513/* \
      ~/Library/Application\ Support/PermissionPilot/

# Restart daemon
launchctl stop com.permissionpilot.daemon
launchctl start com.permissionpilot.daemon
```

---

## Questions?

- **Configuration Help:** [GitHub Discussions](https://github.com/ChaitanyaJoshi1769/PermissionPilot/discussions)
- **Report Issues:** [GitHub Issues](https://github.com/ChaitanyaJoshi1769/PermissionPilot/issues)
- **Email:** dev@permissionpilot.app

---

**Last updated:** May 13, 2024  
**Configuration Version:** 1.0.0
