import Foundation

/// Example: Using PermissionPilot's Policy Engine
/// This example demonstrates policy evaluation and management

class PolicyEngineExample {

    // MARK: - Basic Policy Evaluation

    /// Evaluate a dialog against policies
    func evaluateDialog() async {
        let policyEngine = DefaultPolicyEngine()

        let dialog = Dialog(
            id: "dialog-001",
            title: "Allow access to Keychain?",
            content: "Application wants access to your keychain credentials",
            buttons: [
                Dialog.Button(id: "allow", label: "Allow", position: CGRect(), isDefault: true),
                Dialog.Button(id: "deny", label: "Deny", position: CGRect(), isDefault: false),
            ],
            dialogType: .permission,
            confidence: 0.95,
            timestamp: Date()
        )

        let appInfo = ApplicationInfo(
            bundleIdentifier: "com.example.app",
            name: "Example App",
            publisher: "Example Publisher",
            version: "1.0.0"
        )

        do {
            let decision = await policyEngine.evaluate(dialog: dialog, from: appInfo)

            print("Policy Decision: \(decision)")

            switch decision {
            case .allow:
                print("✅ Dialog approved by policy")
            case .block:
                print("❌ Dialog blocked by policy")
            case .ask:
                print("⚠️ User confirmation required")
            }
        } catch {
            print("Error evaluating policy: \(error)")
        }
    }

    // MARK: - Get Applicable Policies

    /// Get all policies that apply to a dialog
    func getApplicablePolicies() async {
        let policyEngine = DefaultPolicyEngine()

        let dialog = Dialog(
            id: "dialog-002",
            title: "Install Software?",
            content: "Do you want to install this software?",
            buttons: [],
            dialogType: .confirmation,
            confidence: 0.88,
            timestamp: Date()
        )

        do {
            let policies = await policyEngine.getPolicies(for: dialog)

            print("Applicable Policies: \(policies.count)")
            for policy in policies {
                print("  - \(policy.name)")
                print("    Type: \(policy.type)")
                print("    Priority: \(policy.priority)")
                print("    Action: \(policy.action)")
            }
        } catch {
            print("Error retrieving policies: \(error)")
        }
    }

    // MARK: - Policy Management

    /// Add a custom policy
    func addCustomPolicy() async {
        let policyEngine = DefaultPolicyEngine()

        let customPolicy = PolicyDefinition(
            id: "custom-allow-chrome",
            name: "Allow Chrome",
            description: "Automatically allow dialogs from Chrome",
            type: .whitelist,
            targetType: .app,
            targetValues: ["com.google.Chrome"],
            action: .allow,
            priority: 90,
            enabled: true
        )

        do {
            try await policyEngine.addPolicy(customPolicy)
            print("✓ Policy added successfully")
        } catch {
            print("Error adding policy: \(error)")
        }
    }

    /// Update an existing policy
    func updatePolicy() async {
        let policyEngine = DefaultPolicyEngine()

        var policy = PolicyDefinition(
            id: "block-dangerous",
            name: "Block Dangerous Operations",
            description: "Block dialogs containing dangerous keywords",
            type: .rule,
            targetType: .dialogText,
            targetPattern: "(?i)(delete|erase|reset)",
            action: .block,
            priority: 20,
            enabled: true
        )

        // Update priority
        policy.priority = 15

        do {
            try await policyEngine.updatePolicy(policy)
            print("✓ Policy updated successfully")
        } catch {
            print("Error updating policy: \(error)")
        }
    }

    /// Remove a policy
    func removePolicy() async {
        let policyEngine = DefaultPolicyEngine()

        do {
            try await policyEngine.removePolicy(withID: "custom-allow-chrome")
            print("✓ Policy removed successfully")
        } catch {
            print("Error removing policy: \(error)")
        }
    }

    // MARK: - Policy Statistics

    /// Get policy statistics
    func getPolicyStatistics() async {
        let policyEngine = DefaultPolicyEngine()

        do {
            let stats = await policyEngine.getStatistics()

            print("=== Policy Statistics ===")
            print("Total Policies: \(stats.totalPolicies)")
            print("Enabled: \(stats.enabledCount)")
            print("Disabled: \(stats.disabledCount)")
            print("")

            print("By Type:")
            for (type, count) in stats.byType {
                print("  \(type): \(count)")
            }
            print("")

            print("By Action:")
            for (action, count) in stats.byAction {
                print("  \(action): \(count)")
            }
        } catch {
            print("Error getting statistics: \(error)")
        }
    }

    // MARK: - Policy Validation

    /// Validate a policy before adding
    func validatePolicy() async {
        let policyEngine = DefaultPolicyEngine()

        let policyToValidate = PolicyDefinition(
            id: "test-policy",
            name: "Test Policy",
            description: "A test policy",
            type: .rule,
            targetType: .dialogText,
            targetPattern: "(?i)(test)",
            action: .allow,
            priority: 50,
            enabled: true
        )

        do {
            let isValid = await policyEngine.validatePolicy(policyToValidate)

            if isValid {
                print("✓ Policy is valid")
            } else {
                print("✗ Policy validation failed")
            }
        } catch {
            print("Error validating policy: \(error)")
        }
    }

