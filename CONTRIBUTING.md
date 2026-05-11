# Contributing to PermissionPilot

We welcome contributions! This document guides you through the process.

## Code of Conduct

Please be respectful and professional. We're building a tool that respects user privacy and security.

## Getting Started

### Prerequisites
- macOS 13.0+
- Xcode 15.0+
- Swift 5.9+
- Basic familiarity with Swift and macOS APIs

### Development Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/PermissionPilot.git
cd PermissionPilot

# Install development tools
brew install swiftformat swiftlint

# Build and test
make build
make test
```

## Development Workflow

### 1. Create a Branch

```bash
git checkout -b feature/your-feature-name
```

Use descriptive branch names:
- `feature/...` for new features
- `fix/...` for bug fixes
- `refactor/...` for code improvements
- `docs/...` for documentation
- `test/...` for test additions

### 2. Make Changes

Follow these guidelines:

**Code Style**:
- Use SwiftFormat (run `make format`)
- Follow Swift conventions
- Use meaningful variable names
- Keep functions focused and small

**Safety**:
- Avoid unsafe code (`UnsafeMutablePointer`, etc.)
- Use type-safe Swift features
- Handle errors appropriately

**Testing**:
- Add tests for new functionality
- Run `make test` before committing
- Aim for >80% coverage of critical paths

**Documentation**:
- Update relevant docs for feature changes
- Add comments for non-obvious logic
- Update README.md if user-facing

### 3. Commit Changes

```bash
# Format and lint before committing
make format
make lint

# Stage your changes
git add .

# Commit with descriptive message
git commit -m "Concise description of change

Longer explanation if needed. Focus on WHY, not WHAT.
The code already shows WHAT you changed.

Fixes #123 (if applicable)
"
```

**Commit Message Guidelines**:
- First line: ≤50 characters, imperative mood ("Add" not "Added")
- Body: Wrapped at 72 characters
- Reference issues: "Fixes #123" or "Relates to #456"
- No line should exceed 72 characters

### 4. Test Thoroughly

Before pushing, ensure:

```bash
# Run all checks
make all

# Or individually:
make clean
make format
make lint
make test
make build
```

### 5. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a PR with:
- **Title**: Short description (≤70 chars)
- **Description**: What changed and why
- **Testing**: How to verify the changes work
- **Checklist**: Mark completed items

## Areas Where Contributions Help

### High Priority
- [ ] Unit tests (we have scaffolding, need implementation)
- [ ] Dialog type support (Slack, Zoom, Cursor, etc.)
- [ ] Policy rule enhancements
- [ ] Bug fixes

### Medium Priority
- [ ] UI improvements
- [ ] Performance optimizations
- [ ] Localization (i18n)
- [ ] Documentation

### Lower Priority
- [ ] Browser extension (phase 2)
- [ ] iOS companion (phase 3)
- [ ] Enterprise features (phase 4)

## Code Review Process

1. **Automated Checks**: CI/CD pipeline runs (build, tests, lint)
2. **Code Review**: Team reviews for:
   - Security implications
   - Performance impact
   - Test coverage
   - Documentation
3. **Approval**: Requires 1 approval to merge
4. **Merge**: Squash and merge to main

## Testing Guidelines

### Unit Tests
```swift
// Follow this pattern:
func testFeatureDoesXWhenYCondition() {
    // Arrange
    let input = setupTestData()
    
    // Act
    let result = functionUnderTest(input)
    
    // Assert
    XCTAssertEqual(result, expected)
}
```

### Running Tests
```bash
make test              # Run all tests
xcodebuild test \      # Run specific test class
  -scheme PermissionPilot \
  -only-testing:PermissionPilotTests/PolicyEngineTests
```

### Coverage
```bash
make coverage          # Generate coverage report
```

## Documentation Standards

### Code Comments
- Only explain WHY, not WHAT
- Keep comments short (1-2 lines)
- Update when code changes

### README Updates
- Update if user-facing changes
- Keep examples current
- Document new features

### Architecture Changes
- Update ARCHITECTURE.md
- Add diagrams if helpful
- Document decisions in comments

## Security Considerations

**Never**:
- Bypass accessibility permission checks
- Add privilege escalation
- Disable security features
- Add dependencies without security review

**Always**:
- Test with untrusted apps
- Verify no SIP tampering
- Check for TCC database modifications
- Review Accessibility API usage

## Performance Guidelines

Target metrics:
- Idle CPU: <3%
- Memory: <200MB
- Detection latency: <500ms
- Click execution: <1s

Profile changes:
```bash
# In Xcode: Product → Profile
# Use System Trace instrument
# Check CPU time, memory growth
```

## Reporting Issues

Found a bug?

1. **Check existing issues**: Search first
2. **Create detailed report**:
   - Title: Concise description
   - Steps to reproduce
   - Expected vs actual behavior
   - macOS version and hardware
   - Screenshots if applicable
3. **Security issues**: Email security@permissionpilot.app (private)

## Pull Request Checklist

Before submitting:

- [ ] Code follows style guidelines (`make format`)
- [ ] No new warnings (`make lint`)
- [ ] Tests added/updated
- [ ] All tests pass (`make test`)
- [ ] Documentation updated
- [ ] Commit messages are clear
- [ ] No breaking changes (or documented)
- [ ] Benchmarks checked (if performance-related)

## Git Conventions

### Branch Names
```
feature/dialog-detection      ✓
feature/add-ocr              ✓
fix/button-ranking           ✓
docs/update-architecture     ✓
refactor/policy-engine       ✓

Feature/New-Thing            ✗ (use lowercase)
add-feature                  ✗ (missing prefix)
```

### Commit Messages
```
Add OCR fallback for dialog detection        ✓

Add OCR. Fixes bug. Also refactored stuff.  ✗ (too vague)
```

## Code Examples

### Good Pattern
```swift
// Clear, focused function
func evaluateDialogSafety(_ dialog: DetectedDialog) -> Double {
    var score: Double = 0.5
    
    let fullText = (dialog.windowTitle + " " + dialog.dialogText).lowercased()
    
    if hasDangerousKeywords(fullText) {
        score -= 0.3
    }
    
    if hasSafePermission(fullText) {
        score += 0.2
    }
    
    return max(0, min(1, score))
}
```

### Anti-Pattern
```swift
// Too complex, unclear intent
func evaluate(_ d: DetectedDialog) -> Double {
    var s = 0.5
    let t = (d.windowTitle + " " + d.dialogText).lowercased()
    s += t.contains("delete") ? -0.3 : 0
    s += t.contains("allow") ? 0.2 : 0
    s += d.buttons.count > 2 ? -0.1 : 0
    return max(0, min(1, s))
}
```

## Questions?

- **Documentation**: Check README.md, ARCHITECTURE.md
- **Discussions**: GitHub Discussions
- **Email**: dev@permissionpilot.app

## License

By contributing, you agree your code is licensed under the project's license (MIT or Commercial).

---

**Thank you for contributing!** Your work helps make PermissionPilot better for everyone.
