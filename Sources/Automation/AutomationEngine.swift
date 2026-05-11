import AppKit
import CoreGraphics

/// Main automation orchestrator
actor AutomationEngine {
    // MARK: - Dependencies

    private let mouseController: MouseController
    private let keyboardController: KeyboardController
    private let windowManager: WindowManager
    private let buttonMatcher: ButtonMatcher

    // MARK: - Configuration

    let config: AutomationConfig
    private let timeoutSeconds: TimeInterval = 30

    // MARK: - Initialization

    init(
        config: AutomationConfig = .default,
        mouseController: MouseController = MouseController(),
        keyboardController: KeyboardController = KeyboardController(),
        windowManager: WindowManager = WindowManager(),
        buttonMatcher: ButtonMatcher = ButtonMatcher()
    ) {
        self.config = config
        self.mouseController = mouseController
        self.keyboardController = keyboardController
        self.windowManager = windowManager
        self.buttonMatcher = buttonMatcher
    }

    // MARK: - Public API

    func clickButton(
        _ button: DialogButton,
        in dialog: DetectedDialog
    ) async -> AutomationResult {
        let startTime = Date()

        do {
            // Verify button still exists and dialog is visible
            guard await windowManager.isWindowVisible(dialog.windowFrame) else {
                return AutomationResult(
                    status: .failed,
                    error: "Dialog window is no longer visible"
                )
            }

            // Move mouse with human-like behavior
            let mouseMoveResult = await mouseController.moveMouse(to: button.position)
            guard mouseMoveResult else {
                return AutomationResult(
                    status: .failed,
                    error: "Failed to move mouse to button position"
                )
            }

            // Wait for human-like reaction time
            try await Task.sleep(nanoseconds: UInt64(randomDelay() * 1_000_000_000))

            // Click the button
            let clickResult = await mouseController.click(at: button.position)
            guard clickResult else {
                return AutomationResult(
                    status: .failed,
                    error: "Failed to click button"
                )
            }

            // Wait for dialog to process the click
            try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds

            let executionTime = Date().timeIntervalSince(startTime)

            return AutomationResult(
                status: .success,
                button: button,
                executionTime: executionTime
            )
        } catch {
            let executionTime = Date().timeIntervalSince(startTime)
            return AutomationResult(
                status: .failed,
                executionTime: executionTime,
                error: error.localizedDescription
            )
        }
    }

    func automateDialog(_ dialog: DetectedDialog) async -> AutomationResult {
        // Find the best button to click
        let rankedButtons = await buttonMatcher.rankButtons(dialog.buttons, for: dialog)

        guard let bestButton = rankedButtons.first?.button else {
            return AutomationResult(
                status: .failed,
                error: "No safe button found to click"
            )
        }

        // Verify button safety
        if bestButton.confidence < config.confidenceThreshold {
            return AutomationResult(
                status: .failed,
                error: "Button confidence below threshold"
            )
        }

        // Click the button with retry logic
        let maxRetries = config.maxRetries
        for attempt in 1...maxRetries {
            let result = await clickButton(bestButton, in: dialog)

            switch result.status {
            case .success:
                return result
            case .failed, .blocked, .skipped:
                if attempt < maxRetries {
                    // Wait before retry
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    continue
                } else {
                    return result
                }
            case .timeout:
                return result
            }
        }

        return AutomationResult(
            status: .failed,
            error: "Failed after \(maxRetries) attempts"
        )
    }

    // MARK: - Private Helpers

    private func randomDelay() -> TimeInterval {
        let range = config.humanLikeClickDelay
        return TimeInterval.random(in: range)
    }
}

