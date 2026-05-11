import AppKit
import Combine
import Vision

/// Main dialog detection engine
actor DialogDetector {
    // MARK: - Published Properties (use @ObservationIgnored for thread-safe observation)

    let detectedDialogsSubject = PassthroughSubject<DetectedDialog, Never>()
    let errorSubject = PassthroughSubject<Error, Never>()

    // MARK: - Dependencies

    private let accessibilityInspector: AccessibilityInspector
    private let ocrPipeline: OCRPipeline
    private let dialogClassifier: DialogClassifier
    private let windowMonitor: WindowMonitor

    // MARK: - State

    private var activeDialogs: [UUID: DetectedDialog] = [:]
    private var lastProcessedWindows: Set<CGWindowID> = []
    private var debounceTimer: Timer?
    private let debounceInterval: TimeInterval = 0.15

    // MARK: - Configuration

    let config: AutomationConfig

    // MARK: - Initialization

    init(
        config: AutomationConfig = .default,
        accessibilityInspector: AccessibilityInspector = AccessibilityInspector(),
        ocrPipeline: OCRPipeline = OCRPipeline(),
        dialogClassifier: DialogClassifier = DialogClassifier()
    ) {
        self.config = config
        self.accessibilityInspector = accessibilityInspector
        self.ocrPipeline = ocrPipeline
        self.dialogClassifier = dialogClassifier
        self.windowMonitor = WindowMonitor()

        Task {
            await setupWindowMonitoring()
        }
    }

    // MARK: - Public API

    func detectDialogsNow() async {
        guard config.isEnabled, !config.isPaused else { return }

        let windows = NSApplication.shared.windows
        await processWindows(windows)
    }

    func getActiveDialogs() -> [DetectedDialog] {
        Array(activeDialogs.values)
    }

    func markDialogResolved(_ dialogID: UUID) async {
        activeDialogs.removeValue(forKey: dialogID)
    }

    // MARK: - Private Implementation

    private func setupWindowMonitoring() async {
        await windowMonitor.onWindowCreated { [weak self] window in
            await self?.processWindow(window)
        }

        await windowMonitor.onWindowDestroyed { [weak self] windowID in
            await self?.handleWindowClosed(windowID)
        }
    }

    private func processWindows(_ windows: [NSWindow]) async {
        for window in windows {
            await processWindow(window)
        }
    }

    private func processWindow(_ window: NSWindow) async {
        guard config.isEnabled, !config.isPaused else { return }
        guard isDialogLikeWindow(window) else { return }

        // Debounce rapid repeated checks
        debounceWindowProcessing()

        do {
            // Try Accessibility API first (most reliable)
            if let dialog = await tryAccessibilityDetection(window) {
                await publishDialog(dialog)
                return
            }

            // Fall back to OCR if AX insufficient
            if config.enableOCR {
                if let dialog = await tryOCRDetection(window) {
                    await publishDialog(dialog)
                    return
                }
            }
        } catch {
            await errorSubject.send(error)
        }
    }

    private func tryAccessibilityDetection(_ window: NSWindow) async -> DetectedDialog? {
        guard let axElement = accessibilityInspector.getAXElementForWindow(window) else {
            return nil
        }

        let windowTitle = accessibilityInspector.getWindowTitle(axElement) ?? "Unknown"
        let dialogText = accessibilityInspector.getWindowDescription(axElement) ?? ""
        let buttons = await accessibilityInspector.findButtons(in: axElement)

        guard !buttons.isEmpty else {
            return nil
        }

        let appInfo = getAppInfo(for: window)

        let dialog = DetectedDialog(
            windowTitle: windowTitle,
            dialogText: dialogText,
            appBundleID: appInfo.bundleID,
            appName: appInfo.displayName,
            buttons: buttons,
            windowFrame: window.frame,
            confidence: 0.95,  // AX is highly reliable
            detectionMethod: .accessibilityAPI
        )

        // Classify to verify it's actually a permission dialog
        return await dialogClassifier.classify(dialog) ? dialog : nil
    }

    private func tryOCRDetection(_ window: NSWindow) async -> DetectedDialog? {
        guard let screenshot = captureWindowScreenshot(window) else {
            return nil
        }

        let result = await ocrPipeline.processImage(screenshot)
        guard result.confidence >= config.confidenceThreshold else {
            return nil
        }

        let buttons = result.buttons
        guard !buttons.isEmpty else {
            return nil
        }

        let appInfo = getAppInfo(for: window)

        let dialog = DetectedDialog(
            windowTitle: result.title,
            dialogText: result.text,
            appBundleID: appInfo.bundleID,
            appName: appInfo.displayName,
            buttons: buttons,
            windowFrame: window.frame,
            confidence: result.confidence,
            detectionMethod: .ocrVision
        )

        // Classify to verify it's actually a permission dialog
        return await dialogClassifier.classify(dialog) ? dialog : nil
    }

    private func publishDialog(_ dialog: DetectedDialog) async {
        // Check if we already have this dialog active
        if activeDialogs[dialog.id] != nil {
            return  // Already tracking this dialog
        }

        activeDialogs[dialog.id] = dialog
        detectedDialogsSubject.send(dialog)
    }

    private func handleWindowClosed(_ windowID: CGWindowID) async {
        // Clean up any dialogs from this window
        lastProcessedWindows.remove(windowID)
    }

    private func isDialogLikeWindow(_ window: NSWindow) -> Bool {
        // Check window characteristics that suggest it's a dialog
        let isModal = (window.styleMask.contains(.modal))
        let isSmall = window.frame.width < 1200 && window.frame.height < 800
        let hasTitle = window.title.isEmpty == false
        let isVisible = window.isVisible && !window.isHidden

        return (isModal || isSmall) && hasTitle && isVisible
    }

    private func getAppInfo(for window: NSWindow) -> ApplicationInfo {
        guard let windowNumber = window.windowNumber as NSNumber? else {
            return ApplicationInfo(
                bundleID: "unknown",
                displayName: "Unknown App",
                path: "",
                isSigned: false
            )
        }

        // Get app from window
        let cgWindow = CGWindowListCopyWindowInfo([.excludeDesktopElements], windowNumber.uint32Value)
        if let windowInfo = cgWindow as? [[String: AnyObject]], !windowInfo.isEmpty {
            if let ownerName = windowInfo[0][kCGWindowOwnerName as String] as? String {
                let appName = ownerName
                return ApplicationInfo(
                    bundleID: getAppBundleID(for: appName) ?? "com.unknown",
                    displayName: appName,
                    path: getAppPath(for: appName) ?? "",
                    isSigned: true
                )
            }
        }

        return ApplicationInfo(
            bundleID: "unknown",
            displayName: "Unknown App",
            path: "",
            isSigned: false
        )
    }

    private func getAppBundleID(for appName: String) -> String? {
        let workspace = NSWorkspace.shared
        guard let app = workspace.runningApplications.first(where: { $0.localizedName == appName }) else {
            return nil
        }
        return app.bundleIdentifier
    }

    private func getAppPath(for appName: String) -> String? {
        let workspace = NSWorkspace.shared
        guard let app = workspace.runningApplications.first(where: { $0.localizedName == appName }) else {
            return nil
        }
        return app.bundleURL?.path
    }

    private func captureWindowScreenshot(_ window: NSWindow) -> NSImage? {
        guard let windowID = window.windowNumber as CGWindowID? else { return nil }

        if #available(macOS 14.0, *) {
            // Use modern screenshot API
            let cgImage = CGWindowListCreateImage(window.frame, [.optionIncludingWindow], windowID, [])
            guard let cgImage = cgImage else { return nil }
            return NSImage(cgImage: cgImage, size: window.frame.size)
        } else {
            // Fallback for older macOS
            let cgImage = CGWindowListCreateImage(window.frame, [.optionIncludingWindow], windowID, [])
            guard let cgImage = cgImage else { return nil }
            return NSImage(cgImage: cgImage, size: window.frame.size)
        }
    }

    private func debounceWindowProcessing() {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
            // Timer fires after debounce interval
        }
    }
}

