# Database Schema Documentation

Complete reference for the PermissionPilot SQLite database schema, including tables, relationships, queries, and maintenance procedures.

---

## Overview

PermissionPilot uses **SQLite** for persistent audit logging and configuration storage. The database is located at:

```
~/Library/Application Support/PermissionPilot/audit.db
```

**Key Characteristics:**
- SQLite 3.x (embedded in Swift)
- Single-file database (~10MB for 50k events)
- Automatic vacuum enabled (circular retention)
- WAL (Write-Ahead Logging) mode for concurrent access
- Foreign keys enabled for referential integrity

---

## Database Tables

### 1. `automation_events` (Core Audit Log)

Records every dialog detection and automation action.

```sql
CREATE TABLE automation_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    event_uuid TEXT UNIQUE NOT NULL,
    
    -- Dialog Information
    dialog_title TEXT NOT NULL,
    dialog_text TEXT,
    dialog_type TEXT NOT NULL CHECK(dialog_type IN (
        'NATIVE_MACOS',
        'BROWSER',
        'APPLICATION',
        'INSTALLER',
        'CUSTOM',
        'UNKNOWN'
    )),
    
    -- Source Application
    app_pid INTEGER,
    app_name TEXT NOT NULL,
    app_path TEXT,
    app_bundle_id TEXT,
    
    -- Detection Details
    detection_method TEXT NOT NULL CHECK(detection_method IN (
        'ACCESSIBILITY_API',
        'OCR',
        'HYBRID'
    )),
    detection_confidence REAL NOT NULL CHECK(detection_confidence >= 0 AND detection_confidence <= 1),
    detection_time_ms INTEGER,
    
    -- Button Information
    button_clicked TEXT,
    button_position TEXT, -- JSON: {x, y, width, height}
    button_is_default INTEGER,
    button_safety_score REAL,
    
    -- Policy & Trust Decision
    applied_policy_name TEXT,
    trust_score REAL CHECK(trust_score >= 0 AND trust_score <= 1),
    trust_components TEXT, -- JSON: {notarization, known_app, history, reputation, dialog_type}
    action_taken TEXT NOT NULL CHECK(action_taken IN (
        'ALLOW_ONCE',
        'ALLOW_ALWAYS',
        'BLOCK',
        'BLOCKED_DANGEROUS',
        'BLOCKED_POLICY',
        'MANUAL',
        'MANUAL_ALLOWED',
        'MANUAL_BLOCKED',
        'TIMEOUT',
        'UNKNOWN'
    )),
    
    -- Automation Details
    automation_triggered INTEGER,
    automation_success INTEGER,
    automation_error TEXT,
    execution_time_ms INTEGER,
    
    -- Metadata
    user_override INTEGER DEFAULT 0,
    override_reason TEXT,
    screenshot_taken INTEGER DEFAULT 0,
    screenshot_path TEXT,
    notes TEXT,
    
    -- Data Retention
    archived INTEGER DEFAULT 0
);

CREATE INDEX idx_automation_events_timestamp ON automation_events(timestamp DESC);
CREATE INDEX idx_automation_events_app_name ON automation_events(app_name);
CREATE INDEX idx_automation_events_action ON automation_events(action_taken);
CREATE INDEX idx_automation_events_dialog_type ON automation_events(dialog_type);
CREATE INDEX idx_automation_events_uuid ON automation_events(event_uuid);
```

**Columns Breakdown:**

| Column | Type | Purpose | Example |
|--------|------|---------|---------|
| `id` | INTEGER | Auto-incrementing primary key | `1, 2, 3...` |
| `timestamp` | DATETIME | When dialog was detected | `2024-05-13 14:30:45.123` |
| `event_uuid` | TEXT | Globally unique ID | `550e8400-e29b-41d4-a716-446655440000` |
| `dialog_title` | TEXT | Dialog window title | `"Allow Camera Access?"` |
| `dialog_type` | TEXT | Category of dialog | `BROWSER`, `NATIVE_MACOS` |
| `app_name` | TEXT | Application name | `Google Chrome` |
| `app_bundle_id` | TEXT | macOS bundle identifier | `com.google.Chrome` |
| `detection_method` | TEXT | How it was detected | `ACCESSIBILITY_API`, `OCR` |
| `detection_confidence` | REAL | Confidence score 0-1 | `0.95` |
| `trust_score` | REAL | Final trust score 0-1 | `0.82` |
| `action_taken` | TEXT | What automation did | `ALLOW_ONCE`, `BLOCK` |
| `automation_triggered` | INTEGER | Was automation attempted | `1` (yes) or `0` (no) |
| `automation_success` | INTEGER | Did automation succeed | `1` (success), `0` (failed) |
| `execution_time_ms` | INTEGER | Total time elapsed | `342` |

