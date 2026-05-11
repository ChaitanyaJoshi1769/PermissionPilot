---
title: Features
description: Complete feature list for PermissionPilot
---

# Features

## 🎯 Core Detection

### Hybrid Dialog Detection
- **Accessibility API** (primary): Fast, reliable detection for modern apps
- **OCR Fallback** (secondary): Vision Framework for inaccessible dialogs
- **Sub-500ms latency**: Ultra-fast detection and response
- **Multi-monitor support**: Works across all connected displays

### Supported Dialog Types
- macOS system dialogs (permissions, file access)
- Browser popups (Chrome, Safari, Arc, Firefox)
- Application permission requests (Slack, Zoom, VSCode, etc.)
- Installer trust dialogs
- Terminal privilege prompts
- Electron app dialogs
- Custom app dialogs

---

## 🛡️ Safety Features

### Button Safety Ranking
- **"Allow Once"** prioritization (safest option)
- Safe button whitelist (Allow, Continue, OK)
- Dangerous button blacklist (Delete, Erase, Reset, Uninstall)
- Confidence-based filtering (≥85% required)
- Default button detection and boost

### Policy Engine
- Whitelist trusted applications
- Blacklist untrusted applications
- Custom pattern matching rules
- Regex support for advanced policies
- Priority-based rule evaluation
- Dynamic policy loading

### Trust Scoring Algorithm
- App signature validation (20%)
- Notarization status check (20%)
- Known app database (20%)
- User approval history (30%)
- App reputation scoring (10%)
- Configurable thresholds

---

## ⚙️ Automation

### Human-Like Behavior
- **Bézier curve mouse movement**: Natural trajectory over 50 steps
- **Timing jitter**: Gaussian distribution (σ=2 pixels)
- **Reaction time delays**: 0.1–0.3 seconds per action
- **Natural click timing**: Variable delays between actions
- **Keyboard fallback**: Alt+Y, Cmd+D when mouse unavailable

### Execution Control
- **Retry logic**: Up to 3 retries with exponential backoff
- **Timeout protection**: 30-second maximum per operation
- **Window management**: Focus, visibility, and position handling
- **Event debouncing**: 150ms intervals to prevent rapid-fire
- **Pause automation**: One-click or time-based pausing

---

## 📊 Transparency & Audit

### Real-Time Dashboard
- **Statistics visualization**: Dialogs detected, automation rate, blocked count
- **Activity feed**: Last 50 dialog interactions
- **Trend charts**: Success rate over time
- **Quick actions**: Pause, reset, export from dashboard

### Comprehensive Logging
- **SQLite-backed**: Persistent, queryable audit trail
- **Complete history**: Every action recorded with metadata
- **Confidence scores**: Trust and detection confidence logged
- **Execution timing**: Precise performance metrics
- **Screenshot snapshots**: Optional visual audit trail
- **Data export**: CSV and JSON formats

### Audit Trail Contents
- Timestamp (precise to milliseconds)
- Application name and bundle ID
- Dialog title and button labels
- Policy rule applied
- Trust score and confidence
- Decision (ALLOW, BLOCK, ASK)
- Execution time
- Screenshot (optional)

---

## 🎛️ Configuration

### Policy Management
- **Application whitelist**: Pre-configured trusted apps
- **Application blacklist**: Apps to always block
- **Custom rule engine**: Pattern matching, regex, keywords
- **Policy templates**: Pre-built policies for common scenarios
- **Priority system**: Rule precedence and evaluation order
- **Hotload support**: Changes apply without restart

### Settings & Preferences
- **Enable/Disable automation**: Global on/off switch
- **Pause modes**: 10 minutes, 1 hour, until restart, or manual
- **OCR toggle**: Enable/disable Vision Framework fallback
- **Confidence threshold**: Fine-tune detection sensitivity (0–1)
- **Screenshot retention**: Keep or delete captured images
- **Log retention**: Auto-delete events older than N days
- **Debug logging**: Verbose output for troubleshooting

---

## 🔐 Security

### Zero Privilege Escalation
- Runs entirely at user level
- No `sudo` or admin password handling
- Cannot modify system files
- Cannot bypass SIP (System Integrity Protection)
- Cannot tamper with TCC database

### Code Security
- Written in memory-safe Swift
- No unsafe pointer manipulation
- No buffer overflows possible
- Parameterized database queries (no SQL injection)
- Input validation on all boundaries
- Secure random number generation

### Notarization & Signing
- Code signed with Apple Developer ID
- Notarized by Apple (XProtect scanning)
- Hardened runtime enabled
- Entitlements minimized
- Gatekeeper verification required

---

## 📈 Performance

### Metrics (M1 MacBook Pro)
| Metric | Target | Actual |
|--------|--------|--------|
| Idle CPU | <3% | 0.2% |
| Memory | <200MB | 85MB |
| Detection | <500ms | 210ms |
| Click Time | <1s | 0.3s |
| DB Query | <100ms | 45ms |

### Scaling
- Handles 100+ automations/day without degradation
- Efficient window monitoring
- Debounced event processing
- Lazy-loaded OCR processing
- Optimized database queries with indexing

---

## 🌐 Platform Support

### System Requirements
- **macOS 13.0+** (Ventura, Sonoma, Sequoia, etc.)
- **Architectures**: arm64 (Apple Silicon) and x86_64 (Intel)
- **Universal Binary**: Single app for all Macs
- **Swift 5.9+** (for development)

### Dependencies
- **Zero third-party runtime dependencies**
- Uses only Apple system frameworks
- AppKit, SwiftUI, Accessibility APIs
- Vision Framework for OCR
- SQLite3 for logging

---

## 🚀 Advanced Features

### Batch Operations
- Process multiple dialogs in sequence
- Macro recording and playback
- Conditional automation rules
- Time-based scheduling (future)

### Integration
- LaunchAgent daemon (background service)
- Menu bar status icon
- Keyboard shortcuts (future)
- System integration (future)

### Extensibility
- Custom policy API
- Plugin architecture (roadmap)
- Remote management (enterprise, roadmap)
- Team policies (enterprise, roadmap)

---

## 📋 Roadmap Features

### Phase 2 (Q2 2024)
- Advanced policy rule editor
- Browser extension for web dialogs
- Enhanced notification system
- Performance profiling dashboard

### Phase 3 (Q3 2024)
- Machine learning dialog classifier
- iOS companion app
- Cloud backup (optional, encrypted)
- Apple Intelligence integration

### Phase 4 (Q4 2024+)
- Enterprise policies & MDM
- Remote management
- Team collaboration
- Advanced automation macros

---

## ✅ What PermissionPilot Does NOT Do

❌ Does not modify system files or TCC database  
❌ Does not bypass SIP or Gatekeeper  
❌ Does not inject code into other processes  
❌ Does not have admin/root privileges  
❌ Does not send data to servers  
❌ Does not log keystrokes  
❌ Does not access sensitive files  

---

**[Back to Home](/) | [View on GitHub](https://github.com/ChaitanyaJoshi1769/PermissionPilot)**
