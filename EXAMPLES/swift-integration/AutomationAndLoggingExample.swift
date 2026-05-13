import Foundation

/// Example: Dialog Automation and Audit Logging
/// This example demonstrates clicking buttons and querying audit logs

class AutomationAndLoggingExample {

    // MARK: - Dialog Automation

    /// Click a button in a dialog
    func clickButton() async {
        let automation = DefaultAutomationEngine()

        let button = Dialog.Button(
            id: "allow",
            label: "Allow",
            position: CGRect(x: 300, y: 500, width: 100, height: 40),
            isDefault: true
        )

        do {
            let success = await automation.clickButton(button)

            if success {
                print("✓ Button clicked successfully")
            } else {
                print("✗ Failed to click button")
            }
        } catch {
            print("Error clicking button: \(error)")
        }
    }

    /// Type text in a dialog
    func typeText() async {
        let automation = DefaultAutomationEngine()

        do {
            await automation.typeText("my_password_123")
            print("✓ Text typed")
        } catch {
            print("Error typing text: \(error)")
        }
    }

    /// Press keyboard keys
    func pressKeys() async {
        let automation = DefaultAutomationEngine()

        do {
            // Press Enter key
            await automation.pressKey("Return")
            print("✓ Enter key pressed")

            // Press Tab then Enter
            await automation.pressKeys(["Tab", "Return"])
            print("✓ Tab + Enter pressed")
        } catch {
            print("Error pressing keys: \(error)")
        }
    }

    /// Find and click safe button automatically
    func clickSafeButton() async {
        let automation = DefaultAutomationEngine()

        let dialog = Dialog(
            id: "dialog-001",
            title: "Install Software?",
            content: "Do you want to install this software?",
            buttons: [
                Dialog.Button(id: "install", label: "Install", position: CGRect(), isDefault: true),
                Dialog.Button(id: "cancel", label: "Cancel", position: CGRect(), isDefault: false),
            ],
            dialogType: .confirmation,
            confidence: 0.9,
            timestamp: Date()
        )

        if let safeButton = await automation.findSafeButton(in: dialog) {
            let success = await automation.clickButton(safeButton)
            if success {
                print("✓ Safe button clicked: \(safeButton.label)")
            }
        } else {
            print("No safe button found")
        }
    }

    // MARK: - Audit Logging and Querying

    /// Get recent automation events
    func getRecentEvents() async {
        let logManager = DefaultLogManager()

        do {
            let events = await logManager.getEvents(filter: EventFilter(
                limit: 10,
                timeRange: .last24Hours
            ))

            print("=== Recent Events ===")
            for event in events {
                print("Event: \(event.id)")
                print("  App: \(event.appName)")
                print("  Dialog: \(event.dialogTitle)")
                print("  Action: \(event.actionTaken)")
                print("  Time: \(event.timestamp)")
                print("")
            }
        } catch {
            print("Error fetching events: \(error)")
        }
    }

    /// Query events with advanced filters
    func queryEvents() async {
        let logManager = DefaultLogManager()

        do {
            let filter = EventFilter(
                appName: "com.google.Chrome",
                actionTaken: "ALLOW_ONCE",
                successOnly: true,
                timeRange: .last7Days,
                limit: 50
            )

            let events = await logManager.getEvents(filter: filter)

            print("Found \(events.count) matching events")
            for event in events {
                print("- \(event.dialogTitle) ✓")
            }
        } catch {
            print("Error querying events: \(error)")
        }
    }

    /// Get statistics
    func getStatistics() async {
        let logManager = DefaultLogManager()

        do {
            let stats = await logManager.getStatistics(timeRange: .last24Hours)

            print("=== 24-Hour Statistics ===")
            print("Total Events: \(stats.totalEvents)")
            print("Success Rate: \(Int(stats.successRate * 100))%")
            print("Average Trust Score: \(String(format: "%.2f", stats.averageTrustScore))")
            print("")

            print("Actions Breakdown:")
            for (action, count) in stats.actionCounts {
                print("  \(action): \(count)")
            }
            print("")

            print("Top Applications:")
            for (app, count) in stats.topApplications {
                print("  \(app): \(count) dialogs")
            }
        } catch {
            print("Error getting statistics: \(error)")
        }
    }

    /// Export events to CSV
    func exportEvents() async {
        let logManager = DefaultLogManager()

        do {
            let exportPath = "/tmp/permissionpilot_export.csv"

            try await logManager.exportEvents(
                to: exportPath,
                format: .csv,
                filter: EventFilter(timeRange: .last30Days)
            )

            print("✓ Events exported to \(exportPath)")
        } catch {
            print("Error exporting events: \(error)")
        }
    }

