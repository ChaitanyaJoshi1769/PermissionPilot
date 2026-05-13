import Foundation

/// Example: Using PermissionPilot's Trust Scoring System
/// This example demonstrates how to evaluate application trustworthiness

class TrustScoringExample {

    // MARK: - Basic Trust Scoring

    /// Score an application's trustworthiness
    func scoreApplication() async {
        let scorer = DefaultTrustScorer()

        let appInfo = ApplicationInfo(
            bundleIdentifier: "com.example.app",
            name: "Example App",
            publisher: "Example Publisher",
            version: "1.0.0"
        )

        do {
            let score = await scorer.scoreApplication(appInfo)

            print("Trust Score: \(score)")
            print("Percentage: \(Int(score * 100))%")

            // Make decision based on score
            let decision = interpretScore(score)
            print("Decision: \(decision)")
        } catch {
            print("Error scoring application: \(error)")
        }
    }

    // MARK: - Detailed Scoring Analysis

    /// Get detailed scoring breakdown
    func getDetailedScore() async {
        let scorer = DefaultTrustScorer()

        let appInfo = ApplicationInfo(
            bundleIdentifier: "com.apple.Safari",
            name: "Safari",
            publisher: "Apple Inc.",
            version: "15.0"
        )

        do {
            let score = await scorer.scoreApplicationDetailed(appInfo)

            print("=== Trust Score Breakdown ===")
            print("Overall Score: \(score.overallScore)")
            print("")

            print("Component Scores:")
            print("  Notarization: \(score.components.notarization)")
            print("  Known App: \(score.components.knownAppScore)")
            print("  User History: \(score.components.userHistory)")
            print("  Reputation: \(score.components.reputation)")
            print("  Dialog Type: \(score.components.dialogType)")
            print("")

            print("Factors:")
            for factor in score.factors {
                print("  - \(factor.name): \(factor.impact)")
            }
        } catch {
            print("Error getting detailed score: \(error)")
        }
    }

    // MARK: - Known Application Registry

    /// Check if application is in known app registry
    func checkKnownApplication() async {
        let scorer = DefaultTrustScorer()

        let appsToCheck = [
            "com.google.Chrome",
            "com.apple.Safari",
            "com.unknown.randomapp"
        ]

        for bundleID in appsToCheck {
            let appInfo = ApplicationInfo(
                bundleIdentifier: bundleID,
                name: bundleID,
                publisher: "Unknown",
                version: "Unknown"
            )

            if let knownInfo = await scorer.getKnownApplicationInfo(appInfo) {
                print("✓ \(bundleID)")
                print("  Name: \(knownInfo.displayName)")
                print("  Publisher: \(knownInfo.publisher)")
                print("  Trustworthy: \(knownInfo.isTrustworthy)")
            } else {
                print("✗ \(bundleID) - Not in known app registry")
            }
        }
    }

    // MARK: - Score Thresholds

    /// Interpret score based on thresholds
    private func interpretScore(_ score: Double) -> String {
        switch score {
        case 0.0...0.3:
            return "❌ Block - Low trust"
        case 0.3...0.5:
            return "⚠️ Ask user"
        case 0.5...0.8:
            return "✓ Allow with confirmation"
        case 0.8...1.0:
            return "✅ Auto-allow - High trust"
        default:
            return "Unknown"
        }
    }

    // MARK: - Caching Trust Scores

    /// Cache trust scores for performance
    func scoreApplicationWithCaching() async {
        let scorer = DefaultTrustScorer()

        // Create cache
        var scoreCache: [String: Double] = [:]

        let appInfo = ApplicationInfo(
            bundleIdentifier: "com.example.app",
            name: "Example App",
            publisher: "Example Publisher",
            version: "1.0.0"
        )

        // Check cache first
        if let cachedScore = scoreCache[appInfo.bundleIdentifier] {
            print("Using cached score: \(cachedScore)")
            return
        }

        // Score if not cached
        let score = await scorer.scoreApplication(appInfo)

        // Store in cache
        scoreCache[appInfo.bundleIdentifier] = score

        print("Score calculated and cached: \(score)")
    }

