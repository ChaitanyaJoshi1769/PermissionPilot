#!/bin/bash
# health-check.sh - PermissionPilot System Health Check
# Verify PermissionPilot installation and configuration

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

# Helper functions
check_pass() {
  echo -e "  ${GREEN}✓${NC} $1"
  ((CHECKS_PASSED++))
}

check_fail() {
  echo -e "  ${RED}✗${NC} $1"
  ((CHECKS_FAILED++))
}

check_warn() {
  echo -e "  ${YELLOW}⚠${NC} $1"
  ((CHECKS_WARNING++))
}

print_header() {
  echo ""
  echo -e "${BLUE}▶ $1${NC}"
}

# Header
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   PermissionPilot System Health Check                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check 1: Installation
print_header "Installation"

if [ -d "/Applications/PermissionPilot.app" ]; then
  check_pass "Application installed"

  # Check executable
  if [ -x "/Applications/PermissionPilot.app/Contents/MacOS/PermissionPilot" ]; then
    check_pass "Executable found and accessible"
  else
    check_fail "Executable not found or not executable"
  fi
else
  check_fail "PermissionPilot.app not found in /Applications"
fi

# Check 2: Daemon
print_header "Daemon Status"

if launchctl list | grep -q "com.permissionpilot.daemon"; then
  check_pass "Daemon is loaded"

  # Check if running
  if pgrep -f "PermissionPilot" > /dev/null; then
    check_pass "Daemon is running"
  else
    check_warn "Daemon is loaded but not running"
  fi
else
  check_fail "Daemon is not loaded"
fi

# Check LaunchAgent file
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.permissionpilot.daemon.plist"
if [ -f "$LAUNCH_AGENT" ]; then
  check_pass "LaunchAgent configuration found"
else
  check_fail "LaunchAgent configuration not found"
fi

# Check 3: Permissions
print_header "System Permissions"

# Accessibility permission
if sqlite3 /Users/$(whoami)/Library/Preferences/com.apple.LaunchServices.QuarantineResolver.plist \
  ".tables" > /dev/null 2>&1; then
  check_pass "Accessibility permission system accessible"
else
  check_warn "Could not verify accessibility permission"
fi

# Check file permissions
APP_OWNER=$(ls -l "/Applications/PermissionPilot.app" | awk '{print $3}')
if [ "$APP_OWNER" == "$(whoami)" ] || [ "$APP_OWNER" == "root" ]; then
  check_pass "Application has correct ownership"
else
  check_warn "Application ownership is unusual: $APP_OWNER"
fi

# Check 4: Configuration
print_header "Configuration"

CONFIG_DIR="$HOME/Library/Application Support/PermissionPilot"

if [ -d "$CONFIG_DIR" ]; then
  check_pass "Configuration directory exists"
else
  check_fail "Configuration directory not found"
fi

# Check config files
if [ -f "$CONFIG_DIR/config.json" ]; then
  check_pass "config.json exists"

  # Validate JSON
  if jq empty "$CONFIG_DIR/config.json" 2>/dev/null; then
    check_pass "config.json is valid JSON"
  else
    check_fail "config.json is invalid JSON"
  fi
else
  check_warn "config.json not found (using defaults)"
fi

if [ -f "$CONFIG_DIR/policies.json" ]; then
  check_pass "policies.json exists"

  # Validate JSON
  if jq empty "$CONFIG_DIR/policies.json" 2>/dev/null; then
    check_pass "policies.json is valid JSON"
  else
    check_fail "policies.json is invalid JSON"
  fi
else
  check_warn "policies.json not found (using defaults)"
fi

# Check 5: Database
print_header "Database"

DB_PATH="$CONFIG_DIR/audit.db"

if [ -f "$DB_PATH" ]; then
  check_pass "Database exists"

  # Check integrity
  if sqlite3 "$DB_PATH" "PRAGMA integrity_check;" 2>/dev/null | grep -q "ok"; then
    check_pass "Database integrity verified"
  else
    check_fail "Database is corrupted"
  fi

  # Get database size
  DB_SIZE=$(du -h "$DB_PATH" | awk '{print $1}')
  check_pass "Database size: $DB_SIZE"

  # Get event count
  EVENT_COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM automation_events;" 2>/dev/null || echo "0")
  if [ "$EVENT_COUNT" -gt 0 ]; then
    check_pass "Database contains $EVENT_COUNT events"
  else
    check_warn "Database is empty"
  fi
