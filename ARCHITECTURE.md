# PermissionPilot: System Architecture

## Executive Summary

PermissionPilot is a production-ready macOS daemon that intelligently detects and automates permission dialogs across native apps, browsers, installers, and developer tools. It combines Accessibility APIs, Vision-based OCR, policy-driven decision-making, and human-like automation to safely streamline permissions workflows.

---

## Core Design Principles

1. **Security First**: Uses only Apple-approved APIs. No SIP bypass, TCC tampering, or injection.
2. **Transparency**: Every action is logged, auditable, and user-controllable.
3. **Reliability**: Hybrid approach (Accessibility + OCR) ensures detection across all dialog types.
4. **Performance**: Sub-500ms detection, <3% CPU idle, <200MB RAM.
5. **User Control**: Pause/whitelist/blacklist/manual override always available.
6. **Privacy**: Local-only processing, no cloud dependencies, no telemetry by default.

---

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    PermissionPilot                           │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐   │
│  │  SwiftUI App │  │  Menu Bar    │  │  Daemon Service │   │
│  │  (Dashboard, │  │  Controller  │  │  (LaunchAgent)  │   │
│  │   Policies,  │  │              │  │                 │   │
│  │   Logs)      │  │              │  │                 │   │
│  └──────────────┘  └──────────────┘  └─────────────────┘   │
│         │                  │                  │              │
│         └──────────────────┴──────────────────┘              │
│                         │                                    │
│            ┌────────────┴────────────┐                       │
│            │                         │                       │
│  ┌─────────▼──────────┐  ┌──────────▼──────────┐            │
│  │  Automation Engine │  │  Policy Engine      │            │
│  │                    │  │                     │            │
│  │ • Dialog Detection │  │ • Trust Scoring     │            │
│  │ • Button Finding   │  │ • Policy Evaluation │            │
│  │ • Natural Clicking │  │ • Whitelist/Blacklist           │
│  │ • Retry Logic      │  │ • Custom Rules      │            │
│  └────────┬───────────┘  └──────────┬──────────┘            │
│           │                         │                       │
│  ┌────────▼────────────────────────▼──────┐                │
│  │      Decision & Execution Layer        │                │
│  │                                        │                │
│  │  • Accessibility API Inspector        │                │
│  │  • Vision Framework OCR               │                │
│  │  • Mouse/Keyboard Automation          │                │
│  │  • Confidence Scoring                 │                │
│  └────────────┬─────────────────────────┘                 │
│               │                                            │
│  ┌────────────▼──────────────────────┐                    │
│  │  Logging & Storage Layer           │                    │
│  │                                    │                    │
│  │  • SQLite Database                │                    │
│  │  • Screenshot Snapshots           │                    │
│  │  • Audit Trail                    │                    │
│  │  • Performance Metrics            │                    │
│  └────────────────────────────────────┘                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘

                    System Dependencies
┌─────────────────────────────────────────────────────────────┐
│ • AccessibilityAPI (public Apple framework)                 │
│ • Vision Framework (OCR - Apple native)                     │
│ • ScreenCaptureKit (screen monitoring)                      │
│ • Combine (reactive async)                                  │
│ • CoreGraphics (mouse/keyboard automation)                  │
│ • AppKit (window management)                                │
│ • SwiftUI (UI framework)                                    │
│ • SQLite (local database)                                   │
│ • LaunchAgent (background service)                          │
└─────────────────────────────────────────────────────────────┘
```

---

## Module Breakdown

### 1. **Core Detection Engine** (`/core`)

**Responsibility**: Monitor screen for dialogs, identify UI elements.

**Components**:
- `DialogDetector`: Watches for new windows and dialogs
- `AccessibilityInspector`: Queries AX hierarchy for buttons/text
- `OCRFallback`: Vision-based detection when AX insufficient
- `DialogClassifier`: Determines dialog type and safety

**Key APIs**:
```swift
// Accessibility monitoring
AXObserverCreate()
AXUIElementCopyAttributeValue()

// Screen capture for OCR
ScreenCaptureKit.captureContent()

// Vision OCR
VisionKit.recognizeText()
```

**Output**: Detected dialogs with:
- Window title
- Dialog text
- Button labels
- Confidence scores
- Application bundle

---

### 2. **Accessibility Subsystem** (`/accessibility`)

**Responsibility**: Bridge between macOS accessibility APIs and automation.

**Components**:
- `AXUIElementWrapper`: Safe AX element abstraction
- `WindowObserver`: Monitors window creation/destruction
- `ButtonDiscovery`: Finds clickable buttons in dialog
- `HierarchyParser`: Understands window structure

**Capabilities**:
- Detect native macOS dialogs
- Identify button positions from AX attributes
- Read static text, labels, help text
- Determine window focus state
- Detect modal vs modeless dialogs

**Limitations**:
- Some apps don't expose full AX hierarchy
- Sandboxed apps have limited exposure
- Electron apps may use custom rendering
- Web content in WebKit views

---

### 3. **OCR Pipeline** (`/ocr`)

**Responsibility**: Visual text recognition for dialogs inaccessible via AX.

**Architecture**:
```
Screen Region Capture
        ↓
