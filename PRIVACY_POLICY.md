# PermissionPilot Privacy Policy

**Effective Date**: May 11, 2024  
**Last Updated**: May 11, 2024

## 1. Overview

PermissionPilot is designed with **privacy-first** principles. We do not collect, transmit, or analyze personal data. All processing occurs locally on your device.

## 2. What Data We Collect

PermissionPilot collects **ZERO personal data** by default.

### Audit Logs (Optional)

With your consent, PermissionPilot maintains a local audit log containing:
- Dialog titles and text
- Application names and bundle identifiers
- Buttons clicked
- Trust scores and confidence percentages
- Timestamps
- Screenshot snippets (optional, disabled by default)

**Location**: `~/Library/Application Support/PermissionPilot/audit.db`  
**Storage**: Encrypted SQLite database  
**Access**: User read/write only  
**Retention**: Configurable (default: 90 days)  
**Deletion**: User can delete at any time via app or manually

### Settings & Configuration

- Whitelist/blacklist app bundle IDs
- Policy rules and patterns
- User preferences (UI theme, debounce timing, etc.)

**Location**: `~/Library/Preferences/com.permissionpilot.app.plist`  
**Encryption**: Automatic (macOS Keychain for sensitive values)

## 3. What Data We DO NOT Collect

❌ **We do NOT collect**:
- Keystroke data
- Document contents
- Webpage browsing history
- Application data or documents
- User's real name, email, or contact info
- IP addresses or network metadata
- Device identifiers (except app-level)
- Health, financial, or biometric data
- Location data
- Marketing/advertising identifiers

❌ **We do NOT track**:
- Your app usage patterns
- Your automation habits
- Which dialogs you approve/reject
- Which websites you visit

❌ **We do NOT transmit**:
- Any logs to our servers
- Analytics or crash reports
- Personal data anywhere
- Telemetry or statistics
- Screenshots (unless explicitly exported by you)

## 4. Data Processing

### On-Device Processing

All data processing is 100% local:

| Operation | Location | Status |
|-----------|----------|--------|
| Dialog detection | Your Mac | ✅ Local |
| OCR processing | Your Mac | ✅ Local |
| Policy evaluation | Your Mac | ✅ Local |
| Logging | SQLite on your Mac | ✅ Local |
| Screenshots | Your Mac's `/tmp` or Application Support | ✅ Local |

### NO Cloud Transmission

- ❌ No cloud backup (unless explicitly enabled in future version)
- ❌ No server-side storage
- ❌ No analytics dashboards
- ❌ No cross-device sync (unless future feature opt-in)

### NO Third-Party Processors

All data remains under your exclusive control.

## 5. Your Permissions & Control

### Accessibility Permission

PermissionPilot requires macOS Accessibility permission to:
- ✅ Detect UI elements in dialogs
- ✅ Simulate mouse clicks
- ✅ Simulate keyboard input

**NOT used for**:
- ❌ Keylogging
- ❌ Document content reading
- ❌ Password field inspection
- ❌ Text input monitoring

**You can revoke** anytime via System Preferences → Security & Privacy → Accessibility.

### Screenshot Permission

If enabled for OCR, PermissionPilot captures dialog regions only.

**You can disable** in Settings → disable OCR (uses Accessibility API instead).

### File Access Permission

Required for exporting logs as CSV/JSON.

**You control** what data is exported and where.

## 6. Data Retention

### Audit Logs

- **Default retention**: 90 days
- **Configurable**: In Settings
- **Auto-deletion**: Old logs automatically deleted
- **Manual deletion**: Clear logs button in UI

### Whitelist/Blacklist

- **Retention**: Until you remove
- **Deletion**: Remove from Policies tab

### Application Cache

- **Retention**: Until restart
- **Auto-clean**: Cleared on app exit

## 7. Data Security

### Encryption at Rest

- SQLite database: Protected by file permissions
- Preferences: Optionally stored in Keychain
- Screenshots: File permissions (owner read/write only)

### Access Control

- ✅ Data accessible only to your user account
- ✅ No admin/root access
- ✅ Protected by standard macOS file permissions
- ✅ No network transmission = no network interception

### Data Integrity

- ✅ SQLite ACID compliance (guaranteed consistency)
- ✅ Write-ahead logging (corruption protection)
- ✅ Timestamp verification

## 8. Third-Party Sharing

PermissionPilot **never shares** data with:
- ❌ App developers
- ❌ Analytics companies
- ❌ Advertising networks
- ❌ Cloud storage providers
- ❌ Other applications

Even if a third-party app is a feature beneficiary, NO data is shared.

## 9. Export & Portability

You can export your data anytime:

```bash
# Export logs as CSV
PermissionPilot → Logs tab → Export → CSV

# Export settings as JSON
Preferences: ~/Library/Preferences/com.permissionpilot.app.plist

# Export whitelist/blacklist
Policies tab → Export

# Full database backup
cp ~/Library/Application\ Support/PermissionPilot/audit.db ~/backup.db
```

