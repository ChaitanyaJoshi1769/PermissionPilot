import Foundation

/// Matches button labels and ranks them by safety
actor ButtonMatcher {
    // MARK: - Button Ranking

    func rankButtons(_ buttons: [DialogButton], for dialog: DetectedDialog) -> [RankedButton] {
        return buttons.compactMap { button in
            let rank = calculateButtonRank(button, dialog: dialog)
            return RankedButton(button: button, rank: rank)
        }
        .sorted { $0.rank > $1.rank }
    }

    func findBestButton(_ buttons: [DialogButton], for dialog: DetectedDialog) -> DialogButton? {
        rankButtons(buttons, for: dialog).first?.button
    }

    // MARK: - Private Ranking Logic

    private func calculateButtonRank(_ button: DialogButton, dialog: DetectedDialog) -> Double {
        var score: Double = 0.5  // Base score

        let label = button.label.lowercased().trimmingCharacters(in: .whitespaces)

        // NEVER click unsafe buttons
        if isSafetyBlockedButton(label) {
            return -1.0  // Absolute reject
        }

        // Highest priority: "Allow Once" / "Allow This Time"
        if isSafeAllowOnceButton(label) {
            score = 0.95
        }
        // High priority: Safe approval buttons
        else if isSafeApprovalButton(label) {
            score = 0.85
        }
        // Medium priority: Generic safe buttons
        else if isSafeGenericButton(label) {
            score = 0.70
        }
        // Low priority: Uncertain buttons
        else if isUncertainButton(label) {
            score = 0.40
        }

        // Boost score if it's the default button
        if button.isDefault {
            score += 0.05
        }

        // Adjust for confidence score
        score *= button.confidence

        return min(score, 1.0)
    }

    private func isSafeAllowOnceButton(_ label: String) -> Bool {
        ["allow once", "allow this time", "allow for this session", "once"].contains { keyword in
            label.contains(keyword)
        }
    }

    private func isSafeApprovalButton(_ label: String) -> Bool {
        ["allow", "enable", "grant", "approve", "permit"].contains { keyword in
            label.contains(keyword)
        }
    }

    private func isSafeGenericButton(_ label: String) -> Bool {
        ["continue", "ok", "yes", "next", "proceed"].contains { keyword in
            label.contains(keyword)
        }
    }

    private func isUncertainButton(_ label: String) -> Bool {
        // Buttons that might be safe depending on context
        ["accept", "confirm", "agree", "start", "begin"].contains { keyword in
            label.contains(keyword)
        }
    }

    private func isSafetyBlockedButton(_ label: String) -> Bool {
        SafeButtonKeywords.unsafe.contains { keyword in
            label.contains(keyword)
        }
    }

    // MARK: - Types

    struct RankedButton {
        let button: DialogButton
        let rank: Double
    }
}

/// Fuzzy string matching for button labels
struct StringMatcher {
    /// Levenshtein distance-based matching
    static func fuzzyMatch(_ a: String, _ b: String) -> Double {
        let aLower = a.lowercased()
        let bLower = b.lowercased()

        // Exact match
        if aLower == bLower {
            return 1.0
        }

        // Substring match
        if aLower.contains(bLower) || bLower.contains(aLower) {
            return 0.9
        }

        // Calculate Levenshtein distance
        let distance = levenshteinDistance(aLower, bLower)
        let maxLen = max(a.count, b.count)
        let similarity = 1.0 - Double(distance) / Double(maxLen)

        return max(0, similarity)
    }

    /// Calculate Levenshtein distance between two strings
    private static func levenshteinDistance(_ a: String, _ b: String) -> Int {
        let aArray = Array(a)
        let bArray = Array(b)

        let m = aArray.count
        let n = bArray.count

        if m == 0 { return n }
        if n == 0 { return m }

        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)

        for i in 0...m {
            dp[i][0] = i
        }

        for j in 0...n {
            dp[0][j] = j
        }

        for i in 1...m {
            for j in 1...n {
                if aArray[i - 1] == bArray[j - 1] {
                    dp[i][j] = dp[i - 1][j - 1]
                } else {
                    dp[i][j] = 1 + min(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1])
                }
            }
        }

        return dp[m][n]
    }
}
