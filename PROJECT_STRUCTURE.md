# PermissionPilot Project Structure

```
PermissionPilot/
├── ARCHITECTURE.md                          # This document
├── PROJECT_STRUCTURE.md                     # Folder layout
├── README.md                                # User guide
├── SECURITY.md                              # Security review
├── PRIVACY_POLICY.md                        # Privacy statement
├── LICENSE                                  # MIT/Commercial
│
├── Xcode/
│   └── PermissionPilot.xcodeproj/
│       ├── project.pbxproj
│       ├── project.xcworkspace/
│       └── xcshareddata/
│           └── xcschemes/
│
├── Sources/
│   ├── App/                                 # Main app entry points
│   │   ├── PermissionPilotApp.swift        # SwiftUI app
│   │   ├── PermissionPilotDaemon.swift     # Daemon executable
│   │   └── Entitlements.plist
│   │
│   ├── Core/                                # Core detection logic
│   │   ├── DialogDetector.swift            # Main dialog detection
│   │   ├── WindowMonitor.swift             # NSWindow observation
│   │   ├── DialogClassifier.swift          # Dialog type classification
│   │   └── Models.swift                    # Shared data models
│   │
│   ├── Accessibility/                      # Accessibility API layer
│   │   ├── AXUIElementWrapper.swift        # Safe AX wrapper
│   │   ├── AccessibilityInspector.swift    # AX hierarchy inspection
│   │   ├── ButtonDiscovery.swift           # Find buttons in dialog
│   │   ├── WindowHierarchy.swift           # Window structure parsing
│   │   └── AccessibilityPermissions.swift  # Permission checking
│   │
│   ├── OCR/                                 # Vision framework OCR
│   │   ├── OCRPipeline.swift               # Main OCR processor
│   │   ├── ImagePreprocessor.swift         # Image normalization
│   │   ├── TextExtractor.swift             # Vision API wrapper
│   │   ├── ButtonLocator.swift             # Locate buttons by OCR
│   │   └── ConfidenceFilter.swift          # Confidence thresholding
│   │
│   ├── Policy/                              # Policy engine
│   │   ├── PolicyEngine.swift              # Main policy evaluation
│   │   ├── TrustScorer.swift               # Trust score calculation
│   │   ├── BundleValidator.swift           # App signature validation
│   │   ├── WhitelistManager.swift          # Whitelist operations
│   │   ├── BlacklistManager.swift          # Blacklist operations
│   │   └── PolicyRuleEvaluator.swift       # Custom rule matching
│   │
│   ├── Buttons/                             # Button detection & ranking
│   │   ├── ButtonMatcher.swift             # Button label matching
│   │   ├── ButtonRanker.swift              # Priority ranking
│   │   └── ButtonConstants.swift           # Safe/unsafe keywords
│   │
│   ├── Automation/                          # UI automation
│   │   ├── MouseController.swift           # Natural mouse movement
│   │   ├── KeyboardController.swift        # Keyboard automation
│   │   ├── WindowManager.swift             # Window focus/visibility
│   │   ├── AutomationEngine.swift          # Orchestrator
│   │   ├── RetryStrategy.swift             # Retry logic
│   │   └── ClickSimulator.swift            # Human-like clicking
│   │
│   ├── Logging/                             # Audit logging
│   │   ├── DatabaseManager.swift           # SQLite operations
│   │   ├── AuditLogger.swift               # Logging coordinator
│   │   ├── DatabaseSchema.swift            # Schema creation
│   │   ├── ScreenshotCapture.swift         # Screenshot saving
│   │   └── LogExporter.swift               # CSV/JSON export
│   │
│   ├── UI/                                  # SwiftUI views
│   │   ├── ContentView.swift               # Main tabbed interface
│   │   ├── DashboardView.swift             # Dashboard tab
│   │   ├── PoliciesView.swift              # Policies tab
│   │   ├── TrustCenterView.swift           # Whitelist/blacklist
│   │   ├── LogsView.swift                  # Activity logs
│   │   ├── SettingsView.swift              # Settings tab
│   │   ├── Components/                     # Reusable components
│   │   │   ├── StatisticsCard.swift
│   │   │   ├── ActivityFeed.swift
│   │   │   ├── PolicyEditor.swift
│   │   │   ├── PermissionPrompt.swift
│   │   │   └── GlassmorphismCard.swift
│   │   ├── Styles/                         # Design system
│   │   │   ├── AppColors.swift
│   │   │   ├── Typography.swift
│   │   │   └── Shadows.swift
│   │   └── Onboarding/                     # First-run UX
│   │       ├── OnboardingView.swift
│   │       ├── AccessibilityPermissionView.swift
│   │       └── OnboardingStep.swift
│   │
│   ├── MenuBar/                             # Menu bar integration
│   │   ├── MenuBarController.swift         # Status icon management
│   │   ├── MenuBarItem.swift               # Menu bar UI
│   │   └── QuickActions.swift              # Menu actions
│   │
│   ├── Services/                            # System services
│   │   ├── AppDelegate.swift               # Lifecycle
│   │   ├── XPCService.swift                # IPC with daemon
│   │   ├── NotificationManager.swift       # User notifications
│   │   ├── SettingsManager.swift           # UserDefaults + Keychain
│   │   └── LaunchAgentManager.swift        # Daemon management
│   │
│   ├── Utilities/                           # Helper utilities
│   │   ├── StringMatching.swift            # Fuzzy matching
│   │   ├── ImageProcessing.swift           # Image utilities
│   │   ├── ScreenCoordinates.swift         # Multi-monitor support
│   │   ├── DateFormatter.swift             # Formatting helpers
│   │   ├── BundleIdentifier.swift          # Bundle utilities
│   │   └── Logger.swift                    # Unified logging
│   │
│   └── Resources/
│       ├── Assets.xcassets/                # Images, icons
│       ├── Localization/
│       │   ├── en.lproj/
│       │   │   ├── Localizable.strings
│       │   │   └── InfoPlist.strings
│       │   └── es.lproj/
│       │       └── Localizable.strings
│       └── Previews/                       # SwiftUI previews
│           └── PreviewSampleData.swift
│
├── Tests/
│   ├── CoreTests/
│   │   ├── DialogDetectorTests.swift
│   │   ├── DialogClassifierTests.swift
│   │   └── WindowMonitorTests.swift
│   │
│   ├── AccessibilityTests/
│   │   ├── AXUIElementWrapperTests.swift
│   │   ├── AccessibilityInspectorTests.swift
│   │   └── ButtonDiscoveryTests.swift
│   │
│   ├── OCRTests/
│   │   ├── OCRPipelineTests.swift
│   │   ├── TextExtractorTests.swift
│   │   └── ButtonLocatorTests.swift
│   │
│   ├── PolicyTests/
│   │   ├── PolicyEngineTests.swift
│   │   ├── TrustScorerTests.swift
│   │   └── PolicyRuleEvaluatorTests.swift
│   │
│   ├── ButtonTests/
│   │   ├── ButtonMatcherTests.swift
│   │   ├── ButtonRankerTests.swift
│   │   └── SafetyCheckTests.swift
│   │
│   ├── AutomationTests/
│   │   ├── MouseControllerTests.swift
│   │   ├── AutomationEngineTests.swift
│   │   └── RetryStrategyTests.swift
│   │
│   ├── LoggingTests/
│   │   ├── DatabaseManagerTests.swift
│   │   ├── AuditLoggerTests.swift
│   │   └── LogExporterTests.swift
│   │
│   ├── UITests/
│   │   ├── ContentViewTests.swift
│   │   ├── DashboardViewTests.swift
│   │   ├── PoliciesViewTests.swift
│   │   └── OnboardingViewTests.swift
│   │
│   ├── Mocks/
│   │   ├── MockDialogDetector.swift
│   │   ├── MockAccessibilityInspector.swift
│   │   ├── MockPolicyEngine.swift
│   │   ├── MockAutomationEngine.swift
│   │   └── TestDialogSamples.swift
│   │
│   └── Resources/
│       ├── SampleDialogs/
│       │   ├── chrome-notification-dialog.png
│       │   ├── macos-permission-dialog.png
│       │   └── electron-app-dialog.png
│       └── sample-data.json
│
├── Assets/
│   ├── Icons/
│   │   ├── AppIcon.png (512x512)
│   │   ├── MenuBarIcon.png (16x16, 22x22)
│   │   └── PreviewImages/
│   │       ├── dashboard-preview.png
│   │       ├── policies-preview.png
│   │       └── logs-preview.png
│   │
│   └── Onboarding/
│       ├── welcome-illustration.png
│       ├── accessibility-permission.png
│       └── dashboard-preview.png
│
├── Scripts/
│   ├── build.sh                            # Build script
│   ├── sign-and-notarize.sh                # Signing & notarization
│   ├── create-dmg.sh                       # DMG creation
│   ├── setup-launchagent.sh                # Agent installation
│   ├── code-style.sh                       # SwiftFormat
│   ├── run-tests.sh                        # Test runner
│   ├── generate-docs.sh                    # Doc generation
│   └── ci-build.yml                        # GitHub Actions
│
├── Configuration/
│   ├── Info.plist                          # App info
│   ├── Entitlements.plist                  # Required entitlements
│   ├── LaunchAgent.plist                   # Daemon configuration
│   ├── ExportOptions.plist                 # Archive export config
│   ├── SwiftFormat.yml                     # Code formatting
│   ├── SwiftLint.yml                       # Linting rules
│   └── Package.swift                       # SPM manifest (if modular)
│
├── Documentation/
│   ├── INSTALLATION.md
│   ├── USER_GUIDE.md
│   ├── DEVELOPER_GUIDE.md
│   ├── API_REFERENCE.md
│   ├── TROUBLESHOOTING.md
│   ├── CHANGELOG.md
│   └── TECHNICAL_DEEP_DIVE.md
│
├── CI/
│   ├── .github/
│   │   └── workflows/
│   │       ├── build.yml
│   │       ├── test.yml
│   │       ├── lint.yml
│   │       └── release.yml
│   └── pre-commit-config.yaml
│
└── Distribution/
    ├── VERSION.txt
    ├── RELEASE_NOTES.md
    ├── PRIVACY_STATEMENT.txt
    ├── EULA.txt
    └── notarization-info.json
```

