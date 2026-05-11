# Frequently Asked Questions

## General

### What is PermissionPilot?

PermissionPilot is an intelligent macOS utility that detects and safely automates permission dialogs. It uses a hybrid Accessibility API + OCR approach for reliable detection and a policy engine with trust scoring to make intelligent automation decisions—all while maintaining privacy and security.

### Is PermissionPilot free?

Yes, PermissionPilot is open source under the MIT license. You can use it, modify it, and distribute it freely.

### What macOS versions does it support?

PermissionPilot requires macOS 13.0 (Ventura) or later. It runs natively on both Intel (x86_64) and Apple Silicon (arm64) architectures.

### Does PermissionPilot run in the background?

Yes. PermissionPilot runs as a LaunchAgent daemon that starts automatically at login and monitors for permission dialogs in the background.

### How much CPU and memory does it use?

Idle consumption is minimal:
- **CPU**: <3% when idle
- **Memory**: <200MB typical
- **Detection latency**: <500ms average

## Security & Privacy

### Does PermissionPilot escalate privileges?

No. By design, PermissionPilot operates at the user level only. It never requests root access, never modifies system files, and never bypasses System Integrity Protection (SIP).

### Does it modify the TCC database?

No. PermissionPilot respects the macOS security model completely. It relies on the Accessibility permission (which you grant voluntarily) but never tampers with TCC (Transparent Computer Control) or other system security mechanisms.

### Where does my data go?

Nowhere. All processing is local to your machine. PermissionPilot:
- Does not send data to cloud servers
- Does not phone home
- Does not collect user data
- Does not use telemetry

See [PRIVACY_POLICY.md](PRIVACY_POLICY.md) for details.

### How does the trust scoring algorithm work?

Trust scoring combines multiple signals:
- **Notarization status** (20%) — Is the app notarized by Apple?
- **Known trusted apps** (20%) — Is it in our known trusted list?
- **User approval history** (30%) — Has the user approved it before?
- **App reputation** (20%) — Whitelist/blacklist status
- **Dialog type** (10%) — Is the specific permission request safe?

The algorithm produces a score from 0–1:
- **≥0.8**: Auto-approve
- **0.5–0.8**: Ask user
- **<0.5**: Block

### What if I disagree with an automation decision?

You can:
1. Disable PermissionPilot temporarily (`pause` in the menu)
2. Create custom policies in the Settings tab
3. Add/remove apps from whitelist or blacklist
4. Adjust the confidence threshold

See [CONTRIBUTING.md](CONTRIBUTING.md) to suggest policy improvements.

## Technical

### Why use both Accessibility API and OCR?

The Accessibility API is fast and reliable for most modern apps, but some older or sandboxed applications don't expose their UI elements through it. OCR (Optical Character Recognition) via Vision Framework provides a fallback when accessibility fails.

- **Accessibility API** (primary): <100ms, highly accurate
- **OCR fallback** (secondary): 200–500ms, reliable for any dialog

### What dialogs does PermissionPilot support?

It works with:
- macOS system dialogs (permissions, file access)
- Browser popups (Chrome, Safari, Arc, Firefox)
- App permission requests (Slack, Zoom, VSCode, etc.)
- Installer trust dialogs
- Terminal privilege prompts
- Electron app dialogs
- Custom application dialogs

See [README.md](README.md#supported-dialog-types) for a complete list.

### Can I create custom policies?

Yes. Policies are JSON-based and support:
- Pattern matching (keyword-based rules)
- App-based rules (whitelist/blacklist specific apps)
- Trust threshold customization
- Custom action mappings (ALLOW, ASK, BLOCK)

See [Configuration/example-policies.json](Configuration/example-policies.json) for examples.

### How do I debug issues?

1. Check logs in `~/Library/Logs/PermissionPilot/`
2. Enable screenshot capture in Settings (for audit trail)
3. Run `make test` to verify the build
4. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues
5. File a bug report with detailed steps

### Does PermissionPilot work with sandboxed apps?

Partially. Sandboxed apps have limited accessibility exposure by design. PermissionPilot can still detect some dialogs via OCR, but accessibility introspection is limited.

## Development

### Can I contribute?

Absolutely! See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Development setup
- Code style guidelines
- Testing requirements
- Commit conventions
- Pull request process

### What are the system requirements for building?

- macOS 13.0+
- Xcode 15.0+
- Swift 5.9+
- Command Line Tools installed

### How do I build from source?

```bash
# Clone and setup
git clone https://github.com/ChaitanyaJoshi1769/PermissionPilot.git
cd PermissionPilot

# Install dev tools
brew install swiftformat swiftlint

# Build and test
make build
make test

# Install to /Applications
make install
```

### What external dependencies does PermissionPilot have?

Zero. PermissionPilot uses only Apple frameworks (AppKit, SwiftUI, Accessibility APIs, Vision Framework, SQLite). No third-party dependencies to manage or audit.

### How is the audit log stored?

Audit logs are stored in SQLite at `~/Library/Application Support/PermissionPilot/audit.db`. Each entry includes:
- Timestamp
- Application name and bundle ID
- Dialog title and button clicked
- Trust score and confidence
- Execution time

You can export as CSV or JSON from the Logs tab.

## Roadmap

### What's coming next?

See [ROADMAP.md](ROADMAP.md) for our planned phases:
- **Phase 2** (Q2 2024): Browser extension, advanced policy editor
- **Phase 3** (Q3 2024): ML dialog classifier, iOS companion app
- **Phase 4** (Q4 2024): Enterprise MDM integration, team collaboration

### Can I request a feature?

Yes! Open a [feature request](https://github.com/ChaitanyaJoshi1769/PermissionPilot/issues/new?template=feature_request.md) on GitHub.

### How can I stay updated?

- Watch releases: https://github.com/ChaitanyaJoshi1769/PermissionPilot/releases
- Star the repo to follow updates
- Check the [CHANGELOG.md](CHANGELOG.md)

## Support

### Something isn't working. What do I do?

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Review the logs in `~/Library/Logs/PermissionPilot/`
3. Search [existing issues](https://github.com/ChaitanyaJoshi1769/PermissionPilot/issues)
4. Open a [bug report](https://github.com/ChaitanyaJoshi1769/PermissionPilot/issues/new?template=bug_report.md)

### Where can I get help?

- **Documentation**: [README.md](README.md), [ARCHITECTURE.md](ARCHITECTURE.md)
- **Issues**: [GitHub Issues](https://github.com/ChaitanyaJoshi1769/PermissionPilot/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ChaitanyaJoshi1769/PermissionPilot/discussions)
- **Email**: dev@permissionpilot.app

### Is there a Discord server or community?

Not yet, but we're open to building one! Check [Discussions](https://github.com/ChaitanyaJoshi1769/PermissionPilot/discussions) for community coordination.

---

**Have a question not answered here?** [Ask in Discussions](https://github.com/ChaitanyaJoshi1769/PermissionPilot/discussions) or [open an issue](https://github.com/ChaitanyaJoshi1769/PermissionPilot/issues).
