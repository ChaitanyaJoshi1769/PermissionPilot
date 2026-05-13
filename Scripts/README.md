# PermissionPilot Scripts

Utility scripts for system administrators, developers, and operators. All scripts are executable from the command line.

---

## Quick Reference

| Script | Purpose | Usage |
|--------|---------|-------|
| `health-check.sh` | System health verification | `./health-check.sh` |
| `benchmark.sh` | Performance benchmarking | `./benchmark.sh` |
| `export-database.sh` | Export audit database | `./export-database.sh [csv\|json]` |
| `analyze-logs.sh` | Analyze logs and generate reports | `./analyze-logs.sh [json\|text]` |
| `validate-policy.sh` | Validate policy JSON files | `./validate-policy.sh [policy_file]` |
| `database-maintenance.sh` | Database maintenance tasks | `./database-maintenance.sh [command]` |
| `deploy-bulk.sh` | Deploy to multiple machines | `./deploy-bulk.sh <hosts> <policy>` |
| `setup-dev.sh` | Development environment setup | `./setup-dev.sh` |
| `build.sh` | Build PermissionPilot | `./build.sh` |
| `sign-and-notarize.sh` | Code signing and notarization | `./sign-and-notarize.sh` |

---

## System Administration Scripts

### 1. `health-check.sh` - System Health Verification
**Purpose:** Verify PermissionPilot installation and configuration

**Usage:**
```bash
./health-check.sh
```

**Checks:**
- ✓ Application installation
- ✓ Daemon status (loaded and running)
- ✓ System permissions (accessibility)
- ✓ Configuration files (valid JSON)
- ✓ Database integrity
- ✓ Logging functionality
- ✓ Performance metrics
- ✓ Recent activity

**Output:**
- Color-coded pass/warn/fail indicators
- Detailed health report
- Troubleshooting suggestions

**Examples:**
```bash
# Run full health check
./health-check.sh

# Save output to file
./health-check.sh > health_report.txt

# Use in monitoring
./health-check.sh && echo "System OK" || echo "Issues found"
```

---

### 2. `benchmark.sh` - Performance Benchmarking
**Purpose:** Measure PermissionPilot performance on your system

**Usage:**
```bash
./benchmark.sh
```

**Tests:**
- CPU and memory usage (30-second baseline)
- Database query performance
- Event statistics and success rates
- Top applications (last 7 days)
- System resource availability

**Output:**
- Baseline CPU/memory metrics
- Query performance results
- Activity statistics
- Pass/fail indicators

**Examples:**
```bash
# Run benchmark suite
./benchmark.sh

# Schedule weekly benchmark
0 2 * * 0 /path/to/benchmark.sh >> /var/log/pp_benchmark.log
```

---

### 3. `export-database.sh` - Export Audit Database
**Purpose:** Export PermissionPilot audit data for analysis

**Usage:**
```bash
./export-database.sh [format] [output_file] [days_back]
```

**Formats:**
- `csv` - Comma-separated values (default)
- `json` - JSON format

**Parameters:**
- `format` - Output format (default: csv)
- `output_file` - Where to save export (default: timestamp_based)
- `days_back` - How many days of data (default: 30)

**Examples:**
```bash
# Export last 30 days as CSV
./export-database.sh csv

# Export last 7 days as JSON
./export-database.sh json events_7day.json 7

# Export all data as CSV
./export-database.sh csv all_events.csv 365

# Export and open in Excel
./export-database.sh csv | open -f -a "Microsoft Excel"
```

**Output Files:**
- CSV: One event per row, comma-separated columns
- JSON: Structured JSON array of events

**Columns Exported:**
- timestamp, app_name, dialog_title, dialog_content
- detection_method, trust_score, action_taken
- automation_success, button_clicked, reason_blocked
- tags, user_notes

---

### 4. `analyze-logs.sh` - Log Analysis and Reporting
**Purpose:** Analyze logs and generate activity reports

**Usage:**
```bash
./analyze-logs.sh [format] [output_file] [hours_back]
```

**Formats:**
- `text` - Human-readable report (default)
- `json` - JSON format

**Parameters:**
- `format` - Report format (default: text)
- `output_file` - Where to save report
- `hours_back` - Time range (default: 24)

