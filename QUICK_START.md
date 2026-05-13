# Quick Start Guide

Get PermissionPilot up and running in **5 minutes**.

## For Users 👤

### Installation

```bash
# Option 1: Download DMG (Recommended)
# Visit: https://github.com/ChaitanyaJoshi1769/PermissionPilot/releases
# Download latest PermissionPilot.dmg

# Option 2: Build from source (see Developer section)
```

### Setup

1. Open `PermissionPilot.dmg`
2. Drag to `/Applications`
3. Launch the app
4. Grant Accessibility permission (System Settings → Privacy & Security → Accessibility)
5. ✅ Done!

---

## For Developers 👨‍💻

### Prerequisites

```bash
# Check macOS version
sw_vers  # Should be 13.0+

# Install Xcode
xcode-select --install
```

### Setup Development Environment

```bash
# Clone the repository
git clone https://github.com/ChaitanyaJoshi1769/PermissionPilot.git
cd PermissionPilot

# Run setup script (installs tools, sets up git hooks)
./Scripts/setup-dev.sh

# Or manually install tools
brew install swiftformat swiftlint pre-commit
```

### Build & Test

```bash
# Build debug version
make build

# Run tests
make test

# Format code
make format

# Lint code
make lint

# All checks in one command
make all
```

### Running the App

```bash
# Build and launch
make run

# Or manually
make build
open build/DerivedData/Build/Products/Debug/PermissionPilot.app
```

---

## Key Commands

| Command | Description |
|---------|-------------|
| `make build` | Build debug version |
| `make release` | Build release version |
| `make test` | Run all tests |
| `make coverage` | Generate coverage report |
| `make format` | Format code with SwiftFormat |
| `make lint` | Lint code with SwiftLint |
| `make clean-lint` | Auto-fix linting issues |
| `make install` | Install to /Applications |
| `make uninstall` | Remove from /Applications |
| `make clean` | Remove build artifacts |
| `make all` | Full pipeline: clean, format, lint, test, build |

---

## Project Structure

```
PermissionPilot/
├── Sources/                    # Swift source code
│   ├── Core/                  # Core models & detection
│   ├── Accessibility/         # Accessibility API wrapper
│   ├── OCR/                   # Vision Framework OCR
│   ├── Policy/                # Policy engine & trust scoring
│   ├── Buttons/               # Button detection & ranking
│   ├── Automation/            # Automation engine
│   ├── Logging/               # Database & logging
│   └── App/                   # SwiftUI app & dashboard
├── Tests/                      # Unit tests
├── Configuration/              # Config files (plist, JSON)
├── Scripts/                    # Build & deployment scripts
├── .github/                    # GitHub Actions workflows
├── docs/                       # GitHub Pages site
├── Makefile                    # Build commands
└── README.md                   # Full documentation
```

---

## Development Workflow

### 1. Create a Branch

```bash
git checkout -b feature/your-feature-name
```

Branch naming conventions:
- `feature/...` — New features
- `fix/...` — Bug fixes
- `docs/...` — Documentation
- `test/...` — Tests
- `refactor/...` — Code improvements

### 2. Make Changes

```bash
# Edit files...

# Format and lint
make format
make lint

# Run tests
make test

# Build to verify
make build
```

### 3. Commit Changes

```bash
# Stage changes
git add .

# Commit (pre-commit hooks will run automatically)
git commit -m "feat: Add your feature description"

# Pre-commit hooks will automatically:
# ✓ Format code
# ✓ Lint
# ✓ Check for large files
# ✓ Check for secrets
```

### 4. Push and Create PR

```bash
git push origin feature/your-feature-name
```

Then create a PR on GitHub with:
- Clear title (under 70 characters)
- Description of what changed
- Testing notes
- Checklist items completed

---

## Testing

### Run Tests

```bash
# All tests
make test

# Specific test class
xcodebuild test -scheme PermissionPilot \
  -only-testing:PermissionPilotTests/PolicyEngineTests

# With coverage
make coverage
```

### Write Tests

```swift
// Tests/PolicyEngineTests.swift

func testFeatureDoesXWhenYCondition() {
    // Arrange: Set up test data
    let input = setupTestData()
    
    // Act: Execute the code
    let result = functionUnderTest(input)
    
    // Assert: Verify the result
    XCTAssertEqual(result, expected)
}
```

See [CONTRIBUTING.md](CONTRIBUTING.md#testing-guidelines) for detailed guidelines.

---

## Debugging

### Check Logs

```bash
# View daemon logs
tail -f ~/Library/Logs/PermissionPilot/daemon.log

# Stream all logs
log stream --predicate 'process == "PermissionPilot"' --level debug
```

### Enable Debug Mode

```bash
# Enable verbose logging
defaults write com.permissionpilot.app DebugLogging -bool true

# Disable
defaults write com.permissionpilot.app DebugLogging -bool false
```

### Profile Performance

```bash
# Build and open in Instruments
xcodebuild build -scheme PermissionPilot
open -a Instruments build/PermissionPilot.app

# Then: Product → Profile (in Xcode)
```

---

## Git Hooks

Pre-commit hooks automatically run on every commit:

```bash
# View installed hooks
cat .git/hooks/pre-commit

# Run hooks manually on all files
pre-commit run --all-files

# Skip hooks (not recommended)
git commit --no-verify
```

---

## Common Issues

### Build fails with "Xcode not found"

```bash
xcode-select --install
sudo xcode-select --reset
```

### Tests fail with permission errors

```bash
# Grant Accessibility permission
System Settings → Privacy & Security → Accessibility
# Add Terminal if not already there
```

### Pre-commit hooks slow to run

Hooks run on first commit. Subsequent commits are faster due to caching.

---

## Need Help?

- **[Full Documentation](README.md)** — Complete feature list
- **[Architecture](ARCHITECTURE.md)** — System design
- **[Contributing](CONTRIBUTING.md)** — Contribution guidelines
- **[FAQ](FAQ.md)** — Common questions
- **[Discussions](https://github.com/ChaitanyaJoshi1769/PermissionPilot/discussions)** — Ask the community
- **[Issues](https://github.com/ChaitanyaJoshi1769/PermissionPilot/issues)** — Report problems

---

**Happy coding! 🚀**
