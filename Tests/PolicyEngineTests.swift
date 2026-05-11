import XCTest
@testable import PermissionPilot

final class PolicyEngineTests: XCTestCase {
    var policyEngine: PolicyEngine!

    override func setUp() async throws {
        policyEngine = PolicyEngine()
    }

    // MARK: - Trust Scoring Tests

    func testKnownTrustedAppIsAutoApproved() async throws {
        let dialog = DetectedDialog(
            windowTitle: "Camera Permission",
            dialogText: "Allow Chrome to access your camera?",
            appBundleID: "com.google.Chrome",
            appName: "Google Chrome",
            buttons: [DialogButton(label: "Allow", position: CGPoint(x: 100, y: 100), frame: .zero)],
            windowFrame: .zero,
            confidence: 0.95,
            detectionMethod: .accessibilityAPI
        )

        let decision = await policyEngine.evaluateDialog(dialog)
        XCTAssertEqual(decision.action, .autoApprove)
        XCTAssertGreaterThan(decision.trustScore, 0.8)
    }

    func testUnknownAppRequiresUserConfirmation() async throws {
        let dialog = DetectedDialog(
            windowTitle: "Permission Request",
            dialogText: "Unknown app requests permission",
            appBundleID: "com.unknown.suspicious",
            appName: "Unknown App",
            buttons: [DialogButton(label: "Allow", position: CGPoint(x: 100, y: 100), frame: .zero)],
            windowFrame: .zero,
            confidence: 0.90,
            detectionMethod: .accessibilityAPI
        )

        let decision = await policyEngine.evaluateDialog(dialog)
        XCTAssertEqual(decision.action, .askUser)
        XCTAssertLessThan(decision.trustScore, 0.8)
    }

    func testWhitelistedAppIsAutoApproved() async throws {
        await policyEngine.addWhitelistApp("com.test.app", name: "Test App")

        let dialog = DetectedDialog(
            windowTitle: "Permission",
            dialogText: "Test app requests permission",
            appBundleID: "com.test.app",
            appName: "Test App",
            buttons: [DialogButton(label: "Allow", position: CGPoint(x: 100, y: 100), frame: .zero)],
            windowFrame: .zero,
            confidence: 0.85,
            detectionMethod: .accessibilityAPI
        )

        let decision = await policyEngine.evaluateDialog(dialog)
        XCTAssertEqual(decision.action, .autoApprove)
        XCTAssertEqual(decision.trustScore, 1.0)
    }

    func testBlacklistedAppIsBlocked() async throws {
        await policyEngine.addBlacklistApp("com.malware.app", name: "Malware")

        let dialog = DetectedDialog(
            windowTitle: "Permission",
            dialogText: "Malware requests permission",
            appBundleID: "com.malware.app",
            appName: "Malware",
            buttons: [DialogButton(label: "Allow", position: CGPoint(x: 100, y: 100), frame: .zero)],
            windowFrame: .zero,
            confidence: 0.90,
            detectionMethod: .accessibilityAPI
        )

        let decision = await policyEngine.evaluateDialog(dialog)
        XCTAssertEqual(decision.action, .block)
        XCTAssertEqual(decision.trustScore, 0.0)
    }

    func testDangerousDialogKeywordsAreBlocked() async throws {
        let dialog = DetectedDialog(
            windowTitle: "Delete System Files",
            dialogText: "Are you sure you want to delete all system files?",
            appBundleID: "com.test.app",
            appName: "Test",
            buttons: [DialogButton(label: "Delete", position: CGPoint(x: 100, y: 100), frame: .zero)],
            windowFrame: .zero,
            confidence: 0.90,
            detectionMethod: .accessibilityAPI
        )

        let decision = await policyEngine.evaluateDialog(dialog)
        XCTAssertEqual(decision.action, .block)
    }

    func testSafePermissionDialogIsApproved() async throws {
        let dialog = DetectedDialog(
            windowTitle: "Notification Permission",
            dialogText: "Allow Slack to send notifications?",
            appBundleID: "com.slack",
            appName: "Slack",
            buttons: [
                DialogButton(label: "Allow Once", position: CGPoint(x: 100, y: 100), frame: .zero),
                DialogButton(label: "Allow", position: CGPoint(x: 200, y: 100), frame: .zero)
            ],
            windowFrame: .zero,
            confidence: 0.95,
            detectionMethod: .accessibilityAPI
        )

        let decision = await policyEngine.evaluateDialog(dialog)
        XCTAssertNotEqual(decision.action, .block)
    }
}

final class ButtonMatcherTests: XCTestCase {
    var buttonMatcher: ButtonMatcher!

    override func setUp() async throws {
        buttonMatcher = ButtonMatcher()
    }

    func testAllowOnceButtonIsHighestPriority() async throws {
        let dialog = DetectedDialog(
            windowTitle: "Test",
            dialogText: "Test",
            appBundleID: "com.test",
            appName: "Test",
            buttons: [
                DialogButton(label: "Allow Once", position: .zero, frame: .zero),
                DialogButton(label: "Allow", position: .zero, frame: .zero),
                DialogButton(label: "Cancel", position: .zero, frame: .zero)
            ],
            windowFrame: .zero,
            confidence: 0.9,
            detectionMethod: .accessibilityAPI
        )

        let ranked = await buttonMatcher.rankButtons(dialog.buttons, for: dialog)
        XCTAssertEqual(ranked.first?.button.label, "Allow Once")
    }

