# API Reference

Complete Swift API documentation for PermissionPilot core modules. Use this guide to understand the public interfaces available for extension and integration.

---

## Overview

PermissionPilot exposes a set of Swift APIs organized by functional module:

- **DialogDetection** - Detect permission dialogs in real-time
- **PolicyEngine** - Evaluate and apply policies
- **TrustScoring** - Calculate trust scores for applications
- **ButtonMatching** - Identify and rank safe buttons
- **Automation** - Execute dialog automation
- **Logging** - Access audit logs and events

All APIs are Swift-native (no Objective-C bridge required) and use modern async/await patterns.

---

## DialogDetection Module

### DialogDetector Protocol

Primary interface for detecting permission dialogs.

```swift
public protocol DialogDetector {
    associatedtype Dialog
    
    /// Detect a dialog in the current screen context
    /// - Returns: Detected dialog or nil if none found
    func detectDialog() async -> Dialog?
    
    /// Continuously monitor for dialogs with specified interval
    /// - Parameter interval: Check frequency (default: 0.5 seconds)
    /// - Returns: AsyncStream of detected dialogs
    func monitorDialogs(
        interval: TimeInterval = 0.5
    ) -> AsyncStream<Dialog>
    
    /// Force update dialog cache (useful after screen changes)
    func refreshDialogCache() async throws
    
    /// Enable/disable dialog detection
    func setEnabled(_ enabled: Bool)
}
```

### Dialog Model

Represents a detected permission dialog.

```swift
public struct Dialog: Identifiable {
    public let id: UUID
    
    /// Dialog window title
    public let title: String
    
    /// Full dialog message text
    public let message: String
    
    /// Dialog classification
    public let type: DialogType
    
    /// Detected buttons with metadata
    public let buttons: [Button]
    
    /// Accessibility element (for clicking)
    public let axElement: AXUIElement
    
    /// Detection metadata
    public let detectionMethod: DetectionMethod
    public let detectionConfidence: Double
    public let detectionTimeMs: Int
    
    /// Source application
    public let sourceApp: ApplicationInfo
    
    /// Screenshot (if taken)
    public let screenshot: NSImage?
}

public enum DialogType: String, Codable {
    case nativeMacOS
    case browser
    case application
    case installer
    case custom
    case unknown
}

public enum DetectionMethod: String, Codable {
    case accessibilityAPI
    case ocr
    case hybrid
}
```

### Button Model

Represents a clickable button in a dialog.

```swift
public struct Button: Identifiable {
    public let id: UUID
    
    /// Button text/label
    public let title: String
    
    /// Button position on screen
    public let frame: CGRect
    
    /// Is this the default button (highlighted)
    public let isDefault: Bool
    
    /// Is this the cancel button
    public let isCancel: Bool
    
    /// Safety assessment
    public let safetyScore: Double // 0-1, higher = safer
    public let dangerousKeywords: [String]
    public let isSafe: Bool
    
    /// Accessibility element for clicking
    public let axElement: AXUIElement
}
```

### Example Usage

```swift
// Detect a single dialog
let detector = AccessibilityDialogDetector()
if let dialog = await detector.detectDialog() {
    print("Found dialog: \(dialog.title)")
    print("Buttons: \(dialog.buttons.map { $0.title })")
}

// Monitor continuously
let detector = AccessibilityDialogDetector()
for await dialog in detector.monitorDialogs(interval: 0.25) {
    print("New dialog detected: \(dialog.title)")
    // Process dialog...
}

// Combine with timeout
let detector = AccessibilityDialogDetector()
detector.setEnabled(true)

try await withTimeout(seconds: 5) {
    for await dialog in detector.monitorDialogs() {
        print("Dialog: \(dialog.title)")
    }
}
```

---

## PolicyEngine Module

### PolicyEngine Protocol

Evaluate policies and make authorization decisions.

