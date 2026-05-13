# PermissionPilot Operations Guide

Concise guide for system operators managing PermissionPilot in production environments.

---

## Essential Commands Quick Reference

### Daemon Management
```bash
# Start daemon
launchctl start com.permissionpilot.daemon

# Stop daemon
launchctl stop com.permissionpilot.daemon

# Restart daemon
launchctl restart com.permissionpilot.daemon

# Check status
launchctl list | grep permissionpilot
pgrep -f PermissionPilot

# Verify running
launchctl list com.permissionpilot.daemon
```

### System Health
```bash
# Full health check
./Scripts/health-check.sh

# Quick performance check
./Scripts/benchmark.sh

# Database health
./Scripts/database-maintenance.sh health

# View logs
log stream --predicate 'process == "PermissionPilot"' --level debug

# Check specific errors
log show --predicate 'process == "PermissionPilot" AND level == error' --last 24h
```

### Configuration & Policies
```bash
# View current configuration
cat ~/Library/Application\ Support/PermissionPilot/config.json | jq

# View current policies
cat ~/Library/Application\ Support/PermissionPilot/policies.json | jq

# Edit configuration
nano ~/Library/Application\ Support/PermissionPilot/config.json

# Validate policy file
./Scripts/validate-policy.sh ~/Library/Application\ Support/PermissionPilot/policies.json

# Reload after configuration change
launchctl restart com.permissionpilot.daemon
```

### Database Operations
```bash
# Backup database
./Scripts/database-maintenance.sh backup

# Cleanup old events
./Scripts/database-maintenance.sh cleanup

# Vacuum database
./Scripts/database-maintenance.sh vacuum

# Optimize database
./Scripts/database-maintenance.sh optimize

# Export database
./Scripts/export-database.sh csv events_export.csv 30

# Analyze activity
./Scripts/analyze-logs.sh text activity_report.txt 24
```

---

## Daily Operations

### Morning Check (5 minutes)
```bash
#!/bin/bash
# Daily morning health check

echo "=== PermissionPilot Daily Check ==="
echo ""

# 1. Verify daemon running
if pgrep -f "PermissionPilot" > /dev/null; then
    echo "✓ Daemon is running"
else
    echo "✗ Daemon is NOT running!"
    launchctl start com.permissionpilot.daemon
    sleep 2
    echo "  Daemon restarted"
fi

# 2. Check for errors
ERROR_COUNT=$(log show --predicate 'process == "PermissionPilot" AND level == error' --last 24h | wc -l)
if [ "$ERROR_COUNT" -gt 0 ]; then
    echo "⚠ Found $ERROR_COUNT errors in last 24 hours"
    echo ""
    log show --predicate 'process == "PermissionPilot" AND level == error' --last 24h | head -5
else
    echo "✓ No errors in last 24 hours"
fi

# 3. Database size
DB_SIZE=$(du -h ~/Library/Application\ Support/PermissionPilot/audit.db | awk '{print $1}')
echo "✓ Database size: $DB_SIZE"

# 4. Recent activity
EVENTS=$(sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db "SELECT COUNT(*) FROM automation_events WHERE timestamp > datetime('now', '-24 hours');")
echo "✓ Events in last 24 hours: $EVENTS"

echo ""
echo "=== Check Complete ==="
```

### Weekly Review (30 minutes)
```bash
#!/bin/bash
# Weekly review script

echo "=== PermissionPilot Weekly Review ==="

# 1. Full health check
./Scripts/health-check.sh

# 2. Performance analysis
echo ""
echo "=== Weekly Activity ==="
./Scripts/analyze-logs.sh text weekly_report.txt 168
cat weekly_report.txt

# 3. Database statistics
echo ""
echo "=== Database Statistics ==="
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db << 'SQL'
.mode line
SELECT 
  COUNT(*) as total_events,
  SUM(CASE WHEN automation_success = 1 THEN 1 ELSE 0 END) as successful,
  SUM(CASE WHEN automation_success = 0 THEN 1 ELSE 0 END) as failed
FROM automation_events 
WHERE timestamp > datetime('now', '-7 days');
SQL

# 4. Top apps
echo ""
echo "=== Top Applications (7 days) ==="
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db << 'SQL'
.mode column
.headers on
SELECT app_name, COUNT(*) as dialogs 
FROM automation_events 
WHERE timestamp > datetime('now', '-7 days')
GROUP BY app_name 
ORDER BY dialogs DESC 
LIMIT 5;
SQL

echo ""
echo "=== Weekly Review Complete ==="
```