---

### 2. `policies` (Configuration Storage)

Stores user-defined policies and rules.

```sql
CREATE TABLE policies (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    enabled INTEGER DEFAULT 1,
    
    -- Policy Type
    policy_type TEXT NOT NULL CHECK(policy_type IN (
        'WHITELIST',
        'BLACKLIST',
        'RULE'
    )),
    
    -- Target
    target_type TEXT CHECK(target_type IN (
        'APP',
        'DIALOG_PATTERN',
        'BUTTON_PATTERN',
        'GLOBAL'
    )),
    target_value TEXT, -- app name, regex pattern, etc.
    
    -- Action
    default_action TEXT NOT NULL CHECK(default_action IN (
        'ALLOW',
        'BLOCK',
        'ASK',
        'EVALUATE'
    )),
    
    -- Rule Configuration
    trust_threshold REAL,
    require_user_confirmation INTEGER DEFAULT 0,
    max_auto_clicks_per_minute INTEGER,
    timeout_seconds INTEGER DEFAULT 30,
    
    -- Metadata
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT DEFAULT 'user',
    priority INTEGER DEFAULT 100, -- Lower = higher priority
    
    -- Statistics
    times_applied INTEGER DEFAULT 0,
    last_applied DATETIME,
    success_rate REAL -- 0-1, calculated
);

CREATE INDEX idx_policies_name ON policies(name);
CREATE INDEX idx_policies_enabled ON policies(enabled);
CREATE INDEX idx_policies_priority ON policies(priority);
```

**Policy Types:**
- `WHITELIST` - Apps/dialogs to automatically allow
- `BLACKLIST` - Apps/dialogs to automatically block
- `RULE` - Custom conditional rules with patterns

---

### 3. `trust_history` (User Approval History)

Tracks user decisions for reputation building.

```sql
CREATE TABLE trust_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    app_bundle_id TEXT NOT NULL,
    app_name TEXT NOT NULL,
    
    -- Decision Tracking
    total_dialogs INTEGER DEFAULT 0,
    approved_dialogs INTEGER DEFAULT 0,
    blocked_dialogs INTEGER DEFAULT 0,
    
    -- Reputation Metrics
    approval_rate REAL, -- approved / total
    recent_approval_count INTEGER DEFAULT 0, -- last 7 days
    recent_block_count INTEGER DEFAULT 0, -- last 7 days
    
    -- Metadata
    first_seen DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_seen DATETIME,
    whitelisted INTEGER DEFAULT 0,
    blacklisted INTEGER DEFAULT 0,
    
    -- User Notes
    user_trust_level TEXT CHECK(user_trust_level IN (
        'TRUSTED',
        'NEUTRAL',
        'SUSPICIOUS'
    )),
    notes TEXT,
    
    UNIQUE(app_bundle_id)
);

CREATE INDEX idx_trust_history_app_name ON trust_history(app_name);
CREATE INDEX idx_trust_history_approval_rate ON trust_history(approval_rate DESC);
```

---

### 4. `known_apps` (Trusted Application Registry)

Pre-configured list of known, safe applications.

