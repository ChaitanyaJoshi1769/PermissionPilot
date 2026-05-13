# PermissionPilot Incident Response Playbook

Proven procedures for responding to common PermissionPilot issues.

---

## Incident Classification Matrix

| Severity | Time to Response | Time to Resolution | Examples |
|----------|------------------|-------------------|----------|
| **Critical** | 15 min | 1 hour | System compromise, data breach |
| **High** | 1 hour | 4 hours | Policy violations, unauthorized access |
| **Medium** | 4 hours | 24 hours | Performance issues, errors |
| **Low** | 24 hours | 7 days | Minor issues, false positives |

---

## Critical Incidents

### Incident: Daemon Crash Loop

**Severity:** Critical  
**Detection:** Daemon restarts repeatedly within minutes

**Immediate Response (0-5 min):**
```bash
# 1. Stop the daemon immediately
launchctl stop com.permissionpilot.daemon

# 2. Collect evidence
log show --predicate 'process == "PermissionPilot"' --last 1h > /tmp/crash_logs.txt
cp -r ~/Library/Application\ Support/PermissionPilot /tmp/evidence_backup

# 3. Notify stakeholders
# Send critical alert to on-call team
```

**Root Cause Analysis (5-30 min):**
```bash
# Check error logs
grep "FATAL\|CRASH\|SEGFAULT" /tmp/crash_logs.txt

# Check configuration
jq . ~/Library/Application\ Support/PermissionPilot/config.json

# Check disk space
df -h | grep -E "Use%|/var"

# Check database
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db "PRAGMA integrity_check;"
```

**Resolution:**
```bash
# Step 1: Try safe restart with default config
launchctl stop com.permissionpilot.daemon
rm ~/Library/Application\ Support/PermissionPilot/config.json
cp EXAMPLES/configurations/config-balanced.json ~/Library/Application\ Support/PermissionPilot/config.json
launchctl start com.permissionpilot.daemon

# Step 2: Verify it stays running for 5 minutes
sleep 300
pgrep -f "PermissionPilot" || echo "FAILED"

# Step 3: If still crashing, check for corrupted database
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db ".recover" | sqlite3 recovered.db
mv ~/Library/Application\ Support/PermissionPilot/audit.db audit.db.corrupt
mv recovered.db ~/Library/Application\ Support/PermissionPilot/audit.db
launchctl restart com.permissionpilot.daemon

# Step 4: If still crashing, reinstall
brew reinstall permissionpilot
# or reinstall from DMG
```

**Post-Incident (After Resolution):**
```bash
# 1. Document root cause
echo "Root cause: [CAUSE]" >> incident_report_$(date +%Y%m%d).txt

# 2. Run health check
./Scripts/health-check.sh >> incident_report_$(date +%Y%m%d).txt

# 3. Monitor for 24 hours
# Set up monitoring alert for daemon status

# 4. Create preventive measure
# Update monitoring/alerting
# Update runbook
# Train team on issue
```

---

### Incident: Database Corruption Detected

**Severity:** Critical  
**Detection:** Integrity check fails, errors in logs

**Immediate Response (0-5 min):**
```bash
# 1. Verify corruption
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db "PRAGMA integrity_check;"

# 2. Stop daemon
launchctl stop com.permissionpilot.daemon

# 3. Backup corrupted database for analysis
cp ~/Library/Application\ Support/PermissionPilot/audit.db \
   ~/Library/Application\ Support/PermissionPilot/audit.db.corrupt.$(date +%s)

# 4. Notify compliance team immediately
```

**Recovery (5-60 min):**
```bash
# Try recovery approach 1: Automatic recovery
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db ".recover" | \
  sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db.recovered

# Verify recovered database
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db.recovered "PRAGMA integrity_check;"

# If valid, restore
mv ~/Library/Application\ Support/PermissionPilot/audit.db \
   ~/Library/Application\ Support/PermissionPilot/audit.db.corrupt
mv ~/Library/Application\ Support/PermissionPilot/audit.db.recovered \
   ~/Library/Application\ Support/PermissionPilot/audit.db

# If recovery failed, restore from backup
ls -lt ~/audit_backups/ | head -1
./restore_from_backup.sh ~/audit_backups/latest_backup.tar.gz.enc

# Restart daemon
launchctl start com.permissionpilot.daemon
```

**Verification:**
```bash
# Verify restoration
./Scripts/database-maintenance.sh health

# Check event counts match expectations
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "SELECT COUNT(*) FROM automation_events;"

# Monitor for errors
./Scripts/health-check.sh
```

---

### Incident: Unauthorized Policy Changes

**Severity:** Critical  
**Detection:** Policy audit shows unexpected changes, security alert triggered

