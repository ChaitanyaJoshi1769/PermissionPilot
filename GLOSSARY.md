# Glossary of Terms

Complete reference of terminology, abbreviations, and concepts used throughout PermissionPilot documentation and codebase.

---

## A

### Accessibility API
The macOS Accessibility framework (AXUIElement) used to detect and interact with UI elements. PermissionPilot's primary method for identifying dialogs.

**Related:** Accessibility permission, Dialog detection

### Automation
The process of automatically clicking buttons, typing text, or performing actions in response to detected dialogs without user intervention.

**Related:** Dialog detection, Trust scoring, Policy engine

### Audit Log
A database record of all dialogs detected, actions taken, and system events. Used for transparency, debugging, and compliance.

**Related:** SQLite, Database schema, automation_events table

### Auto-allow Threshold
Trust score boundary (default: 0.8) above which dialogs are automatically approved. Scores ≥ 0.8 trigger automatic "Allow Once" action.

**Related:** Trust scoring, Policy decision, Confidence threshold

### Auto-block Threshold
Trust score boundary (default: 0.3) below which dialogs are automatically blocked. Scores ≤ 0.3 trigger automatic block action.

**Related:** Trust scoring, Dangerous keywords, Policy decision

---

## B

### Bezier Curve
Mathematical curve used for smooth, natural-looking mouse movement. Creates human-like motion instead of linear movement.

**Related:** Automation, Human-like behavior, Mouse movement

### Blacklist Policy
Policy type that blocks all dialogs from specified applications or matching patterns. Opposite of whitelist.

**Related:** Policy types, Whitelist policy, Rule policy

### Bundle ID
Unique identifier for a macOS application (e.g., `com.google.Chrome`). Used to identify and target specific apps.

**Related:** Application info, Known apps, Policy targeting

### Button Matching
Process of identifying and analyzing buttons in a detected dialog to determine which is safest to click.

**Related:** Dialog detection, Button safety, Confidence scoring

### Button Safety Score
0-1 score indicating how safe a button is to click. Factors: keywords, position, color, context.

**Related:** Button matching, Trust scoring, Dangerous keywords

---

## C

### Cache / Caching
Storing frequently accessed data in memory to improve performance. PermissionPilot caches dialog detection results.

**Related:** Performance, Memory optimization, Detection cache

### Confidence Threshold
Minimum detection confidence (default: 0.85) required to proceed with automation. Lower = more automation, higher = more safety.

**Related:** Detection confidence, Trust scoring, Sensitivity

### Configuration Management
Tools and processes for deploying and managing PermissionPilot across multiple machines (Ansible, Chef, Puppet, etc.).

**Related:** Deployment, MDM, Enterprise deployment

### Code Signing
Process of cryptographically signing the PermissionPilot app with Apple Developer ID to verify authenticity and integrity.

**Related:** Notarization, Security, Code signature validation

---

## D

### Daemon
Background service (LaunchAgent) running continuously to monitor for dialogs. Provides non-intrusive automation.

**Related:** LaunchAgent, Background service, Polling

### Dangerous Keywords
Text patterns indicating risky operations (delete, erase, reset, uninstall, etc.). Buttons with these keywords are blocked by default.

**Related:** Button safety, Blocking, Trust scoring

### Database
SQLite database storing audit logs, policies, trust history, and configuration. Located at `~/Library/Application Support/PermissionPilot/audit.db`

**Related:** Audit log, SQLite, Schema

### Debounce
Ignoring repeated similar dialogs within a short timeframe (default: 100ms). Prevents multiple automations of same dialog.

**Related:** Polling, Performance, Dialog deduplication

### Decision (Policy)
Outcome of policy evaluation: `allow`, `block`, or `ask`. Determines what PermissionPilot does with a detected dialog.

**Related:** Policy engine, Trust scoring, Action taken

### Detection (Dialog)
Process of identifying a permission dialog using Accessibility API or OCR. Includes classification and confidence scoring.

**Related:** Dialog, Accessibility API, OCR, Detection confidence

### Detection Confidence
0-1 score indicating how confident PermissionPilot is that detected dialog is actually a permission dialog. Affects decision-making.

**Related:** Confidence threshold, Trust scoring, Detection method

### Detection Method
Technique used to identify dialogs: `accessibility_api`, `ocr`, or `hybrid` (both combined).

**Related:** Accessibility API, OCR, Hybrid detection

### Dialog
A permission request window or prompt from an application or macOS. Examples: camera access, notifications, deletion confirmation.

