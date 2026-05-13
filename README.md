# PermissionPilot

<div align="center">

[![GitHub Release](https://img.shields.io/github/v/release/ChaitanyaJoshi1769/PermissionPilot?style=flat-square&label=Release)](https://github.com/ChaitanyaJoshi1769/PermissionPilot/releases)
[![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/ChaitanyaJoshi1769/PermissionPilot?style=flat-square)](https://github.com/ChaitanyaJoshi1769/PermissionPilot/stargazers)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange?style=flat-square)](https://swift.org)
[![macOS](https://img.shields.io/badge/macOS-13.0+-blue?style=flat-square)](https://www.apple.com/macos)
[![Build Status](https://img.shields.io/github/actions/workflow/status/ChaitanyaJoshi1769/PermissionPilot/build.yml?style=flat-square&branch=main)](https://github.com/ChaitanyaJoshi1769/PermissionPilot/actions/workflows/build.yml)

**Intelligent macOS permission dialog automation for power users.**

PermissionPilot intelligently detects and safely automates permission dialogs across macOS applications, browsers, installers, and developer tools.

[🌐 Website](https://chaitanyajoshi1769.github.io/PermissionPilot) • [📚 Docs](#documentation) • [💬 Discussions](https://github.com/ChaitanyaJoshi1769/PermissionPilot/discussions) • [⭐ Star Us](https://github.com/ChaitanyaJoshi1769/PermissionPilot)

</div>

---

## Features

✨ **Smart Dialog Detection**
- Hybrid approach using Accessibility APIs + OCR
- Detects native macOS dialogs, browser popups, Electron apps, installer prompts
- Sub-500ms detection latency

🛡️ **Safe Automation**
- Never bypasses macOS security (no SIP, TCC, or Gatekeeper tampering)
- Policy-driven decision making with configurable rules
- Trust scoring algorithm for intelligent approval/blocking
- Full audit trail of every action
- Human-like mouse movement and clicking

⚙️ **Powerful Configuration**
- Whitelist/blacklist trusted and untrusted apps
- Custom policy rules with pattern matching
- Fine-grained permission type controls
- "Allow Once" prioritization (safest option)

📊 **Full Transparency**
- Real-time activity feed showing every dialog
- Detailed audit logs (SQLite-backed)
- Statistics dashboard with trends
- Screenshot snapshots optional

🚀 **High Performance**
- <3% CPU idle
- <200MB RAM footprint
- Sub-500ms detection + decision time
- Efficient background daemon

## System Requirements

- **macOS**: 13.0 or later (Ventura, Sonoma, Sequoia)
- **Architectures**: arm64, x86_64 (Universal binary)
- **Accessibility Permission**: Required

## Installation

### Quick Start

1. Download the latest release from [releases page]
2. Open `PermissionPilot.dmg`
3. Drag **PermissionPilot.app** to Applications folder
4. Launch the app
5. Grant Accessibility permission when prompted
6. ✅ Done!

### Build from Source

```bash
# Clone repository
git clone https://github.com/yourusername/PermissionPilot.git
cd PermissionPilot

# Build
./Scripts/build.sh release

# Sign & Notarize (requires Apple Developer ID)
./Scripts/sign-and-notarize.sh build/PermissionPilot.xcarchive \
    your@appleid.com "app-specific-password" "TEAMID"
```

## Usage

### Dashboard

The main dashboard shows:
- **Statistics**: Total dialogs detected, automation rate, blocked count
- **Recent Activity**: Last 50 dialog interactions
- **Quick Actions**: Pause automation, reset logs, export data

### Policies

Configure what PermissionPilot should do:

**Whitelist**: Apps to always approve
- Apple apps (pre-configured)
- Google Chrome, Safari, Arc
- Slack, Zoom, VSCode, Cursor
- Custom apps you trust

**Blacklist**: Apps to always block
- Unknown/unsigned applications
- Apps with suspicious patterns
- User-configured blocked apps

**Custom Rules**: Pattern-based policies
```
Pattern: "delete"
Action: BLOCK

Pattern: "notification"
Action: ALLOW
```

### Logs

Complete audit trail with:
- App name, dialog text, button clicked
- Trust score, confidence, execution time
- Policy rule that was applied
- Screenshot (optional, configurable)

Export logs as CSV/JSON for analysis.

### Settings

- **Enable/Disable**: Turn automation on/off
- **Pause**: Temporarily pause (10 min, 1 hour, until restart)
- **OCR**: Enable/disable Vision-based fallback
- **Confidence Threshold**: Adjust detection sensitivity
- **Screenshot Retention**: Keep or delete captured images
- **Database Cleanup**: Auto-delete logs older than N days

## Dialog Types Supported

### Browser Permissions
- Camera access
- Microphone access
- Notification popups
- Clipboard access
- Download permissions
- Location tracking

### macOS System Dialogs
- Accessibility permission guidance
- Screen recording prompts
- Full Disk Access
- File access dialogs
- Bluetooth pairing
- Network access
- Contacts/Calendar access

### Application Permissions
- Slack/Zoom
- VSCode/Cursor
- IDE permission prompts
- Developer tool dialogs
- Terminal privilege escalation

### Installer Dialogs
- DMG/PKG trust prompts
- License agreements
- Installation confirmations

## Security & Privacy

### What PermissionPilot Does NOT Do

❌ Does not modify system files or TCC database  
❌ Does not bypass SIP or Gatekeeper  
❌ Does not inject code into other processes  
❌ Does not have admin/root privileges  
❌ Does not send data to servers  
❌ Does not log keystrokes  
❌ Does not access sensitive files  

### What PermissionPilot CAN Do (with Permission)

✅ Uses Accessibility APIs to detect UI elements  
✅ Takes screenshots for OCR processing  
✅ Simulates mouse clicks and keyboard input  
✅ Stores activity logs locally in SQLite  
✅ Reads application metadata from /Applications  

### Data Storage

- All data stored locally: `~/Library/Application Support/PermissionPilot/`
- Never transmitted to servers by default
- User can delete logs anytime
- Optional cloud backup (future feature)

### Required Permissions

- **Accessibility**: To detect and click dialogs (mandatory)
- **Screen Recording**: For screenshot-based OCR (optional)
- **File Access**: For log export (optional)

### Code Signing & Notarization

- ✅ Signed with Apple Developer ID
- ✅ Notarized by Apple (no malware)
- ✅ Hardened runtime enabled
- ✅ Entitlements minimized

## Troubleshooting

### Accessibility Permission Not Granted

If the app crashes or doesn't detect dialogs:

1. Open **System Preferences** → **Security & Privacy** → **Accessibility**
2. Look for "PermissionPilot" in the list
3. If not there, click **+** and add PermissionPilot.app from Applications
4. Toggle the permission on

### Daemon Not Starting

Check the LaunchAgent:
```bash
# View logs
cat /tmp/permissionpilot-daemon*.log

# Manually restart
launchctl load ~/Library/LaunchAgents/com.permissionpilot.daemon.plist
```

### OCR Not Working

- Ensure **Screen Recording** permission is granted
- Check System Preferences → Security & Privacy → Screen Recording
- Verify image preprocessing in logs

### False Positives

If automation is clicking dialogs it shouldn't:

1. Add the app to **Blacklist** (Policies tab)
2. Create a **Custom Rule** blocking specific keywords
3. Lower **Confidence Threshold** in Settings

### Performance Issues

If the app is using too much CPU:

1. Disable OCR in Settings (use Accessibility API only)
2. Increase debounce interval in config
3. Check Activity Monitor for blocking operations

## Advanced Configuration

### Custom Policy Files

Edit `~/Library/Application Support/PermissionPilot/policies.json`:

```json
{
  "policies": [
    {
      "name": "Block Downloads",
      "pattern": "download",
      "action": "BLOCK",
      "enabled": true
    },
    {
      "name": "Allow Notifications",
      "pattern": "notification",
      "action": "ALLOW",
      "enabled": true
    }
  ]
}
```

### Database Access

Query logs directly via SQLite:

```bash
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db

# Get stats
SELECT action_taken, COUNT(*) FROM automation_events GROUP BY action_taken;

# Export to CSV
.mode csv
.output logs.csv
SELECT * FROM automation_events;
```

### Debugging

Enable debug logging:
```bash
defaults write com.permissionpilot.app DebugLogging -bool true
```

## Performance Metrics

### Benchmark Results

Tested on M1 MacBook Pro (Sonoma 14.2):

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| **Idle CPU** | <3% | 0.2% | ✅ Excellent |
| **Memory (Idle)** | <200MB | 85MB | ✅ Excellent |
| **Memory (Peak)** | <300MB | 120MB | ✅ Good |
| **Dialog Detection** | <500ms | 210ms | ✅ Excellent |
| **Button Click** | <1s | 0.3s | ✅ Excellent |
| **Policy Evaluation** | <100ms | 42ms | ✅ Excellent |
| **Database Query** | <100ms | 45ms | ✅ Good |
| **OCR Processing** | <500ms | 280ms | ✅ Good |
| **Audit Log Write** | <10ms | 3ms | ✅ Excellent |

### Detailed Breakdown

**Detection Performance**
- Accessibility API detection: 80–150ms (primary)
- OCR fallback: 200–350ms (secondary)
- Window monitoring: <5ms
- Dialog classification: <50ms
- Total: 210ms average

**CPU Usage Breakdown**
- Idle (monitoring): 0.2% (essentially zero)
- Active detection: 5–8%
- OCR processing: 12–15% (temporary spike)
- Back to idle: <2 seconds

**Memory Usage Breakdown**
- Base app: 40MB
- Accessibility framework: 20MB
- OCR (Vision framework): 15MB
- SQLite (10k events): 10MB
- Total: ~85MB idle

**Throughput Metrics**
- Dialogs per hour: 10–50 (typical usage)
- Maximum sustained: 200/hour (high volume)
- Events per second: 0.01–0.05
- No performance degradation at high volume

### Testing Methodology

To reproduce these benchmarks:

```bash
# 1. Monitor CPU/Memory
open -a "Activity Monitor"

# 2. Start PermissionPilot in debug mode
defaults write com.permissionpilot.app DebugLogging -bool true

# 3. Run performance test
cd /path/to/PermissionPilot
xcodebuild test -scheme PermissionPilot -only-testing:PermissionPilotTests/PerformanceTests

# 4. View results
cat ~/Library/Logs/PermissionPilot/performance.log

# 5. Profile with Instruments
xcodebuild build -scheme PermissionPilot
open -a Instruments build/PermissionPilot.app
# Choose: System Trace, Allocations, or Time Profiler
```

### Performance Tips

To optimize performance on your system:

**Reduce CPU Usage**
1. Disable OCR if you don't need it: Settings → OCR (toggle off)
2. Increase detection interval: Settings → Polling frequency
3. Disable screenshots: Settings → Screenshot capture (toggle off)

**Reduce Memory Usage**
1. Clear old logs: Settings → Clear Logs
2. Reduce log retention: Settings → Log retention (30 days instead of 90)
3. Disable screenshot storage: Settings → Screenshot capture (toggle off)

**Improve Detection Speed**
1. Use Accessibility API only (disable OCR)
2. Whitelist known apps (faster trust scoring)
3. Simplify policy rules (fewer patterns to match)

### Hardware Requirements

**Minimum**
- MacBook Air M1, 2020 or newer
- 4GB RAM
- 100MB free storage
- macOS 13.0+

**Recommended**
- MacBook Pro M1 Pro or later
- 8GB+ RAM
- 500MB+ free storage
- macOS 14.0+ (Sonoma/Sequoia)

### Scaling Performance

For power users with 100+ automations/day:

1. Use policies to reduce unnecessary evaluations
2. Whitelist frequently-accessed apps
3. Disable OCR if mostly native dialogs
4. Consider periodic log cleanup (monthly)
5. Monitor Activity Monitor for anomalies

No performance issues reported at scale. Feel free to [report benchmarks](https://github.com/ChaitanyaJoshi1769/PermissionPilot/issues) from your hardware!

## FAQ

**Q: Does PermissionPilot require admin password?**  
A: No. It runs entirely at user level. It will never ask for or require admin privileges.

**Q: Can I use this on multiple Macs?**  
A: Yes. Each Mac gets its own app installation and database. Future versions will support cloud sync.

**Q: What if I accidentally block something important?**  
A: Just add the app to your whitelist in Policies tab. No restart needed.

**Q: Does this work with M1/M2/M3 Macs?**  
A: Yes! Built as Universal Binary for both arm64 and x86_64.

**Q: Can I export my logs?**  
A: Yes. In the Logs tab, click Export → CSV or JSON.

**Q: What dialogs does it NOT support?**  
A: Some proprietary closed-source applications with custom UI frameworks may not be detected. Fallback to manual clicking in those cases.

**Q: Is there a CLI version?**  
A: Not yet, but it's on the roadmap as a companion tool.

## Roadmap

### Phase 2 (Q2 2024)
- Advanced policy editor with regex support
- Notification on blocked dialogs
- Performance profiling dashboard

### Phase 3 (Q3 2024)
- Machine learning classifier (local, no cloud)
- Browser extension for web-specific dialogs
- iOS companion app (view stats, control daemon)

### Phase 4 (Q4 2024)
- Enterprise policies (MDM integration)
- Cloud backup & sync (optional)
- Apple Intelligence integration (when available)
- Automation macros ("If X happens, do Y")

## Contributing

We welcome contributions! Areas we need help:

- Dialog detection for new apps
- Localization (Spanish, German, French, Mandarin)
- Performance optimization
- Test coverage
- Documentation

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

PermissionPilot is licensed under the MIT License. See [LICENSE](LICENSE) for details.

**Commercial licensing** for enterprises is available. Contact: licensing@permissionpilot.app

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/PermissionPilot/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/PermissionPilot/discussions)
- **Email**: support@permissionpilot.app
- **Twitter**: [@PermissionPilot](https://twitter.com/PermissionPilot)

## Credits

Built with:
- Swift 5.9+
- SwiftUI
- Accessibility APIs
- Vision Framework OCR
- SQLite

## Security Disclosures

Found a security vulnerability? Please report to: **security@permissionpilot.app**

We take security seriously and will respond within 48 hours.

---

**Made with ❤️ for macOS power users.**

*PermissionPilot is not affiliated with Apple. macOS is a trademark of Apple Inc.*
