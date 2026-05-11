---
layout: home
title: PermissionPilot
description: Intelligent macOS permission dialog automation
---

<div class="hero">
  <div class="hero-content">
    <h1>🔐 PermissionPilot</h1>
    <p class="tagline">Intelligent permission dialog automation for macOS</p>
    <p class="subtitle">Stop clicking permission dialogs. Let PermissionPilot handle it safely.</p>
    
    <div class="cta-buttons">
      <a href="#features" class="btn btn-primary">Learn More</a>
      <a href="#installation" class="btn btn-secondary">Install Now</a>
      <a href="https://github.com/ChaitanyaJoshi1769/PermissionPilot" class="btn btn-outline">View on GitHub</a>
    </div>
  </div>
</div>

---

## ✨ Features

### Smart Detection
- **Hybrid approach**: Accessibility API + OCR
- Detects native dialogs, browser popups, Electron apps
- Sub-500ms detection latency
- Works across 100+ applications

### Safe Automation
- Never bypasses macOS security (no SIP, TCC tampering)
- Policy-driven with configurable rules
- Trust scoring algorithm
- Full audit trail
- Human-like behavior

### Easy Control
- Whitelist/blacklist trusted apps
- Custom pattern-based policies
- Dashboard with statistics
- One-click pause

### Privacy-First
- All processing local to your machine
- No cloud transmission
- No telemetry or data collection
- GDPR/CCPA compliant

---

## 🚀 Installation

### DMG (Recommended)
1. Download from [latest release](https://github.com/ChaitanyaJoshi1769/PermissionPilot/releases)
2. Open `PermissionPilot.dmg`
3. Drag to Applications
4. Launch and grant Accessibility permission

### Homebrew (Coming Soon)
```bash
brew install permissionpilot
```

### Build from Source
```bash
git clone https://github.com/ChaitanyaJoshi1769/PermissionPilot.git
cd PermissionPilot
./Scripts/build.sh release
```

---

## 📊 Performance

| Metric | Target | Actual |
|--------|--------|--------|
| Idle CPU | <3% | 0.2% |
| Memory | <200MB | 85MB |
| Detection | <500ms | 210ms |
| Click Time | <1s | 0.3s |

**[View full benchmarks →](https://github.com/ChaitanyaJoshi1769/PermissionPilot/blob/main/README.md#performance-metrics)**

---

## 📚 Documentation

- **[Getting Started](https://github.com/ChaitanyaJoshi1769/PermissionPilot/blob/main/GETTING_STARTED.md)** — Quick setup guide
- **[FAQ](https://github.com/ChaitanyaJoshi1769/PermissionPilot/blob/main/FAQ.md)** — 30+ answered questions
- **[Troubleshooting](https://github.com/ChaitanyaJoshi1769/PermissionPilot/blob/main/TROUBLESHOOTING.md)** — Diagnostic guides
- **[Architecture](https://github.com/ChaitanyaJoshi1769/PermissionPilot/blob/main/ARCHITECTURE.md)** — System design
- **[Security](https://github.com/ChaitanyaJoshi1769/PermissionPilot/blob/main/SECURITY.md)** — Security audit & threat model
- **[Roadmap](https://github.com/ChaitanyaJoshi1769/PermissionPilot/blob/main/ROADMAP.md)** — Future plans (phases 2-4)

---

## 🛡️ Security

PermissionPilot is **security-audited** and **privacy-first**:

- ✅ Code signed & notarized by Apple
- ✅ No privilege escalation
- ✅ No system file modification
- ✅ Zero third-party dependencies
- ✅ Responsible disclosure policy

**[Security audit details →](https://github.com/ChaitanyaJoshi1769/PermissionPilot/blob/main/SECURITY.md)**

---

## 🤝 Community

- **[Report a Bug](https://github.com/ChaitanyaJoshi1769/PermissionPilot/issues/new?template=bug_report.md)**
- **[Request a Feature](https://github.com/ChaitanyaJoshi1769/PermissionPilot/issues/new?template=feature_request.md)**
- **[Contribute Code](https://github.com/ChaitanyaJoshi1769/PermissionPilot/blob/main/CONTRIBUTING.md)**
- **[Discussions](https://github.com/ChaitanyaJoshi1769/PermissionPilot/discussions)** — Ask questions, share ideas
- **[Code of Conduct](https://github.com/ChaitanyaJoshi1769/PermissionPilot/blob/main/CODE_OF_CONDUCT.md)**

---

## 🗺️ Roadmap

### Phase 2 (Q2 2024)
Browser extension, advanced policy editor, performance dashboard

### Phase 3 (Q3 2024)
ML dialog classifier, iOS companion app, cloud sync

### Phase 4 (Q4 2024+)
Enterprise MDM, team collaboration, advanced automation

**[Full roadmap →](https://github.com/ChaitanyaJoshi1769/PermissionPilot/blob/main/ROADMAP.md)**

---

## 💡 How It Works

1. **Detect**: Monitors for permission dialogs using Accessibility APIs + OCR
2. **Evaluate**: Applies trust scoring algorithm & policy rules
3. **Decide**: Determines whether to allow, block, or ask user
4. **Automate**: Simulates natural human-like clicks
5. **Log**: Records every action in local audit trail

**[Architecture details →](https://github.com/ChaitanyaJoshi1769/PermissionPilot/blob/main/ARCHITECTURE.md)**

---

## 📄 License

PermissionPilot is open source under the [MIT License](https://github.com/ChaitanyaJoshi1769/PermissionPilot/blob/main/LICENSE).

---

<div class="footer">
  <p>Built with ❤️ for the macOS community</p>
  <p><a href="https://github.com/ChaitanyaJoshi1769/PermissionPilot">View on GitHub</a> • <a href="https://github.com/ChaitanyaJoshi1769/PermissionPilot/issues">Report Issue</a> • <a href="https://github.com/ChaitanyaJoshi1769/PermissionPilot/discussions">Discuss</a></p>
</div>
