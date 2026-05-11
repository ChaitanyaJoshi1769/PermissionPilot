import AppKit
import CoreFoundation

/// Safe wrapper around Accessibility APIs
actor AccessibilityInspector {
    // MARK: - Initialization

    init() {
        checkAccessibilityPermission()
    }

    // MARK: - Window Operations

    func getAXElementForWindow(_ window: NSWindow) -> AXUIElement? {
        let pid = NSRunningApplication.current.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)

        guard let windowNumber = window.windowNumber as NSNumber? else { return nil }

        // Get all windows from the app
        var windows: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXWindowsAttribute as CFString,
            &windows
        )

        guard result == .success, let windowArray = windows as? [AXUIElement] else {
            return nil
        }

        // Find the window matching our window number
        for axWindow in windowArray {
            if let number = getAttributeValue(axWindow, kAXWindowNumberAttribute),
               let num = number as? NSNumber,
               num.intValue == window.windowNumber {
                return axWindow
            }
        }

        return nil
    }

    func getWindowTitle(_ element: AXUIElement) -> String? {
        getAttributeValue(element, kAXTitleAttribute) as? String
    }

    func getWindowDescription(_ element: AXUIElement) -> String? {
        // Traverse the element tree to extract all text
        var allText: [String] = []

        // Get main description
        if let title = getAttributeValue(element, kAXTitleAttribute) as? String {
            allText.append(title)
        }

        // Get value
        if let value = getAttributeValue(element, kAXValueAttribute) as? String {
            allText.append(value)
        }

        // Get static text elements
        collectStaticText(element, into: &allText)

        return allText.filter { !$0.isEmpty }.joined(separator: " ")
    }

    func findButtons(in element: AXUIElement) async -> [DialogButton] {
        var buttons: [DialogButton] = []

        // Search for buttons recursively
        searchForButtons(element, into: &buttons)

        // Filter out invalid buttons and sort by position
        return buttons
            .filter { isValidButton($0) }
            .sorted { $0.position.x < $1.position.x }
    }

    // MARK: - Private Helpers

    private func searchForButtons(_ element: AXUIElement, into buttons: inout [DialogButton]) {
        let role = getAttributeValue(element, kAXRoleAttribute) as? String

        // Check if this element is a button
        if role == kAXButtonRole as String {
            if let button = parseButton(element) {
                buttons.append(button)
            }
        }

        // Recursively search children
        if let children = getAttributeValue(element, kAXChildrenAttribute) as? [AXUIElement] {
            for child in children {
                searchForButtons(child, into: &buttons)
            }
        }
    }

    private func parseButton(_ element: AXUIElement) -> DialogButton? {
        guard let label = (getAttributeValue(element, kAXTitleAttribute) as? String) ??
                          (getAttributeValue(element, kAXValueAttribute) as? String),
              !label.isEmpty else {
            return nil
        }

        // Get button position and size
        guard let position = getAttributeValue(element, kAXPositionAttribute) as? NSValue,
              let size = getAttributeValue(element, kAXSizeAttribute) as? NSValue else {
            return nil
        }

        let cgPoint = position.pointValue
        let cgSize = size.sizeValue
        let frame = CGRect(origin: cgPoint, size: cgSize)

        // Check if button is focused/default
        let isDefault = (getAttributeValue(element, kAXFocusedAttribute) as? NSNumber)?.boolValue ?? false

        return DialogButton(
            label: label.trimmingCharacters(in: .whitespaces),
            position: cgPoint,
            frame: frame,
            isDefault: isDefault,
            accessibilityRole: kAXButtonRole as String,
            confidence: 0.95
        )
    }

    private func collectStaticText(_ element: AXUIElement, into textArray: inout [String]) {
        let role = getAttributeValue(element, kAXRoleAttribute) as? String

        // Collect static text
        if role == kAXStaticTextRole as String {
            if let text = getAttributeValue(element, kAXValueAttribute) as? String {
                textArray.append(text)
            }
        }

        // Recursively search children
        if let children = getAttributeValue(element, kAXChildrenAttribute) as? [AXUIElement] {
            for child in children {
                collectStaticText(child, into: &textArray)
            }
        }
    }

    private func isValidButton(_ button: DialogButton) -> Bool {
        // Filter out empty labels and internal buttons
        let label = button.label.lowercased()

        // Exclude buttons with very short labels (likely not real buttons)
        guard label.count >= 2 else { return false }

        // Exclude system buttons
        let systemExclusions = ["", "-", "ok", "yes", "no"]
        guard !systemExclusions.contains(label) else { return true }  // Actually keep these

        return true
    }

    private func getAttributeValue(_ element: AXUIElement, _ attribute: CFString) -> AnyObject? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, attribute, &value)
        return result == .success ? value : nil
    }

    private func checkAccessibilityPermission() {
        if !AXIsProcessTrusted() {
            Logger.warning("Accessibility permission not granted. App may not function correctly.")
        }
    }
}

// MARK: - Accessibility Utilities

/// Check if app has accessibility permission
func isAccessibilityEnabled() -> Bool {
    return AXIsProcessTrusted()
}

/// Request accessibility permission (opens System Preferences)
func requestAccessibilityPermission() {
    let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    if let url = URL(string: urlString) {
        NSWorkspace.shared.open(url)
    }
}

// MARK: - Accessibility Constants

let kAXButtonRole = "AXButton"
let kAXStaticTextRole = "AXStaticText"
let kAXWindowRole = "AXWindow"
let kAXScrollBarRole = "AXScrollBar"
let kAXCheckBoxRole = "AXCheckBox"

let kAXTitleAttribute = "AXTitle"
let kAXValueAttribute = "AXValue"
let kAXRoleAttribute = "AXRole"
let kAXPositionAttribute = "AXPosition"
let kAXSizeAttribute = "AXSize"
let kAXChildrenAttribute = "AXChildren"
let kAXWindowNumberAttribute = "AXWindowNumber"
let kAXWindowsAttribute = "AXWindows"
let kAXFocusedAttribute = "AXFocused"
let kAXVisibleAttribute = "AXVisible"
let kAXEnabledAttribute = "AXEnabled"
let kAXDescriptionAttribute = "AXDescription"
let kAXHelpAttribute = "AXHelp"

// MARK: - Logger Placeholder

struct Logger {
    static func warning(_ message: String) {
        print("⚠️ \(message)")
    }

    static func debug(_ message: String) {
        print("🔍 \(message)")
    }

    static func info(_ message: String) {
        print("ℹ️ \(message)")
    }

    static func error(_ message: String) {
        print("❌ \(message)")
    }
}
