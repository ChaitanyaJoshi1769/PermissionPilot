#!/bin/bash
# analyze-logs.sh - Analyze PermissionPilot logs and generate reports
# Usage: ./analyze-logs.sh [json|text] [output_file] [optional: hours_back]

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
DB_PATH="$HOME/Library/Application Support/PermissionPilot/audit.db"
FORMAT="${1:-text}"
OUTPUT_FILE="${2:-permissionpilot_analysis_$(date +%Y%m%d_%H%M%S).${FORMAT}}"
HOURS_BACK="${3:-24}"

# Validate inputs
if [ ! -f "$DB_PATH" ]; then
  echo -e "${RED}Error: Database not found at $DB_PATH${NC}"
  exit 1
fi

if [ "$FORMAT" != "json" ] && [ "$FORMAT" != "text" ]; then
  echo -e "${RED}Error: Format must be 'json' or 'text'${NC}"
  exit 1
fi

# Helper function for SQL queries
query_db() {
  sqlite3 "$DB_PATH" "$1" 2>/dev/null || echo "N/A"
}

# Collect statistics
TOTAL_EVENTS=$(query_db "SELECT COUNT(*) FROM automation_events WHERE timestamp > datetime('now', '-$HOURS_BACK hours');")
ALLOWED=$(query_db "SELECT COUNT(*) FROM automation_events WHERE action_taken = 'ALLOW_ONCE' AND timestamp > datetime('now', '-$HOURS_BACK hours');")
BLOCKED=$(query_db "SELECT COUNT(*) FROM automation_events WHERE action_taken = 'BLOCK' AND timestamp > datetime('now', '-$HOURS_BACK hours');")
MANUAL=$(query_db "SELECT COUNT(*) FROM automation_events WHERE action_taken = 'MANUAL' AND timestamp > datetime('now', '-$HOURS_BACK hours');")
SUCCESS_RATE=$(query_db "SELECT ROUND(100.0 * SUM(CASE WHEN automation_success = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) FROM automation_events WHERE timestamp > datetime('now', '-$HOURS_BACK hours');")
AVG_TRUST=$(query_db "SELECT ROUND(AVG(trust_score), 2) FROM automation_events WHERE timestamp > datetime('now', '-$HOURS_BACK hours');")

# Get top apps
TOP_APPS=$(query_db "SELECT app_name, COUNT(*) as count FROM automation_events WHERE timestamp > datetime('now', '-$HOURS_BACK hours') GROUP BY app_name ORDER BY count DESC LIMIT 5;")

# Get detection methods
API_DETECTIONS=$(query_db "SELECT COUNT(*) FROM automation_events WHERE detection_method = 'ACCESSIBILITY_API' AND timestamp > datetime('now', '-$HOURS_BACK hours');")
OCR_DETECTIONS=$(query_db "SELECT COUNT(*) FROM automation_events WHERE detection_method = 'OCR' AND timestamp > datetime('now', '-$HOURS_BACK hours');")

# Get most common dialogs
COMMON_DIALOGS=$(query_db "SELECT dialog_title, COUNT(*) as count FROM automation_events WHERE timestamp > datetime('now', '-$HOURS_BACK hours') GROUP BY dialog_title ORDER BY count DESC LIMIT 5;")

# Get blocked reasons
BLOCKED_REASONS=$(query_db "SELECT reason_blocked, COUNT(*) as count FROM automation_events WHERE action_taken = 'BLOCK' AND timestamp > datetime('now', '-$HOURS_BACK hours') GROUP BY reason_blocked ORDER BY count DESC LIMIT 5;")