Image Preprocessing (resize, contrast)
        ↓
Vision.VNRecognizeTextRequest
        ↓
Character Recognition + Layout Analysis
        ↓
Confidence Filtering (>85%)
        ↓
Button/Text Extraction
        ↓
Position Mapping to Screen Coordinates
```

**Features**:
- Multilingual support
- Retina-aware processing
- Dynamic scaling for various DPI
- Confidence thresholding
- Layout-aware text grouping

**Fallback Chain**:
1. Accessibility API (most reliable)
2. Vision framework OCR (visual fallback)
3. Heuristic button detection (last resort)

---

### 4. **Policy Engine** (`/policy`)

**Responsibility**: Intelligent decision-making about which dialogs to automate.

**Policy Categories**:

| Category | Action | Examples |
|----------|--------|----------|
| **SAFE_AUTO** | Auto-click | Notifications, camera/mic for trusted apps |
| **ASK_USER** | Prompt user | Full disk access, accessibility access |
| **BLOCK** | Refuse | Unsigned apps, suspicious patterns |
| **WHITELIST** | Always approve | User-configured trusted apps |
| **BLACKLIST** | Always refuse | User-configured blocked dialogs |

**Trust Scoring Algorithm**:
```
TrustScore = 
    (BundleSignatureBonus × 0.3) +
    (NotarizationBonus × 0.3) +
    (KnownAppBonus × 0.2) +
    (RecentApprovalBonus × 0.1) +
    (ReputationScore × 0.1)

Action Decision:
    if TrustScore > 0.8: AUTO_APPROVE
    if 0.5 < TrustScore < 0.8: ASK_USER
    if TrustScore < 0.5: BLOCK
```

**Database**:
- Whitelist: user-trusted apps
- Blacklist: user-blocked apps
- Policy rules: custom configurations
- Approval history: recent decisions

---

### 5. **Button Prioritization Engine** (`/buttons`)

**Responsibility**: Rank buttons by safety and likelihood.

**Priority Ranking**:
```
Tier 1 (Safest):
  - "Allow Once"
  - "Allow This Time"
  
Tier 2 (Safe):
  - "Allow"
  - "Enable"
  - "Grant"
  
Tier 3 (Neutral):
  - "Continue"
  - "OK"
  - "Yes"
  
Never Click:
  - "Delete", "Erase", "Reset"
  - "Disable", "Disable Security"
  - "Purchase", "Buy"
  - "Install", "Run Anyway"
  - "Format", "Clear"
```

**Button Matching**:
- Exact string matching
- Fuzzy matching (Levenshtein distance)
- Accessibility role matching
- Position heuristics (default button = usually rightmost)

---

### 6. **Automation Engine** (`/automation`)

**Responsibility**: Safely execute UI interactions.

**Components**:
- `MouseController`: Natural mouse movement with jitter
- `KeyboardController`: Keyboard shortcut handling
- `WindowManager`: Focus/visibility management
- `RetryHandler`: Intelligent retry logic

**Human-Like Behavior**:
```swift
// Natural mouse movement (Bézier curve)
move(from: startPoint, to: endPoint, duration: 0.15...0.35s)

// Random jitter
jitterX = randomGaussian(0, σ=2)
jitterY = randomGaussian(0, σ=2)

// Realistic click timing
wait(0.05...0.15s before click)
wait(0.1...0.3s after click for effects)