/// Handles mouse movement and clicking
actor MouseController {
    private let eventSource = CGEventSource(stateID: .combinedSessionState)

    func moveMouse(to point: CGPoint) async -> Bool {
        do {
            let steps = 50  // Smooth movement over 50 steps
            let duration = TimeInterval.random(in: 0.1...0.3)
            let stepDuration = duration / TimeInterval(steps)

            let currentPos = NSEvent.mouseLocation
            let dx = (point.x - currentPos.x) / Double(steps)
            let dy = (point.y - currentPos.y) / Double(steps)

            for step in 1...steps {
                let newX = currentPos.x + (dx * Double(step))
                let newY = currentPos.y + (dy * Double(step))

                let moveEvent = CGEvent(mouseEventSource: eventSource, mouseType: .mouseMoved, mouseCursorPosition: CGPoint(x: newX, y: newY), data: CGEventData())
                moveEvent?.post(tap: .cghidEventTap)

                // Small delay between steps
                try await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
            }

            return true
        } catch {
            Logger.error("Mouse movement failed: \(error)")
            return false
        }
    }

    func click(at point: CGPoint) async -> Bool {
        guard let eventSource = CGEventSource(stateID: .combinedSessionState) else {
            return false
        }

        // Move to position
        let moveEvent = CGEvent(mouseEventSource: eventSource, mouseType: .mouseMoved, mouseCursorPosition: point, data: CGEventData())
        moveEvent?.post(tap: .cghidEventTap)

        // Down
        let downEvent = CGEvent(mouseEventSource: eventSource, mouseType: .leftMouseDown, mouseCursorPosition: point, data: CGEventData())
        downEvent?.post(tap: .cghidEventTap)

        // Small delay
        try? await Task.sleep(nanoseconds: 20_000_000)  // 20ms

        // Up
        let upEvent = CGEvent(mouseEventSource: eventSource, mouseType: .leftMouseUp, mouseCursorPosition: point, data: CGEventData())
        upEvent?.post(tap: .cghidEventTap)

        return true
    }

    func doubleClick(at point: CGPoint) async -> Bool {
        guard let eventSource = CGEventSource(stateID: .combinedSessionState) else {
            return false
        }

        for _ in 0..<2 {
            let downEvent = CGEvent(mouseEventSource: eventSource, mouseType: .leftMouseDown, mouseCursorPosition: point, data: CGEventData())
            downEvent?.post(tap: .cghidEventTap)

            try? await Task.sleep(nanoseconds: 10_000_000)

            let upEvent = CGEvent(mouseEventSource: eventSource, mouseType: .leftMouseUp, mouseCursorPosition: point, data: CGEventData())
            upEvent?.post(tap: .cghidEventTap)

            try? await Task.sleep(nanoseconds: 20_000_000)
        }

        return true
    }
}

/// Handles keyboard automation
actor KeyboardController {
    func pressKey(_ key: CGKeyCode) async -> Bool {
        guard let eventSource = CGEventSource(stateID: .combinedSessionState) else {
            return false
        }

        let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: key, keyDown: true)
        keyDown?.post(tap: .cghidEventTap)

        try? await Task.sleep(nanoseconds: 50_000_000)

        let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: key, keyDown: false)
        keyUp?.post(tap: .cghidEventTap)

        return true
    }

    func pressTab() async -> Bool {
        await pressKey(48)  // Tab key code
    }

    func pressReturn() async -> Bool {
        await pressKey(36)  // Return key code
    }

    func pressSpace() async -> Bool {
        await pressKey(49)  // Space key code
    }
}

/// Manages window focus and visibility
actor WindowManager {
    func isWindowVisible(_ frame: CGRect) -> Bool {
        // Check if window is within screen bounds
        let screens = NSScreen.screens
        let anyScreenContains = screens.contains { screen in
            screen.frame.intersects(frame)
        }

        return anyScreenContains
    }

    func focusWindow(_ windowNumber: Int) async -> Bool {
        // Bring window to front
        let workspace = NSWorkspace.shared
        guard let app = NSRunningApplication(processIdentifier: pid_t(windowNumber)) else {
            return false
        }

        return app.activate(options: .activateAllWindows)
    }

    func waitForWindowVisibility(_ frame: CGRect, timeout: TimeInterval) async -> Bool {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            if isWindowVisible(frame) {
                return true
            }

            try? await Task.sleep(nanoseconds: 100_000_000)  // Check every 100ms
        }

        return false
    }
}