else
  check_warn "Database not found (will be created on first run)"
fi

# Check 6: Logs
print_header "Logging"

LOG_DIR="$HOME/Library/Logs/PermissionPilot"

if [ -d "$LOG_DIR" ]; then
  check_pass "Log directory exists"

  # Get recent logs
  LOG_COUNT=$(ls "$LOG_DIR"/*.log 2>/dev/null | wc -l)
  if [ "$LOG_COUNT" -gt 0 ]; then
    check_pass "Log files found ($LOG_COUNT)"

    # Check log age
    LATEST_LOG=$(ls -t "$LOG_DIR"/*.log 2>/dev/null | head -1)
    if [ -n "$LATEST_LOG" ]; then
      MODIFY_TIME=$(stat -f "%m" "$LATEST_LOG")
      CURRENT_TIME=$(date +%s)
      DIFF=$((CURRENT_TIME - MODIFY_TIME))

      if [ "$DIFF" -lt 3600 ]; then
        check_pass "Recent log activity (< 1 hour)"
      elif [ "$DIFF" -lt 86400 ]; then
        check_warn "Last log activity: $(($DIFF / 3600)) hours ago"
      else
        check_warn "Last log activity: $(($DIFF / 86400)) days ago"
      fi
    fi
  else
    check_warn "No log files found"
  fi
else
  check_warn "Log directory not found"
fi

# Check 7: Performance
print_header "Performance"

if pgrep -f "PermissionPilot" > /dev/null; then
  # Get CPU usage
  CPU=$(ps aux | grep "[P]ermissionPilot" | awk '{print $3}')
  MEM=$(ps aux | grep "[P]ermissionPilot" | awk '{print $6}')

  # Evaluate
  CPU_OK=$(echo "$CPU < 2" | bc)
  MEM_OK=$(echo "$MEM < 200" | bc)

  if [ "$CPU_OK" -eq 1 ]; then
    check_pass "CPU usage normal: ${CPU}%"
  else
    check_warn "CPU usage elevated: ${CPU}%"
  fi

  if [ "$MEM_OK" -eq 1 ]; then
    check_pass "Memory usage normal: ${MEM}MB"
  else
    check_warn "Memory usage elevated: ${MEM}MB"
  fi
else
  check_warn "Cannot measure performance (daemon not running)"
fi

# Check 8: Recent Activity
print_header "Recent Activity"

if [ -f "$DB_PATH" ]; then
  # Check last 24 hours
  EVENTS_24H=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM automation_events WHERE timestamp > datetime('now', '-24 hours');" 2>/dev/null || echo "0")

  if [ "$EVENTS_24H" -gt 0 ]; then
    check_pass "Activity in last 24 hours: $EVENTS_24H events"
  else
    check_warn "No activity in last 24 hours"
  fi

  # Check success rate
  SUCCESS=$(sqlite3 "$DB_PATH" "SELECT ROUND(100.0 * SUM(CASE WHEN automation_success = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) FROM automation_events WHERE timestamp > datetime('now', '-24 hours');" 2>/dev/null || echo "N/A")

  if [ "$SUCCESS" != "N/A" ]; then
    if (( $(echo "$SUCCESS >= 95" | bc -l) )); then
      check_pass "Success rate good: ${SUCCESS}%"
    else
      check_warn "Success rate: ${SUCCESS}%"
    fi
  fi
fi

# Summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                   Health Check Summary                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Passed:${NC}   $CHECKS_PASSED"
echo -e "${YELLOW}Warnings:${NC} $CHECKS_WARNING"
echo -e "${RED}Failed:${NC}   $CHECKS_FAILED"
echo ""

# Final status
if [ "$CHECKS_FAILED" -eq 0 ]; then
  if [ "$CHECKS_WARNING" -eq 0 ]; then
    echo -e "${GREEN}✓ All health checks passed!${NC}"
    exit 0
  else
    echo -e "${YELLOW}⚠ Health checks passed with warnings. See above for details.${NC}"
    exit 0
  fi
else
  echo -e "${RED}✗ Some health checks failed. Please see above for details.${NC}"
  echo ""
  echo "Common solutions:"
  echo "  1. Reinstall PermissionPilot"
  echo "  2. Reset configuration: rm -rf ~/Library/Application\ Support/PermissionPilot/"
  echo "  3. Check System Preferences → Security & Privacy → Accessibility"
  echo "  4. See TROUBLESHOOTING.md for more help"
  exit 1
fi