# Output function
output_text() {
  {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║      PermissionPilot Log Analysis Report                    ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Time Range: Last $HOURS_BACK hours"
    echo ""

    echo -e "${CYAN}Summary Statistics${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "Total Events:        ${PURPLE}$TOTAL_EVENTS${NC}"
    echo -e "Allowed:             ${GREEN}$ALLOWED${NC}"
    echo -e "Blocked:             ${RED}$BLOCKED${NC}"
    echo -e "Manual:              ${YELLOW}$MANUAL${NC}"
    echo -e "Success Rate:        ${GREEN}$SUCCESS_RATE%${NC}"
    echo -e "Average Trust Score: ${CYAN}$AVG_TRUST${NC}"
    echo ""

    echo -e "${CYAN}Detection Methods${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "Accessibility API:   ${GREEN}$API_DETECTIONS${NC}"
    echo -e "OCR:                 ${YELLOW}$OCR_DETECTIONS${NC}"
    echo ""

    if [ "$TOTAL_EVENTS" -gt 0 ]; then
      echo -e "${CYAN}Top Applications${NC}"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "$TOP_APPS" | while IFS='|' read -r app count; do
        printf "%-40s %s\n" "$app" "$count"
      done
      echo ""

      echo -e "${CYAN}Most Common Dialogs${NC}"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "$COMMON_DIALOGS" | while IFS='|' read -r dialog count; do
        printf "%-50s %s\n" "${dialog:0:50}" "$count"
      done
      echo ""

      if [ ! -z "$BLOCKED_REASONS" ] && [ "$BLOCKED_REASONS" != "N/A" ]; then
        echo -e "${CYAN}Block Reasons${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "$BLOCKED_REASONS" | while IFS='|' read -r reason count; do
          printf "%-50s %s\n" "$reason" "$count"
        done
        echo ""
      fi
    fi

    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo "Report generated at: $(date)"
  } | tee "$OUTPUT_FILE"
}

output_json() {
  {
    # Calculate percentages
    if [ "$TOTAL_EVENTS" -gt 0 ]; then
      ALLOW_PCT=$((ALLOWED * 100 / TOTAL_EVENTS))
      BLOCK_PCT=$((BLOCKED * 100 / TOTAL_EVENTS))
      MANUAL_PCT=$((MANUAL * 100 / TOTAL_EVENTS))
    else
      ALLOW_PCT=0
      BLOCK_PCT=0
      MANUAL_PCT=0
    fi

    cat << EOF
{
  "metadata": {
    "generated": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
    "time_range_hours": $HOURS_BACK,
    "database_path": "$DB_PATH"
  },
  "summary": {
    "total_events": $TOTAL_EVENTS,
    "allowed": {
      "count": $ALLOWED,
      "percentage": $ALLOW_PCT
    },
    "blocked": {
      "count": $BLOCKED,
      "percentage": $BLOCK_PCT
    },
    "manual": {
      "count": $MANUAL,
      "percentage": $MANUAL_PCT
    },
    "success_rate": "$SUCCESS_RATE%",
    "average_trust_score": $AVG_TRUST
  },
  "detection_methods": {
    "accessibility_api": $API_DETECTIONS,
    "ocr": $OCR_DETECTIONS
  },
  "top_applications": [
EOF

    # Add top apps as JSON array
    query_db "SELECT json_object('app_name', app_name, 'count', COUNT(*)) as json_row FROM automation_events WHERE timestamp > datetime('now', '-$HOURS_BACK hours') GROUP BY app_name ORDER BY COUNT(*) DESC LIMIT 5;" | sed 's/^/    /' | sed '$!s/$/,/'

    cat << EOF
  ],
  "common_dialogs": [
EOF

    # Add common dialogs
    query_db "SELECT json_object('dialog_title', dialog_title, 'count', COUNT(*)) as json_row FROM automation_events WHERE timestamp > datetime('now', '-$HOURS_BACK hours') GROUP BY dialog_title ORDER BY COUNT(*) DESC LIMIT 5;" | sed 's/^/    /' | sed '$!s/$/,/'

    cat << EOF
  ]
}
EOF
  } > "$OUTPUT_FILE"
}

# Generate report
echo -e "${BLUE}PermissionPilot Log Analysis${NC}"
echo "Format: $FORMAT"
echo "Output: $OUTPUT_FILE"
echo "Time Range: Last $HOURS_BACK hours"
echo ""

case "$FORMAT" in
  text)
    output_text
    ;;
  json)
    output_json
    ;;
esac

echo ""
echo -e "${GREEN}✓ Analysis complete!${NC}"
echo "Report saved to: $OUTPUT_FILE"
