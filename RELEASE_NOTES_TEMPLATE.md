# Release Notes Template

Use this template for creating release notes for each version.

---

## [Version X.Y.Z] - YYYY-MM-DD

### 🎉 Highlights

Brief highlight of the major features or improvements in this release.

- ✨ **Feature Name**: One-line description
- 🚀 **Feature Name**: One-line description
- 🔒 **Security Fix**: One-line description

---

### ✨ New Features

#### Major Features
- **Feature Name** (#123) — Full description of what was added and why
- **Feature Name** (#456) — Full description

#### Minor Features
- Feature brief
- Feature brief

---

### 🐛 Bug Fixes

- **Fix name** (#789) — Description of what was broken and how it's fixed
- **Fix name** (#012) — Description
- **Fix name** — Minor bug fix

---

### 🔒 Security

- **[SECURITY] Vulnerability Name** — Description and impact
  - Severity: Critical/High/Medium/Low
  - Affected versions: X.Y.Z and earlier
  - Fix: Brief description of the fix
  - Patch: If applicable

---

### ⚡ Performance

- Improvement name and metrics
  - Before: X ms
  - After: Y ms (Z% faster)

---

### 📚 Documentation

- Updated: Feature guides, API documentation, examples
- Added: New troubleshooting section, performance tuning guide
- Improved: Clarity and completeness

---

### 🔄 Breaking Changes

⚠️ If there are breaking changes, list them clearly:

- **Change**: Old behavior → New behavior
  - Migration: How to update code
  - Reason: Why this change was necessary

---

### 🧪 Testing

- New tests added: X
- Test coverage: X%
- All tests passing: ✅

---

### 🙏 Contributors

Thanks to everyone who contributed to this release:

- [@username1](https://github.com/username1) — Feature implementation
- [@username2](https://github.com/username2) — Bug fix and tests
- [@username3](https://github.com/username3) — Documentation improvements

---

### 📥 Installation

**Download**
- [PermissionPilot.dmg](https://github.com/ChaitanyaJoshi1769/PermissionPilot/releases/download/vX.Y.Z/PermissionPilot.dmg)

**Build from source**
```bash
git clone https://github.com/ChaitanyaJoshi1769/PermissionPilot.git
git checkout vX.Y.Z
./Scripts/build.sh release
```

**Homebrew** (when available)
```bash
brew install permissionpilot
brew upgrade permissionpilot
```

---

### 📋 What's Next

Sneak peek at the roadmap:
- Next version focus
- Community requests being prioritized
- Planned features

---

### 🔗 Links

- [Full Changelog](CHANGELOG.md)
- [Compare versions](https://github.com/ChaitanyaJoshi1769/PermissionPilot/compare/vX.Y.W...vX.Y.Z)
- [GitHub Discussions](https://github.com/ChaitanyaJoshi1769/PermissionPilot/discussions)

---

### Known Issues

If any known issues exist in this release:
- Issue description and workaround
- Expected fix in next release

---

---

## Release Notes Examples

### Example 1: Major Feature Release

```
## [2.0.0] - 2024-09-15

### 🎉 Highlights

PermissionPilot 2.0 introduces machine learning-powered dialog 
classification and iOS companion app, plus significant performance 
improvements.

- 🧠 **ML Dialog Classifier**: Intelligent dialog type prediction
- 📱 **iOS Companion**: iPhone/iPad remote control and stats
- ⚡ **50% Faster**: Optimized detection and policy evaluation

### ✨ New Features

#### Major Features
- **Machine Learning Classifier** (#456) — Trained model predicts 
  dialog types with 95% accuracy, enabling smarter policies
- **iOS Companion App** (#789) — View stats, manage policies, 
  control automation from iPhone/iPad via iCloud sync

#### Minor Features
- macOS Sonoma support
- Dark mode for dashboard
- Export logs to CSV/JSON

### 🐛 Bug Fixes

- Fixed OCR occasionally failing on non-ASCII text (#234)
- Fixed daemon crash on rapid dialog sequences (#567)
- Fixed policy regex parsing edge cases (#890)

### ⚡ Performance

- Detection latency: 210ms → 105ms (2x faster)
- Policy evaluation: 42ms → 18ms (2.3x faster)
- Memory overhead: 85MB → 65MB (24% reduction)

### 🙏 Contributors

- [@alice](https://github.com/alice) — ML classifier implementation
- [@bob](https://github.com/bob) — iOS app development
- [@charlie](https://github.com/charlie) — Performance profiling
- [@diana](https://github.com/diana) — Bug fixes and tests
```

### Example 2: Patch/Bug Fix Release

```
## [1.0.1] - 2024-06-20

### 🎉 Highlights

Critical bug fix and security patch. All users should upgrade.

### 🐛 Bug Fixes

- **[CRITICAL] Memory leak in OCR pipeline** (#234) — Fixed 
  dangling references that caused 100MB+ leak after 48 hours
- Fixed daemon hang on macOS Ventura when multiple dialogs appear
- Fixed crash when policy JSON contains unicode characters

### 🔒 Security

- **[SECURITY] OCR screenshot data not deleted** (#567) — 
  Screenshots were cached on disk indefinitely. Now deleted 
  after processing.
  - Severity: High
  - Affected: 1.0.0
  - Fix: Immediate deletion of OCR cache files

### 🙏 Contributors

- [@maintainer](https://github.com/maintainer) — All fixes
- [@security-researcher](https://github.com/security-researcher) — 
  Reported security issue responsibly
```

---

## Release Notes Guidelines

### Writing
- Be clear and concise
- Use active voice
- Explain the "why" for significant changes
- Link to related issues/PRs (#123)
- Credit contributors by username

### Organization
- Highlights first (what users care about)
- Features second
- Bug fixes third
- Security critical
- Performance improvements
- Documentation changes

### Tone
- Professional but friendly
- Celebrate contributions
- Be honest about limitations
- Avoid hype; let features speak

### Format
- Use emojis consistently
- Group related items
- Bold important items
- Link to GitHub discussions for feedback

---

## Automated Release Notes

Future: We'll implement automated release notes generation from:
- Commit messages
- PR titles
- Issue labels
- Merge commit structure

This template documents the structure we'll generate to.

---

## Questions?

See [CONTRIBUTING.md](CONTRIBUTING.md#release-process) for the full release workflow.
