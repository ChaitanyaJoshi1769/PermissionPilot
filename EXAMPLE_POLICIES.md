# Example Policies

Ready-to-use policies for different workflows and use cases. Copy, customize, and use in your `~/.application-support/PermissionPilot/policies.json`.

## 📋 Quick Reference

- [Developer Setup](#developer-setup) — Safe for coding
- [Privacy Mode](#privacy-mode) — Maximum privacy
- [Gaming Mode](#gaming-mode) — Minimal interruptions
- [Work Mode](#work-mode) — Corporate environment
- [Parental Controls](#parental-controls) — Restricted access
- [Permissive Mode](#permissive-mode) — Minimal restrictions

---

## Developer Setup

Optimized for Swift/Xcode development. Auto-approves Xcode and system tools, blocks everything suspicious.

```json
{
  "name": "Developer Setup",
  "policies": [
    {
      "name": "Trusted Developer Tools",
      "apps": [
        "com.apple.dt.Xcode",
        "com.apple.dt.XCODELauncher",
        "com.apple.com.apple.CoreSimulator.CoreSimulatorService",
        "com.jetbrains.CLion",
        "com.jetbrains.AppCode",
        "com.microsoft.VSCode",
        "com.tokaido.Cursor"
      ],
      "action": "ALLOW",
      "priority": 100
    },
    {
      "name": "Block Installers from Unknown Apps",
      "patterns": [
        {"keyword": "install", "action": "ASK"},
        {"keyword": "setup", "action": "ASK"},
        {"keyword": "license agreement", "action": "ASK"}
      ],
      "enabled": true,
      "priority": 80
    },
    {
      "name": "Allow Safe System Dialogs",
      "patterns": [
        {"keyword": "notification", "action": "ALLOW"},
        {"keyword": "allow", "action": "ALLOW"},
        {"keyword": "permission", "action": "ALLOW"}
      ],
      "enabled": true,
      "priority": 50
    }
  ],
  "whitelist": [
    {"bundleID": "com.apple.finder", "name": "Finder"},
    {"bundleID": "com.apple.mail", "name": "Mail"},
    {"bundleID": "com.google.Chrome", "name": "Chrome"},
    {"bundleID": "com.apple.Terminal", "name": "Terminal"}
  ],
  "settings": {
    "confidenceThreshold": 0.85,
    "trustScoreThreshold": 0.6
  }
}
```

---

## Privacy Mode

Maximum privacy. Blocks everything not explicitly whitelisted. Asks for everything else.

```json
{
  "name": "Privacy Mode (Paranoid)",
  "policies": [
    {
      "name": "Block Everything Except Whitelist",
      "trustThreshold": 0.95,
      "action": "BLOCK",
      "enabled": true,
      "priority": 100
    },
    {
      "name": "Ask for Unknown Apps",
      "trustThreshold": 0.5,
      "action": "ASK",
      "enabled": true,
      "priority": 50
    },
    {
      "name": "Block Dangerous Operations",
      "patterns": [
        {"keyword": "delete", "action": "BLOCK"},
        {"keyword": "uninstall", "action": "BLOCK"},
        {"keyword": "reset", "action": "BLOCK"},
        {"keyword": "disable security", "action": "BLOCK"},
        {"keyword": "admin password", "action": "BLOCK"}
      ],
      "enabled": true,
      "priority": 90
    }
  ],
  "whitelist": [
    {"bundleID": "com.apple.finder"},
    {"bundleID": "com.apple.mail"},
    {"bundleID": "com.apple.Safari"}
  ],
  "blacklist": [
    {"bundleID": "unknown", "reason": "Unsigned/unknown app"}
  ],
  "settings": {
    "confidenceThreshold": 0.95,
    "trustScoreThreshold": 0.9
  }
}
```

---

## Gaming Mode

Minimal interruptions. Auto-approves dialogs, only asks for critical security.

```json
{
  "name": "Gaming Mode",
  "policies": [
    {
      "name": "Auto-Approve Safe Dialogs",
      "patterns": [
        {"keyword": "notification", "action": "ALLOW"},
        {"keyword": "allow once", "action": "ALLOW"},
        {"keyword": "continue", "action": "ALLOW"},
        {"keyword": "ok", "action": "ALLOW"}
      ],
      "enabled": true,
      "priority": 100
    },
    {
      "name": "Block Dangerous Only",
      "patterns": [
        {"keyword": "delete", "action": "BLOCK"},
        {"keyword": "uninstall", "action": "BLOCK"},
        {"keyword": "reset", "action": "BLOCK"},
        {"keyword": "system critical", "action": "BLOCK"}
      ],
      "enabled": true,
      "priority": 95
    },
    {
      "name": "Ask Everything Else",
      "trustThreshold": 0.4,
      "action": "ASK",
      "enabled": true,
      "priority": 10
    }
  ],
  "whitelist": [
    {"bundleID": "com.apple.find"},
    {"bundleID": "com.google.Chrome"},
    {"bundleID": "com.Discord.Discord"},
    {"bundleID": "com.nvidia.GeForceNOW"}
  ],
  "settings": {
    "confidenceThreshold": 0.7,
    "enableOCR": true
  }
}
```

---

## Work Mode

Corporate environment. Strict controls on unverified apps, but flexible for work tools.

```json
{
  "name": "Work Mode (Corporate)",
  "policies": [
    {
      "name": "Trusted Work Applications",
      "apps": [
        "com.microsoft.Outlook",
        "com.microsoft.Teams",
        "com.slack",
        "com.zoom.xos",
        "com.google.Chrome",
        "com.notion",
        "com.asana"
      ],
      "action": "ALLOW",
      "priority": 100
    },
    {
      "name": "Block Destructive Operations",
      "patterns": [
        {"keyword": "delete", "action": "BLOCK"},
        {"keyword": "uninstall", "action": "BLOCK"},
        {"keyword": "reset", "action": "BLOCK"},
        {"keyword": "format", "action": "BLOCK"}
      ],
      "enabled": true,
      "priority": 90
    },
    {
      "name": "Ask for Unknown Apps",
      "trustThreshold": 0.5,
      "action": "ASK",
      "enabled": true,
      "priority": 40
    }
  ],
  "blacklist": [
    {"bundleID": "com.utorrent", "reason": "Corporate policy"},
    {"bundleID": "com.limewire", "reason": "Corporate policy"}
  ],
  "settings": {
    "confidenceThreshold": 0.85,
    "enableScreenshots": true,
    "logRetentionDays": 180
  }
}
```

---

## Parental Controls

Restricted access. Only whitelisted apps, blocks downloads and installations.

```json
{
  "name": "Parental Controls",
  "policies": [
    {
      "name": "Whitelist Only",
      "trustThreshold": 0.99,
      "action": "BLOCK",
      "enabled": true,
      "priority": 100
    },
    {
      "name": "Block Installations",
      "patterns": [
        {"keyword": "install", "action": "BLOCK"},
        {"keyword": "setup", "action": "BLOCK"},
        {"keyword": "download", "action": "BLOCK"},
        {"keyword": "uninstall", "action": "BLOCK"}
      ],
      "enabled": true,
      "priority": 95
    }
  ],
  "whitelist": [
    {"bundleID": "com.apple.Safari", "name": "Safari"},
    {"bundleID": "com.google.Chrome", "name": "Chrome"},
    {"bundleID": "com.apple.mail", "name": "Mail"},
    {"bundleID": "com.apple.Finder", "name": "Finder"},
    {"bundleID": "com.minecraft.LauncherApp", "name": "Minecraft"},
    {"bundleID": "com.roblox", "name": "Roblox"}
  ],
  "settings": {
    "confidenceThreshold": 0.95,
    "trustScoreThreshold": 0.95
  }
}
```

---

## Permissive Mode

Minimal restrictions. Useful for testing apps or when you trust everything.

```json
{
  "name": "Permissive Mode (Low Safety)",
  "policies": [
    {
      "name": "Block Only Extreme Dangers",
      "patterns": [
        {"keyword": "disable security", "action": "BLOCK"},
        {"keyword": "remove protection", "action": "BLOCK"},
        {"keyword": "admin password", "action": "BLOCK"}
      ],
      "enabled": true,
      "priority": 100
    },
    {
      "name": "Allow Everything Else",
      "trustThreshold": 0.0,
      "action": "ALLOW",
      "enabled": true,
      "priority": 10
    }
  ],
  "settings": {
    "confidenceThreshold": 0.5,
    "trustScoreThreshold": 0.2
  }
}
```

---

## Customization Guide

### Step 1: Choose a Base Policy
Start with one of the above as a template.

### Step 2: Adjust Thresholds
```json
"settings": {
  "confidenceThreshold": 0.85,    // Lower = click more dialogs
  "trustScoreThreshold": 0.6      // Lower = trust more apps
}
```

### Step 3: Customize Whitelist
Add your most-used apps:
```bash
# Find bundle IDs
mdls -name kMDItemCFBundleIdentifier -r /Applications/YourApp.app
```

### Step 4: Test
- Enable policy in PermissionPilot UI
- Observe behavior over a few days
- Adjust as needed

---

## Policy Syntax Reference

```json
{
  "policies": [
    {
      "name": "Policy name",
      "description": "Optional description",
      
      // Application-based rule
      "apps": ["com.example.app"],
      
      // Pattern-based rule
      "patterns": [
        {"keyword": "delete", "action": "BLOCK"}
      ],
      
      // Trust threshold rule
      "trustThreshold": 0.5,
      
      // Action: ALLOW, BLOCK, or ASK
      "action": "ALLOW",
      
      // Enable/disable this policy
      "enabled": true,
      
      // Rule priority (higher = evaluated first)
      "priority": 100
    }
  ],
  
  "whitelist": [
    {"bundleID": "com.apple.finder", "name": "Finder"}
  ],
  
  "blacklist": [
    {"bundleID": "com.malware", "name": "Malware"}
  ],
  
  "settings": {
    "confidenceThreshold": 0.85,
    "trustScoreThreshold": 0.6,
    "maxRetries": 3,
    "clickTimeoutSeconds": 30
  }
}
```

---

## Common Use Cases

### "Allow Slack but ask about everything else"
```json
{
  "name": "Slack Primary",
  "apps": ["com.slack"],
  "action": "ALLOW",
  "priority": 100
}
```

### "Block all downloads"
```json
{
  "name": "No Downloads",
  "patterns": [
    {"keyword": "download", "action": "BLOCK"},
    {"keyword": "save file", "action": "BLOCK"}
  ]
}
```

### "Auto-approve only from Apple"
```json
{
  "apps": [
    "com.apple.finder",
    "com.apple.mail",
    "com.apple.Safari",
    "com.apple.Terminal"
  ],
  "action": "ALLOW",
  "priority": 90
}
```

---

## Tips

1. **Start permissive, tighten over time** — It's easier to restrict later than to allow unsafely
2. **Monitor logs** — Check what's being blocked/allowed in the Logs tab
3. **Use specific keywords** — Exact matches are more reliable
4. **Priority matters** — Higher priority rules are checked first
5. **Test before relying** — Adjust settings over a few days

---

## Questions?

- Read [FAQ.md](FAQ.md#configuration-faq)
- Check [CONTRIBUTING.md](CONTRIBUTING.md#advanced-configuration)
- Ask in [Discussions](https://github.com/ChaitanyaJoshi1769/PermissionPilot/discussions)

---

**Enjoying these policies?** Star the repo ⭐ and share with others!