**Related:** Dialog types, Detection, Automation

### Dialog Type
Classification of dialog: `native_macos`, `browser`, `application`, `installer`, `custom`, or `unknown`.

**Related:** Dialog detection, Policy targeting

### DMG (Disk Image)
macOS installer format (.dmg file). PermissionPilot is distributed as PermissionPilot.dmg for easy installation.

**Related:** Installation, Distribution, Deployment

---

## E

### Entitlements
Permissions requested by app in Info.plist. Controls what the app can access (files, camera, microphone, etc.).

**Related:** Accessibility permission, Security, Code signing

### Event
Record of a single dialog detection and automation action in the audit log.

**Related:** Audit log, automation_events table

---

## F

### Fallback
Secondary method used when primary fails. PermissionPilot uses OCR as fallback when Accessibility API insufficient.

**Related:** OCR, Accessibility API, Hybrid detection

### False Positive
Dialog incorrectly identified as permission request and automated when it shouldn't be.

**Related:** Confidence threshold, Trust scoring, Safety

### Field / Field Name
Column or property in database table. Example: `dialog_title`, `button_clicked`, `trust_score`.

**Related:** Database schema, SQLite

---

## G

### GitHub Actions
Automation platform for CI/CD. PermissionPilot uses GitHub Actions for automated building, testing, and releases.

**Related:** CI/CD, Continuous integration, Release automation

### Gatekeeper
macOS security feature that prevents execution of unverified code. PermissionPilot bypasses this via code signing + notarization.

**Related:** Code signing, Notarization, Security

---

## H

### Homebrew
macOS package manager. PermissionPilot can be installed via: `brew install permissionpilot`

**Related:** Installation, Distribution, Package management

### Human-like Behavior
Automation techniques mimicking human actions: natural mouse movement (Bezier curves), typing delays, reaction time simulation.

**Related:** Automation, Mouse movement, Click timing

### Hybrid Detection
Detection method combining both Accessibility API (fast) and OCR (fallback). Provides best accuracy and coverage.

**Related:** Accessibility API, OCR, Detection method

---

## I

### Index (Database)
Optimized data structure for faster database queries. PermissionPilot creates indexes on frequently-queried columns.

**Related:** Database performance, SQL query optimization

### Injection Attack
Security threat where malicious code injected into PermissionPilot could modify behavior. Mitigated by parameter validation.

**Related:** Security, Threat model, Input validation

---

## J

### JSON (JavaScript Object Notation)
Human-readable data format used for configuration files and data export. Format for config.json and policies.json.

**Related:** Configuration, Data format, Policy files

---

## K

### Known App / Known Apps List
Pre-configured registry of trusted applications (Apple, Google, Microsoft, etc.) used for higher trust scores.

**Related:** Trust scoring, Whitelist, Application info

---

## L

### LaunchAgent
macOS daemon launcher that starts PermissionPilot automatically on login. Runs at user level (not system-wide).

**Related:** Daemon, Background service, Auto-start

### Launch Hook
Script or code run at specific time: app launch, daemon start, etc. Used for initialization and startup tasks.

**Related:** LaunchAgent, Initialization

---

## M

### MDM (Mobile Device Management)
System for managing and deploying software across multiple devices. Apple Business Manager is MDM service.

**Related:** Deployment, Enterprise, Configuration management

### Memory Footprint
Amount of RAM used by PermissionPilot. Target: <200MB idle, <300MB peak.

**Related:** Performance, Memory leak, Optimization

### Memory Leak
Bug where application doesn't release memory, causing memory usage to grow over time.

**Related:** Performance, Optimization, Debugging

### Migration
Process of upgrading from one version to another while preserving data and settings.

**Related:** Version upgrade, Backup, Data preservation

### Mitigate / Mitigation
Action taken to reduce or eliminate risk. PermissionPilot mitigates 10 security threats via specific architectural choices.

**Related:** Security, Threat model, Risk management

### Mouse Movement
Simulated mouse movement from current to target position. PermissionPilot uses Bezier curves for natural appearance.

**Related:** Automation, Bezier curve, Human-like behavior

---

## N

### Notarization
Apple security process certifying an app is free of malware. Required for macOS distribution.

**Related:** Code signing, Security, Distribution

### Notarized App
Application signed and verified by Apple as safe. Indicates the app has been scanned for malware.

**Related:** Notarization, Code signing, Trust scoring

---

## O

### OCR (Optical Character Recognition)
Computer vision technique extracting text from images. PermissionPilot uses Vision Framework for dialog text extraction.

