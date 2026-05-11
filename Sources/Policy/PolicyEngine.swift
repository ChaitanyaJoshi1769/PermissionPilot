import Foundation

/// Main policy evaluation engine
actor PolicyEngine {
    // MARK: - Dependencies

    private let trustScorer: TrustScorer
    private let whitelistManager: WhitelistManager
    private let blacklistManager: BlacklistManager
    private let ruleEvaluator: PolicyRuleEvaluator

    // MARK: - Configuration

    private let trustThresholdAuto: Double = 0.8
    private let trustThresholdBlock: Double = 0.5

    // MARK: - Initialization

    init(
        trustScorer: TrustScorer = TrustScorer(),
        whitelistManager: WhitelistManager = WhitelistManager(),
        blacklistManager: BlacklistManager = BlacklistManager(),
        ruleEvaluator: PolicyRuleEvaluator = PolicyRuleEvaluator()
    ) {
        self.trustScorer = trustScorer
        self.whitelistManager = whitelistManager
        self.blacklistManager = blacklistManager
        self.ruleEvaluator = ruleEvaluator
    }

    // MARK: - Public API

    func evaluateDialog(_ dialog: DetectedDialog) async -> PolicyDecision {
        // Check explicit whitelist/blacklist first
        if await whitelistManager.isWhitelisted(dialog.appBundleID) {
            return PolicyDecision(
                action: .autoApprove,
                trustScore: 1.0,
                reason: "App is whitelisted",
                policyRule: nil
            )
        }

        if await blacklistManager.isBlacklisted(dialog.appBundleID) {
            return PolicyDecision(
                action: .block,
                trustScore: 0.0,
                reason: "App is blacklisted",
                policyRule: nil
            )
        }

        // Evaluate against custom policy rules
        if let ruleDecision = await ruleEvaluator.evaluateDialog(dialog) {
            return ruleDecision
        }

        // Calculate trust score
        let trustScore = await trustScorer.scoreApplication(dialog.appBundleID, dialog.appName)

        // Check dialog safety
        let dialogSafety = evaluateDialogSafety(dialog)

        // Combine scores
        let finalScore = (trustScore * 0.7) + (dialogSafety * 0.3)

        // Make decision based on final score
        let action: PolicyDecision.Action
        let reason: String

        if finalScore >= trustThresholdAuto {
            action = .autoApprove
            reason = "Trust score \(String(format: "%.0f%%", finalScore * 100)) exceeds auto-approve threshold"
        } else if finalScore >= trustThresholdBlock {
            action = .askUser
            reason = "Trust score \(String(format: "%.0f%%", finalScore * 100)) requires user confirmation"
        } else {
            action = .block
            reason = "Trust score \(String(format: "%.0f%%", finalScore * 100)) below block threshold"
        }

        return PolicyDecision(
            action: action,
            trustScore: finalScore,
            reason: reason,
            policyRule: nil
        )
    }

    // MARK: - Private Helpers

    private func evaluateDialogSafety(_ dialog: DetectedDialog) -> Double {
        // Analyze the dialog to determine safety
        var safetyScore: Double = 0.5  // Start neutral

        let fullText = (dialog.windowTitle + " " + dialog.dialogText).lowercased()

        // Check for dangerous keywords
        let dangerousKeywords = ["delete", "erase", "reset", "uninstall", "disable"]
        let hasDangerous = dangerousKeywords.contains { keyword in
            fullText.contains(keyword)
        }

        if hasDangerous {
            safetyScore -= 0.3
        }

        // Check for safe permission types
        let safePermissions = ["camera", "microphone", "notification", "clipboard"]
        let hasSafePermission = safePermissions.contains { permission in
            fullText.contains(permission)
        }

        if hasSafePermission {
            safetyScore += 0.2
        }

        // Check button safety
        let hasOnceButton = dialog.buttons.contains { button in
            button.label.lowercased().contains("once") ||
            button.label.lowercased().contains("this time")
        }

        if hasOnceButton {
            safetyScore += 0.2  // "Allow Once" is safer than "Always Allow"
        }

        // Check for suspicious patterns
        if fullText.contains("run anyway") || fullText.contains("disable security") {
            safetyScore -= 0.4
        }

        return max(0, min(1, safetyScore))  // Clamp to 0-1
    }

    // MARK: - Configuration Management

    func addWhitelistApp(_ bundleID: String, name: String) async {
        await whitelistManager.add(bundleID: bundleID, appName: name)
    }

    func removeWhitelistApp(_ bundleID: String) async {
        await whitelistManager.remove(bundleID: bundleID)
    }

    func addBlacklistApp(_ bundleID: String, name: String) async {
        await blacklistManager.add(bundleID: bundleID, appName: name)
    }

    func removeBlacklistApp(_ bundleID: String) async {
        await blacklistManager.remove(bundleID: bundleID)
    }

    func addPolicyRule(_ rule: PolicyRule) async {
        await ruleEvaluator.addRule(rule)
    }

    func removePolicyRule(_ ruleID: UUID) async {
        await ruleEvaluator.removeRule(ruleID)
    }

    func getWhitelistedApps() async -> [String] {
        await whitelistManager.getAll()
    }

    func getBlacklistedApps() async -> [String] {
        await blacklistManager.getAll()
    }
}