    func testDangerousButtonsNeverClicked() async throws {
        let dangerousLabels = ["Delete", "Erase", "Reset", "Uninstall", "Run Anyway"]

        for label in dangerousLabels {
            let button = DialogButton(label: label, position: .zero, frame: .zero, confidence: 0.99)
            let dialog = DetectedDialog(
                windowTitle: "Test",
                dialogText: "Test",
                appBundleID: "com.test",
                appName: "Test",
                buttons: [button],
                windowFrame: .zero,
                confidence: 0.9,
                detectionMethod: .accessibilityAPI
            )

            let ranked = await buttonMatcher.rankButtons([button], for: dialog)
            XCTAssertTrue(ranked.isEmpty || ranked.first?.rank ?? 0 < 0,
                         "Button '\(label)' should not be clickable")
        }
    }

    func testLowConfidenceButtonsSkipped() async throws {
        let button = DialogButton(label: "Allow", position: .zero, frame: .zero, confidence: 0.5)
        let dialog = DetectedDialog(
            windowTitle: "Test",
            dialogText: "Test",
            appBundleID: "com.test",
            appName: "Test",
            buttons: [button],
            windowFrame: .zero,
            confidence: 0.9,
            detectionMethod: .accessibilityAPI
        )

        let ranked = await buttonMatcher.rankButtons([button], for: dialog)
        // Low confidence should result in lower ranking
        XCTAssertLessThan(ranked.first?.rank ?? 0, 0.8)
    }
}

final class StringMatcherTests: XCTestCase {
    func testExactMatch() {
        let score = StringMatcher.fuzzyMatch("Allow", "Allow")
        XCTAssertEqual(score, 1.0)
    }

    func testSubstringMatch() {
        let score = StringMatcher.fuzzyMatch("Allow", "Allow Once")
        XCTAssertGreaterThan(score, 0.85)
    }

    func testCaseInsensitiveMatch() {
        let score = StringMatcher.fuzzyMatch("allow", "ALLOW")
        XCTAssertEqual(score, 1.0)
    }

    func testNoMatch() {
        let score = StringMatcher.fuzzyMatch("Delete", "Allow")
        XCTAssertLessThan(score, 0.5)
    }

    func testLevenshteinDistance() {
        // "Allow" vs "Alloc" - 1 character difference
        let score = StringMatcher.fuzzyMatch("Allow", "Alloc")
        XCTAssertGreaterThan(score, 0.7)
    }
}

final class DetectedDialogTests: XCTestCase {
    func testDialogInitialization() {
        let dialog = DetectedDialog(
            windowTitle: "Test Dialog",
            dialogText: "This is a test",
            appBundleID: "com.test.app",
            appName: "Test App",
            buttons: [],
            windowFrame: CGRect(x: 0, y: 0, width: 400, height: 300),
            confidence: 0.95,
            detectionMethod: .accessibilityAPI
        )

        XCTAssertEqual(dialog.windowTitle, "Test Dialog")
        XCTAssertEqual(dialog.appName, "Test App")
        XCTAssertEqual(dialog.confidence, 0.95)
        XCTAssertTrue(dialog.isVisible)
    }

    func testDialogIDIsUnique() {
        let dialog1 = DetectedDialog(
            windowTitle: "Dialog 1",
            dialogText: "Test",
            appBundleID: "com.test",
            appName: "Test",
            buttons: [],
            windowFrame: .zero,
            confidence: 0.9,
            detectionMethod: .accessibilityAPI
        )

        let dialog2 = DetectedDialog(
            windowTitle: "Dialog 1",
            dialogText: "Test",
            appBundleID: "com.test",
            appName: "Test",
            buttons: [],
            windowFrame: .zero,
            confidence: 0.9,
            detectionMethod: .accessibilityAPI
        )

        XCTAssertNotEqual(dialog1.id, dialog2.id)
    }
}

final class SafeButtonKeywordsTests: XCTestCase {
    func testAllowKeywordsExist() {
        XCTAssertFalse(SafeButtonKeywords.safeAllow.isEmpty)
        XCTAssertTrue(SafeButtonKeywords.safeAllow.contains("allow once"))
    }

    func testApproveKeywordsExist() {
        XCTAssertFalse(SafeButtonKeywords.safeApprove.isEmpty)
        XCTAssertTrue(SafeButtonKeywords.safeApprove.contains("allow"))
    }

    func testUnsafeKeywordsExist() {
        XCTAssertFalse(SafeButtonKeywords.unsafe.isEmpty)
        XCTAssertTrue(SafeButtonKeywords.unsafe.contains("delete"))
        XCTAssertTrue(SafeButtonKeywords.unsafe.contains("erase"))
    }

    func testNoOverlapBetweenSafeAndUnsafe() {
        let safeSet = Set(SafeButtonKeywords.safeAllow + SafeButtonKeywords.safeApprove)
        let unsafeSet = Set(SafeButtonKeywords.unsafe)
        let intersection = safeSet.intersection(unsafeSet)
        XCTAssertTrue(intersection.isEmpty, "Safe and unsafe keywords should not overlap")
    }
}