**Immediate Response (0-5 min):**
```bash
# 1. Verify change
git log --oneline -- POLICIES/
git show HEAD:POLICIES/

# 2. Collect evidence
git log -p --all -- POLICIES/ > /tmp/policy_changes.txt
./Scripts/export-database.sh csv recent_events.csv 1

# 3. Disable suspicious policy immediately
jq '.policies[].enabled = false' ~/Library/Application\ Support/PermissionPilot/policies.json > policies.disabled.json
cp policies.disabled.json ~/Library/Application\ Support/PermissionPilot/policies.json

# 4. Restart daemon
launchctl restart com.permissionpilot.daemon

# 5. Alert security team
```

**Investigation (5-30 min):**
```bash
# Who changed the policy?
git log --oneline --all -- POLICIES/ | head -5
git show [COMMIT_HASH]

# When did it change?
git log -p --since="24 hours ago" -- POLICIES/

# What machines are affected?
# Check replication log or deployment tracking

# Check if policy was actually used
./Scripts/analyze-logs.sh json events.json 24
grep "policy\|rule" events.json
```

**Resolution:**
```bash
# Step 1: Revert to known-good version
git checkout HEAD~1 -- POLICIES/
cp POLICIES/balanced-default.json ~/Library/Application\ Support/PermissionPilot/policies.json

# Step 2: Restart daemon
launchctl restart com.permissionpilot.daemon

# Step 3: Verify policy effectiveness
./Scripts/analyze-logs.sh text verification.txt 1

# Step 4: Investigate source of change
# Check git logs
# Review access logs
# Interview team members
# Check for compromised accounts
```

---

## High Severity Incidents

### Incident: High Success Rate Mismatch

**Severity:** High  
**Detection:** Success rate drops below 80%, trend shows degradation

**Diagnosis (5-10 min):**
```bash
# Get current success rate
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "SELECT ROUND(100.0 * SUM(CASE WHEN automation_success = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) \
   FROM automation_events WHERE timestamp > datetime('now', '-24 hours');"

# Get trend
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "SELECT DATE(timestamp) as day, ROUND(100.0 * SUM(CASE WHEN automation_success = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) \
   FROM automation_events WHERE timestamp > datetime('now', '-7 days') GROUP BY day ORDER BY day;"

# Find failures
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "SELECT dialog_title, COUNT(*) as failures FROM automation_events \
   WHERE automation_success = 0 AND timestamp > datetime('now', '-24 hours') \
   GROUP BY dialog_title ORDER BY failures DESC LIMIT 10;"
```

**Investigation:**
```bash
# Check for pattern
# - Specific dialogs failing?
# - Specific apps?
# - Time-based pattern?
# - After policy change?

# Review recent changes
git log --oneline -10
git diff HEAD~1 HEAD -- POLICIES/ config.json

# Check system status
./Scripts/health-check.sh
./Scripts/benchmark.sh
```

**Resolution:**
```bash
# Option 1: Policy adjustment
# Review failing policies
jq '.policies[] | select(.action == "allow")' ~/Library/Application\ Support/PermissionPilot/policies.json

# Lower confidence threshold
jq '.policies[].confidence_required = 0.75' config.json > config.new && mv config.new config.json

# Option 2: Configuration tuning
# Increase click delay for reliability
jq '.automation.click_delay_ms = 200' config.json > config.new && mv config.new config.json

# Option 3: Investigate specific dialogs
# Get details of failed dialogs
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "SELECT app_name, dialog_title, button_clicked, reason_blocked \
   FROM automation_events WHERE automation_success = 0 LIMIT 10;"
```

---

### Incident: Excessive CPU Usage

**Severity:** High  
**Detection:** CPU usage >5%, sustained for >10 minutes

**Diagnosis (5 min):**
```bash
# Check current CPU
ps aux | grep "[P]ermissionPilot"

# Monitor trend
for i in {1..10}; do
  ps aux | grep "[P]ermissionPilot" | awk '{print $3}' | tee -a /tmp/cpu_trend.txt
  sleep 6
done

# Identify what's using CPU
log stream --predicate 'process == "PermissionPilot"' --level debug | head -50
```

**Root Causes to Check:**
```bash
# 1. OCR processing taking too long
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "SELECT detection_method, COUNT(*) FROM automation_events \
   WHERE timestamp > datetime('now', '-1 hour') GROUP BY detection_method;"

# 2. Database I/O
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "SELECT COUNT(*) FROM automation_events WHERE timestamp > datetime('now', '-1 hour');"

# 3. Regex processing
jq '.policies[].target_pattern' config.json | head -5

# 4. Memory pressure
vm_stat | grep "Pages free"
```

**Resolution:**
```bash
# Quick fix: Reduce polling frequency
jq '.daemon.polling_interval_ms = 1000' config.json > config.new && mv config.new config.json
launchctl restart com.permissionpilot.daemon
sleep 10
ps aux | grep "[P]ermissionPilot"  # Check CPU again

# If still high: Disable OCR
jq '.detection.ocr.enabled = false' config.json > config.new && mv config.new config.json
launchctl restart com.permissionpilot.daemon

# If still high: Reduce logging
jq '.logging.level = "warn"' config.json > config.new && mv config.new config.json
launchctl restart com.permissionpilot.daemon

# Monitor for 5 minutes
sleep 300
ps aux | grep "[P]ermissionPilot"
```

