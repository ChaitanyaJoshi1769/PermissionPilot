# Testing Guide

Comprehensive testing documentation for PermissionPilot development, CI/CD, and quality assurance.

---

## Overview

PermissionPilot maintains **80%+ test coverage** with automated CI/CD testing on every commit. This document covers:
- Unit testing strategies
- Integration testing
- Performance benchmarking
- Security testing
- Manual testing procedures
- Debugging techniques

---

## Unit Testing

### Running Tests

```bash
# Run all tests
make test

# Run specific test suite
xcodebuild test -scheme PermissionPilot -only-testing:PermissionPilotTests/DialogDetectorTests

# Run with verbose output
xcodebuild test -scheme PermissionPilot -verbose

# Run and generate coverage report
make coverage
```

### Test Structure

Tests are organized by module under `Tests/PermissionPilotTests/`:

```
Tests/PermissionPilotTests/
├── DialogDetectorTests/
│   ├── AccessibilityAPITests.swift
│   ├── OCRPipelineTests.swift
│   └── DialogClassificationTests.swift
├── PolicyEngineTests/
│   ├── PolicyEvaluationTests.swift
│   ├── TrustScoringTests.swift
│   └── PatternMatchingTests.swift
├── ButtonMatcherTests/
│   ├── ButtonRankingTests.swift
│   ├── SafetyTests.swift
│   └── ConfidenceTests.swift
├── AutomationEngineTests/
│   ├── MouseMovementTests.swift
│   ├── ClickSequenceTests.swift
│   └── TimingTests.swift
├── DatabaseTests/
│   ├── AuditLogTests.swift
│   ├── QueryTests.swift
│   └── MigrationTests.swift
├── PerformanceTests/
│   ├── DetectionBenchmarkTests.swift
│   ├── MemoryTests.swift
│   └── CPUTests.swift
└── SecurityTests/
    ├── ThreatModelTests.swift
    ├── InjectionTests.swift
    └── AccessControlTests.swift
```

### Writing Tests

**Test Naming Convention:**
```swift
func test_<ComponentUnderTest>_<Scenario>_<ExpectedResult>()
```

**Example:**
```swift
func test_trustScoring_knownAppWithHighHistory_returnsHighScore() {
    // Arrange
    let app = MockApp(notarized: true, knownApp: true)
    let history = MockHistory(approvalCount: 50)
    let scorer = TrustScorer(app: app, history: history)
    
    // Act
    let score = scorer.calculateTrust()
    
    // Assert
    XCTAssertGreaterThan(score, 0.8, "Score should exceed 0.8")
}
```

### Coverage Targets by Module

| Module | Target | Current | Status |
|--------|--------|---------|--------|
| DialogDetector | 80% | 82% | ✅ |
| PolicyEngine | 85% | 87% | ✅ |
| ButtonMatcher | 90% | 91% | ✅ |
| AutomationEngine | 75% | 76% | ✅ |
| DatabaseManager | 80% | 81% | ✅ |
| TrustScorer | 85% | 88% | ✅ |
| **Overall** | **80%** | **82%** | ✅ |

### Test Categories

**Fast Tests (Unit)** - <100ms each
- Trust scoring algorithm variations
- Policy pattern matching
- Button safety classification
- Mouse movement calculations
- Database queries

**Medium Tests (Integration)** - 100ms-1s each
- End-to-end dialog detection
- Policy evaluation with OCR
- Complete automation sequence
- Database transaction handling

**Slow Tests (System)** - >1s each
- Full application launch
- Real Accessibility API interaction
- OCR processing with images
- Long-running stress tests

### Skipping Tests

Mark slow tests to run selectively:
```swift
@slow
func test_fullApplicationLaunch_completesSuccessfully() { ... }
```

Run only fast tests:
```bash
xcodebuild test -scheme PermissionPilot -filter "not SLOW"
```

---

## Integration Testing

### Dialog Detection Integration

Test the complete detection pipeline:

```bash
# Mock dialog injection and verify detection
make test-integration-dialogs

# Test Accessibility API detection
xcodebuild test -scheme PermissionPilot \
  -only-testing:PermissionPilotTests/IntegrationTests/AccessibilityDetectionTests

# Test OCR fallback detection
xcodebuild test -scheme PermissionPilot \
  -only-testing:PermissionPilotTests/IntegrationTests/OCRDetectionTests
```

