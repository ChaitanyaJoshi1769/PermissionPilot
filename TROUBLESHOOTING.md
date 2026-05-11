# Troubleshooting Guide

## Installation & Setup

### PermissionPilot won't launch

**Symptoms**: App crashes immediately or doesn't appear in /Applications

**Solutions**:
1. Verify Xcode Command Line Tools are installed:
   ```bash
   xcode-select --install
   ```

2. Check that the app was installed correctly:
   ```bash
   ls -la /Applications/PermissionPilot.app
   ```

3. Try reinstalling:
   ```bash
   make clean
   make install
   ```

4. Check system logs:
   ```bash
   log stream --predicate 'eventMessage contains[cd] "PermissionPilot"' --level debug
   ```

### Accessibility permission prompt won't disappear

**Symptoms**: Accessibility permission request keeps appearing

**Solutions**:
1. Open System Settings → Privacy & Security → Accessibility
2. Look for "PermissionPilot" in the list
3. If it's already there, toggle it OFF then ON
4. Restart PermissionPilot:
   ```bash
   killall PermissionPilot
   open /Applications/PermissionPilot.app
   ```

5. If not in the list, grant permission manually:
   - Click the lock icon to unlock
   - Click the "+" button and select `PermissionPilot.app`
   - Confirm the prompt

### Can't grant Accessibility permission

**Symptoms**: Accessibility permission button is greyed out or unavailable