---

## Medium Severity Incidents

### Incident: Dialogs Not Being Detected

**Severity:** Medium  
**Detection:** 0 events in database for >1 hour, user reports

**Diagnosis (10 min):**
```bash
# 1. Check daemon status
pgrep -f "PermissionPilot"
launchctl list | grep permissionpilot

# 2. Check accessibility permission
system_profiler SPConfigurationProfileDataType | grep -i "PermissionPilot\|Accessibility"

# 3. Check logs for detection attempts
log stream --predicate 'process == "PermissionPilot"' --level debug | grep -i "detect"

# 4. Test with known dialog
# Open System Preferences and trigger permission dialog
```

**Resolution Steps:**
```bash
# Step 1: Verify accessibility permission
# System Preferences > Security & Privacy > Accessibility
# PermissionPilot should be listed

# If missing, add it:
# Open System Preferences > Security & Privacy > Accessibility
# Click + and select /Applications/PermissionPilot.app

# Step 2: Restart daemon
launchctl stop com.permissionpilot.daemon
sleep 2
launchctl start com.permissionpilot.daemon
sleep 5

# Step 3: Test detection
# Trigger a dialog from Safari or Chrome
# Check if event logged: sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db "SELECT COUNT(*) FROM automation_events WHERE timestamp > datetime('now', '-5 minutes');"

# Step 4: If still not working, reset
launchctl stop com.permissionpilot.daemon
rm -rf ~/Library/Application\ Support/PermissionPilot/
# Reinstall and reconfigure
```

---

### Incident: High Memory Usage

**Severity:** Medium  
**Detection:** Memory usage >500MB

**Diagnosis (5 min):**
```bash
# Check current memory
ps aux | grep "[P]ermissionPilot" | awk '{print $6}'

# Check database size
du -h ~/Library/Application\ Support/PermissionPilot/audit.db

# Check screenshot cache
du -h ~/Library/Application\ Support/PermissionPilot/screenshots/
```

**Resolution:**
```bash
# Option 1: Clean up old events
./Scripts/database-maintenance.sh cleanup
./Scripts/database-maintenance.sh vacuum
launchctl restart com.permissionpilot.daemon

# Option 2: Disable screenshots
jq '.screenshots.capture_enabled = false' config.json > config.new && mv config.new config.json
launchctl restart com.permissionpilot.daemon

# Option 3: Reduce cache size
jq '.screenshots.cache_size_mb = 50' config.json > config.new && mv config.new config.json
launchctl restart com.permissionpilot.daemon

# Verify memory usage after changes
ps aux | grep "[P]ermissionPilot"
```

---

## Incident Reporting

### Incident Report Template
```markdown
# Incident Report

**Incident ID:** INC-[DATE]-[NUMBER]  
**Date/Time:** [Date] [Time]  
**Reported By:** [Name]  
**Severity:** [Critical/High/Medium/Low]  

## Description
[What happened]

## Detection
- Detected at: [Time]
- Detection method: [How discovered]
- Time to detect: [Duration]

## Impact
- Systems affected: [Which machines]
- Users affected: [Number]
- Duration: [Start - End]
- Data lost: [Yes/No, describe if yes]

## Timeline
- 00:00 - Event occurred
- 00:15 - Incident detected
- 00:20 - Investigation started
- 01:00 - Root cause identified
- 01:30 - Fix implemented
- 02:00 - Verified resolved

## Root Cause
[Detailed explanation]

## Resolution
[Steps taken to resolve]

## Prevention
[Changes to prevent recurrence]

## Lessons Learned
[What we learned]

## Follow-up Actions
- [ ] Action 1 - Owner: [Name] - Due: [Date]
- [ ] Action 2 - Owner: [Name] - Due: [Date]

**Prepared By:** [Name]  
**Date:** [Date]  
**Approved By:** [Manager]
```

---

## Post-Incident Review

### Blameless Postmortem Checklist
- [ ] Gathered all stakeholders
- [ ] Discussed what happened (not who caused it)
- [ ] Identified contributing factors
- [ ] Agreed on prevention measures
- [ ] Assigned follow-up actions with owners
- [ ] Set follow-up meeting to verify fixes
- [ ] Shared lessons with team

---

## Runbook Quick Links

- [Daemon Not Running](#incident-daemon-crash-loop)
- [Database Corrupted](#incident-database-corruption-detected)
- [Policy Changed](#incident-unauthorized-policy-changes)
- [Low Success Rate](#incident-high-success-rate-mismatch)
- [High CPU Usage](#incident-excessive-cpu-usage)
- [Dialogs Not Detected](#incident-dialogs-not-being-detected)
- [High Memory Usage](#incident-high-memory-usage)

---

**Version:** 1.0.0  
**Last Updated:** May 14, 2024  
**License:** MIT
