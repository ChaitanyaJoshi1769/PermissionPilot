# PermissionPilot Policy Library

Pre-configured policy sets for different use cases and environments. Choose a policy that matches your needs, customize it, and deploy to your system.

---

## Quick Start

1. **Choose a Policy Set** - Pick the one that matches your use case
2. **Copy to System** - `cp POLICIES/your-policy.json ~/Library/Application\ Support/PermissionPilot/policies.json`
3. **Customize** - Edit the JSON to match your specific requirements
4. **Reload** - Restart the daemon: `launchctl restart com.permissionpilot.daemon`

---

## Available Policy Sets

### 1. **Balanced Default** (`balanced-default.json`)
**Best for:** Typical users who want convenience + some safety

- ✅ Auto-approves Apple system applications
- ✅ Auto-approves popular browsers and communication tools
- ✅ Auto-approves notarized applications (high confidence)
- ⚠️ Asks user for unknown applications
- ❌ Blocks dangerous operations
- ❌ Blocks privilege escalation attempts

**Trust Threshold:** 0.70
**Default Action:** Ask user
**Best For:** General users, mixed environments

### 2. **Development Friendly** (`development-friendly.json`)
**Best for:** Software developers, build systems, CI/CD environments

- ✅ Auto-approves Xcode and development tools
- ✅ Auto-approves Homebrew and package managers
- ✅ Auto-approves Docker and containerization tools
- ✅ Auto-approves npm, pod, cargo, pip, Python, Node
- ✅ Auto-approves software installation/updates
- ❌ Blocks dangerous operations
- ❌ Blocks data destruction commands

**Trust Threshold:** 0.60
**Default Action:** Ask user
**Best For:** Development teams, build machines, local development

### 3. **Enterprise Secure** (`enterprise-secure.json`)
**Best for:** Organizations with strict security requirements

- ✅ Only allows Apple-signed applications
- ✅ Only allows notarized applications (very high confidence)
- ✅ Strict whitelist of pre-approved vendors
- ❌ Blocks all unverified/unsigned applications
- ❌ Blocks dangerous operations
- ❌ Blocks privilege escalation
- ❌ Blocks system configuration changes
- 🔍 High audit logging enabled

**Trust Threshold:** 0.85
**Default Action:** Block
**Best For:** Financial services, healthcare, regulated industries, corporate environments

### 4. **Privacy Focused** (`privacy-focused.json`)
**Best for:** Privacy-conscious users who prefer minimal automation

- ✅ Only allows Apple applications
- ❌ Blocks all non-Apple dialogs by default
- 🔒 No database logging
- 🔒 No audit trail
- 🔒 No screenshots
- 🔒 Privacy mode enabled
- 🔒 No telemetry
- 🔒 No external API calls

**Trust Threshold:** 0.99 (requires manual approval)
**Default Action:** Block
**Best For:** Privacy advocates, security researchers, minimal-trust environments

---

## Policy File Structure

Each policy file contains:

```json
{
  "name": "Policy Set Name",
  "version": "1.0.0",
  "description": "What this policy set is for",
  "policies": [
    {
      "id": "unique-id",
      "name": "Policy Name",
      "type": "whitelist|blacklist|rule",
      "target_type": "app|dialog_text|notarization_status|etc",
      "target_values": ["value1", "value2"],
      "target_pattern": "regex pattern",
      "action": "allow|block|ask",
      "priority": 100,
      "enabled": true,
      "confidence_required": 0.75,
      "notes": "Optional notes for maintainers"
    }
  ],
  "settings": {
    "default_action": "ask",
    "trust_threshold": 0.70,
    "ask_timeout_seconds": 30,
    "log_level": "debug|info|warn|error"
  }
}
```

### Policy Types

- **whitelist** - Explicitly allow matching entries
- **blacklist** - Explicitly block matching entries  
- **rule** - Conditional allow/block based on patterns

### Target Types

- **app** - Bundle identifier of application
- **dialog_text** - Text content of the dialog
- **notarization_status** - Apple notarization status
- **signature_status** - Code signing status
- **app_signature** - Certificate signing identifier

### Actions

- **allow** - Automatically approve the dialog
- **block** - Automatically reject the dialog
- **ask** - Prompt the user for decision

---

## Customization Guide

### Adding Your Own Application

Edit your policies.json and add a whitelist entry:

```json
{
  "id": "allow-my-app",
  "name": "Allow My Custom Application",
  "type": "whitelist",
  "target_type": "app",
  "target_values": ["com.company.myapp"],
  "action": "allow",
  "priority": 85,
  "enabled": true
}
```

Find your app's bundle ID:
```bash
mdls -name kMDItemCFBundleIdentifier -r /Applications/MyApp.app
```

### Adding a Custom Rule

Block dialogs containing specific text:

```json
{
  "id": "block-my-keyword",
  "name": "Block Dangerous Word",
  "type": "rule",
  "target_type": "dialog_text",
  "target_pattern": "(?i)(dangerous|forbidden|blocked)",
  "action": "block",
  "priority": 20,
  "enabled": true
}
```

### Combining Policies

Mix and match elements from different policy sets:

