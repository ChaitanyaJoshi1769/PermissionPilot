# PermissionPilot: Implementation Guide

## Getting Started

This guide covers everything needed to build, test, and deploy PermissionPilot.

## Prerequisites

- **macOS**: 13.0 or later (Ventura minimum)
- **Xcode**: 15.0 or later
- **Swift**: 5.9+
- **Apple Developer ID**: For signing & notarization

### System Requirements

```bash
# Verify Xcode installation
xcode-select --install

# Check Swift version
swift --version  # Should be 5.9+

# Verify macOS version
sw_vers -productVersion  # Should be 13.0+
```

## Project Setup

### 1. Clone & Initialize

```bash
git clone https://github.com/yourusername/PermissionPilot.git
cd PermissionPilot

# Initialize submodules (if any)
git submodule update --init --recursive

# Make scripts executable
chmod +x Scripts/*.sh
```

### 2. Create Xcode Project

The `Xcode/PermissionPilot.xcodeproj` is pre-configured. To recreate:

```bash
# Create new project (optional)
xcodebuild -create-default-code-sign-identity

# Verify project structure
open Xcode/PermissionPilot.xcodeproj
```

### 3. Configure Signing Identity

In Xcode:
1. **Targets** → **PermissionPilot**
2. **Build Settings** → Search "Code Sign"
3. Set **Code Sign Identity** to your Developer ID
4. Set **Team ID** to your Apple Team ID

```bash
# Or from command line
defaults write com.permissionpilot.app TeamIdentifier "ABCD123456"
```

## Building

### Debug Build (for development)

```bash
./Scripts/build.sh debug

# Output: build/DerivedData/...
```

### Release Build (for distribution)

```bash
./Scripts/build.sh release

# Output: build/PermissionPilot.xcarchive
```

### Build from Xcode

1. **Product** → **Build** (⌘B)
2. Wait for build to complete
3. **Product** → **Run** (⌘R) to test

## Testing

### Run Unit Tests

```bash
xcodebuild test -scheme PermissionPilot

# Or from Xcode: ⌘U
```

### Run Specific Test

```bash
xcodebuild test -scheme PermissionPilot \
    -only-testing:PermissionPilotTests/PolicyEngineTests
```

### Coverage Report

```bash
xcodebuild test \
    -scheme PermissionPilot \
    -enableCodeCoverage YES

# Coverage: build/DerivedData/.../Logs/Build/coverage.profdata
```

### Manual Testing Checklist

- [ ] Dialog detection (test with native macOS dialog)
- [ ] Button ranking (verify "Allow Once" prioritized)
- [ ] OCR fallback (disable AX, verify OCR works)
- [ ] Policy engine (whitelist, blacklist, rules)
- [ ] Automation (click buttons, verify logs)
- [ ] Logging (verify audit trail)
- [ ] Settings persistence (change settings, restart)
- [ ] Accessibility permission (request flow)
- [ ] Multi-monitor support
- [ ] Dark/light mode toggle

## Debugging

### Enable Debug Logging

```bash
defaults write com.permissionpilot.app DebugLogging -bool true

# Then restart app and check console output
```

### View Console Logs

```bash
# In Xcode
View → Debug Area → Show Console (⇧⌘C)

# Or from Terminal
log stream --predicate 'eventMessage contains "PermissionPilot"'
```

### Database Inspection

```bash
# Query audit logs
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db

# Example queries
sqlite> SELECT COUNT(*) FROM automation_events;
sqlite> SELECT app_name, action_taken FROM automation_events LIMIT 5;
sqlite> SELECT * FROM automation_events WHERE confidence < 0.85;
```

### Performance Profiling

```bash
# In Xcode: Product → Profile (⌘I)
# Select "System Trace" instrument
# Look for:
# - CPU time
# - Memory growth
# - Disk I/O
```

## Code Style & Quality

### SwiftFormat

Install and format code:

```bash
# Install (if not installed)
brew install swiftformat

# Format all files
swiftformat Sources/ Tests/ --recursive

# Auto-format on save (Xcode integration)
# Xcode → Preferences → Text Editing → Editing
# Enable "Automatically format on save"
```

### SwiftLint

Check code quality:

```bash
# Install
brew install swiftlint

# Run linting
swiftlint lint Sources/

# Auto-fix
swiftlint lint --fix Sources/
```

### Test Coverage Target

Aim for >80% coverage:

```bash
# View coverage in Xcode
Product → Scheme → Edit Scheme → Test → Code Coverage
```

## Signing & Notarization

### Prerequisites

- Apple Developer ID certificate (in Keychain)
- App-specific password (from appleid.apple.com)
- Team ID

### Sign & Notarize

```bash
./Scripts/sign-and-notarize.sh \
    build/PermissionPilot.xcarchive \
    your@appleid.com \
    "app-specific-password" \
    "ABCD123456"
```

This script will:
1. Extract app from archive
2. Verify code signature
3. Create ZIP for notarization
4. Submit to Apple
5. Wait for notarization (30-60 minutes)
6. Staple notary ticket
7. Create DMG