**Examples:**
```bash
# Generate text report for last 24 hours
./analyze-logs.sh text

# Generate JSON report for last 7 days (168 hours)
./analyze-logs.sh json report.json 168

# Generate and view report
./analyze-logs.sh text | less
```

**Report Includes:**
- Total events, allowed/blocked/manual counts
- Success rate and average trust score
- Detection method distribution
- Top applications
- Most common dialogs
- Block reasons

---

### 5. `validate-policy.sh` - Policy Validation
**Purpose:** Validate policy JSON syntax and structure

**Usage:**
```bash
./validate-policy.sh [policy_file]
```

**Parameters:**
- `policy_file` - Policy file to validate (default: active policies.json)

**Checks:**
- JSON syntax validity
- Required fields (name, version, policies)
- Policy structure (id, type, action, etc.)
- Priority value ranges
- Regular expression validity
- Settings validation
- Policy logic sanity

**Examples:**
```bash
# Validate active policies
./validate-policy.sh

# Validate specific policy file
./validate-policy.sh POLICIES/enterprise-secure.json

# Validate before deployment
./validate-policy.sh new_policy.json && echo "Ready to deploy"

# Validate all policy files
for file in POLICIES/*.json; do
  ./validate-policy.sh "$file"
done
```

**Exit Codes:**
- 0 - Validation passed
- 1 - Validation failed

---

### 6. `database-maintenance.sh` - Database Maintenance
**Purpose:** Perform database maintenance tasks

**Usage:**
```bash
./database-maintenance.sh [command]
```

**Commands:**

#### backup
Creates timestamped database backup
```bash
./database-maintenance.sh backup
```
- Creates backup in `~/Library/Application Support/PermissionPilot/backups/`
- Preserves all data
- No downtime required

#### cleanup
Deletes old events and optimizes storage
```bash
./database-maintenance.sh cleanup
```
- Removes events older than 60 days
- Reclaims disk space
- Requires backup confirmation

#### vacuum
Reclaims unused database space
```bash
./database-maintenance.sh vacuum
```
- Defragments database file
- Reduces file size
- May take time on large databases

#### optimize
Analyzes, reindexes, and optimizes
```bash
./database-maintenance.sh optimize
```
- Runs ANALYZE for statistics
- Reindexes all tables
- Runs defragmentation
- May take time on large databases

#### health
Checks database health and statistics
```bash
./database-maintenance.sh health
```
- Shows database size and event count
- Verifies integrity
- Reports statistics
- Lists recent backups

**Examples:**
```bash
# Weekly backup
0 3 * * 0 ./database-maintenance.sh backup

# Monthly cleanup
0 2 1 * * ./database-maintenance.sh cleanup

# Check health
./database-maintenance.sh health

# Full maintenance routine
./database-maintenance.sh backup
./database-maintenance.sh cleanup
./database-maintenance.sh vacuum
```

---

### 7. `deploy-bulk.sh` - Bulk Policy Deployment
**Purpose:** Deploy policies to multiple machines

**Usage:**
```bash
./deploy-bulk.sh <hosts_file> <policy_file> [ssh_key]
```

**Parameters:**
- `hosts_file` - File with list of hosts (one per line)
- `policy_file` - Policy to deploy
- `ssh_key` - SSH private key (optional)

**Hosts File Format:**
```
user@machine1.example.com
user@machine2.example.com
user@machine3.example.com
```

**Examples:**

**1. Deploy to machines via SSH**
```bash
# Create hosts file
cat > machines.txt << EOF
admin@mac1.corp.local
admin@mac2.corp.local
admin@mac3.corp.local
EOF

# Deploy policy
./deploy-bulk.sh machines.txt POLICIES/enterprise-secure.json ~/.ssh/id_rsa
```

**2. Deploy with SSH key**
```bash
./deploy-bulk.sh servers.txt new_policy.json ~/.ssh/deploy_key
```

**3. Deploy without explicit key (uses default SSH agent)**
```bash
./deploy-bulk.sh servers.txt policy.json --
```

**What It Does:**
1. Validates hosts file and policy file
2. For each host:
   - Copies policy via SCP
   - Creates PermissionPilot directory if needed
   - Validates policy JSON
   - Restarts daemon
3. Reports success/failure count

**Output:**
```
✓ user@host1: Success
✓ user@host2: Success
✗ user@host3: Failed

Deployed: 2/3
Failed: 1/3
```