### Monthly Maintenance (1-2 hours)
```bash
#!/bin/bash
# Monthly maintenance script

echo "=== PermissionPilot Monthly Maintenance ==="

# 1. Backup database
echo "1. Backing up database..."
./Scripts/database-maintenance.sh backup

# 2. Cleanup old events
echo ""
echo "2. Cleaning up events older than 60 days..."
./Scripts/database-maintenance.sh cleanup

# 3. Vacuum database
echo ""
echo "3. Vacuuming database..."
./Scripts/database-maintenance.sh vacuum

# 4. Export for compliance
echo ""
echo "4. Exporting data for compliance..."
./Scripts/export-database.sh csv compliance_report_$(date +%Y%m).csv 30

# 5. Performance analysis
echo ""
echo "5. Running performance benchmark..."
./Scripts/benchmark.sh > monthly_benchmark_$(date +%Y%m).txt

# 6. Full health check
echo ""
echo "6. Running full health check..."
./Scripts/health-check.sh > health_report_$(date +%Y%m).txt

echo ""
echo "=== Monthly Maintenance Complete ==="
echo "Backups stored in: ~/Library/Application\ Support/PermissionPilot/backups/"
```

---

## Troubleshooting Decision Tree

### Problem: Daemon Not Running

**Diagnosis:**
```bash
launchctl list | grep permissionpilot  # Check if loaded
pgrep -f PermissionPilot               # Check if actually running
log show --predicate 'process == "PermissionPilot" AND level == error' --last 1h
```

**Solution Steps:**
1. Try restart: `launchctl restart com.permissionpilot.daemon`
2. Check logs: `log stream --predicate 'process == "PermissionPilot"' --level debug`
3. If still fails:
   - Check LaunchAgent: `cat ~/Library/LaunchAgents/com.permissionpilot.daemon.plist`
   - Reload: `launchctl load ~/Library/LaunchAgents/com.permissionpilot.daemon.plist`
4. If still fails:
   - Reinstall: `brew reinstall permissionpilot` or reinstall from DMG

---

### Problem: Dialogs Not Being Detected

**Diagnosis:**
```bash
log stream --predicate 'process == "PermissionPilot"' --level debug | grep -i detect
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db "SELECT COUNT(*) FROM automation_events WHERE timestamp > datetime('now', '-1 hour');"
```

**Solution Steps:**
1. Verify accessibility permission:
   - System Preferences → Security & Privacy → Accessibility
   - PermissionPilot should be listed
2. If missing, add it: Grant accessibility permission in System Preferences
3. Test with dialog from known application (e.g., Chrome)
4. Check logs for detection errors
5. Try restarting daemon: `launchctl restart com.permissionpilot.daemon`

---

### Problem: High CPU Usage

**Diagnosis:**
```bash
ps aux | grep "[P]ermissionPilot"  # Check CPU %
./Scripts/benchmark.sh
log stream --predicate 'process == "PermissionPilot"' --level debug
```

**Solution Steps:**
1. Check for runaway OCR processing
2. Increase polling interval:
   ```bash
   jq '.daemon.polling_interval_ms = 500' config.json > config.new && mv config.new config.json
   launchctl restart com.permissionpilot.daemon
   ```
3. Disable OCR if not needed:
   ```bash
   jq '.detection.ocr.enabled = false' config.json > config.new && mv config.new config.json
   ```
4. Check for pathological policies
5. Review logs for clues

---

### Problem: High Memory Usage