```swift
public protocol PolicyEngine {
    /// Evaluate a dialog against all policies
    /// - Parameter dialog: Dialog to evaluate
    /// - Returns: Decision (allow, block, ask)
    func evaluate(dialog: Dialog) async -> PolicyDecision
    
    /// Get all active policies
    func getPolicies() async -> [Policy]
    
    /// Add a new policy
    /// - Parameter policy: Policy to add
    /// - Throws: PolicyError if invalid
    func addPolicy(_ policy: Policy) async throws
    
    /// Update existing policy
    /// - Parameter policy: Updated policy
    /// - Throws: PolicyError if not found
    func updatePolicy(_ policy: Policy) async throws
    
    /// Remove a policy
    /// - Parameter name: Policy name
    /// - Throws: PolicyError if not found
    func removePolicy(named name: String) async throws
    
    /// Enable/disable a policy
    func setPolicy(named name: String, enabled: Bool) async throws
}

public enum PolicyDecision {
    case allow
    case block
    case ask // Require user confirmation
}
```

### Policy Model

```swift
public struct Policy: Codable, Identifiable {
    public let id: UUID
    public let name: String
    public let description: String?
    
    /// Type of policy
    public let type: PolicyType
    
    /// What this policy targets
    public let target: PolicyTarget
    
    /// What to do when policy matches
    public let action: PolicyAction
    
    /// Is policy enabled
    public var enabled: Bool
    
    /// Trust threshold for automatic approval
    public let trustThreshold: Double?
    
    /// Priority (lower = higher)
    public let priority: Int
    
    /// Created timestamp
    public let createdAt: Date
    public var modifiedAt: Date
}

public enum PolicyType {
    case whitelist      // Always allow
    case blacklist      // Always block
    case rule           // Conditional rule
}

public enum PolicyTarget {
    case app(String)            // Bundle ID or app name
    case dialogPattern(String)  // Regex pattern
    case buttonPattern(String)  // Regex pattern
    case global                 // Apply to all
}

public enum PolicyAction {
    case allow
    case block
    case askUser
    case evaluate // Use trust scoring
}

public enum PolicyError: Error {
    case policyNotFound
    case invalidPattern
    case duplicateName
    case invalidTarget
}
```

### Example Usage

```swift
// Create policies
let chromeWhitelist = Policy(
    name: "Allow Chrome",
    type: .whitelist,
    target: .app("com.google.Chrome"),
    action: .allow,
    enabled: true
)

let deleteBlocker = Policy(
    name: "Block Delete Dialogs",
    type: .rule,
    target: .dialogPattern("(?i)delete|erase|remove"),
    action: .block,
    enabled: true,
    priority: 10
)

// Add policies
let engine = DefaultPolicyEngine()
try await engine.addPolicy(chromeWhitelist)
try await engine.addPolicy(deleteBlocker)

// Evaluate dialog
let decision = await engine.evaluate(dialog: detectedDialog)
switch decision {
case .allow:
    print("Policy allows this dialog")
case .block:
    print("Policy blocks this dialog")
case .ask:
    print("Need user confirmation")
}

// Manage policies
let policies = await engine.getPolicies()
for policy in policies {
    print("Policy: \(policy.name) - \(policy.enabled ? "enabled" : "disabled")")
}

try await engine.setPolicy(named: "Allow Chrome", enabled: false)
```

---

## TrustScoring Module

### TrustScorer Protocol

Calculate trust scores for applications and dialogs.

```swift
public protocol TrustScorer {
    /// Calculate trust score for an application
    /// - Parameter app: Application info
    /// - Returns: Score from 0.0 (untrusted) to 1.0 (trusted)
    func scoreApplication(_ app: ApplicationInfo) async -> Double
    
    /// Calculate trust score with detailed components
    /// - Parameter app: Application info
    /// - Returns: Trust components breakdown
    func scoreApplicationDetailed(_ app: ApplicationInfo) async -> TrustComponents
    
    /// Get reputation data for an app
    /// - Parameter bundleId: App bundle identifier
    /// - Returns: Reputation info or nil if unknown
    func getReputation(for bundleId: String) async -> AppReputation?
    
    /// Update reputation based on user action
    func recordUserDecision(
        for app: ApplicationInfo,
        decision: UserDecision
    ) async throws
}

public enum UserDecision {
    case approved   // User allowed dialog
    case blocked    // User blocked dialog
    case timeout    // Dialog timed out without action
}
```

### TrustComponents Model

