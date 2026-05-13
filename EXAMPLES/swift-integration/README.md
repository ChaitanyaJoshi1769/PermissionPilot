# PermissionPilot Swift Integration Examples

Production-ready Swift code examples for integrating with PermissionPilot APIs.

---

## Overview

These examples demonstrate how to:
- Detect system dialogs
- Score application trustworthiness
- Evaluate and manage policies
- Automate dialog interactions
- Query and analyze audit logs

---

## Example Files

### 1. DialogDetectionExample.swift
**Learn how to detect permission dialogs**

#### Key Classes
- `DialogDetectionExample` - Main example class
- `AccessibilityDialogDetector` - Protocol for dialog detection
- `Dialog` - Dialog model with buttons and metadata

#### Key Methods
```swift
// Detect a single dialog
func detectSingleDialog() async

// Monitor for dialogs continuously
func monitorForDialogs() async

// Detect specific dialog types
func detectSpecificDialogType() async

// Handle detection errors
func handleDetectionErrors() async
```

#### Use Cases
- ✓ Single-time dialog detection
- ✓ Continuous monitoring for permission requests
- ✓ Filter dialogs by type (permission, authentication, etc.)
- ✓ Handle accessibility permission errors

#### Example Usage
```swift
let example = DialogDetectionExample()

// Detect a dialog
await example.detectSingleDialog()

// Or monitor continuously
await example.monitorForDialogs()
```

---

### 2. TrustScoringExample.swift
**Learn how to evaluate application trustworthiness**

#### Key Classes
- `TrustScoringExample` - Main example class
- `TrustScorer` - Protocol for trust scoring
- `ApplicationInfo` - Application metadata
- `TrustScoreDetailed` - Detailed scoring breakdown

#### Key Methods
```swift
// Score an application
func scoreApplication() async

// Get detailed scoring breakdown
func getDetailedScore() async

// Check if app is in known registry
func checkKnownApplication() async

// Score with caching
func scoreApplicationWithCaching() async

// Batch score multiple apps
func scoreMultipleApplications() async
```

#### Score Interpretation
- **0.0 - 0.3**: ❌ Block (Low trust)
- **0.3 - 0.5**: ⚠️ Ask user
- **0.5 - 0.8**: ✓ Allow with confirmation
- **0.8 - 1.0**: ✅ Auto-allow (High trust)

#### Scoring Components
- **Notarization (20%)**: Apple's code notarization status
- **Known App (20%)**: Is app in known registry?
- **User History (30%)**: User's past approval history
- **Reputation (20%)**: Community reputation scores
- **Dialog Type (10%)**: Type of permission being requested

#### Example Usage
```swift
let example = TrustScoringExample()

// Score an application
await example.scoreApplication()

// Get detailed breakdown
await example.getDetailedScore()

// Check if known
await example.checkKnownApplication()
```

---

### 3. PolicyEngineExample.swift
**Learn how to manage and evaluate policies**

#### Key Classes
- `PolicyEngineExample` - Main example class
- `PolicyEngine` - Protocol for policy management
- `PolicyDefinition` - Policy model
- `PolicyStatistics` - Policy metrics

#### Key Methods
```swift
// Evaluate a dialog against policies
func evaluateDialog() async

// Get applicable policies
func getApplicablePolicies() async

// Add custom policy
func addCustomPolicy() async

// Update policy
func updatePolicy() async

// Remove policy
func removePolicy() async

// Get policy statistics
func getPolicyStatistics() async

// Validate policy
func validatePolicy() async

// Load from JSON
func loadPoliciesFromJSON() async

// Export to JSON
func exportPoliciesToJSON() async
```

#### Policy Types
- **Whitelist**: Explicitly allow entries
- **Blacklist**: Explicitly deny entries
- **Rule**: Conditional logic based on patterns

#### Target Types
- **app**: Bundle identifier matching
- **dialogText**: Dialog content pattern matching
- **notarizationStatus**: Apple notarization status
- **signatureStatus**: Code signing verification

#### Example Usage
```swift
let example = PolicyEngineExample()

// Evaluate dialog
await example.evaluateDialog()

// Add custom policy
await example.addCustomPolicy()

// Get statistics
await example.getPolicyStatistics()

// Load policies from file
await example.loadPoliciesFromJSON()
```

---

### 4. AutomationAndLoggingExample.swift
**Learn how to automate dialogs and query logs**

#### Key Classes
- `AutomationAndLoggingExample` - Main example class
- `AutomationEngine` - Protocol for automation
- `LogManager` - Protocol for audit logging
- `AutomationEvent` - Event model

#### Key Methods
```swift
// Click a button
func clickButton() async

// Type text
func typeText() async

// Press keyboard keys
func pressKeys() async

// Find and click safe button
func clickSafeButton() async

// Get recent events
func getRecentEvents() async

// Query events with filters
func queryEvents() async

// Get statistics
func getStatistics() async

// Export events to CSV
func exportEvents() async

// Monitor events in real-time
func monitorEvents() async

// Process event batch
func processEventBatch() async
```

#### Supported Time Ranges
- `last1Hour`
- `last24Hours`
- `last7Days`
- `last30Days`
- `last90Days`
- `all`

#### Export Formats
- **CSV**: Comma-separated values
- **JSON**: Structured JSON
- **TSV**: Tab-separated values

