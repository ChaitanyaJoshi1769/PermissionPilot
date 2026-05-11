import Foundation
import AppKit

// MARK: - Core Data Models

/// Represents a detected permission dialog
struct DetectedDialog: Identifiable, Equatable, Codable {
    let id: UUID
    let timestamp: Date
    let windowTitle: String
    let dialogText: String
    let appBundleID: String
    let appName: String
    let buttons: [DialogButton]
    let windowFrame: CGRect
    let confidence: Double
    let detectionMethod: DetectionMethod
    var isVisible: Bool = true

    enum DetectionMethod: String, Codable {
        case accessibilityAPI = "ax"
        case ocrVision = "ocr"
        case hybrid = "hybrid"
    }

    init(
        windowTitle: String,
        dialogText: String,
        appBundleID: String,
        appName: String,
        buttons: [DialogButton],
        windowFrame: CGRect,
        confidence: Double,
        detectionMethod: DetectionMethod
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.windowTitle = windowTitle
        self.dialogText = dialogText
        self.appBundleID = appBundleID
        self.appName = appName
        self.buttons = buttons
        self.windowFrame = windowFrame
        self.confidence = confidence
        self.detectionMethod = detectionMethod
    }
}

/// Represents a clickable button in a dialog
struct DialogButton: Identifiable, Hashable, Codable {
    let id: UUID
    let label: String
    let position: CGPoint
    let frame: CGRect
    let isDefault: Bool
    let accessibilityRole: String?
    let confidence: Double

    init(
        label: String,
        position: CGPoint,
        frame: CGRect,
        isDefault: Bool = false,
        accessibilityRole: String? = nil,
        confidence: Double = 1.0
    ) {
        self.id = UUID()
        self.label = label
        self.position = position
        self.frame = frame
        self.isDefault = isDefault
        self.accessibilityRole = accessibilityRole
        self.confidence = confidence
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DialogButton, rhs: DialogButton) -> Bool {
        lhs.id == rhs.id
    }
}

/// Policy decision result
struct PolicyDecision: Equatable {
    enum Action: String, Equatable {
        case autoApprove = "auto_approve"
        case askUser = "ask_user"
        case block = "block"
    }

    let action: Action
    let trustScore: Double
    let reason: String
    let policyRule: PolicyRule?
    let timestamp: Date

    init(
        action: Action,
        trustScore: Double,
        reason: String,
        policyRule: PolicyRule? = nil
    ) {
        self.action = action
        self.trustScore = trustScore
        self.reason = reason
        self.policyRule = policyRule
        self.timestamp = Date()
    }
}

/// Represents a policy rule
struct PolicyRule: Identifiable, Codable {
    let id: UUID
    let name: String
    let pattern: String  // Regex or simple substring match
    let action: String   // "ALLOW", "BLOCK", "ASK"
    let enabled: Bool
    let priority: Int

    enum CodingKeys: String, CodingKey {
        case id, name, pattern, action, enabled, priority
    }
}

/// Automation execution result
struct AutomationResult: Equatable {
    enum Status: String, Equatable {
        case success = "success"
        case failed = "failed"
        case timeout = "timeout"
        case blocked = "blocked"
        case skipped = "skipped"
    }

    let status: Status
    let button: DialogButton?
    let executionTime: TimeInterval
    let error: String?
    let screenshot: NSImage?

    init(
        status: Status,
        button: DialogButton? = nil,
        executionTime: TimeInterval = 0,
        error: String? = nil,
        screenshot: NSImage? = nil
    ) {
        self.status = status
        self.button = button
        self.executionTime = executionTime
        self.error = error
        self.screenshot = screenshot
    }
}

/// Complete audit event for logging
struct AuditEvent: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let appBundleID: String
    let appName: String
    let dialogTitle: String
    let dialogText: String
    let buttonLabel: String
    let actionTaken: String  // "CLICKED", "BLOCKED", "ASKED", "SKIPPED"
    let trustScore: Double
    let confidence: Double
    let executionTimeMs: Int
    let policyRuleID: UUID?
    let detectionMethod: String

    enum CodingKeys: String, CodingKey {
        case id, timestamp, appBundleID, appName, dialogTitle
        case dialogText, buttonLabel, actionTaken, trustScore
        case confidence, executionTimeMs, policyRuleID, detectionMethod
    }
}

/// Trust history for an application
struct TrustDecision: Identifiable, Codable {
    let id: UUID
    let appBundleID: String
    let appName: String
    let firstSeen: Date
    let lastSeen: Date
    let approvalCount: Int
    let rejectionCount: Int
    var userOverride: UserOverrideAction?

    enum UserOverrideAction: String, Codable {
        case alwaysAllow = "always_allow"
        case alwaysBlock = "always_block"
    }
}

/// Application metadata
struct ApplicationInfo: Identifiable, Equatable, Codable {
    let id: UUID
    let bundleID: String
    let displayName: String
    let path: String
    let isSigned: Bool
    let isNotarized: Bool?
    let developerID: String?
    let teamID: String?
    let version: String?
    let isSystemApp: Bool

    init(
        bundleID: String,
        displayName: String,
        path: String,
        isSigned: Bool,
        isNotarized: Bool? = nil,
        developerID: String? = nil,
        teamID: String? = nil,
        version: String? = nil,
        isSystemApp: Bool = false
    ) {
        self.id = UUID()
        self.bundleID = bundleID
        self.displayName = displayName
        self.path = path
        self.isSigned = isSigned
        self.isNotarized = isNotarized
        self.developerID = developerID
        self.teamID = teamID
        self.version = version
        self.isSystemApp = isSystemApp
    }
}

/// Configuration for the automation system
struct AutomationConfig: Codable {
    var isEnabled: Bool = true
    var isPaused: Bool = false
    var confidenceThreshold: Double = 0.85
    var trustScoreThreshold: Double = 0.6
    var maxRetries: Int = 3
    var clickTimeoutSeconds: TimeInterval = 30
    var debounceMs: Int = 100
    var enableScreenshots: Bool = true
    var enableOCR: Bool = true
    var multiMonitorSupport: Bool = true
    var humanLikeClickDelay: ClosedRange<TimeInterval> = 0.1...0.3
    var mouseJitterMax: Int = 5

    static let `default` = AutomationConfig()
}

/// Statistics for dashboard
struct AutomationStatistics: Codable {
    let totalDialogsDetected: Int
    let totalDialogsAutomated: Int
    let totalUserPrompts: Int
    let totalBlocked: Int
    let averageConfidence: Double
    let averageTrustScore: Double
    let avgExecutionTimeMs: Int
    let lastActivityDate: Date?
    let mostCommonApp: String?
    let successRate: Double  // percentage 0-100

    var automationRate: Double {
        guard totalDialogsDetected > 0 else { return 0 }
        return Double(totalDialogsAutomated) / Double(totalDialogsDetected) * 100
    }
}

// MARK: - Safety Constants

enum SafeButtonKeywords {
    static let safeAllow = [
        "allow once",
        "allow this time",
        "allow for this session"
    ]

    static let safeApprove = [
        "allow",
        "enable",
        "grant",
        "approve",
        "continue",
        "yes",
        "ok",
        "next"
    ]

    static let unsafe = [
        "delete",
        "erase",
        "reset",
        "clear",
        "remove",
        "uninstall",
        "disable",
        "disable security",
        "purchase",
        "buy",
        "install",
        "run anyway",
        "ignore",
        "proceed anyway",
        "format",
        "restart",
        "shutdown"
    ]

    static let keywords = safeAllow + safeApprove
}