    // MARK: - Batch Scoring

    /// Score multiple applications efficiently
    func scoreMultipleApplications() async {
        let scorer = DefaultTrustScorer()

        let applications = [
            ApplicationInfo(bundleIdentifier: "com.google.Chrome", name: "Chrome", publisher: "Google", version: "1.0"),
            ApplicationInfo(bundleIdentifier: "com.apple.Safari", name: "Safari", publisher: "Apple", version: "1.0"),
            ApplicationInfo(bundleIdentifier: "com.unknown.app", name: "Unknown", publisher: "Unknown", version: "1.0"),
        ]

        print("Scoring multiple applications...")

        var results: [(bundleID: String, score: Double)] = []

        for app in applications {
            let score = await scorer.scoreApplication(app)
            results.append((app.bundleIdentifier, score))
        }

        // Sort by score descending
        results.sort { $0.score > $1.score }

        print("\n=== Scoring Results (sorted by trust) ===")
        for (bundleID, score) in results {
            let trustLevel = Int(score * 100)
            print("\(bundleID): \(trustLevel)%")
        }
    }

    // MARK: - Custom Scoring Logic

    /// Implement custom scoring with additional factors
    func customScoringLogic() async {
        let baseScorer = DefaultTrustScorer()

        let appInfo = ApplicationInfo(
            bundleIdentifier: "com.example.app",
            name: "Example App",
            publisher: "Example Publisher",
            version: "1.0.0"
        )

        let baseScore = await baseScorer.scoreApplication(appInfo)

        // Apply custom adjustments
        var adjustedScore = baseScore

        // Example: Check for specific publisher
        if appInfo.publisher.contains("Apple") {
            adjustedScore += 0.2  // Boost Apple apps
            adjustedScore = min(adjustedScore, 1.0)
        }

        // Example: Check for specific version
        if appInfo.version.contains("beta") {
            adjustedScore -= 0.1  // Reduce beta versions
            adjustedScore = max(adjustedScore, 0.0)
        }

        print("Base Score: \(baseScore)")
        print("Adjusted Score: \(adjustedScore)")
    }
}

// MARK: - Models

struct ApplicationInfo {
    let bundleIdentifier: String
    let name: String
    let publisher: String
    let version: String
}

struct TrustScoreDetailed {
    let overallScore: Double

    struct ComponentScores {
        let notarization: Double
        let knownAppScore: Double
        let userHistory: Double
        let reputation: Double
        let dialogType: Double
    }

    let components: ComponentScores

    struct ScoreFactor {
        let name: String
        let impact: Double
    }

    let factors: [ScoreFactor]
}

struct KnownApplicationInfo {
    let displayName: String
    let publisher: String
    let isTrustworthy: Bool
    let verifiedPublisher: Bool
}

// MARK: - Protocol Definition (for reference)

protocol TrustScorer {
    /// Score an application
    func scoreApplication(_ appInfo: ApplicationInfo) async -> Double

    /// Get detailed scoring breakdown
    func scoreApplicationDetailed(_ appInfo: ApplicationInfo) async -> TrustScoreDetailed

    /// Check if app is known
    func getKnownApplicationInfo(_ appInfo: ApplicationInfo) async -> KnownApplicationInfo?
}

class DefaultTrustScorer: TrustScorer {
    // Implementation would go here
    func scoreApplication(_ appInfo: ApplicationInfo) async -> Double {
        // Placeholder implementation
        return 0.75
    }

    func scoreApplicationDetailed(_ appInfo: ApplicationInfo) async -> TrustScoreDetailed {
        // Placeholder implementation
        return TrustScoreDetailed(
            overallScore: 0.75,
            components: .init(
                notarization: 1.0,
                knownAppScore: 0.8,
                userHistory: 0.7,
                reputation: 0.7,
                dialogType: 0.6
            ),
            factors: []
        )
    }

    func getKnownApplicationInfo(_ appInfo: ApplicationInfo) async -> KnownApplicationInfo? {
        // Placeholder implementation
        return nil
    }
}