### Manual Steps (if scripting fails)

```bash
# Extract
xcodebuild -exportArchive \
    -archivePath build/PermissionPilot.xcarchive \
    -exportOptionsPlist Configuration/ExportOptions.plist \
    -exportPath build/Export

# Verify signature
codesign -dvvv build/Export/PermissionPilot.app

# Create ZIP
ditto -c -k --keepParent \
    build/Export/PermissionPilot.app \
    build/PermissionPilot.zip

# Submit for notarization
xcrun notarytool submit build/PermissionPilot.zip \
    --apple-id your@appleid.com \
    --password "app-password" \
    --team-id "TEAMID" \
    --wait

# Staple
xcrun stapler staple build/Export/PermissionPilot.app
```

## Distribution

### Create DMG

```bash
./Scripts/create-dmg.sh

# Output: PermissionPilot.dmg
```

### Create ZIP Archive

```bash
cd build/Export
zip -r -y ../PermissionPilot-universal.zip PermissionPilot.app
```

### Create Homebrew Cask (Optional)

Create `homebrew-permissionpilot/Casks/permissionpilot.rb`:

```ruby
cask 'permissionpilot' do
  version '1.0.0'
  sha256 'xxxxx...'
  
  url "https://releases.permissionpilot.app/PermissionPilot-#{version}.dmg"
  
  app 'PermissionPilot.app'
  
  homepage 'https://permissionpilot.app'
end
```

## Continuous Integration

### GitHub Actions Workflow

Create `.github/workflows/build.yml`:

```yaml
name: Build & Test

on: [push, pull_request]

jobs:
  build:
    runs-on: macos-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Build
        run: ./Scripts/build.sh release
      
      - name: Test
        run: xcodebuild test -scheme PermissionPilot
      
      - name: Archive
        run: |
          cd build/DerivedData
          tar czf ../../PermissionPilot.tar.gz .
      
      - name: Upload Artifact
        uses: actions/upload-artifact@v3
        with:
          name: PermissionPilot-build
          path: PermissionPilot.tar.gz
```

## Deployment Checklist

Before releasing:

- [ ] Version bumped (Bundle Version, Short Version String)
- [ ] CHANGELOG.md updated
- [ ] All tests passing (100% on critical paths)
- [ ] Code signed with Developer ID
- [ ] Notarized by Apple
- [ ] DMG created and tested
- [ ] README reviewed
- [ ] Security review completed
- [ ] Privacy policy finalized
- [ ] Release notes written
- [ ] GitHub release created
- [ ] Homebrew cask updated (if applicable)

## Post-Release

### Monitor for Issues

```bash
# Check for crash reports
log stream --predicate 'process contains "PermissionPilot"' --level debug

# Monitor user feedback
# GitHub Issues, email, Twitter
```

### Version Updates

If fixing a critical bug:

1. Fix the issue
2. Increment patch version (1.0.0 → 1.0.1)
3. Rebuild & re-sign
4. Create new release
5. Update release notes

## Troubleshooting

### Build Failures

**Error**: "Code signing failed"
```bash
# Reset code signing
rm -rf ~/Library/Developer/Xcode/DerivedData/
killall -9 Xcode
xcode-select --reset
```

**Error**: "Module not found"
```bash
# Update dependencies
xcodebuild -resolvePackageDependencies
```

### Notarization Failures

**Error**: "The app is not signed"
```bash
# Re-sign before notarization
codesign -f --deep --sign "Developer ID Application" \
    build/Export/PermissionPilot.app
```

**Error**: "Invalid Team ID"
```bash
# Verify team ID
security find-identity -v -p codesigning
```

### Runtime Issues

**Dialog detection not working**
1. Verify Accessibility permission granted
2. Check `DebugLogging` output
3. Ensure dialog is not hidden/minimized
4. Test with native macOS dialog (Spotlight)

**Automation not executing**
1. Check button confidence score
2. Verify policy engine allowing automation
3. Test with whitelisted app
4. Check logs for errors

## Contributing

For contributors:

1. Fork the repository
2. Create feature branch: `git checkout -b feature/my-feature`
3. Make changes and test thoroughly
4. Commit: `git commit -am "Add my feature"`
5. Push: `git push origin feature/my-feature`
6. Create Pull Request

**Code Review Checklist**:
- [ ] Swift style compliant (SwiftFormat)
- [ ] No SwiftLint warnings
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No new dependencies
- [ ] Backward compatible

## Resources

- [Swift Documentation](https://developer.apple.com/documentation/swift)
- [Accessibility Framework](https://developer.apple.com/documentation/accessibility)
- [Vision Framework](https://developer.apple.com/documentation/vision)
- [SwiftUI](https://developer.apple.com/documentation/swiftui)
- [macOS Code Signing](https://developer.apple.com/support/code-signing/)

## Support

Questions? Contact:
- **Issues**: GitHub Issues
- **Discussions**: GitHub Discussions
- **Email**: support@permissionpilot.app

---

**Ready to build? Start with `./Scripts/build.sh debug` and open PermissionPilot.app!**