#### Example Usage
```swift
let example = AutomationAndLoggingExample()

// Click button
await example.clickButton()

// Type text
await example.typeText()

// Query events
await example.queryEvents()

// Get statistics
await example.getStatistics()

// Export to CSV
await example.exportEvents()

// Monitor in real-time
await example.monitorEvents()
```

---

## Common Integration Patterns

### Pattern 1: Detect and Score
```swift
// 1. Detect dialog
let detector = AccessibilityDialogDetector()
if let dialog = await detector.detectDialog() {
    // 2. Score the app
    let scorer = DefaultTrustScorer()
    let appInfo = ApplicationInfo(...)
    let score = await scorer.scoreApplication(appInfo)

    // 3. Make decision
    if score > 0.8 {
        // Auto-allow
    }
}
```

### Pattern 2: Evaluate and Automate
```swift
// 1. Evaluate against policies
let engine = DefaultPolicyEngine()
let decision = await engine.evaluate(dialog: dialog, from: appInfo)

// 2. Automate if safe
if decision == .allow {
    let automation = DefaultAutomationEngine()
    if let safeButton = await automation.findSafeButton(in: dialog) {
        await automation.clickButton(safeButton)
    }
}
```

### Pattern 3: Monitor and Log
```swift
// 1. Monitor for events
let logManager = DefaultLogManager()
await logManager.monitorEvents { event in
    // Process new event
    print("Dialog: \(event.dialogTitle)")
}

// 2. Query later for analysis
let events = await logManager.getEvents(filter: EventFilter(...))
```

### Pattern 4: Policy Management
```swift
// 1. Define policy
let policy = PolicyDefinition(
    id: "allow-chrome",
    name: "Allow Chrome",
    type: .whitelist,
    targetType: .app,
    targetValues: ["com.google.Chrome"],
    action: .allow,
    priority: 90,
    enabled: true
)

// 2. Add policy
try await policyEngine.addPolicy(policy)

// 3. Verify it works
await policyEngine.evaluate(dialog: dialog, from: appInfo)
```

---

## Error Handling

### Accessibility Errors
```swift
do {
    let detector = AccessibilityDialogDetector()
    let dialog = try await detector.detectDialog()
} catch AccessibilityError.permissionDenied {
    print("Grant accessibility permission in System Preferences")
} catch AccessibilityError.timeout {
    print("Detection timed out")
}
```

### Policy Errors
```swift
do {
    try await policyEngine.addPolicy(policy)
} catch {
    print("Failed to add policy: \(error)")
}
```

### Automation Errors
```swift
do {
    try await automation.clickButton(button)
} catch AutomationError.buttonNotFound {
    print("Button location invalid")
}
```

---

## Testing Examples

### Unit Testing Patterns
```swift
class DialogDetectionTests: XCTestCase {
    func testDetectPermissionDialog() async {
        let example = DialogDetectionExample()
        // Test detection
    }

    func testScoreApplication() async {
        let scorer = DefaultTrustScorer()
        let score = await scorer.scoreApplication(...)
        XCTAssertGreater(score, 0.5)
    }

    func testPolicyEvaluation() async {
        let engine = DefaultPolicyEngine()
        let decision = await engine.evaluate(...)
        XCTAssertEqual(decision, .allow)
    }
}
```

---

## Real-World Integration Checklist

- [ ] Import PermissionPilot framework
- [ ] Handle accessibility permission request
- [ ] Implement error handling
- [ ] Test with real dialogs
- [ ] Configure policies
- [ ] Set up monitoring
- [ ] Implement logging
- [ ] Test automation
- [ ] Verify audit trail
- [ ] Monitor performance

---

## Performance Considerations

### Detection Performance
- Single detection: ~50-200ms
- Continuous monitoring: ~100-500ms overhead
- Consider debouncing rapid dialogs

### Scoring Performance
- Single score: ~10-50ms
- Known app lookup: ~5-20ms
- Implement caching for repeated scores

### Policy Evaluation
- Simple policies: <5ms
- Complex regex rules: 10-50ms
- Load policies once, reuse engine

### Automation Timing
- Mouse movement: 100-300ms (human-like)
- Button click: 50-100ms
- Text input: 10ms per character

---

## Security Best Practices

✅ **Do:**
- Always validate dialog content before automation
- Use trust scores to gate automation
- Implement comprehensive logging
- Regularly audit policy effectiveness
- Handle accessibility gracefully
- Cache credentials securely

❌ **Don't:**
- Automate without score checks
- Click buttons without validation
- Store sensitive data in logs
- Trust user input directly
- Disable accessibility prompts
- Ignore policy evaluation

---

## API Reference Quick Links

For complete API documentation, see:
- [API_REFERENCE.md](../../API_REFERENCE.md)
- [CONFIGURATION_GUIDE.md](../../CONFIGURATION_GUIDE.md)
- [MONITORING.md](../../MONITORING.md)

---

## Support & Resources

| Need | Resource |
|------|----------|
| Basic setup | [QUICK_START.md](../../QUICK_START.md) |
| API reference | [API_REFERENCE.md](../../API_REFERENCE.md) |
| Troubleshooting | [TROUBLESHOOTING.md](../../TROUBLESHOOTING.md) |
| Examples | This directory |
| Questions | [GitHub Discussions](https://github.com/ChaitanyaJoshi1769/PermissionPilot/discussions) |

---

**Version:** 1.0.0  
**Last Updated:** May 14, 2024  
**License:** MIT