```sql
CREATE TABLE known_apps (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    bundle_id TEXT UNIQUE NOT NULL,
    app_name TEXT NOT NULL,
    developer TEXT,
    notarized INTEGER DEFAULT 0,
    code_signed INTEGER DEFAULT 0,
    
    -- Trust Level
    trust_level TEXT NOT NULL CHECK(trust_level IN (
        'APPLE',
        'VERIFIED_PUBLISHER',
        'OPEN_SOURCE',
        'COMMUNITY'
    )),
    
    -- Metadata
    added_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_verified DATETIME,
    version TEXT,
    
    -- Notes
    category TEXT, -- 'browser', 'development', 'productivity', etc.
    notes TEXT,
    
    UNIQUE(bundle_id)
);

CREATE INDEX idx_known_apps_bundle_id ON known_apps(bundle_id);
CREATE INDEX idx_known_apps_trust_level ON known_apps(trust_level);
```

---

### 5. `statistics_cache` (Performance Optimization)

Cached statistics to avoid expensive queries on every dashboard load.

```sql
CREATE TABLE statistics_cache (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cache_key TEXT UNIQUE NOT NULL,
    metric_value REAL,
    int_value INTEGER,
    text_value TEXT,
    
    -- Cache Metadata
    calculated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    valid_until DATETIME NOT NULL,
    
    UNIQUE(cache_key)
);

-- Typical cache keys:
-- 'total_dialogs_today'
-- 'automation_success_rate'
-- 'top_app_name'
-- 'average_detection_time_ms'
-- 'blocked_dialogs_count'
```

---

### 6. `audit_log` (System Events)

Logs configuration changes and system events.

```sql
CREATE TABLE audit_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    event_type TEXT NOT NULL CHECK(event_type IN (
        'POLICY_CREATED',
        'POLICY_MODIFIED',
        'POLICY_DELETED',
        'WHITELIST_ADDED',
        'WHITELIST_REMOVED',
        'BLACKLIST_ADDED',
        'BLACKLIST_REMOVED',
        'SETTINGS_CHANGED',
        'DATABASE_BACKUP',
        'DATABASE_CLEANUP',
        'DAEMON_STARTED',
        'DAEMON_STOPPED',
        'OCR_ENABLED',
        'OCR_DISABLED',
        'SECURITY_INCIDENT'
    )),
    
    -- Change Details
    target_object TEXT, -- what was changed
    old_value TEXT,
    new_value TEXT,
    
    -- Context
    user_action INTEGER DEFAULT 1, -- 1 = user, 0 = system
    reason TEXT,
    
    -- Metadata
    severity TEXT CHECK(severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL'))
);

CREATE INDEX idx_audit_log_timestamp ON audit_log(timestamp DESC);
CREATE INDEX idx_audit_log_event_type ON audit_log(event_type);
```

---

### 7. `screenshots` (Optional, for Visual Debugging)

Stores optional screenshots of dialogs for debugging/verification.

```sql
CREATE TABLE screenshots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_id INTEGER NOT NULL,
    screenshot_data BLOB, -- compressed image data
    format TEXT CHECK(format IN ('PNG', 'JPEG')), -- compression format
    file_size_bytes INTEGER,
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME, -- auto-delete after config days
    
    FOREIGN KEY(event_id) REFERENCES automation_events(id) ON DELETE CASCADE,
    UNIQUE(event_id)
);

CREATE INDEX idx_screenshots_event_id ON screenshots(event_id);
CREATE INDEX idx_screenshots_created_at ON screenshots(created_at);
```

---

## Database Relationships

```
┌─────────────────────┐
│  automation_events  │
└──────────┬──────────┘
           │
           ├─→ screenshot_id (FK → screenshots)
           ├─→ applied_policy_name (FK → policies.name)
           └─→ app_bundle_id (FK → trust_history.app_bundle_id)

┌──────────────────┐
│    policies      │
└──────────────────┘

┌──────────────────────┐
│   trust_history      │
└──────────────────────┘

┌──────────────────┐
│   known_apps     │
└──────────────────┘

┌──────────────────────┐
│ statistics_cache     │
└──────────────────────┘

┌──────────────────┐
│   audit_log      │
└──────────────────┘

┌──────────────────┐
│  screenshots     │ (optional)
└──────────────────┘
```

---

## Common Queries

### Statistics Dashboard

**Total dialogs detected today:**
```sql
SELECT COUNT(*) 
FROM automation_events 
WHERE DATE(timestamp) = DATE('now');
-- Result: 42
```