    /// Monitor events in real-time
    func monitorEvents() async {
        let logManager = DefaultLogManager()

        // Create monitoring task
        let monitorTask = Task {
            await logManager.monitorEvents { event in
                print("New Event: \(event.dialogTitle)")
                print("  Action: \(event.actionTaken)")
                print("  Time: \(event.timestamp)")
            }
        }

        // Monitor for 60 seconds
        try? await Task.sleep(nanoseconds: 60 * 1_000_000_000)
        monitorTask.cancel()

        print("Monitoring stopped")
    }

    // MARK: - Error Handling During Automation

    /// Handle automation errors gracefully
    func handleAutomationErrors() async {
        let automation = DefaultAutomationEngine()

        let button = Dialog.Button(
            id: "test",
            label: "Test Button",
            position: CGRect(x: 0, y: 0, width: 0, height: 0),
            isDefault: false
        )

        do {
            let success = await automation.clickButton(button)
            if !success {
                print("Click failed but no error thrown")
            }
        } catch AutomationError.buttonNotFound {
            print("Button location not found")
        } catch AutomationError.accessibilityDisabled {
            print("Accessibility not enabled")
        } catch AutomationError.timeout {
            print("Operation timed out")
        } catch {
            print("Unexpected error: \(error)")
        }
    }

    // MARK: - Batch Operations

    /// Process multiple events
    func processEventBatch() async {
        let logManager = DefaultLogManager()

        do {
            let events = await logManager.getEvents(filter: EventFilter(
                actionTaken: "ASK",
                timeRange: .last24Hours,
                limit: 100
            ))

            print("Processing \(events.count) 'ASK' events")

            for event in events {
                // Process each event
                await processEvent(event)
            }

            print("Batch processing complete")
        } catch {
            print("Error processing batch: \(error)")
        }
    }

    private func processEvent(_ event: AutomationEvent) async {
        // Custom event processing logic
        print("  Processing: \(event.dialogTitle)")
    }
}

// MARK: - Models

enum TimeRange: String {
    case last1Hour
    case last24Hours
    case last7Days
    case last30Days
    case last90Days
    case all
}

enum ExportFormat: String {
    case csv
    case json
    case tsv
}

enum AutomationError: Error {
    case buttonNotFound
    case accessibilityDisabled
    case timeout
    case invalidPosition
}

struct AutomationEvent {
    let id: String
    let timestamp: Date
    let appName: String
    let dialogTitle: String
    let dialogContent: String
    let actionTaken: String
    let automationSuccess: Bool
    let trustScore: Double
    let buttonClicked: String?
    let reasonBlocked: String?
}

struct EventFilter {
    var appName: String?
    var actionTaken: String?
    var successOnly: Bool = false
    var timeRange: TimeRange = .last24Hours
    var limit: Int = 100
}

struct EventStatistics {
    let totalEvents: Int
    let successRate: Double
    let averageTrustScore: Double
    let actionCounts: [String: Int]
    let topApplications: [(app: String, count: Int)]
}

// MARK: - Protocol Definitions (for reference)

protocol AutomationEngine {
    /// Click a button
    func clickButton(_ button: Dialog.Button) async -> Bool

    /// Type text
    func typeText(_ text: String) async throws

    /// Press a keyboard key
    func pressKey(_ key: String) async throws

    /// Press multiple keys
    func pressKeys(_ keys: [String]) async throws

    /// Find safe button in dialog
    func findSafeButton(in dialog: Dialog) async -> Dialog.Button?
}

protocol LogManager {
    /// Get events with filter
    func getEvents(filter: EventFilter) async -> [AutomationEvent]

    /// Get statistics
    func getStatistics(timeRange: TimeRange) async -> EventStatistics

    /// Export events
    func exportEvents(to path: String, format: ExportFormat, filter: EventFilter) async throws

    /// Monitor events in real-time
    func monitorEvents(handler: @escaping (AutomationEvent) -> Void) async
}

class DefaultAutomationEngine: AutomationEngine {
    func clickButton(_ button: Dialog.Button) async -> Bool {
        // Placeholder
        return true
    }

    func typeText(_ text: String) async throws {
        // Placeholder
    }

    func pressKey(_ key: String) async throws {
        // Placeholder
    }

    func pressKeys(_ keys: [String]) async throws {
        // Placeholder
    }

    func findSafeButton(in dialog: Dialog) async -> Dialog.Button? {
        // Placeholder
        return dialog.buttons.first
    }
}

class DefaultLogManager: LogManager {
    func getEvents(filter: EventFilter) async -> [AutomationEvent] {
        // Placeholder
        return []
    }

    func getStatistics(timeRange: TimeRange) async -> EventStatistics {
        // Placeholder
        return EventStatistics(
            totalEvents: 0,
            successRate: 0,
            averageTrustScore: 0,
            actionCounts: [:],
            topApplications: []
        )
    }

    func exportEvents(to path: String, format: ExportFormat, filter: EventFilter) async throws {
        // Placeholder
    }

    func monitorEvents(handler: @escaping (AutomationEvent) -> Void) async {
        // Placeholder
    }
}
