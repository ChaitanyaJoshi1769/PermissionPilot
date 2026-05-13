# PermissionPilot Examples

Example configurations and use cases for PermissionPilot deployment scenarios.

---

## Configuration Examples

Pre-configured JSON files for different use cases. Copy and customize for your needs.

### Directory Structure

```
EXAMPLES/
├── configurations/
│   ├── config-performance.json     # High performance configuration
│   ├── config-powersaver.json      # Battery/resource optimization
│   ├── config-security.json        # Audit & compliance focused
│   ├── config-development.json     # Development with debug logging
│   └── config-privacy.json         # Privacy-maximized configuration
└── README.md
```

---

## Configuration Files

### 1. High Performance (`config-performance.json`)
**Best for:** Power users, developers, fast-paced environments

**Key Settings:**
- Polling: 100ms (very responsive)
- Detection: Hybrid (fast)
- Automation: Fast clicks (50ms)
- OCR: High quality
- Logging: Info level
- Database: WAL mode enabled

**Use When:**
- You want instant dialog detection and handling
- You're okay with higher CPU/memory usage
- Speed is more important than battery life

**Deploy:**
```bash
cp EXAMPLES/configurations/config-performance.json ~/Library/Application\ Support/PermissionPilot/config.json
launchctl restart com.permissionpilot.daemon
```

---

### 2. Power Saver (`config-powersaver.json`)
**Best for:** Laptops, battery-conscious users, light users

**Key Settings:**
- Polling: 2000ms (low CPU)
- Detection: Accessibility API only (no OCR)
- Automation: Natural timing (300ms delays)
- OCR: Disabled
- Logging: Warn level only
- Database: Cleanup every 14 days

**Use When:**
- Battery life is critical
- You want minimal CPU/memory usage
- You're on a laptop or underpowered machine
- Light usage patterns

**Deploy:**
```bash
cp EXAMPLES/configurations/config-powersaver.json ~/Library/Application\ Support/PermissionPilot/config.json
launchctl restart com.permissionpilot.daemon
```

---

### 3. Security Audit (`config-security.json`)
**Best for:** Enterprises, compliance, regulated industries

**Key Settings:**
- Polling: 500ms (balanced)
- Detection: Hybrid with highest quality
- Confidence threshold: 0.85 (very strict)
- Screenshots: Always captured
- Logging: Debug level with JSON format
- Database: 90-day retention, automatic backups
- Notarization: Required

**Use When:**
- Compliance/audit requirements
- You need complete activity logging
- Security monitoring is critical
- Screenshots required for compliance

**Deploy:**
```bash
cp EXAMPLES/configurations/config-security.json ~/Library/Application\ Support/PermissionPilot/config.json
launchctl restart com.permissionpilot.daemon
```

---

### 4. Development (`config-development.json`)
**Best for:** Developers testing PermissionPilot features

**Key Settings:**
- Polling: 200ms (responsive)
- Detection: Hybrid with debug output
- Confidence threshold: 0.5 (very permissive for testing)
- Screenshots: Always captured with raw images
- Logging: Debug level with console output
- Development mode: Enabled

**Use When:**
- Testing new features
- Debugging issues
- Evaluating different approaches
- Performance profiling

**Deploy:**
```bash
cp EXAMPLES/configurations/config-development.json ~/Library/Application\ Support/PermissionPilot/config.json
launchctl restart com.permissionpilot.daemon
```

---

### 5. Privacy Focused (`config-privacy.json`)
**Best for:** Privacy-conscious users, security researchers

**Key Settings:**
- Polling: 1000ms (minimal overhead)
- Detection: Accessibility API only
- Logging: Disabled
- Database: Disabled
- Screenshots: Disabled
- Privacy mode: Full enabled
- Notarization: Required
- Local only: All operations local

**Use When:**
- Privacy is paramount
- You don't want any logging
- You prefer manual approval over automation
- No external API calls needed

**Deploy:**
```bash
cp EXAMPLES/configurations/config-privacy.json ~/Library/Application\ Support/PermissionPilot/config.json
launchctl restart com.permissionpilot.daemon
```

---

## Customization Workflow

### 1. Choose a Base Configuration
```bash
# Start with a configuration that's close to your needs
cp EXAMPLES/configurations/config-security.json my-config.json
```

### 2. Edit Your Configuration
```bash
# Open in your preferred editor
nano my-config.json

# Or use jq for specific changes
jq '.daemon.polling_interval_ms = 300' my-config.json > updated-config.json
```

### 3. Validate Your Configuration
```bash
# Check JSON syntax
jq empty my-config.json

# Validate with PermissionPilot validation script
./Scripts/validate-policy.sh my-config.json
```

### 4. Deploy
```bash
# Copy to system
cp my-config.json ~/Library/Application\ Support/PermissionPilot/config.json

# Restart daemon
launchctl restart com.permissionpilot.daemon

# Verify with health check
./Scripts/health-check.sh
```

---

## Configuration Comparison