/// Calculates trust scores for applications
actor TrustScorer {
    private var applicationReputation: [String: Double] = [:]
    private let knownTrustedApps = Set([
        "com.apple.finder",
        "com.apple.mail",
        "com.apple.Safari",
        "com.google.Chrome",
        "com.slack",
        "com.zoom.xos",
        "com.microsoft.VSCode",
        "com.jetbrains.pycharm",
        "com.cursor.cursor",
    ])

    func scoreApplication(_ bundleID: String, _ appName: String) -> Double {
        // Check known trusted apps
        if knownTrustedApps.contains(bundleID) {
            return 0.9
        }

        // Check if we have reputation history
        if let reputation = applicationReputation[bundleID] {
            return reputation
        }

        // Default moderate score (requires user confirmation)
        return 0.6
    }

    func updateReputation(_ bundleID: String, score: Double) {
        applicationReputation[bundleID] = score
    }
}

/// Manages whitelist of trusted applications
actor WhitelistManager {
    private var whitelistSet: Set<String> = []

    func isWhitelisted(_ bundleID: String) -> Bool {
        whitelistSet.contains(bundleID)
    }

    func add(bundleID: String, appName: String) {
        whitelistSet.insert(bundleID)
    }

    func remove(bundleID: String) {
        whitelistSet.remove(bundleID)
    }

    func getAll() -> [String] {
        Array(whitelistSet)
    }
}

/// Manages blacklist of untrusted applications
actor BlacklistManager {
    private var blacklistSet: Set<String> = []

    func isBlacklisted(_ bundleID: String) -> Bool {
        blacklistSet.contains(bundleID)
    }

    func add(bundleID: String, appName: String) {
        blacklistSet.insert(bundleID)
    }

    func remove(bundleID: String) {
        blacklistSet.remove(bundleID)
    }

    func getAll() -> [String] {
        Array(blacklistSet)
    }
}

/// Evaluates dialogs against custom policy rules
actor PolicyRuleEvaluator {
    private var rules: [PolicyRule] = []

    func evaluateDialog(_ dialog: DetectedDialog) -> PolicyDecision? {
        let fullText = (dialog.windowTitle + " " + dialog.dialogText).lowercased()

        for rule in rules where rule.enabled {
            // Simple substring pattern matching (can be upgraded to regex)
            if fullText.contains(rule.pattern.lowercased()) {
                let decision: PolicyDecision.Action = {
                    switch rule.action.lowercased() {
                    case "allow": return .autoApprove
                    case "block": return .block
                    default: return .askUser
                    }
                }()

                return PolicyDecision(
                    action: decision,
                    trustScore: decision == .autoApprove ? 0.9 : 0.1,
                    reason: "Matched policy rule: \(rule.name)",
                    policyRule: rule
                )
            }
        }

        return nil
    }

    func addRule(_ rule: PolicyRule) {
        rules.append(rule)
    }

    func removeRule(_ ruleID: UUID) {
        rules.removeAll { $0.id == ruleID }
    }

    func getRules() -> [PolicyRule] {
        rules
    }
}