**Solutions**:
1. Disable System Integrity Protection (if you're comfortable doing so):
   - Restart in Recovery Mode (Cmd + R during startup)
   - Open Terminal
   - Run: `csrutil disable`
   - Restart

2. Or, use the command line to grant permission:
   ```bash
   # Add to Accessibility via TCC database (requires SIP disabled)
   # Better: manually grant via System Settings
   ```

3. Verify you're on macOS 13.0 or later:
   ```bash
   sw_vers
   ```

## Dialog Detection Issues

### PermissionPilot isn't detecting dialogs

**Symptoms**: Dialog detection is disabled or no dialogs are being detected

**Solutions**:
1. Verify the daemon is running:
   ```bash
   ps aux | grep PermissionPilot
   ```

2. Verify Accessibility permission is granted:
   - System Settings → Privacy & Security → Accessibility
   - Ensure "PermissionPilot" is in the list and enabled

3. Check if automation is paused:
   - Open PermissionPilot menu bar icon
   - Look for "Pause Automation" toggle—make sure it's OFF

4. Enable debug logging:
   - Check `~/Library/Logs/PermissionPilot/debug.log`
   ```bash
   tail -f ~/Library/Logs/PermissionPilot/debug.log
   ```

5. Try manually triggering a dialog:
   - Open System Preferences → Security & Privacy → General
   - This should trigger a standard macOS dialog
   - Check if PermissionPilot detects it

### OCR is not working

**Symptoms**: OCR fallback isn't detecting text in dialogs

**Solutions**:
1. Verify OCR is enabled:
   - PermissionPilot → Settings → OCR enabled?

2. Check Vision Framework availability:
   ```bash
   # Verify Vision framework is available on your system
   /usr/bin/swift -e 'import Vision; print("Vision available")'
   ```

3. Check image quality:
   - Enable screenshots in Settings
   - Review captured dialog images in audit logs
   - Poor image quality can reduce OCR confidence

4. Manually test OCR:
   ```bash
   # Create a test screenshot and analyze it
   screencapture -x test.png
   ```

5. Update macOS—OCR performance improves with newer versions

## Automation Issues

### Buttons aren't being clicked

**Symptoms**: PermissionPilot detects the dialog but doesn't click buttons

**Solutions**:
1. Check trust score:
   - Open Logs tab in dashboard
   - Verify trust score is ≥0.5 for click to occur

2. Verify button detection:
   - Enable screenshots in Settings
   - Check audit logs for button labels
   - Ensure the button text matches expected patterns

3. Check trust threshold policy:
   - Settings → Policies
   - Verify trustThreshold isn't too high (>0.8)

4. Try a trusted app:
   - Create a dialog from a whitelisted app (e.g., Finder, Mail)
   - PermissionPilot should auto-click these

5. Check confidence score:
   - Dialogs with <0.5 confidence are skipped
   - Review Settings → confidence threshold setting

### Clicks are happening too fast

**Symptoms**: PermissionPilot clicks buttons before they're ready to be clicked

**Solutions**:
1. Adjust timing in policy settings:
   - Increase `clickTimeoutSeconds` (default: 30s)

2. Disable automation temporarily and do it manually:
   - Toggle "Pause Automation" in menu bar

3. Check if app is responding slowly:
   - System monitor may be under load
   - Close other apps to free resources

4. Review click logs:
   - Check `~/Library/Logs/PermissionPilot/actions.log`
   - Look for timing information

### Wrong button is being clicked

**Symptoms**: PermissionPilot clicks a button but it's not the one you wanted

**Solutions**:
1. Check button ranking preferences:
   - Settings → Policy Rules
   - Review button priority ranking (Allow Once > Allow > OK > Continue)

2. Create a custom policy to block/allow specific buttons:
   ```json
   {
     "name": "Custom Button Rules",
     "patterns": [
       {
         "keyword": "Don't Allow",
         "action": "BLOCK"
       }
     ]
   }
   ```

3. Add the app to blacklist:
   - Settings → Blacklist
   - Add problematic app bundle ID

4. Enable screenshots and review audit logs:
   - Verify button text was recognized correctly

## Performance Issues

### High CPU usage

**Symptoms**: PermissionPilot consuming >20% CPU

**Solutions**:
1. Disable OCR if not needed:
   - Settings → OCR enabled? (toggle off)

2. Reduce polling frequency:
   - Settings → Detection interval (increase from default)

3. Check for dialog flood:
   - System → Activity Monitor
   - Verify only one PermissionPilot process is running
   - Kill any duplicates:
     ```bash
     killall PermissionPilot
     sleep 2
     open /Applications/PermissionPilot.app
     ```

4. Profile the app:
   - Xcode → Product → Profile
   - Use System Trace instrument
   - Check which functions are consuming CPU

### High memory usage

**Symptoms**: PermissionPilot using >300MB RAM

**Solutions**:
1. Clear audit logs:
   - Settings → Clear Logs
   - Or delete old entries: `rm ~/Library/Application\ Support/PermissionPilot/audit.db`

2. Disable screenshot capture:
   - Settings → Screenshots enabled? (toggle off)

3. Reduce log retention:
   - Settings → Log retention (default: 90 days)
   - Shorten to 30 days

4. Check for memory leaks:
   - Xcode → Product → Profile
   - Use Memory instrument
   - Check for retain cycles

## Database & Logging

### Audit log is too large

**Symptoms**: `~/Library/Application Support/PermissionPilot/audit.db` is very large (>100MB)

**Solutions**:
1. Clear old logs:
   - PermissionPilot → Settings → Clear Logs
   
2. Reduce retention:
   ```bash
   # Edit Preferences to reduce logRetentionDays from 90 to 30
   defaults write com.permissionpilot.app logRetentionDays -int 30
   ```

3. Manually delete database:
   ```bash
   rm ~/Library/Application\ Support/PermissionPilot/audit.db
   ```
   PermissionPilot will recreate it on next launch.

### Can't export logs

**Symptoms**: CSV/JSON export fails or produces empty file

**Solutions**:
1. Verify database exists:
   ```bash
   ls -lh ~/Library/Application\ Support/PermissionPilot/audit.db
   ```

2. Check file permissions:
   ```bash
   chmod 644 ~/Library/Application\ Support/PermissionPilot/audit.db
   ```

3. Try exporting to Desktop:
   - Logs tab → Export → Save to Desktop
   - This may have better permissions

## Policy & Rules

### Custom policies not applying

**Symptoms**: Policy changes don't take effect

**Solutions**:
1. Restart PermissionPilot:
   ```bash
   killall PermissionPilot
   open /Applications/PermissionPilot.app
   ```

2. Verify policy JSON is valid:
   ```bash
   # Check for syntax errors
   cat Configuration/example-policies.json | python3 -m json.tool
   ```

3. Check policy priority:
   - Higher priority rules evaluated first
   - Ensure your custom rule has higher priority than defaults

4. Enable debug logging to verify policy evaluation:
   ```bash
   log stream --predicate 'eventMessage contains[cd] "policy"' --level debug
   ```

## Advanced Debugging

### Enable verbose logging

```bash
# Enable debug logging
defaults write com.permissionpilot.app LogLevel -string DEBUG

# Tail logs in real-time
log stream --predicate 'process == "PermissionPilot"' --level debug
```

### Access diagnostic data

```bash
# Logs
tail -100 ~/Library/Logs/PermissionPilot/*.log

# Configuration
cat ~/Library/Preferences/com.permissionpilot.plist

# Database
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db "SELECT * FROM automation_events LIMIT 10;"
```

### Reset to factory defaults

```bash
# Remove all preferences and data
rm -rf ~/Library/Application\ Support/PermissionPilot
rm -rf ~/Library/Logs/PermissionPilot
rm ~/Library/Preferences/com.permissionpilot*
defaults delete com.permissionpilot.app

# Reinstall
killall PermissionPilot
open /Applications/PermissionPilot.app
```

## Still Stuck?

1. **Check the docs**:
   - [README.md](README.md) — Overview and quick start
   - [ARCHITECTURE.md](ARCHITECTURE.md) — System design details
   - [FAQ.md](FAQ.md) — Common questions

2. **Search issues**:
   - [GitHub Issues](https://github.com/ChaitanyaJoshi1769/PermissionPilot/issues)
   - Your problem might already be solved

3. **Ask for help**:
   - [GitHub Discussions](https://github.com/ChaitanyaJoshi1769/PermissionPilot/discussions)
   - [File a bug report](https://github.com/ChaitanyaJoshi1769/PermissionPilot/issues/new?template=bug_report.md)
   - Email: dev@permissionpilot.app

---

**Helpful info when reporting issues**:
- macOS version (`sw_vers`)
- PermissionPilot version (About menu)
- Steps to reproduce
- Relevant logs (`~/Library/Logs/PermissionPilot/`)
- Screenshot of the issue