### Policy Engine Integration

```bash
# Test policy evaluation with real configuration
make test-integration-policies

# Verify trust scoring with 100+ scenarios
xcodebuild test -scheme PermissionPilot \
  -only-testing:PermissionPilotTests/IntegrationTests/TrustScoringIntegrationTests
```

### Automation Sequence Testing

```bash
# Test complete automation flow (detect → evaluate → click)
make test-integration-automation

# Test with various timing conditions
xcodebuild test -scheme PermissionPilot \
  -only-testing:PermissionPilotTests/IntegrationTests/AutomationSequenceTests
```

### Database Integration

```bash
# Test database operations and transactions
make test-integration-database

# Verify audit logging
xcodebuild test -scheme PermissionPilot \
  -only-testing:PermissionPilotTests/IntegrationTests/AuditLoggingTests
```

---

## Performance Testing

### Benchmark Tests

```bash
# Run all performance benchmarks
make test-performance

# Specific benchmark
xcodebuild test -scheme PermissionPilot \
  -only-testing:PermissionPilotTests/PerformanceTests/DetectionBenchmarkTests
```

### Benchmark Targets

| Operation | Target | Method | Pass Criteria |
|-----------|--------|--------|---------------|
| Dialog Detection | <500ms | Accessibility API | ✅ |
| OCR Fallback | <350ms | Vision Framework | ✅ |
| Policy Evaluation | <100ms | Regex matching | ✅ |
| Trust Scoring | <50ms | Algorithm | ✅ |
| Button Click | <1s | Event simulation | ✅ |
| Database Query | <100ms | SQLite | ✅ |
| Full Automation | <2s | End-to-end | ✅ |

### Memory Profiling

```bash
# Generate memory usage report
make test-memory

# Profile with Instruments
xcodebuild build -scheme PermissionPilot
open -a Instruments build/PermissionPilot.app
# Select: Allocations or VM Tracker
```

### CPU Profiling

```bash
# Profile CPU usage during automation
make test-cpu

# Manual profiling with Instruments
xcodebuild build -scheme PermissionPilot
open -a Instruments build/PermissionPilot.app
# Select: Time Profiler or System Trace
```

### Load Testing

```bash
# Stress test with 100 dialogs/minute
make test-load

# Custom load simulation
./Scripts/load-test.sh --rate=200/min --duration=60s
```

**Load Test Scenarios:**
- Rapid dialog sequences (10+ dialogs/second)
- High memory pressure (large screenshot storage)
- Database transaction volume
- OCR pipeline concurrent requests
- Policy evaluation with 1000+ rules

---

## Security Testing

### Threat Model Verification

```bash
# Test all 10 threat scenarios
make test-security

# Individual threat tests
xcodebuild test -scheme PermissionPilot \
  -only-testing:PermissionPilotTests/SecurityTests/ThreatModelTests
```

### Tested Threats

1. **Malicious Code Injection** - Verify no code injection possible
2. **Accessibility API Abuse** - Test authorization boundaries
3. **Unintended Automation** - Verify confidence thresholds prevent false positives
4. **Privilege Escalation** - Confirm runs at user level only
5. **TCC Tampering** - Verify no TCC modification
6. **SIP Bypass** - Confirm no SIP modification attempts
7. **Configuration Poisoning** - Test malformed policy handling
8. **OCR Data Leakage** - Verify screenshot cleanup
9. **Denial of Service** - Test resource exhaustion handling
10. **Supply Chain Compromise** - Verify code signing

### Injection Testing

```bash
# Test resistance to common injections
xcodebuild test -scheme PermissionPilot \
  -only-testing:PermissionPilotTests/SecurityTests/InjectionTests

# Scenarios tested:
# - SQL injection in policy patterns
# - Command injection in shell integration
# - Path traversal in file operations
# - AppleScript injection in automation
```

### Access Control Testing