/// Detects dialog window types
actor DialogClassifier {
    private let permissionKeywords = [
        "permission",
        "access",
        "allow",
        "approve",
        "camera",
        "microphone",
        "notification",
        "location",
        "clipboard",
        "contacts",
        "calendar",
        "files",
        "downloads",
        "security",
        "trust",
        "grant",
        "enable",
    ]

    func classify(_ dialog: DetectedDialog) -> Bool {
        let fullText = (dialog.windowTitle + " " + dialog.dialogText).lowercased()

        // Check if text contains permission-related keywords
        let hasPermissionKeyword = permissionKeywords.contains { keyword in
            fullText.contains(keyword)
        }

        // Check if there are safe action buttons
        let hasSafeButtons = dialog.buttons.contains { button in
            SafeButtonKeywords.keywords.contains { keyword in
                button.label.lowercased().contains(keyword)
            }
        }

        return hasPermissionKeyword || hasSafeButtons
    }
}

/// Monitors window creation/destruction events
actor WindowMonitor {
    private var windowCreationCallback: ((NSWindow) -> Void)?
    private var windowDestructionCallback: ((CGWindowID) -> Void)?

    func onWindowCreated(_ callback: @escaping (NSWindow) -> Void) {
        self.windowCreationCallback = callback
    }

    func onWindowDestroyed(_ callback: @escaping (CGWindowID) -> Void) {
        self.windowDestructionCallback = callback
    }
}