```swift
public struct TrustComponents: Codable {
    /// 0-1 score based on app notarization status
    public let notarizationScore: Double
    
    /// 0-1 score if app is in known list
    public let knownAppScore: Double
    
    /// 0-1 score based on user history with app
    public let historyScore: Double
    
    /// 0-1 score from external reputation data
    public let reputationScore: Double
    
    /// 0-1 score based on dialog type safety
    public let dialogTypeSafetyScore: Double
    
    /// Final weighted score
    public let finalScore: Double
    
    /// Component weights
    public let weights: TrustWeights
}

public struct TrustWeights: Codable {
    public let notarization: Double    // Default: 0.20
    public let knownApp: Double        // Default: 0.20
    public let history: Double         // Default: 0.30
    public let reputation: Double      // Default: 0.20
    public let dialogType: Double      // Default: 0.10
}

public struct AppReputation: Codable {
    public let bundleId: String
    public let appName: String
    public let reputationScore: Double
    public let approvalRate: Double
    public let dataSource: String
    public let lastUpdated: Date
}
```

### ApplicationInfo Model

```swift
public struct ApplicationInfo: Identifiable {
    public let id: String // Bundle ID
    
    /// Application name
    public let name: String
    
    /// Application path
    public let path: String
    
    /// Bundle identifier
    public let bundleId: String
    
    /// Code signing information
    public let codeSignatureValid: Bool
    public let codeSignatureSigning: String? // Apple Developer ID
    
    /// Notarization status
    public let notarized: Bool
    public let notarizedDate: Date?
    
    /// Executable architecture
    public let architecture: ProcessorArchitecture
    
    /// App size
    public let size: Int64
    
    public enum ProcessorArchitecture: String {
        case arm64
        case x86_64
        case universal
    }
}
```

### Example Usage

```swift
// Score an application
let scorer = DefaultTrustScorer()
let appInfo = ApplicationInfo(
    name: "Google Chrome",
    bundleId: "com.google.Chrome",
    notarized: true
)

let score = await scorer.scoreApplication(appInfo)
print("Trust score: \(Int(score * 100))%") // 82%

// Get detailed breakdown
let components = await scorer.scoreApplicationDetailed(appInfo)
print("Notarization: \(Int(components.notarizationScore * 100))%")
print("Known app: \(Int(components.knownAppScore * 100))%")
print("User history: \(Int(components.historyScore * 100))%")
print("Reputation: \(Int(components.reputationScore * 100))%")

// Record user decision for reputation building
try await scorer.recordUserDecision(
    for: appInfo,
    decision: .approved
)

// Get reputation data
if let reputation = await scorer.getReputation(for: "com.google.Chrome") {
    print("Approval rate: \(Int(reputation.approvalRate * 100))%")
}
```

---

## ButtonMatching Module

### ButtonMatcher Protocol

Identify and rank buttons in dialogs for safe automation.

```swift
public protocol ButtonMatcher {
    /// Find the safest button to click
    /// - Parameter dialog: Dialog with buttons
    /// - Returns: Safest button or nil if none safe enough
    func findSafeButton(in dialog: Dialog) -> Button?
    
    /// Rank all buttons by safety
    /// - Parameter buttons: Buttons to rank
    /// - Returns: Sorted list (safest first)
    func rankButtonsBySafety(_ buttons: [Button]) -> [Button]
    
    /// Analyze button for safety
    /// - Parameter button: Button to analyze
    /// - Returns: Safety analysis result
    func analyzeSafety(of button: Button) -> ButtonSafetyAnalysis
}
```

### ButtonSafetyAnalysis Model

```swift
public struct ButtonSafetyAnalysis: Codable {
    /// 0-1 safety score
    public let safetyScore: Double
    
    /// Detected dangerous keywords
    public let dangerousKeywords: [String]
    
    /// Detected safe keywords
    public let safeKeywords: [String]
    
    /// Button classification
    public let classification: ButtonClassification
    
    /// Reason for safety score
    public let reasoning: String
    
    /// Confidence in analysis
    public let confidence: Double
}

public enum ButtonClassification: String {
    case safe          // Allow, OK, Yes, Continue, Proceed, Next
    case neutral       // Maybe, Later, Remind
    case dangerous     // Delete, Erase, Reset, Remove, Uninstall, Discard
    case cancel        // Cancel, No, Decline, Refuse, Block
}

// Safe button keywords
let SAFE_KEYWORDS = [
    "allow", "permit", "enable", "authorize",
    "agree", "accept", "enable", "continue",
    "ok", "yes", "proceed", "next", "confirm"
]

// Dangerous button keywords
let DANGEROUS_KEYWORDS = [
    "delete", "erase", "reset", "remove",
    "uninstall", "discard", "destroy", "clear",
    "format", "wipe"
]
```