```bash
# Verify permission boundaries
xcodebuild test -scheme PermissionPilot \
  -only-testing:PermissionPilotTests/SecurityTests/AccessControlTests

# Scenarios tested:
# - Accessibility permission requirements
# - File system access boundaries
# - Network connectivity verification
# - Daemon privilege levels
```

---

## Manual Testing

### Dialog Detection Testing

**Setup:**
```bash
# Enable debug logging
defaults write com.permissionpilot.app DebugLogging -bool true

# Watch logs in real-time
log stream --predicate 'process == "PermissionPilot"' --level debug
```

**Test Cases:**

1. **Native macOS Dialogs**
   - [ ] Accessibility permission prompt
   - [ ] Screen recording dialog
   - [ ] Full Disk Access request
   - [ ] Bluetooth pairing dialog
   - [ ] Network security warning

2. **Browser Dialogs**
   - [ ] Chrome notification permission
   - [ ] Safari camera/microphone access
   - [ ] Arc location tracking
   - [ ] Firefox clipboard access
   - [ ] Brave cryptocurrency detection

3. **Application Dialogs**
   - [ ] Slack permission request
   - [ ] Zoom join dialog
   - [ ] VSCode extension install
   - [ ] Cursor AI permission
   - [ ] Terminal `sudo` prompt

4. **Installer Dialogs**
   - [ ] DMG trust prompt
   - [ ] PKG installer confirmation
   - [ ] License agreement dialog
   - [ ] Installation path selection

### Trust Scoring Testing

**Test Matrix:**

| App Status | Notarized | Known | History | Score | Action |
|-----------|-----------|-------|---------|-------|--------|
| Trusted | ✅ | ✅ | ✅ | 0.9+ | AUTO ALLOW |
| Known | ❌ | ✅ | ✅ | 0.75+ | ASK |
| Unknown | ❌ | ❌ | ❌ | 0.3 | BLOCK |
| Suspicious | ❌ | ❌ | ✅ (blocked) | 0.2 | BLOCK |

### Policy Testing

**Whitelist Policy:**
```bash
# Add app to whitelist
# Verify all dialogs from app are automatically approved
# Test with 10+ different dialogs from that app
```

**Blacklist Policy:**
```bash
# Add app to blacklist
# Verify all dialogs from app are automatically blocked
# Test with 10+ different dialogs from that app
```

**Custom Rules:**
```bash
# Add rule: BLOCK if text contains "delete"
# Verify "Delete permanent data?" dialog is blocked
# Verify other dialogs still work normally
# Test with 20+ dialogs containing/not containing keyword
```

### Performance Testing Manual

**CPU Usage:**
```bash
# Launch Activity Monitor
open -a "Activity Monitor"

# Run PermissionPilot
open /Applications/PermissionPilot.app

# Idle CPU usage should be <0.5%
# Active detection should spike to 5-8% briefly
# Return to idle within 2 seconds
```

**Memory Usage:**
```bash
# Check Activity Monitor > Memory tab
# Idle: ~85MB
# Peak: ~120MB
# After 1 hour: still ~85MB (no leak)
```

**Responsiveness:**
```bash
# Trigger 10 dialogs in sequence
# Measure time from dialog appearance to automation
# Should be <500ms consistently
```

---

## Continuous Integration Testing

### GitHub Actions Pipeline

**On Push/PR:**
```yaml
1. Run all unit tests (fast)
2. Run integration tests (medium)
3. SwiftLint code quality checks
4. Code coverage report
5. Build release binary
```

**On Release Tag:**
```yaml
1. Run complete test suite
2. Build and sign release binary
3. Create DMG
4. Generate notarization request
5. Create GitHub release with artifacts
```

### Pre-commit Testing

```bash
# Pre-commit hooks run:
1. SwiftFormat code formatting
2. SwiftLint quality checks
3. Unit tests (fast suite only)
4. Markdown linting
5. YAML/JSON validation
```

---

## Debugging Tests

### Verbose Output

```bash
# Show detailed test output
xcodebuild test -scheme PermissionPilot -verbose

# Show only failures
xcodebuild test -scheme PermissionPilot | grep "FAILED\|ERROR"
```

### Debugging Failed Test

