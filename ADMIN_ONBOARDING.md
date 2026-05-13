# PermissionPilot Administrator Onboarding Guide

Your first week as PermissionPilot administrator - everything you need to know.

---

## Welcome! 👋

This guide will get you from zero to operational in one week. Follow the checklist and you'll be comfortable managing PermissionPilot in production.

---

## Day 1: Installation & Verification

**Goal:** Get PermissionPilot installed and verify it's working

### Morning (30 minutes)
- [ ] Read [QUICK_START.md](QUICK_START.md) - 5 min overview
- [ ] Install PermissionPilot
  - Option A (easiest): `brew install permissionpilot`
  - Option B: Download DMG from [releases](https://github.com/ChaitanyaJoshi1769/PermissionPilot/releases)
  - Option C: Build from source: `make build && make install`
- [ ] Launch the application
- [ ] Grant accessibility permission (System Preferences → Security & Privacy → Accessibility)

### Afternoon (30 minutes)
- [ ] Run health check: `./Scripts/health-check.sh`
- [ ] All checks should show ✓ (green)
- [ ] Check that daemon is running: `pgrep -f PermissionPilot`
- [ ] Review initial dashboard

**Success Criteria:** Daemon running, health check passing, no errors in logs

---

## Day 2: Configuration & Policies

**Goal:** Understand configurations and choose policies for your environment

### Morning (45 minutes)
- [ ] Read [EXAMPLES/README.md](EXAMPLES/README.md) - understand the 5 configurations
- [ ] Read [POLICIES/README.md](POLICIES/README.md) - understand the 4 policy sets
- [ ] Copy a configuration matching your use case:
  ```bash
  # For typical environments
  cp EXAMPLES/configurations/config-balanced.json \
     ~/Library/Application\ Support/PermissionPilot/config.json
  
  # For enterprises requiring audit
  cp EXAMPLES/configurations/config-security.json \
     ~/Library/Application\ Support/PermissionPilot/config.json
  ```

### Afternoon (45 minutes)
- [ ] Copy appropriate policy set:
  ```bash
  # For typical users
  cp POLICIES/balanced-default.json \
     ~/Library/Application\ Support/PermissionPilot/policies.json
  
  # For enterprises
  cp POLICIES/enterprise-secure.json \
     ~/Library/Application\ Support/PermissionPilot/policies.json
  ```
- [ ] Restart daemon: `launchctl restart com.permissionpilot.daemon`
- [ ] Verify configuration loaded: `cat ~/Library/Application\ Support/PermissionPilot/config.json | jq`
- [ ] Verify policies loaded: `cat ~/Library/Application\ Support/PermissionPilot/policies.json | jq`

**Success Criteria:** Configuration and policies applied, daemon running without errors

---

## Day 3: Monitoring & Maintenance

**Goal:** Set up monitoring and understand daily operations

### Morning (1 hour)
- [ ] Read [OPERATIONS_GUIDE.md](OPERATIONS_GUIDE.md) sections on:
  - Daily operations (5 min summary)
  - Monitoring setup
- [ ] Run benchmark to establish baseline: `./Scripts/benchmark.sh`
- [ ] Save output for future comparison

### Afternoon (1 hour)
- [ ] Set up daily health check with cron:
  ```bash
  # Edit crontab
  crontab -e
  
  # Add this line (runs daily at 2 AM)
  0 2 * * * /path/to/PermissionPilot/Scripts/health-check.sh >> /var/log/permissionpilot_health.log
  ```
- [ ] Set up weekly activity report:
  ```bash
  # Add to crontab (runs Sundays at 9 AM)
  0 9 * * 0 /path/to/PermissionPilot/Scripts/analyze-logs.sh text | mail -s "Weekly PermissionPilot Report" your_email@example.com
  ```
- [ ] Test cron jobs manually:
  ```bash
  ./Scripts/health-check.sh
  ./Scripts/analyze-logs.sh text weekly_test.txt
  ```

**Success Criteria:** Cron jobs working, health checks passing, reports generating

---

## Day 4: Understanding Compliance

**Goal:** Know what compliance requirements apply to your organization

### Morning (1 hour)
- [ ] Read [COMPLIANCE_GUIDE.md](COMPLIANCE_GUIDE.md) - choose your framework:
  - **GDPR** if you process EU resident data
  - **HIPAA** if you're in healthcare (US)
  - **SOX** if you're a public company
  - **PCI DSS** if you process payments
  - **ISO 27001** if you need formal information security
- [ ] Understand the compliance features PermissionPilot provides
- [ ] List any gaps between what's required and what's provided

### Afternoon (1 hour)
- [ ] Create a simple compliance checklist for your framework:
  ```bash
  # Create a file listing your organization's compliance needs
  cat > compliance_checklist_$(date +%Y%m).md << 'EOF'
  # Compliance Checklist - [Framework Name]
  
  ## Requirements
  - [ ] Audit logging
  - [ ] Access controls
  - [ ] Data retention
  - [ ] Encryption
  - [ ] Incident response
  
  ## PermissionPilot Capabilities
  - [x] Audit logging: audit.db
  - [x] Access controls: User-level only
  - [ ] Data retention: Configurable (default 60 days)
  - [ ] Encryption: Optional
  - [ ] Incident response: Playbook available
  
  ## Action Items
  - [ ] Enable encryption if required
  - [ ] Adjust data retention policy
  - [ ] Set up compliance reporting
  EOF
  ```

**Success Criteria:** You know your compliance requirements and what PermissionPilot provides

---

## Day 5: Emergency Procedures

**Goal:** Know what to do when something goes wrong

### Morning (1 hour)
- [ ] Read [INCIDENT_RESPONSE.md](INCIDENT_RESPONSE.md) introduction
- [ ] Skim the 7 playbooks (don't memorize, just know they exist)
- [ ] Bookmark or print the incident response guide

### Afternoon (1 hour)
- [ ] Create an emergency contact list:
  ```bash
  cat > emergency_contacts.txt << 'EOF'
  # PermissionPilot Emergency Contacts
  
  On-Call Admin: [Name] - [Phone]
  Manager: [Name] - [Phone]
  Security Team: [Email]
  
  External Support:
  - GitHub Issues: https://github.com/ChaitanyaJoshi1769/PermissionPilot/issues
  - Email: dev@permissionpilot.app
  - Security: security@permissionpilot.app
  EOF
  ```
- [ ] Create a quick reference for common issues:
  ```bash
  # Test one procedure from INCIDENT_RESPONSE.md
  # Try: Daemon not running - restart it
  launchctl stop com.permissionpilot.daemon
  sleep 2
  launchctl start com.permissionpilot.daemon
  sleep 5
  pgrep -f "PermissionPilot" && echo "✓ Running" || echo "✗ Failed"
  ```

**Success Criteria:** You have emergency procedures documented and tested

---

## Week 2+: Ongoing Operations

### Weekly Tasks (30 minutes every Sunday)
```bash
# Run comprehensive weekly check
./Scripts/health-check.sh > weekly_health_$(date +%Y%m%d).txt
./Scripts/analyze-logs.sh text weekly_activity_$(date +%Y%m%d).txt 168
./Scripts/benchmark.sh > weekly_benchmark_$(date +%Y%m%d).txt
```

### Monthly Tasks (1-2 hours first of month)
```bash
# Run full maintenance routine
./Scripts/database-maintenance.sh backup
./Scripts/database-maintenance.sh cleanup
./Scripts/database-maintenance.sh vacuum

# Export for compliance
./Scripts/export-database.sh csv monthly_export_$(date +%Y%m).csv 30

# Review and document
# - Update policies if needed
# - Review incident reports
# - Verify compliance
```

### Quarterly Tasks (4 hours each quarter)
- [ ] Full security audit
- [ ] Policy effectiveness review
- [ ] Performance analysis
- [ ] Update documentation as needed
- [ ] Team training refresh

---

## Essential Reading by Role

### For Operations/Sysadmin
Priority reading order:
1. [QUICK_START.md](QUICK_START.md) - 10 min
2. [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - 15 min
3. [OPERATIONS_GUIDE.md](OPERATIONS_GUIDE.md) - 30 min
4. [INCIDENT_RESPONSE.md](INCIDENT_RESPONSE.md) - 30 min
5. [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - 20 min

### For Security/Compliance
Priority reading order:
1. [SECURITY.md](SECURITY.md) - 20 min
2. [COMPLIANCE_GUIDE.md](COMPLIANCE_GUIDE.md) - 45 min
3. [INCIDENT_RESPONSE.md](INCIDENT_RESPONSE.md) - 30 min
4. [MONITORING.md](MONITORING.md) - 25 min

### For Developers
Priority reading order:
1. [QUICK_START.md](QUICK_START.md) - 10 min
2. [ARCHITECTURE.md](ARCHITECTURE.md) - 30 min
3. [API_REFERENCE.md](API_REFERENCE.md) - 30 min
4. [EXAMPLES/swift-integration/README.md](EXAMPLES/swift-integration/README.md) - 20 min

---

## Common Tasks in Week 1

### "How do I see what dialogs are being detected?"
```bash
# Check recent events
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "SELECT timestamp, app_name, dialog_title FROM automation_events LIMIT 10;"

# Or use the analysis script
./Scripts/analyze-logs.sh text activity.txt 1
cat activity.txt
```

### "How do I add a custom policy?"
1. Edit: `nano ~/Library/Application\ Support/PermissionPilot/policies.json`
2. Add policy following [POLICIES/README.md](POLICIES/README.md) format
3. Validate: `./Scripts/validate-policy.sh`
4. Restart: `launchctl restart com.permissionpilot.daemon`

### "How do I check if it's working?"
```bash
# Quick health check
./Scripts/health-check.sh

# Or manual check
pgrep -f "PermissionPilot"  # Should return PID
launchctl list | grep permissionpilot  # Should show it's loaded
log stream --predicate 'process == "PermissionPilot"'  # Should show logs
```

### "How do I backup the database?"
```bash
./Scripts/database-maintenance.sh backup
# Backup stored in: ~/Library/Application\ Support/PermissionPilot/backups/
```

---

## Success Checkpoints

### End of Day 1 ✅
- [ ] PermissionPilot installed
- [ ] Daemon running
- [ ] Health check passing
- [ ] No critical errors

### End of Day 2 ✅
- [ ] Configuration applied
- [ ] Policies loaded
- [ ] Dashboard accessible
- [ ] First dialogs being detected

### End of Day 3 ✅
- [ ] Baseline benchmark captured
- [ ] Cron jobs scheduled
- [ ] Reports generating
- [ ] Monitoring operational

### End of Day 4 ✅
- [ ] Compliance requirements understood
- [ ] Gaps identified
- [ ] Action plan created
- [ ] Team informed

### End of Day 5 ✅
- [ ] Emergency procedures documented
- [ ] Contact list created
- [ ] One procedure tested
- [ ] Ready for production

### End of Week 1 ✅
- [ ] System running smoothly
- [ ] No unresolved issues
- [ ] Team comfortable with operations
- [ ] Policies effective
- [ ] Compliance on track

---

## Need Help?

| Question | Answer | Time |
|----------|--------|------|
| Installation issue? | [QUICK_START.md](QUICK_START.md) | 5 min |
| System not working? | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | 15 min |
| Policy question? | [POLICIES/README.md](POLICIES/README.md) | 10 min |
| Emergency situation? | [INCIDENT_RESPONSE.md](INCIDENT_RESPONSE.md) | varies |
| Compliance question? | [COMPLIANCE_GUIDE.md](COMPLIANCE_GUIDE.md) | 30 min |
| Command reference? | [QUICK_REFERENCE.md](QUICK_REFERENCE.md) | 5 min |

---

## Key Contacts

- **GitHub Issues**: https://github.com/ChaitanyaJoshi1769/PermissionPilot/issues
- **Email Support**: dev@permissionpilot.app
- **Security Issues**: security@permissionpilot.app
- **GitHub Discussions**: https://github.com/ChaitanyaJoshi1769/PermissionPilot/discussions

---

## Next Steps After Week 1

1. **Week 2-4**: Monitor system, optimize policies based on activity
2. **Month 2**: Set up compliance reporting if required
3. **Month 3**: Plan for team growth (if applicable)
4. **Quarter 2**: Conduct security review

---

**Congratulations on starting your PermissionPilot journey! 🎉**

You're now equipped to:
- ✅ Install and configure PermissionPilot
- ✅ Monitor system operations
- ✅ Respond to incidents
- ✅ Maintain compliance
- ✅ Support your team

Bookmark this guide for easy reference. Most answers are within these docs.

---

**Version:** 1.0.0  
**Created:** May 14, 2024  
**License:** MIT