### Example Usage

```swift
// Find safest button
let matcher = DefaultButtonMatcher()
if let safeButton = matcher.findSafeButton(in: dialog) {
    print("Safe to click: \(safeButton.title)")
} else {
    print("No safe button found - manual review required")
}

// Rank all buttons
let rankedButtons = matcher.rankButtonsBySafety(dialog.buttons)
for (index, button) in rankedButtons.enumerated() {
    print("\(index + 1). \(button.title) - Safety: \(Int(button.safetyScore * 100))%")
}

// Analyze specific button
let analysis = matcher.analyzeSafety(of: button)
print("Classification: \(analysis.classification)")
print("Dangerous keywords: \(analysis.dangerousKeywords)")
print("Reasoning: \(analysis.reasoning)")
```

---

## Automation Module

### AutomationEngine Protocol

Execute dialog automation with human-like behavior.

```swift
public protocol AutomationEngine {
    /// Click a button with human-like motion
    /// - Parameter button: Button to click
    /// - Returns: Success/failure
    func clickButton(_ button: Button) async -> AutomationResult
    
    /// Type text naturally
    /// - Parameter text: Text to type
    /// - Parameter speed: Words per minute (default: 60)
    func typeText(_ text: String, speed: Int = 60) async throws
    
    /// Press keyboard shortcut
    /// - Parameter keys: Keys to press (e.g., [.command, .q])
    func pressKeys(_ keys: [VirtualKey]) async throws
    
    /// Wait for condition with timeout
    /// - Parameter condition: Condition to wait for
    /// - Parameter timeout: Maximum wait time
    func waitFor(
        _ condition: @escaping () async -> Bool,
        timeout: TimeInterval = 5
    ) async throws
    
    /// Get current automation state
    func getState() -> AutomationState
}

public enum VirtualKey: String {
    case command, option, shift, control
    case enter, space, tab, escape, backspace
    case delete, home, end, pageUp, pageDown
    case up, down, left, right
}

public enum AutomationState: String {
    case idle
    case detecting
    case evaluating
    case automating
    case paused
}
```

### AutomationResult Model

```swift
public enum AutomationResult {
    case success(details: AutomationDetails)
    case failure(error: AutomationError)
    case timeout
    case manualInterventionRequired
}

public struct AutomationDetails {
    public let buttonClicked: String
    public let executionTimeMs: Int
    public let mouseDistance: CGFloat
    public let confidence: Double
}

public enum AutomationError: Error {
    case elementNotFound
    case accessibilityDisabled
    case invalidElement
    case systemBusy
    case userInterrupted
}
```

### Example Usage

```swift
// Click a button
let engine = DefaultAutomationEngine()
let result = await engine.clickButton(safeButton)

switch result {
case .success(let details):
    print("Clicked in \(details.executionTimeMs)ms")
    print("Confidence: \(Int(details.confidence * 100))%")
    
case .failure(let error):
    print("Failed: \(error)")
    
case .timeout:
    print("Automation timed out")
    
case .manualInterventionRequired:
    print("Manual intervention needed")
}

// Type text with natural speed
try await engine.typeText("Hello, World!", speed: 45) // 45 WPM

// Press keyboard shortcut
try await engine.pressKeys([.command, .w]) // Cmd+W

// Wait for dialog to close
try await engine.waitFor(
    { await detector.detectDialog() == nil },
    timeout: 3
)
```

---

## Logging Module

### LogManager Protocol

Access audit logs and events.

```swift
public protocol LogManager {
    /// Get events filtered by criteria
    /// - Parameter filter: Filter criteria
    /// - Returns: Matching events
    func getEvents(filter: EventFilter) async -> [AutomationEvent]
    
    /// Get event statistics
    /// - Parameter range: Time range
    /// - Returns: Statistics summary
    func getStatistics(for range: DateRange) async -> LogStatistics
    
    /// Export events to file
    /// - Parameter format: Export format (CSV, JSON)
    /// - Parameter destination: File URL
    func exportEvents(
        format: ExportFormat,
        to destination: URL
    ) async throws
    
    /// Clear old events
    /// - Parameter olderThan: Delete events older than this
    func deleteEvents(olderThan: Date) async throws
    
    /// Get detailed event
    /// - Parameter id: Event ID
    func getEvent(id: UUID) async -> AutomationEvent?
}

public struct EventFilter {
    var appName: String?
    var actionTaken: String?
    var dateRange: DateRange?
    var minTrustScore: Double?
    var limit: Int = 100
}

public struct DateRange {
    let start: Date
    let end: Date
    
    static func last(_ days: Int) -> DateRange {
        let end = Date()
        let start = Calendar.current.date(
            byAdding: .day,
            value: -days,
            to: end
        )!
        return DateRange(start: start, end: end)
    }
}

public enum ExportFormat {
    case csv
    case json
    case sqlite
}
```