---

## Development Scripts

### 8. `setup-dev.sh` - Development Environment Setup
**Purpose:** Set up local development environment

**Usage:**
```bash
./setup-dev.sh
```

**Sets Up:**
- Installs Xcode Command Line Tools if needed
- Configures git hooks
- Sets up development environment

---

### 9. `build.sh` - Build PermissionPilot
**Purpose:** Build PermissionPilot from source

**Usage:**
```bash
./build.sh
```

**Builds:**
- Release executable
- Signed and ready for deployment

---

### 10. `sign-and-notarize.sh` - Code Signing & Notarization
**Purpose:** Sign and notarize PermissionPilot for distribution

**Usage:**
```bash
./sign-and-notarize.sh
```

**Requires:**
- Apple Developer ID certificate
- Valid developer account credentials

---

## Common Workflows

### Daily Operations
```bash
# Morning health check
./health-check.sh

# Review daily activity
./analyze-logs.sh text daily_$(date +%Y%m%d).txt 24
```

### Weekly Maintenance
```bash
# Backup database
./database-maintenance.sh backup

# Run benchmark
./benchmark.sh > benchmarks_$(date +%Y%m%d).txt

# Analyze week's activity
./analyze-logs.sh text weekly_report.txt 168
```

### Monthly Operations
```bash
# Full maintenance routine
./database-maintenance.sh backup
./database-maintenance.sh cleanup
./database-maintenance.sh vacuum

# Export for compliance
./export-database.sh csv compliance_$(date +%Y%m).csv 30

# Performance analysis
./benchmark.sh >> monthly_benchmarks.log
```

### Policy Deployment
```bash
# Validate new policy
./validate-policy.sh my_new_policy.json

# Test on one machine
scp my_new_policy.json testuser@testmac:~/
ssh testuser@testmac "cp ~/my_new_policy.json ~/Library/Application\ Support/PermissionPilot/policies.json && launchctl restart com.permissionpilot.daemon"

# Deploy to all machines
./deploy-bulk.sh machines.txt my_new_policy.json ~/.ssh/id_rsa
```

---

## Scheduling Scripts with cron

### Example crontab entries

```bash
# Daily health check at 2 AM
0 2 * * * /path/to/PermissionPilot/Scripts/health-check.sh >> /var/log/pp_health.log

# Weekly benchmark on Sundays at 3 AM
0 3 * * 0 /path/to/PermissionPilot/Scripts/benchmark.sh >> /var/log/pp_bench.log

# Monthly cleanup on 1st of month at 2 AM
0 2 1 * * /path/to/PermissionPilot/Scripts/database-maintenance.sh cleanup

# Daily activity analysis (email to admin)
0 9 * * * /path/to/PermissionPilot/Scripts/analyze-logs.sh text | mail -s "PP Daily Report" admin@example.com

# Hourly health check (light check)
0 * * * * /path/to/PermissionPilot/Scripts/health-check.sh > /dev/null && echo "OK" || echo "FAILED"
```

To edit crontab:
```bash
crontab -e
```

---

## Troubleshooting

### Script doesn't run: "permission denied"
```bash
chmod +x script_name.sh
```

### Database is locked
```bash
# Stop daemon, run maintenance, restart
launchctl stop com.permissionpilot.daemon
./database-maintenance.sh vacuum
launchctl start com.permissionpilot.daemon
```

### Policy deployment fails
```bash
# Verify policy syntax
./validate-policy.sh /path/to/policy.json

# Test SSH access
ssh user@host "echo OK"

# Check permissions on remote
ssh user@host "ls -la ~/Library/Application\ Support/PermissionPilot/"
```

### Export doesn't show any data
```bash
# Verify database has events
./database-maintenance.sh health

# Check time range
./export-database.sh csv export.csv 365  # Last year
```

---

## Support & Resources

- Full documentation: [QUICK_REFERENCE.md](../QUICK_REFERENCE.md)
- Configuration guide: [CONFIGURATION_GUIDE.md](../CONFIGURATION_GUIDE.md)
- Monitoring guide: [MONITORING.md](../MONITORING.md)
- Troubleshooting: [TROUBLESHOOTING.md](../TROUBLESHOOTING.md)

---

**Version:** 1.0.0  
**Last Updated:** May 13, 2024  
**License:** MIT