**Related:** Dialog detection, Fallback, Vision Framework

### Operator
Person managing PermissionPilot deployment in organization. Usually IT administrator or system administrator.

**Related:** Administrator, Deployment, Configuration management

---

## P

### Pattern / Regex Pattern
Regular expression matching text. Policies use patterns like `(?i)(delete|erase)` to identify dangerous dialogs.

**Related:** Policy rules, Pattern matching, Regular expressions

### Performance Baseline
Expected performance metrics: <3% CPU idle, <200MB memory, <500ms detection, <1s total automation.

**Related:** Performance targets, Benchmarking, Optimization

### Permission / Accessibility Permission
macOS security setting allowing apps to use Accessibility APIs. PermissionPilot requires this permission.

**Related:** Accessibility API, Security, System requirements

### Polling
Repeatedly checking for new dialogs at regular intervals (default: 500ms). Enables continuous monitoring without overhead.

**Related:** Daemon, Detection, Polling interval

### Policy
Rule determining how PermissionPilot handles dialogs. Types: whitelist, blacklist, rule (conditional).

**Related:** Policy engine, Policy types, Decision

### Policy Engine
Component evaluating policies against dialogs and making allow/block/ask decisions.

**Related:** Trust scoring, Policy, Decision

---

## Q

### Query
SQL statement retrieving data from database. Examples: get event statistics, export audit log.

**Related:** Database, SQLite, SQL

---

## R

### Regex / Regular Expression
Pattern matching language for text. PermissionPilot policies use PCRE-compatible regex.

**Related:** Pattern matching, Policy rules

### Reputation
Historical trust data for application based on user decisions and external sources. Part of trust scoring.

**Related:** Trust scoring, Trust history, App reputation

### Retry / Retry Logic
Attempting operation multiple times if initial attempt fails. PermissionPilot retries detection up to 3 times.

**Related:** Reliability, Robustness, Error handling

### Rule Policy
Policy type with conditional pattern matching (e.g., "Allow if dialog contains 'notification'").

**Related:** Policy types, Whitelist, Blacklist, Pattern matching

---

## S

### Safe / Safety
Indicates dialog is safe to automate. Opposite of dangerous. Determined by trust scoring and button safety analysis.

**Related:** Trust scoring, Button safety, Confidence

### Safety Score
0-1 metric indicating safety of automating a dialog. Combines multiple factors: trust, button safety, keywords.

**Related:** Trust scoring, Button safety, Confidence

### Sandbox / Sandboxed App
App running in restricted environment with limited system access. PermissionPilot handles sandboxed apps via OCR fallback.

**Related:** Security, Accessibility API, OCR fallback

### Schema
Structure and organization of database tables, columns, relationships. Also called database schema.

**Related:** Database, SQLite, Tables, Relationships

### Screenshot
Image capture of dialog for visual debugging or OCR processing. Stored in screenshots table (optional).

**Related:** OCR, Debugging, Visual inspection

### Security Boundary
Architectural limit preventing unauthorized access or modification. PermissionPilot maintains strict security boundaries.

**Related:** Security, Architecture, Threat model

### SIP (System Integrity Protection)
macOS security feature preventing even root-level access to critical system files. PermissionPilot never attempts to bypass SIP.

**Related:** Security, Macros, Restrictions

### SQLite
Lightweight embedded SQL database used for audit logs. Provides ACID guarantees and efficient queries.

**Related:** Database, Audit log, Schema

### Stats / Statistics
Metrics about PermissionPilot usage: dialogs detected, automation rate, app distribution, etc.

**Related:** Dashboard, Metrics, Analytics

---

## T

### TCC (Transparency, Consent & Control)
macOS system controlling app access to sensitive data (files, camera, microphone, etc.). PermissionPilot respects TCC completely.

**Related:** Security, Permissions, Privacy

### Threshold
Boundary value for decision-making. Examples: confidence threshold, trust threshold, auto-allow threshold.

**Related:** Trust scoring, Policy decision, Confidence

### Threat Model
Systematic analysis of potential security attacks and mitigations. PermissionPilot documents 10 threats with mitigations.

**Related:** Security, Risk management, Architecture

### Trust History
Record of user's past decisions about application. Used to build reputation and inform trust score.

**Related:** Trust scoring, Reputation, User history

### Trust Score
0-1 value indicating how trustworthy an application and dialog combination is. Drives automation decision.

**Related:** Trust scoring, Decision, Confidence