```bash
# Start with balanced default
cp POLICIES/balanced-default.json policies.json

# Add development tools (from development-friendly)
# Add security blocking (from enterprise-secure)
# Customize to your needs

# Verify syntax
jq empty policies.json
```

---

## Testing Your Policies

### Validate JSON Syntax
```bash
jq empty ~/Library/Application\ Support/PermissionPilot/policies.json
```

### Check Policy Loading
```bash
log stream --predicate 'process == "PermissionPilot"' --level debug | grep -i policy
```

### Test Specific Scenarios
1. Trigger dialogs from your test applications
2. Check logs for policy evaluation
3. Verify correct actions taken
4. Review audit database

---

## Common Customizations

### Allow More Apps (while keeping security)
```json
// Add to the whitelist section
{
  "target_values": [
    "com.my-company.app1",
    "com.my-company.app2",
    "com.my-company.app3"
  ]
}
```

### Increase Trust Threshold
```json
// In settings, change:
"trust_threshold": 0.80  // More restrictive
"trust_threshold": 0.50  // More permissive
```

### Add Department-Specific Rules
```json
{
  "id": "block-finance-changes",
  "name": "Finance Team - Block Risky Operations",
  "type": "rule",
  "target_type": "dialog_text",
  "target_pattern": "(?i)(accounting|financial record)",
  "action": "block",
  "priority": 30
}
```

### Create Time-Based Rules
```json
{
  "id": "block-after-hours",
  "name": "Block Risky Operations After Hours",
  "type": "rule",
  "target_type": "time_based",
  "target_pattern": "18:00-08:00",  // 6 PM to 8 AM
  "action": "block"
}
```

---

## Deployment Options

### Single Machine
```bash
cp POLICIES/balanced-default.json ~/Library/Application\ Support/PermissionPilot/policies.json
launchctl restart com.permissionpilot.daemon
```

### Multiple Machines
```bash
# Using Ansible
for host in machine1 machine2 machine3; do
  scp POLICIES/enterprise-secure.json user@$host:/tmp/policies.json
  ssh user@$host "mv /tmp/policies.json ~/Library/Application\ Support/PermissionPilot/"
done
```

### MDM Deployment
```bash
# Create configuration profile with policies.json as payload
# Deploy via Apple Business Manager
# See DEPLOYMENT_GUIDE.md for full MDM instructions
```

---

## Policy Priority System

Lower priority numbers are evaluated **first**:

```
Priority 100 (highest)   ← Evaluated first
Priority 85
Priority 70
Priority 50
Priority 20
Priority 10 (lowest)     ← Evaluated last
```

**Important:** First matching policy wins. Order your policies from most specific to most general.

---

## Monitoring Policy Effectiveness

### Query Recent Policy Decisions
```bash
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "SELECT app_name, action_taken, COUNT(*) FROM automation_events \
   WHERE timestamp > datetime('now', '-24 hours') \
   GROUP BY app_name, action_taken;"
```

### Check Block Rate
```bash
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "SELECT ROUND(100.0 * SUM(CASE WHEN action_taken = 'BLOCK' THEN 1 ELSE 0 END) / COUNT(*), 1) \
   FROM automation_events WHERE timestamp > datetime('now', '-24 hours');"
```

### Identify Problematic Policies
```bash
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
  "SELECT dialog_title, COUNT(*) FROM automation_events \
   WHERE action_taken = 'ASK' AND timestamp > datetime('now', '-24 hours') \
   GROUP BY dialog_title ORDER BY COUNT(*) DESC LIMIT 10;"
```

---

## Best Practices

✅ **Do:**
- Start with a conservative policy set
- Test policies before broad deployment
- Review and adjust monthly
- Keep audit logging enabled
- Document your policy customizations
- Version control your policy files
- Test policy effectiveness regularly

❌ **Don't:**
- Use overly permissive policies in production
- Leave all dialogs set to "allow"
- Disable audit logging for compliance
- Mix incompatible policies without testing
- Deploy without reviewing each policy
- Forget to reload the daemon after changes

---

## Troubleshooting

### Policies Not Taking Effect

1. Verify syntax: `jq empty ~/Library/Application\ Support/PermissionPilot/policies.json`
2. Check daemon is running: `pgrep -f PermissionPilot`
3. Restart daemon: `launchctl restart com.permissionpilot.daemon`
4. Check logs: `log stream --predicate 'process == "PermissionPilot"' --level debug`

### Too Many Blocks
- Lower trust threshold in settings
- Review and adjust priority values
- Check pattern matching in rules

### Too Many Auto-Approvals  
- Raise trust threshold in settings
- Make whitelist more specific
- Add blocking rules for risky operations

### Conflicting Policies
- Check priority order (first match wins)
- Ensure target patterns don't overlap
- Test individual policies in isolation

---

## Support & Resources

- Full configuration guide: [CONFIGURATION_GUIDE.md](../CONFIGURATION_GUIDE.md)
- Advanced policy examples: [EXAMPLE_POLICIES.md](../EXAMPLE_POLICIES.md)
- Troubleshooting: [TROUBLESHOOTING.md](../TROUBLESHOOTING.md)
- Database schema: [DATABASE_SCHEMA.md](../DATABASE_SCHEMA.md)

---

**Version:** 1.0.0  
**Last Updated:** May 13, 2024  
**License:** MIT