**Automation success rate (last 7 days):**
```sql
SELECT 
    ROUND(100.0 * SUM(CASE WHEN automation_success = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) as success_rate
FROM automation_events 
WHERE timestamp > datetime('now', '-7 days');
-- Result: 97.4
```

**Top apps with most dialogs:**
```sql
SELECT app_name, COUNT(*) as dialog_count
FROM automation_events
WHERE timestamp > datetime('now', '-30 days')
GROUP BY app_name
ORDER BY dialog_count DESC
LIMIT 10;
-- Result: Chrome (145), Zoom (87), VSCode (52), ...
```

**Average detection time:**
```sql
SELECT 
    ROUND(AVG(detection_time_ms), 2) as avg_ms,
    MIN(detection_time_ms) as min_ms,
    MAX(detection_time_ms) as max_ms
FROM automation_events
WHERE detection_time_ms IS NOT NULL;
-- Result: avg=215, min=45, max=789
```

**Action distribution (pie chart data):**
```sql
SELECT 
    action_taken,
    COUNT(*) as count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) as percentage
FROM automation_events
WHERE timestamp > datetime('now', '-30 days')
GROUP BY action_taken
ORDER BY count DESC;
-- Result: ALLOW_ONCE (65%), BLOCK (20%), MANUAL (15%)
```

### Policy Analysis

**Most effective policies:**
```sql
SELECT 
    name,
    times_applied,
    ROUND(success_rate * 100, 1) as success_pct,
    last_applied
FROM policies
WHERE enabled = 1
ORDER BY success_rate DESC
LIMIT 5;
```

**Policies that need tuning (low success rate):**
```sql
SELECT 
    name,
    times_applied,
    ROUND(success_rate * 100, 1) as success_pct
FROM policies
WHERE enabled = 1 AND success_rate < 0.7
ORDER BY success_rate ASC;
```

### Trust Scoring Insights

**Apps with highest approval rate:**
```sql
SELECT 
    app_name,
    app_bundle_id,
    approval_rate,
    total_dialogs,
    approved_dialogs
FROM trust_history
WHERE total_dialogs >= 10
ORDER BY approval_rate DESC
LIMIT 10;
```

**Apps flagged as suspicious (recent blocks):**
```sql
SELECT 
    app_name,
    total_dialogs,
    approved_dialogs,
    blocked_dialogs,
    ROUND(approval_rate * 100, 1) as approval_pct,
    recent_block_count
FROM trust_history
WHERE recent_block_count >= 3
ORDER BY recent_block_count DESC;
```

### Audit Trail

**Configuration changes in last 7 days:**
```sql
SELECT 
    timestamp,
    event_type,
    target_object,
    old_value,
    new_value,
    reason
FROM audit_log
WHERE timestamp > datetime('now', '-7 days')
ORDER BY timestamp DESC;
```

**Security incidents:**
```sql
SELECT 
    timestamp,
    event_type,
    severity,
    target_object,
    reason
FROM audit_log
WHERE severity IN ('HIGH', 'CRITICAL')
ORDER BY timestamp DESC;
```

---

## Database Maintenance

### Checking Database Health

```bash
# Verify database integrity
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db "PRAGMA integrity_check;"
-- Result: ok

# Check database size
ls -lh ~/Library/Application\ Support/PermissionPilot/audit.db
-- Result: -rw-r--r-- 1 user staff 12M May 13 14:30 audit.db
```

### Vacuum (Reclaim Space)

```sql
-- Compact database (removes deleted records space)
VACUUM;

-- Runs automatically based on settings (e.g., nightly)
```

### Backup

```bash
# Manual backup
cp ~/Library/Application\ Support/PermissionPilot/audit.db \
   ~/Library/Application\ Support/PermissionPilot/audit.db.backup.$(date +%Y%m%d)

# Verify backup
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db.backup.20240513 \
  "SELECT COUNT(*) FROM automation_events;"
```

### Cleanup Old Records