### AutomationEvent Model

```swift
public struct AutomationEvent: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    
    // Dialog info
    public let dialogTitle: String
    public let dialogType: String
    
    // Application info
    public let appName: String
    public let appBundleId: String?
    
    // Detection info
    public let detectionMethod: String
    public let detectionConfidence: Double
    public let detectionTimeMs: Int
    
    // Decision info
    public let actionTaken: String
    public let trustScore: Double
    public let appliedPolicy: String?
    
    // Automation result
    public let automationSuccess: Bool
    public let executionTimeMs: Int?
    
    // User info
    public let userOverride: Bool
}

public struct LogStatistics: Codable {
    public let totalDialogs: Int
    public let automatedCount: Int
    public let blockedCount: Int
    public let manualCount: Int
    
    public let successRate: Double
    public let averageDetectionTimeMs: Int
    public let averageTrustScore: Double
    
    public let topApps: [AppStats]
}

public struct AppStats: Codable {
    public let appName: String
    public let dialogCount: Int
    public let automatedCount: Int
    public let successRate: Double
}
```

### Example Usage

```swift
// Get recent events
let manager = DefaultLogManager()
let events = await manager.getEvents(filter: EventFilter(
    dateRange: .last(7),
    limit: 50
))

// Get statistics
let stats = await manager.getStatistics(for: .last(30))
print("Success rate: \(Int(stats.successRate * 100))%")
print("Top apps: \(stats.topApps.map { $0.appName })")

// Export events
try await manager.exportEvents(
    format: .csv,
    to: URL(fileURLWithPath: "~/logs.csv")
)

// Clean old events
try await manager.deleteEvents(olderThan: Date(timeIntervalSinceNow: -90 * 24 * 3600))

// Get specific event
if let event = await manager.getEvent(id: eventId) {
    print("Dialog: \(event.dialogTitle)")
    print("Action: \(event.actionTaken)")
}
```

---

## Error Handling

All APIs use Swift structured concurrency with `async/await`. Errors are thrown using standard `throws` syntax:

```swift
do {
    try await policyEngine.addPolicy(policy)
} catch PolicyError.duplicateName {
    print("Policy name already exists")
} catch PolicyError.invalidPattern {
    print("Invalid regex pattern")
} catch {
    print("Unknown error: \(error)")
}
```

---

## Extending PermissionPilot

### Creating Custom Dialog Detector

```swift
public class CustomDialogDetector: DialogDetector {
    func detectDialog() async -> Dialog? {
        // Your custom detection logic
        return nil
    }
    
    func monitorDialogs(interval: TimeInterval = 0.5) -> AsyncStream<Dialog> {
        return AsyncStream { continuation in
            // Your monitoring logic
        }
    }
    
    func refreshDialogCache() async throws {
        // Refresh logic
    }
    
    func setEnabled(_ enabled: Bool) {
        // Enable/disable
    }
}
```

### Creating Custom Policy

```swift
let customPolicy = Policy(
    name: "My Custom Policy",
    type: .rule,
    target: .dialogPattern("custom.*"),
    action: .ask,
    enabled: true,
    priority: 50
)

try await policyEngine.addPolicy(customPolicy)
```

---

## Versioning

- **Current Version:** 1.0.0
- **API Stability:** ✅ Stable
- **Minimum Swift:** 5.9
- **Minimum macOS:** 13.0

---

## Questions & Support

- **Questions:** [GitHub Discussions](https://github.com/ChaitanyaJoshi1769/PermissionPilot/discussions)
- **Issues:** [GitHub Issues](https://github.com/ChaitanyaJoshi1769/PermissionPilot/issues)
- **Email:** dev@permissionpilot.app

---

**Last updated:** May 13, 2024  
**Maintainer:** PermissionPilot Team