| Setting | Performance | PowerSaver | Security | Development | Privacy |
|---------|------------|-----------|----------|------------|---------|
| Polling (ms) | 100 | 2000 | 500 | 200 | 1000 |
| Hybrid Detection | ✓ | ✗ | ✓ | ✓ | ✗ |
| OCR Enabled | ✓ | ✗ | ✓ | ✓ | ✗ |
| Confidence Level | 0.75 | 0.80 | 0.85 | 0.50 | 0.90 |
| Screenshots | ✗ | ✗ | ✓ | ✓ | ✗ |
| Logging | info | warn | debug | debug | off |
| Database | ✓ | ✓ | ✓ | ✓ | ✗ |
| Notarization Check | ✓ | ✗ | ✓ | ✗ | ✓ |
| CPU Usage | Higher | Very Low | Moderate | Moderate | Very Low |
| Memory Usage | Higher | Low | High | High | Very Low |
| Battery Impact | High | Very Low | Moderate | Moderate | Very Low |

---

## Common Customizations

### Disable OCR for Battery Life
```bash
jq '.detection.ocr.enabled = false' config.json
```

### Increase Polling Interval for Low Resource Systems
```bash
jq '.daemon.polling_interval_ms = 3000' config.json
```

### Enable Screenshot Capture for Compliance
```bash
jq '.screenshots.capture_enabled = true | .screenshots.capture_on_ask = true' config.json
```

### Change Confidence Threshold
```bash
jq '.detection.confidence_threshold = 0.80' config.json
```

### Set Log Level to Debug
```bash
jq '.logging.level = "debug"' config.json
```

### Increase Database Retention
```bash
jq '.database.cleanup_old_events_days = 180' config.json
```

---

## Deployment Scenarios

### Single User Development
```bash
cp EXAMPLES/configurations/config-development.json \
  ~/Library/Application\ Support/PermissionPilot/config.json
```

### Small Team (Mixed Usage)
1. Use balanced from POLICIES
2. Base config on config-security.json
3. Adjust polling to 500ms
4. Enable screenshots
5. Deploy via scripts/deploy-bulk.sh

### Enterprise Wide
1. Start with config-security.json
2. Add notarization requirements
3. Increase retention to 90 days
4. Enable regular backups
5. Set up monitoring with analyze-logs.sh
6. Deploy via MDM

### Privacy-Focused Organization
1. Start with config-privacy.json
2. Combine with privacy-focused policies
3. Disable all logging and database
4. Use policy-based controls only
5. Manual approval workflow

---

## Performance Tuning Examples

### For Old Macbook (2015)
```json
{
  "daemon": {"polling_interval_ms": 1500},
  "detection": {"ocr": {"enabled": false}},
  "automation": {"click_delay_ms": 200},
  "screenshots": {"capture_enabled": false},
  "database": {"wal_mode": false}
}
```

### For M1 Mac (High Performance)
```json
{
  "daemon": {"polling_interval_ms": 50},
  "detection": {"ocr": {"quality": "highest"}},
  "automation": {"click_delay_ms": 30},
  "screenshots": {"capture_enabled": true}
}
```

### For Mac Mini Server (24/7 Operation)
```json
{
  "daemon": {"polling_interval_ms": 500},
  "logging": {"level": "info"},
  "database": {"backup_enabled": true},
  "screenshots": {"cache_size_mb": 1000}
}
```

---

## Monitoring Configuration Changes

After deploying a new configuration:

```bash
# Check if daemon is running with new settings
./Scripts/health-check.sh

# Run benchmark to measure performance
./Scripts/benchmark.sh

# Monitor logs for issues
log stream --predicate 'process == "PermissionPilot"' --level debug

# Check CPU/memory with new settings
ps aux | grep PermissionPilot
```

---

## Reverting Configuration

### To Default Configuration
```bash
rm ~/Library/Application\ Support/PermissionPilot/config.json
launchctl restart com.permissionpilot.daemon
```

### To Previous Configuration
```bash
# If you have a backup
cp ~/Library/Application\ Support/PermissionPilot/config.json.backup \
   ~/Library/Application\ Support/PermissionPilot/config.json
launchctl restart com.permissionpilot.daemon
```

### To Specific Known Configuration
```bash
cp EXAMPLES/configurations/config-balanced.json \
   ~/Library/Application\ Support/PermissionPilot/config.json
launchctl restart com.permissionpilot.daemon
```

---

## Configuration Best Practices

✅ **Do:**
- Start with a base configuration close to your needs
- Test changes on one machine before rolling out
- Document your customizations
- Keep a backup of working configurations
- Monitor performance after changes
- Review and adjust monthly

❌ **Don't:**
- Change too many settings at once
- Deploy without testing
- Use extreme values (polling_interval_ms = 10)
- Forget to restart daemon after changes
- Disable all logging in production environments

---

## Support & Resources

- Configuration Guide: [CONFIGURATION_GUIDE.md](../CONFIGURATION_GUIDE.md)
- Performance Tuning: [PERFORMANCE_TUNING.md](../PERFORMANCE_TUNING.md)
- Monitoring: [MONITORING.md](../MONITORING.md)
- Quick Reference: [QUICK_REFERENCE.md](../QUICK_REFERENCE.md)

---

**Version:** 1.0.0  
**Last Updated:** May 13, 2024  
**License:** MIT