    // MARK: - Batch Policy Operations

    /// Load policies from JSON
    func loadPoliciesFromJSON() async {
        let policyEngine = DefaultPolicyEngine()

        let jsonPath = "~/Library/Application Support/PermissionPilot/policies.json"

        do {
            let policies = try await policyEngine.loadPoliciesFromFile(jsonPath)
            print("✓ Loaded \(policies.count) policies from JSON")

            for policy in policies {
                print("  - \(policy.name) (priority: \(policy.priority))")
            }
        } catch {
            print("Error loading policies: \(error)")
        }
    }

    /// Export policies to JSON
    func exportPoliciesToJSON() async {
        let policyEngine = DefaultPolicyEngine()

        let exportPath = "/tmp/exported_policies.json"

        do {
            try await policyEngine.exportPolicies(to: exportPath)
            print("✓ Policies exported to \(exportPath)")
        } catch {
            print("Error exporting policies: \(error)")
        }
    }

    // MARK: - Policy Evaluation Examples

    /// Evaluate multiple dialogs
    func evaluateMultipleDialogs() async {
        let policyEngine = DefaultPolicyEngine()

        let dialogs = [
            createTestDialog(title: "Allow Keychain Access?", type: .permission),
            createTestDialog(title: "Delete files?", type: .confirmation),
            createTestDialog(title: "Install update?", type: .alert),
        ]

        for dialog in dialogs {
            let decision = await policyEngine.evaluate(dialog: dialog, from: ApplicationInfo(
                bundleIdentifier: "com.test.app",
                name: "Test App",
                publisher: "Test",
                version: "1.0"
            ))

            print("\(dialog.title): \(decision)")
        }
    }

    private func createTestDialog(title: String, type: DialogType) -> Dialog {
        Dialog(
            id: UUID().uuidString,
            title: title,
            content: "This is a test dialog",
            buttons: [
                Dialog.Button(id: "yes", label: "Yes", position: CGRect(), isDefault: true),
                Dialog.Button(id: "no", label: "No", position: CGRect(), isDefault: false),
            ],
            dialogType: type,
            confidence: 0.9,
            timestamp: Date()
        )
    }
}

// MARK: - Models

enum PolicyAction: String, Codable {
    case allow
    case block
    case ask
}

enum PolicyType: String, Codable {
    case whitelist
    case blacklist
    case rule
}

enum TargetType: String, Codable {
    case app
    case dialogText
    case notarizationStatus
    case signatureStatus
}

struct PolicyDefinition {
    var id: String
    var name: String
    var description: String
    var type: PolicyType
    var targetType: TargetType
    var targetValues: [String]?
    var targetPattern: String?
    var action: PolicyAction
    var priority: Int
    var enabled: Bool
}

struct PolicyStatistics {
    let totalPolicies: Int
    let enabledCount: Int
    let disabledCount: Int
    let byType: [String: Int]
    let byAction: [String: Int]
}

// MARK: - Protocol Definition (for reference)

protocol PolicyEngine {
    /// Evaluate a dialog against policies
    func evaluate(dialog: Dialog, from appInfo: ApplicationInfo) async -> PolicyAction

    /// Get policies applicable to a dialog
    func getPolicies(for dialog: Dialog) async -> [PolicyDefinition]

    /// Add a new policy
    func addPolicy(_ policy: PolicyDefinition) async throws

    /// Update an existing policy
    func updatePolicy(_ policy: PolicyDefinition) async throws

    /// Remove a policy
    func removePolicy(withID id: String) async throws

    /// Validate a policy
    func validatePolicy(_ policy: PolicyDefinition) async -> Bool

    /// Get statistics
    func getStatistics() async -> PolicyStatistics

    /// Load from file
    func loadPoliciesFromFile(_ path: String) async throws -> [PolicyDefinition]

    /// Export to file
    func exportPolicies(to path: String) async throws
}

class DefaultPolicyEngine: PolicyEngine {
    // Implementation would go here
    func evaluate(dialog: Dialog, from appInfo: ApplicationInfo) async -> PolicyAction {
        return .ask
    }

    func getPolicies(for dialog: Dialog) async -> [PolicyDefinition] {
        return []
    }

    func addPolicy(_ policy: PolicyDefinition) async throws {
        // Placeholder
    }

    func updatePolicy(_ policy: PolicyDefinition) async throws {
        // Placeholder
    }

    func removePolicy(withID id: String) async throws {
        // Placeholder
    }

    func validatePolicy(_ policy: PolicyDefinition) async -> Bool {
        return true
    }

    func getStatistics() async -> PolicyStatistics {
        return PolicyStatistics(totalPolicies: 0, enabledCount: 0, disabledCount: 0, byType: [:], byAction: [:])
    }

    func loadPoliciesFromFile(_ path: String) async throws -> [PolicyDefinition] {
        return []
    }

    func exportPolicies(to path: String) async throws {
        // Placeholder
    }
}