Your data is always yours. You can:
- ✅ Export it
- ✅ Delete it
- ✅ Back it up
- ✅ Take it elsewhere

## 10. Data Deletion

### Delete Everything

```bash
# Remove all PermissionPilot data
rm -rf ~/Library/Application\ Support/PermissionPilot
rm -rf ~/Library/Preferences/com.permissionpilot.*
rm -rf ~/Library/Caches/com.permissionpilot.*
```

### Delete Specific Data

- **Logs only**: Logs tab → Clear logs
- **Whitelist/Blacklist**: Policies tab → Reset
- **Settings**: Settings tab → Reset to defaults

## 11. Children's Privacy

PermissionPilot is designed for macOS power users (developers, sysadmins). We do not knowingly collect data from children under 13.

If you believe a child's data has been collected, contact: **privacy@permissionpilot.app**

## 12. Compliance

### GDPR (Europe)

✅ **Compliance**: Full GDPR compliance  
- No personal data collection
- No data transfers outside EU
- User has right to access/delete

**Data Processing Agreement**: Available on request for B2B deployments

### CCPA (California)

✅ **Compliance**: Full CCPA compliance
- No personal information collection
- No sale of data
- No sharing with third parties
- Transparency in data practices

### HIPAA (Healthcare)

⚠️ **Use with caution** in healthcare contexts
- Audit logs may capture healthcare app dialogs
- Patient privacy is user's responsibility
- Recommended: Block healthcare apps in policy

### SOC 2

PermissionPilot is **designed** with SOC 2 principles:
- ✅ Security controls
- ✅ Availability (<3% CPU)
- ✅ Data integrity (audit trail)
- ✅ Confidentiality (encryption at rest)

## 13. Cookies & Tracking

✅ **PermissionPilot uses**:
- ❌ NO cookies
- ❌ NO tracking pixels
- ❌ NO advertising networks
- ❌ NO analytics libraries

## 14. Changes to This Policy

We may update this policy. Changes will be announced in:
- In-app notifications (for material changes)
- GitHub release notes
- Email to registered users (if applicable)

You will always have 30 days' notice before material changes take effect.

## 15. Contact & Rights

### Privacy Questions

Email: **privacy@permissionpilot.app**

### Data Subject Rights (GDPR)

- Right to access your data: Export from app
- Right to delete your data: Clear logs + settings
- Right to data portability: Export feature
- Right to object to processing: Pause automation

### California Rights (CCPA)

- Right to know: See audit logs
- Right to delete: Clear logs button
- Right to opt-out: Disable automation
- Right to non-discrimination: No differential pricing

### To Exercise Your Rights

Contact: **privacy@permissionpilot.app** with:
- Your request type
- Any relevant details
- How you'd like to be contacted

We will respond within **14 days** (GDPR) or **45 days** (CCPA).

## 16. International Users

### EU Users

Your data is processed in compliance with GDPR. By using PermissionPilot, you consent to processing as described herein.

### China Users

PermissionPilot does not operate in China. If you access it via VPN from China, you accept that Chinese authorities may intercept VPN traffic (not PermissionPilot's responsibility).

### Other Jurisdictions

PermissionPilot complies with all applicable local privacy laws. For jurisdiction-specific questions, contact privacy@permissionpilot.app.

## 17. Data Breach Notification

In the unlikely event of a data breach:

1. **Investigation**: We investigate immediately
2. **Notification**: Affected users notified within 24 hours
3. **Details**: Breach scope, types of data, remediation steps
4. **Reporting**: Filed with relevant regulatory authorities

Contact: **security@permissionpilot.app**

## 18. Subpoena & Law Enforcement

PermissionPilot may disclose data only when:
- ✅ Required by valid legal process (subpoena, warrant)
- ✅ Necessary to prevent imminent harm
- ✅ With user consent

We will:
- ✅ Notify you of legal requests (unless prohibited)
- ✅ Provide only the minimum data legally required
- ✅ Challenge overbroad requests in court

## 19. AI & Machine Learning (Future)

If PermissionPilot adds ML features (local dialog classification):

- ✅ Model runs 100% on-device
- ✅ No training data leaves your Mac
- ✅ No personal data in training
- ✅ Opt-in (user explicit consent)

## 20. Acknowledgment

By using PermissionPilot, you acknowledge that:

1. You have read this privacy policy
2. You consent to data practices described
3. You understand your data remains local
4. You can exercise rights anytime

## Contact Information

**PermissionPilot Privacy Team**

- **Email**: privacy@permissionpilot.app
- **Postal**: See website for mailing address
- **Web**: https://permissionpilot.app/privacy
- **Response Time**: 14 days (GDPR) / 45 days (CCPA)

---

**Last Updated**: May 11, 2024  
**Version**: 1.0 (Release)

*PermissionPilot is committed to your privacy. Questions? We're here to help.*