```sql
-- Delete automation events older than 90 days
DELETE FROM automation_events 
WHERE timestamp < datetime('now', '-90 days');

-- Delete expired screenshots
DELETE FROM screenshots
WHERE expires_at < datetime('now');

-- Reclaim space
VACUUM;
```

### Export Data

**Export to CSV:**
```bash
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db
.headers on
.mode csv
.output events.csv
SELECT * FROM automation_events WHERE timestamp > datetime('now', '-7 days');
.quit
```

**Export to JSON:**
```bash
# Manual JSON export with query results
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "SELECT json_object('id', id, 'app', app_name, 'action', action_taken, 'timestamp', timestamp) FROM automation_events LIMIT 10;"
```

---

## Database Configuration

### Connection Settings

```swift
// Swift implementation example
let dbPath = FileManager.default.urls(
    for: .applicationSupportDirectory,
    in: .userDomainMask
)[0].appendingPathComponent("PermissionPilot/audit.db")

var db: OpaquePointer?
if sqlite3_open(dbPath.path, &db) == SQLITE_OK {
    // Enable foreign keys
    sqlite3_exec(db, "PRAGMA foreign_keys = ON;", nil, nil, nil)
    
    // Enable WAL mode for concurrency
    sqlite3_exec(db, "PRAGMA journal_mode = WAL;", nil, nil, nil)
    
    // Set auto-vacuum
    sqlite3_exec(db, "PRAGMA auto_vacuum = INCREMENTAL;", nil, nil, nil)
}
```

### Performance Settings

```sql
-- Optimize for read-heavy workload (dashboard)
PRAGMA synchronous = NORMAL;  -- Balance safety vs speed
PRAGMA cache_size = -64000;   -- 64MB cache
PRAGMA temp_store = MEMORY;   -- Use RAM for temp storage

-- Indexes speed up common queries
-- See individual table definitions above
```

---

## Data Retention Policies

### Automatic Cleanup Schedule

**Default (User Configurable):**
- Automation events: Keep 90 days, auto-delete older
- Screenshots: Keep 7 days (optional), auto-delete
- Statistics cache: Keep 24 hours, refresh
- Audit log: Keep 1 year, archive to separate file

### Manual Cleanup

From Settings UI:
1. Settings → Data Retention
2. Select "Clean Old Logs"
3. Choose retention period (30/60/90 days)
4. Click "Clean"

Via command line:
```bash
# Clean logs older than 60 days
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "DELETE FROM automation_events WHERE timestamp < datetime('now', '-60 days'); VACUUM;"
```

---

## Troubleshooting

### Database Locked Error

**Problem:** `database is locked`

**Solution:**
```sql
-- Kill blocking connection
PRAGMA busy_timeout = 5000; -- Wait 5 seconds

-- Or restart daemon
launchctl stop com.permissionpilot.daemon
launchctl start com.permissionpilot.daemon
```

### Corrupted Database

**Problem:** `database disk image is malformed`

**Solution:**
```bash
# 1. Restore from backup
cp ~/Library/Application\ Support/PermissionPilot/audit.db.backup.latest \
   ~/Library/Application\ Support/PermissionPilot/audit.db

# 2. Or rebuild
rm ~/Library/Application\ Support/PermissionPilot/audit.db
# App will recreate on next run

# 3. Verify integrity
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db "PRAGMA integrity_check;"
```

### Slow Queries

**Problem:** Dashboard takes >2 seconds to load

**Solution:**
```sql
-- Analyze query performance
EXPLAIN QUERY PLAN
SELECT COUNT(*) FROM automation_events 
WHERE timestamp > datetime('now', '-7 days');

-- If slow, ensure indexes exist:
CREATE INDEX idx_automation_events_timestamp ON automation_events(timestamp DESC);

-- Run ANALYZE for query optimization hints
ANALYZE;
```

---

## Questions?

- **Database Questions:** [GitHub Discussions](https://github.com/ChaitanyaJoshi1769/PermissionPilot/discussions)
- **Report Issues:** [GitHub Issues](https://github.com/ChaitanyaJoshi1769/PermissionPilot/issues)
- **Contact:** dev@permissionpilot.app

---

**Last updated:** May 13, 2024  
**Database Version:** 1.0.0