// Fallback to keyboard shortcuts
if mouseClick fails: try Tab + Space/Return
```

**Safety Guarantees**:
- Window must be visible and in foreground
- Button must have positive confidence
- Double-check position before click
- Abort if dialog disappears
- Timeout protection (30s max)

---

### 7. **Logging & Analytics** (`/logging`)

**Responsibility**: Immutable audit trail of all actions.

**SQLite Schema**:
```sql
-- Main audit log
CREATE TABLE automation_events (
    id INTEGER PRIMARY KEY,
    timestamp INTEGER,
    app_bundle_id TEXT,
    app_name TEXT,
    dialog_title TEXT,
    dialog_text TEXT,
    button_label TEXT,
    action_taken TEXT,  -- 'CLICKED', 'BLOCKED', 'ASKED', 'SKIPPED'
    trust_score REAL,
    confidence REAL,
    execution_time_ms INTEGER,
    screenshot_path TEXT,
    policy_rule_id TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Trust history
CREATE TABLE trust_decisions (
    id INTEGER PRIMARY KEY,
    app_bundle_id TEXT UNIQUE,
    app_name TEXT,
    first_seen INTEGER,
    last_seen INTEGER,
    approval_count INTEGER,
    rejection_count INTEGER,
    user_override TEXT  -- 'ALWAYS_ALLOW', 'ALWAYS_BLOCK', NULL
);

-- Custom policies
CREATE TABLE policies (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    pattern TEXT,
    action TEXT,  -- 'ALLOW', 'BLOCK', 'ASK'
    enabled BOOLEAN DEFAULT 1
);
```

**Features**:
- Full-text searchable dialog text
- Screenshot snippets (optional, configurable)
- Performance metrics
- Policy decision tracking
- User override history

---

### 8. **UI Layer** (`/ui`)

**Responsibility**: User-facing dashboards and controls.

**SwiftUI Architecture**:
```
ContentView
├── DashboardTab
│   ├── StatisticsCard
│   ├── RecentActivityList
│   └── QuickActionPanel
├── PoliciesTab
│   ├── TrustCenterView
│   ├── WhitelistEditor
│   └── BlacklistEditor
├── LogsTab
│   ├── LogSearchView
│   ├── FilterPanel
│   └── LogDetailView
└── SettingsTab
    ├── AccessibilityPermissions
    ├── BackgroundServiceToggle
    └── PrivacySettings
```

**Design System**:
- Glassmorphism cards
- Native SF Symbols
- Semantic colors (success/warning/error)
- Dark/light mode support
- Accessibility (VoiceOver ready)
- Haptic feedback

---

### 9. **Menu Bar Integration** (`/menu-bar`)

**Responsibility**: Quick access and status indication.

**Features**:
- Status icon (idle/active/paused)
- Recent actions submenu
- Quick pause toggle
- Emergency stop
- Open main window
- Activity history peek

---

### 10. **Background Daemon** (`/daemon`)

**Responsibility**: Runs continuously monitoring for dialogs.

**LaunchAgent Setup**:
```xml
<!-- /Library/LaunchAgents/com.permissionpilot.daemon.plist -->
<key>ProgramArguments</key>
<array>
    <string>/Applications/PermissionPilot.app/Contents/MacOS/PermissionPilotDaemon</string>
</array>
<key>RunAtLoad</key>
<true/>
<key>KeepAlive</key>
<true/>
```

**Behavior**:
- Starts at login
- Restarts on crash
- Pauses when accessibility disabled
- Syncs with UI app
- Uses XPC for IPC with UI

---

## Data Flow

### Happy Path: Permission Dialog Detection & Automation

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Application shows permission dialog                       │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│ 2. WindowObserver detects new window                        │
│    • Captures NSWindow event                                │
│    • Extracts app bundle identifier                         │
│    • Takes screenshot for OCR                              │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│ 3. DialogClassifier analyzes                                │
│    • Queries AX hierarchy                                   │
│    • Runs Vision OCR on region                              │
│    • Matches dialog type pattern                            │
│    • Extracts button labels & positions                     │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│ 4. PolicyEngine evaluates                                   │
│    • Checks whitelist/blacklist                             │
│    • Calculates trust score                                 │
│    • Matches policy rules                                   │
│    • Determines: AUTO / ASK / BLOCK                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                    ┌┴┐
              ┌─────┴─┴─────┐
              │              │
        ┌─────▼──┐      ┌────▼──┐
        │  AUTO  │      │ ASK / │
        │ CLICK  │      │ BLOCK │
        └─────┬──┘      └────┬──┘
              │              │
        ┌─────▼──┐      ┌────▼──────────┐
        │ Mouse  │      │ Notify user   │
        │ move & │      │ Await input   │
        │ click  │      │ from UI app   │
        └─────┬──┘      └────┬──────────┘
              │              │
        ┌─────▼──────────────▼──┐
        │  Log to SQLite         │
        │  • Action taken        │
        │  • Confidence          │
        │  • Timing              │
        │  • Screenshot          │
        └────────────────────────┘
                     │
        ┌────────────▼────────────┐
        │ Update trust history    │
        │ Broadcast to UI         │
        │ Continue monitoring     │
        └────────────────────────┘
```

---

## Concurrency & Performance

**Reactive Architecture** (Combine):
```swift
// WindowCreation → Dialog Detection → Classification → Decision → Action
windowPublisher
    .debounce(for: 0.1)  // Avoid flurries
    .flatMap { window in
        dialogDetector.analyze(window)
    }
    .flatMap { dialog in
        policyEngine.evaluate(dialog)
    }
    .flatMap { decision in
        automationEngine.execute(decision)
    }
    .sink { result in
        logging.record(result)
    }
```

**Threading**:
- Main: UI updates
- Background: AX queries, OCR processing
- Async/await: File I/O, database

**Performance Targets**:
- Dialog detection: <200ms
- OCR processing: <300ms
- Policy evaluation: <50ms
- Total latency: <500ms (user-imperceptible)

---

## Security Model

### Threat Model

| Threat | Mitigation |
|--------|-----------|
| Malware hijacking automation | Signed binary, notarization, gatekeeper |
| TCC database tampering | No direct TCC manipulation; use approved APIs only |
| SIP bypass | No SIP operations; accessibility API only |
| Accessibility permission abuse | Logging, UI disclosure, timeout protection |
| Privilege escalation | No admin elevation, stays in user context |
| Injection attacks | XPC security checks, signed communication |
| Prompt injection | No LLM in v1; manual policy rules only |

### Required Permissions

```
✓ Accessibility (mandatory)
✓ Screen Recording (for screenshots)
✓ Files (optional, for log export)
```

### No Permissions Exploited

```
✗ Keychain access
✗ Full Disk Access
✗ Admin elevation
✗ TCC modification
✗ System Preferences modification
✗ Private API usage
```

---

## Notarization & Code Signing

**Requirements**:
- Signed with Apple Developer ID
- All dependencies signed
- Entitlements whitelist (minimal)
- Notarized by Apple (hardened runtime)
- Timestamped signature

**Entitlements Needed**:
```xml
<key>com.apple.security.accessibility</key>
<true/>

<key>com.apple.security.files.user-selected.read-write</key>
<true/>

<key>com.apple.security.automation.apple-events</key>
<false/>  <!-- No AppleScript injection -->
```

---

## Testing Strategy

### Unit Tests
- Button ranking logic
- Trust scoring algorithm
- Policy evaluation
- OCR confidence filtering
- Dialog classification

### Integration Tests
- Mock dialogs with AX tree
- Simulated windows
- End-to-end clicking
- Logging verification

### UI Tests
- SwiftUI component rendering
- User interaction flows
- Permission walk-through
- Settings persistence

### Manual Testing
- Real macOS dialogs (Spotlight, Mail, etc.)
- Browser popups (Chrome, Safari, Arc)
- App installers (dmg, pkg)
- Developer tools (Xcode, VSCode, Cursor)

---

## Roadmap

### Phase 1 (MVP)
- Core detection + AX API
- Basic policy engine
- Simple UI
- SQLite logging
- LaunchAgent daemon

### Phase 2
- Vision OCR fallback
- Menu bar integration
- Batch policy configuration
- Advanced logging UI

### Phase 3
- Machine learning classifier
- Trust reputation DB
- Analytics dashboard
- Cloud backup (optional)

### Phase 4+
- Browser extensions
- iOS companion
- Enterprise policies
- Apple Intelligence integration

---

## Deployment

### Build
```bash
xcodebuild -scheme PermissionPilot -configuration Release \
  -derivedDataPath build/ \
  -archivePath build/PermissionPilot.xcarchive \
  archive
```

### Sign & Notarize
```bash
xcodebuild -exportArchive \
  -archivePath build/PermissionPilot.xcarchive \
  -exportOptionsPlist exportOptions.plist \
  -exportPath build/release
```

### Package
- Create .dmg with code signature verification
- Include README + privacy policy
- Sign DMG

### Distribution
- Direct download from website
- Sparkle framework for auto-updates
- Optional: Homebrew cask

---

## Privacy & Compliance

**Data Storage**:
- All data stored locally in ~/Library/Application Support/PermissionPilot/
- No cloud transmission unless explicitly enabled by user
- User can delete logs anytime

**Privacy Policy Statements**:
- "We do not collect, transmit, or analyze personal data"
- "All logs remain on your device"
- "No telemetry by default"
- "Full transparency in logging"

**Accessibility Policy**:
- "We use Accessibility APIs only to detect and interact with UI elements"
- "No keystroke logging"
- "No document reading"
- "No sensitive data extraction"

---

## Conclusion

PermissionPilot is a sophisticated yet secure automation tool that respects macOS security architecture while providing genuine productivity benefits. Its hybrid approach, rigorous policy framework, and transparent logging make it suitable for professional and consumer use.