```bash
# Run single test with breakpoints
xcodebuild test -scheme PermissionPilot \
  -only-testing:PermissionPilotTests/PolicyEngineTests/test_policyEvaluation_multipleRules_appliesToCorrectRule \
  -enableCodeCoverage YES \
  -verbose
```

### Test Logs

```bash
# View test logs
cat ~/Library/Logs/DiagnosticMessages/*.log

# Filter for PermissionPilot
log show --predicate 'process == "xctest"' --last 1h
```

### Breakpoint Debugging

```swift
// Add in test code
XCTAssertTrue(condition, "Debug: value=\(value)")

// Or use breakpoints in Xcode
// Product → Scheme → Edit Scheme → Test → Pre-actions/Post-actions
```

---

## Test Coverage Reports

### Generate Coverage

```bash
# Create coverage report
make coverage

# View HTML coverage report
open coverage/index.html
```

### Coverage by Module

```bash
# Detailed coverage by module
xcov report --xcodebuild_arguments "-scheme,PermissionPilot" \
  --output_directory coverage

# View in browser
open coverage/index.html
```

### Coverage Trending

Track coverage over time:
```bash
# Store coverage metrics
make coverage > coverage_$(date +%Y%m%d).txt

# Compare over time
diff coverage_20240501.txt coverage_20240601.txt
```

---

## Common Test Issues

### Test Timeout

**Problem:** Test times out after 30 seconds

**Solution:**
```swift
// Increase timeout for slow test
func test_longRunningOperation() {
    let timeout = TimeInterval(60) // 60 second timeout
    // test code
}
```

### Flaky Tests

**Problem:** Test passes sometimes, fails other times

**Solution:**
```swift
// Add synchronization/waiting
let expectation = XCTestExpectation(description: "Operation completes")

async {
    // perform operation
    expectation.fulfill()
}

wait(for: [expectation], timeout: 5)
```

### Resource Cleanup

**Problem:** Tests leave files/processes running

**Solution:**
```swift
override func tearDown() {
    // Clean up test files
    try? FileManager.default.removeItem(at: testFile)
    
    // Stop mock servers
    mockServer.stop()
    
    super.tearDown()
}
```

### Mock Accessibility API

**Problem:** Accessibility API not available in test environment

**Solution:**
```swift
// Use mock implementation
let mockAccessibility = MockAccessibilityInspector()
mockAccessibility.mockDialogDetection = [
    MockDialog(title: "Allow?", buttons: ["Allow", "Block"])
]

let detector = DialogDetector(accessibility: mockAccessibility)
```

---

## Test Maintenance

### Updating Tests for New Features

1. Add new test file: `NewFeatureTests.swift`
2. Follow existing naming conventions
3. Aim for >80% code coverage
4. Document test scenarios
5. Update this guide with new test categories

### Deprecating Tests

1. Mark with `@available(*, deprecated, message: "...")`
2. Update related documentation
3. Remove in next major version
4. Announce in release notes

### Test Review Checklist

- [ ] Tests follow naming convention
- [ ] Coverage >80% for module
- [ ] No hardcoded timeouts
- [ ] Proper setup/teardown
- [ ] Documented edge cases
- [ ] Passes on CI/CD
- [ ] No external dependencies

---

## Performance Baseline

### Current Benchmarks (M1 MacBook Pro)

| Operation | Measurement | Status |
|-----------|-------------|--------|
| Unit tests | ~45s | ✅ Fast |
| Integration tests | ~90s | ✅ Acceptable |
| Performance benchmarks | ~120s | ✅ Comprehensive |
| Full test suite | ~4m | ✅ Good |
| Code coverage | ~90s | ✅ Good |

### Performance Regression Testing

```bash
# Establish baseline
make test-performance > baseline.json

# After changes
make test-performance > current.json

# Compare (should not regress >10%)
./Scripts/compare-benchmarks.sh baseline.json current.json
```

---

## Questions?

- **Test Issues:** [GitHub Issues](https://github.com/ChaitanyaJoshi1769/PermissionPilot/issues)
- **Testing Discussions:** [GitHub Discussions](https://github.com/ChaitanyaJoshi1769/PermissionPilot/discussions)
- **Email:** dev@permissionpilot.app

---

**Last updated:** May 13, 2024  
**Maintained by:** PermissionPilot Team