**Diagnosis:**
```bash
ps aux | grep "[P]ermissionPilot"  # Check memory
./Scripts/database-maintenance.sh health
du -h ~/Library/Application\ Support/PermissionPilot/
```

**Solution Steps:**
1. Clean up database:
   ```bash
   ./Scripts/database-maintenance.sh cleanup
   ./Scripts/database-maintenance.sh vacuum
   ```
2. Reduce screenshot retention:
   ```bash
   jq '.screenshots.capture_enabled = false' config.json > config.new && mv config.new config.json
   ```
3. Check for memory leaks in logs
4. Restart daemon: `launchctl restart com.permissionpilot.daemon`

---

### Problem: Policy Not Taking Effect

**Diagnosis:**
```bash
jq empty ~/Library/Application\ Support/PermissionPilot/policies.json  # Check syntax
./Scripts/validate-policy.sh
log stream --predicate 'process == "PermissionPilot"' --level debug | grep -i policy
```

**Solution Steps:**
1. Validate JSON: `jq empty policies.json`
2. Run validation script: `./Scripts/validate-policy.sh`
3. Restart daemon: `launchctl restart com.permissionpilot.daemon`
4. Monitor logs for policy loading errors
5. Check policy priorities and ordering

---

### Problem: Database Corrupted

**Diagnosis:**
```bash
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db "PRAGMA integrity_check;"
```

**Solution Steps:**
1. Stop daemon: `launchctl stop com.permissionpilot.daemon`
2. Backup database: `cp audit.db audit.db.corrupt`
3. Try recovery:
   ```bash
   sqlite3 audit.db ".recover" | sqlite3 recovered.db
   ```
4. If successful, restore:
   ```bash
   mv audit.db audit.db.corrupt
   mv recovered.db audit.db
   ```
5. Restart daemon: `launchctl start com.permissionpilot.daemon`
6. If recovery fails, restore from backup or start fresh

---

## Performance Tuning

### For Slow Machines (Old Macs, Budget Systems)
```bash
# Use power saver configuration
cp EXAMPLES/configurations/config-powersaver.json \
   ~/Library/Application\ Support/PermissionPilot/config.json

# Key changes:
# - polling_interval_ms: 2000 (lower = less CPU)
# - ocr.enabled: false (OCR is CPU intensive)
# - click_delay_ms: 300 (natural, less stressful)
# - screenshots.capture_enabled: false

launchctl restart com.permissionpilot.daemon
./Scripts/benchmark.sh
```

### For High Performance Machines (M1, Recent Macs)
```bash
# Use performance configuration
cp EXAMPLES/configurations/config-performance.json \
   ~/Library/Application\ Support/PermissionPilot/config.json

# Key changes:
# - polling_interval_ms: 100 (very responsive)
# - ocr.enabled: true with high quality
# - click_delay_ms: 50 (fast clicks)
# - All features enabled

launchctl restart com.permissionpilot.daemon
./Scripts/benchmark.sh
```

---

## Monitoring Setup

### Automated Checks with Cron
```bash
# Add to crontab: crontab -e

# Daily health check at 2 AM
0 2 * * * /path/to/Scripts/health-check.sh >> /var/log/permissionpilot_health.log

# Weekly benchmark on Sunday at 3 AM
0 3 * * 0 /path/to/Scripts/benchmark.sh >> /var/log/permissionpilot_bench.log

# Monthly database maintenance on 1st of month at 2 AM
0 2 1 * * /path/to/Scripts/database-maintenance.sh backup

# Daily activity analysis
0 9 * * * /path/to/Scripts/analyze-logs.sh text | \
  mail -s "PermissionPilot Daily Report" admin@example.com
```

### Monitoring Dashboard (Example with Splunk/Datadog)
```bash
# Export events to external monitoring
./Scripts/export-database.sh json | curl -X POST \
  -H "Content-Type: application/json" \
  -d @- \
  https://your-monitoring.example.com/api/events
```

---

## Regular Maintenance Schedule

### Daily (Automated)
- [ ] Automated health check
- [ ] Log file review
- [ ] Daemon verification

