import Foundation
import Accessibility

/// Example: Detecting system dialogs using PermissionPilot APIs
/// This example shows how to detect dialogs and monitor for permission requests

class DialogDetectionExample {

    // MARK: - Basic Dialog Detection

    /// Detect a single dialog (one-time detection)
    func detectSingleDialog() async {
        do {
            let detector = AccessibilityDialogDetector()

            if let dialog = await detector.detectDialog() {
                print("Dialog detected!")
                print("  Title: \(dialog.title)")
                print("  Content: \(dialog.content)")
                print("  Buttons: \(dialog.buttons.map { $0.label })")

                // Check if it's a known type
                if let dialogType = dialog.dialogType {
                    print("  Type: \(dialogType)")
                }
            } else {
                print("No dialog detected")
            }
        } catch {
            print("Error detecting dialog: \(error)")
        }
    }

    // MARK: - Continuous Monitoring

    /// Monitor for dialogs continuously
    func monitorForDialogs() async {
        let detector = AccessibilityDialogDetector()

        // Create a task that monitors indefinitely
        let monitorTask = Task {
            await detector.monitorDialogs { dialog in
                print("Dialog appeared: \(dialog.title)")

                // Process dialog
                self.handleDialog(dialog)
            }
        }

        // Cancel monitoring after 60 seconds
        try? await Task.sleep(nanoseconds: 60 * 1_000_000_000)
        monitorTask.cancel()
    }

    // MARK: - Dialog Filtering

    /// Detect dialogs of a specific type
    func detectSpecificDialogType() async {
        let detector = AccessibilityDialogDetector()

        // Configuration for focused detection
        let config = DetectionConfig(
            dialogTypes: [.permission, .authentication],
            excludeTypes: [.notification, .tooltip],
            confidenceThreshold: 0.85
        )

        if let dialog = await detector.detectDialog(with: config) {
            print("Detected targeted dialog type: \(dialog.title)")
        }
    }

    // MARK: - Error Handling

    /// Handle detection errors gracefully
    func handleDetectionErrors() async {
        let detector = AccessibilityDialogDetector()

        do {
            if let dialog = await detector.detectDialog() {
                self.handleDialog(dialog)
            }
        } catch AccessibilityError.permissionDenied {
            print("Accessibility permission required")
            print("Please enable in System Preferences > Security & Privacy > Accessibility")
        } catch AccessibilityError.timeout {
            print("Dialog detection timed out")
        } catch {
            print("Unexpected error: \(error)")
        }
    }

    // MARK: - Dialog Handler

    private func handleDialog(_ dialog: Dialog) {
        print("Processing dialog:")
        print("  Title: \(dialog.title)")
        print("  Buttons available: \(dialog.buttons.count)")

        // Get button information
        for button in dialog.buttons {
            print("  - \(button.label) (position: \(button.position))")
        }
    }
}

// MARK: - Detection Models

struct DetectionConfig {
    let dialogTypes: [DialogType]?
    let excludeTypes: [DialogType]?
    let confidenceThreshold: Double
}

enum DialogType: String, CaseIterable {
    case permission
    case authentication
    case notification
    case tooltip
    case alert
    case confirmation
    case unknown
}

enum AccessibilityError: Error {
    case permissionDenied
    case timeout
    case accessibilityDisabled
}

// MARK: - Protocol Definition (for reference)

protocol DialogDetector {
    /// Detect a single dialog
    func detectDialog() async -> Dialog?

    /// Detect dialog with custom configuration
    func detectDialog(with config: DetectionConfig) async -> Dialog?

    /// Monitor for dialogs continuously
    func monitorDialogs(handler: @escaping (Dialog) -> Void) async

    /// Stop monitoring
    func stopMonitoring()
}

struct Dialog {
    let id: String
    let title: String
    let content: String
    let buttons: [Button]
    let dialogType: DialogType?
    let confidence: Double
    let timestamp: Date

    struct Button {
        let id: String
        let label: String
        let position: CGRect
        let isDefault: Bool
    }
}