### Trust Scoring Algorithm
Mathematical formula combining multiple factors to produce final trust score:
`score = (0.2 × notarization) + (0.2 × known_app) + (0.3 × history) + (0.2 × reputation) + (0.1 × dialog_type)`

**Related:** Trust scoring, Decision-making, Algorithm

---

## U

### Universal Binary
Executable supporting multiple CPU architectures (arm64 for Apple Silicon, x86_64 for Intel). PermissionPilot is universal binary.

**Related:** Architecture support, Compatibility

### User Decision
Action taken by user: approve dialog, block dialog, or manual action. Recorded in trust history.

**Related:** Trust history, Reputation, User interaction

---

## V

### Vacuum (Database)
Operation to compact database and reclaim space. Periodically runs to maintain database performance.

**Related:** Database maintenance, Performance, SQLite

### Vision Framework
Apple's computer vision library used for OCR processing. Performs text recognition from dialog screenshots.

**Related:** OCR, Dialog detection, Image processing

---

## W

### WAL (Write-Ahead Logging)
SQLite mode enabling concurrent read/write access. Improves performance under heavy load.

**Related:** Database performance, SQLite, Concurrency

### Whitelist / Whitelisting
List of trusted applications that are automatically approved. Opposite of blacklist.

**Related:** Policy types, Blacklist, Policy engine

### Workflow
Sequence of steps users follow. Examples: detection → evaluation → automation → logging.

**Related:** Process, Automation, Pipeline

---

## X

### Xcode
Apple's integrated development environment for macOS/iOS development. Used to build PermissionPilot from source.

**Related:** Build from source, Development, Compilation

---

## Y

*(No common PermissionPilot terms start with Y)*

---

## Z

### Zero-Trust Model
Security principle treating all software as potentially untrustworthy until proven otherwise. PermissionPilot implements zero-trust: blocks by default, allows only with sufficient trust score.

**Related:** Security, Trust scoring, Philosophy

---

## Acronyms & Abbreviations

| Acronym | Full Name | Meaning |
|---------|-----------|---------|
| API | Application Programming Interface | Software interface for interacting with components |
| CPU | Central Processing Unit | Computer processor, impacts performance |
| CSV | Comma-Separated Values | Data format for spreadsheets |
| DMG | Disk Image | macOS installer file format |
| GB | Gigabyte | 1,000 MB of storage |
| HID | Human Interface Device | Keyboard, mouse input simulation |
| JSON | JavaScript Object Notation | Human-readable data format |
| KB | Kilobyte | 1,000 bytes of storage |
| MB | Megabyte | 1,000 KB of storage |
| MDM | Mobile Device Management | Device management system |
| ms | millisecond | 1/1000 of a second |
| OCR | Optical Character Recognition | Text extraction from images |
| PDF | Portable Document Format | Document format |
| PR | Pull Request | Code change proposal in Git |
| RAM | Random Access Memory | Computer memory (temporary storage) |
| SQL | Structured Query Language | Database query language |
| TCC | Transparency, Consent & Control | macOS privacy control system |
| UI | User Interface | Visual elements users interact with |
| UUID | Universally Unique Identifier | Unique ID string |
| WPM | Words Per Minute | Typing speed measurement |

---

## Cross-References

### By Category

**Automation:**
Automation, Dialog detection, Trust scoring, Button matching, Policy engine, Decision, Action taken

**Detection:**
Dialog, Detection, OCR, Accessibility API, Accessibility permission, Confidence, Hybrid detection

**Trust & Security:**
Trust score, Trust scoring algorithm, Threat model, Whitelist, Blacklist, Dangerous keywords, Safe, Safety

**Database:**
SQLite, Schema, Audit log, Event, Query, Vacuum, Migration

**Deployment:**
MDM, Configuration management, Ansible, Daemon, LaunchAgent, Homebrew, DMG

**Performance:**
CPU, Memory, Polling, Cache, Index, Performance baseline, Optimization

---

## Further Reading

- **Architecture Overview:** See [ARCHITECTURE.md](ARCHITECTURE.md)
- **API Reference:** See [API_REFERENCE.md](API_REFERENCE.md)
- **Database Details:** See [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md)
- **Trust Scoring Details:** See [SECURITY.md#Trust Scoring](SECURITY.md#trust-scoring-algorithm)
- **Configuration Options:** See [CONFIGURATION_GUIDE.md](CONFIGURATION_GUIDE.md)

---

**Last updated:** May 13, 2024  
**Total terms:** 100+