### Weekly (Manual)
- [ ] Review activity report
- [ ] Check for errors
- [ ] Database size review
- [ ] Policy effectiveness review

### Monthly (Manual)
- [ ] Database backup
- [ ] Event cleanup (delete 60+ days old)
- [ ] Database optimization (vacuum)
- [ ] Full performance benchmark
- [ ] Compliance export

### Quarterly (Manual)
- [ ] Major version updates
- [ ] Policy review and updates
- [ ] Configuration review
- [ ] Security audit
- [ ] Performance analysis

### Annually (Manual)
- [ ] Full system review
- [ ] Architecture assessment
- [ ] Disaster recovery test
- [ ] Security audit
- [ ] Roadmap planning

---

## Emergency Procedures

### If Daemon Crashes Repeatedly
```bash
# 1. Check logs
log show --predicate 'process == "PermissionPilot"' --last 1h

# 2. Stop daemon
launchctl stop com.permissionpilot.daemon

# 3. Reset to defaults
rm ~/Library/Application\ Support/PermissionPilot/config.json
cp EXAMPLES/configurations/config-balanced.json \
   ~/Library/Application\ Support/PermissionPilot/config.json

# 4. Start daemon
launchctl start com.permissionpilot.daemon

# 5. Test and verify
./Scripts/health-check.sh
```

### If Database Becomes Unusable
```bash
# 1. Backup current database
cp ~/Library/Application\ Support/PermissionPilot/audit.db \
   ~/Library/Application\ Support/PermissionPilot/audit.db.backup

# 2. Remove corrupted database
rm ~/Library/Application\ Support/PermissionPilot/audit.db

# 3. Restart daemon (will create new database)
launchctl restart com.permissionpilot.daemon

# 4. Verify
./Scripts/health-check.sh
```

### Complete System Reset
```bash
# WARNING: This removes all data and logs
# Only use as last resort

# 1. Stop daemon
launchctl stop com.permissionpilot.daemon

# 2. Remove all PermissionPilot data
rm -rf ~/Library/Application\ Support/PermissionPilot/
rm -rf ~/Library/Logs/PermissionPilot/
rm ~/Library/LaunchAgents/com.permissionpilot.daemon.plist

# 3. Reinstall
# Option A: Homebrew
brew install permissionpilot

# Option B: DMG
# Download and install from releases page

# 4. Reconfigure
# Grant accessibility permission
# Copy desired configuration and policies
# Start daemon

launchctl start com.permissionpilot.daemon
```

---

## Support Resources

| Issue | Resource |
|-------|----------|
| Installation problems | [QUICK_START.md](QUICK_START.md) |
| Configuration questions | [CONFIGURATION_GUIDE.md](CONFIGURATION_GUIDE.md) |
| Performance tuning | [PERFORMANCE_TUNING.md](PERFORMANCE_TUNING.md) |
| Troubleshooting | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) |
| Monitoring setup | [MONITORING.md](MONITORING.md) |
| Deployment planning | [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md) |
| Database operations | [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) |
| Script usage | [Scripts/README.md](Scripts/README.md) |

---

## Key Files & Locations

```
~/Library/Application Support/PermissionPilot/
├── config.json          # Main configuration
├── policies.json        # Policy definitions
├── audit.db            # Audit database
├── screenshots/        # Captured screenshots
└── backups/           # Database backups

~/Library/LaunchAgents/
└── com.permissionpilot.daemon.plist  # LaunchAgent config

~/Library/Logs/PermissionPilot/
└── *.log               # Application logs

/Applications/PermissionPilot.app/  # Application bundle
```

---

## Contact & Escalation

**For Issues:** [GitHub Issues](https://github.com/ChaitanyaJoshi1769/PermissionPilot/issues)  
**For Discussions:** [GitHub Discussions](https://github.com/ChaitanyaJoshi1769/PermissionPilot/discussions)  
**For Security:** security@permissionpilot.app  

---

**Version:** 1.0.0  
**Last Updated:** May 13, 2024  
**License:** MIT

