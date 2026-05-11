import SwiftUI
import AppKit

@main
struct PermissionPilotApp: App {
    // MARK: - State

    @StateObject private var appViewModel = AppViewModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appViewModel)
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowStyle(.hiddenTitleBar)

        Settings {
            SettingsView()
                .environmentObject(appViewModel)
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        checkAccessibilityPermission()
        startBackgroundDaemon()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: nil)
            button.image?.size = NSSize(width: 18, height: 18)
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Dashboard", action: #selector(openMainWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Pause", action: #selector(togglePause), keyEquivalent: "p"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    private func checkAccessibilityPermission() {
        if !AXIsProcessTrusted() {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "PermissionPilot needs accessibility permission to detect and click dialogs. Please grant permission in System Preferences."
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "Later")

            if alert.runModal() == .alertFirstButtonReturn {
                requestAccessibilityPermission()
            }
        }
    }

    private func startBackgroundDaemon() {
        // Start the background monitoring service
        DispatchQueue.global(qos: .background).async {
            // Daemon will run here
        }
    }

    @objc private func openMainWindow() {
        NSApplication.shared.windows.first?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    @objc private func togglePause() {
        // Toggle pause state
    }
}

// MARK: - View Models

@MainActor
class AppViewModel: ObservableObject {
    @Published var config = AutomationConfig.default
    @Published var detectedDialogs: [DetectedDialog] = []
    @Published var recentEvents: [AuditEvent] = []
    @Published var statistics: AutomationStatistics?
    @Published var isAccessibilityEnabled = false
    @Published var isPaused = false

    private let dialogDetector = DialogDetector()
    private let policyEngine = PolicyEngine()
    private let automationEngine = AutomationEngine()
    private let databaseManager = DatabaseManager()

    init() {
        Task {
            await setupMonitoring()
            await refreshStatistics()
        }

        isAccessibilityEnabled = AXIsProcessTrusted()
    }

    func setupMonitoring() async {
        await dialogDetector.detectDialogsNow()
    }

    func togglePause() {
        isPaused.toggle()
        config.isPaused = isPaused
    }

    func refreshStatistics() async {
        statistics = await databaseManager.getStatistics()
    }

    func loadRecentEvents() async {
        recentEvents = await databaseManager.getRecentEvents()
    }

    func processDialog(_ dialog: DetectedDialog) async {
        // Evaluate policy
        let decision = await policyEngine.evaluateDialog(dialog)

        switch decision.action {
        case .autoApprove:
            // Automatically click the best button
            let result = await automationEngine.automateDialog(dialog)
            logEvent(dialog: dialog, result: result, action: "CLICKED")

        case .askUser:
            // Show notification to user
            showUserPrompt(for: dialog, decision: decision)

        case .block:
            logEvent(dialog: dialog, result: AutomationResult(status: .blocked), action: "BLOCKED")
        }

        // Clean up
        await dialogDetector.markDialogResolved(dialog.id)
    }

    private func logEvent(dialog: DetectedDialog, result: AutomationResult, action: String) {
        Task {
            let event = AuditEvent(
                id: UUID(),
                timestamp: Date(),
                appBundleID: dialog.appBundleID,
                appName: dialog.appName,
                dialogTitle: dialog.windowTitle,
                dialogText: dialog.dialogText,
                buttonLabel: result.button?.label ?? "N/A",
                actionTaken: action,
                trustScore: 0.8,  // From policy decision
                confidence: dialog.confidence,
                executionTimeMs: Int(result.executionTime * 1000),
                policyRuleID: nil,
                detectionMethod: dialog.detectionMethod.rawValue
            )

            await databaseManager.logEvent(event)
            await refreshStatistics()
        }
    }

    private func showUserPrompt(for dialog: DetectedDialog, decision: PolicyDecision) {
        let alert = NSAlert()
        alert.messageText = "Permission Dialog Detected"
        alert.informativeText = "\(dialog.appName) is requesting: \(dialog.windowTitle)\n\n\(dialog.dialogText)"
        alert.addButton(withTitle: "Allow")
        alert.addButton(withTitle: "Cancel")

        DispatchQueue.main.async {
            if alert.runModal() == .alertFirstButtonReturn {
                Task {
                    let result = await self.automationEngine.automateDialog(dialog)
                    self.logEvent(dialog: dialog, result: result, action: "CLICKED")
                }
            }
        }
    }
}

// MARK: - Main Content View

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedTab: Tab = .dashboard

    enum Tab {
        case dashboard
        case policies
        case logs
        case settings
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List(selection: $selectedTab) {
                    NavigationLink(value: Tab.dashboard) {
                        Label("Dashboard", systemImage: "square.grid.2x2")
                    }
                    NavigationLink(value: Tab.policies) {
                        Label("Policies", systemImage: "shield.fill")
                    }
                    NavigationLink(value: Tab.logs) {
                        Label("Logs", systemImage: "list.bullet.rectangle")
                    }
                    NavigationLink(value: Tab.settings) {
                        Label("Settings", systemImage: "gear")
                    }
                }
                .listStyle(.sidebar)

                Divider()

                VStack(spacing: 12) {
                    if !viewModel.isAccessibilityEnabled {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Permission Required")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text("Enable Accessibility")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                    }

                    Toggle("Pause Automation", isOn: $viewModel.isPaused)
                        .onChange(of: viewModel.isPaused) { _, _ in
                            viewModel.togglePause()
                        }
                }
                .padding(12)
            }
            .frame(width: 250)
        } detail: {
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView()
                case .policies:
                    PoliciesView()
                case .logs:
                    LogsView()
                case .settings:
                    SettingsView()
                }
            }
            .environmentObject(viewModel)
        }
        .task {
            await viewModel.loadRecentEvents()
        }
    }
}

// MARK: - Tab Views (Stubs)

struct DashboardView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 20) {
            if let stats = viewModel.statistics {
                HStack(spacing: 20) {
                    StatCard(
                        title: "Dialogs Detected",
                        value: "\(stats.totalDialogsDetected)",
                        icon: "rectangle.and.hand.point.up.left.fill"
                    )
                    StatCard(
                        title: "Automated",
                        value: String(format: "%.0f%%", stats.automationRate),
                        icon: "checkmark.circle.fill"
                    )
                    StatCard(
                        title: "Blocked",
                        value: "\(stats.totalBlocked)",
                        icon: "xmark.circle.fill"
                    )
                }
            }

            Text("Recent Activity")
                .font(.headline)

            List(viewModel.recentEvents.prefix(10)) { event in
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.appName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(event.dialogTitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.blue)
            VStack(spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct PoliciesView: View {
    var body: some View {
        Text("Policies Configuration")
            .padding(20)
    }
}

struct LogsView: View {
    var body: some View {
        Text("Activity Logs")
            .padding(20)
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Settings")
            .padding(20)
    }
}