## Key File Naming Conventions

- **Models**: `DataType.swift` (e.g., `DialogWindow.swift`)
- **Views**: `*View.swift` (e.g., `DashboardView.swift`)
- **Controllers**: `*Controller.swift` or `*Manager.swift`
- **Services**: `*Service.swift` (e.g., `DatabaseService.swift`)
- **Tests**: `*Tests.swift` (e.g., `DialogDetectorTests.swift`)

## Build Targets

1. **PermissionPilot** (Main App)
   - Type: macOS App
   - Deployment: macOS 13.0+
   - Architectures: arm64, x86_64 (Universal)

2. **PermissionPilotDaemon** (Background Service)
   - Type: Command Line Tool
   - Installed to: `/Library/LaunchAgents/`
   - Launched by: LaunchAgent

3. **PermissionPilotTests** (Unit Tests)
   - Type: Test Bundle
   - Coverage Target: 80%+

## Compilation & Linking

- **Swift**: Swift 5.9+
- **Frameworks**: AppKit, SwiftUI, Combine, Vision, CoreGraphics
- **External**: No third-party dependencies (pure Apple frameworks)
- **SQLite**: Built into macOS

## Signing & Notarization

- Code Signing Identity: Apple Developer ID
- Provisioning: Not required (Developer ID signed)
- Notarization: Required for distribution
- Hardened Runtime: Required entitlements

