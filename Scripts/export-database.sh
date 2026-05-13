#!/bin/bash
# export-database.sh - Export PermissionPilot audit database to CSV/JSON
# Usage: ./export-database.sh [csv|json] [output_file] [optional: days_back]

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DB_PATH="$HOME/Library/Application Support/PermissionPilot/audit.db"
FORMAT="${1:-csv}"
OUTPUT_FILE="${2:-permissionpilot_export_$(date +%Y%m%d_%H%M%S).${FORMAT}}"
DAYS_BACK="${3:-30}"

# Validate inputs
if [ ! -f "$DB_PATH" ]; then
  echo -e "${RED}Error: Database not found at $DB_PATH${NC}"
  exit 1
fi

if [ "$FORMAT" != "csv" ] && [ "$FORMAT" != "json" ]; then
  echo -e "${RED}Error: Format must be 'csv' or 'json'${NC}"
  exit 1
fi

# Validate days_back is a number
if ! [[ "$DAYS_BACK" =~ ^[0-9]+$ ]]; then
  echo -e "${RED}Error: days_back must be a number${NC}"
  exit 1
fi

echo -e "${BLUE}PermissionPilot Database Export${NC}"
echo "Format: $FORMAT"
echo "Output: $OUTPUT_FILE"
echo "Time Range: Last $DAYS_BACK days"
echo ""

# Export function
export_csv() {
  echo "Exporting to CSV..."
  sqlite3 "$DB_PATH" \
    ".mode csv" \
    ".headers on" \
    ".output $OUTPUT_FILE" \
    "SELECT * FROM automation_events WHERE timestamp > datetime('now', '-$DAYS_BACK days') ORDER BY timestamp DESC;"
  echo -e "${GREEN}✓ CSV export complete${NC}"
}

export_json() {
  echo "Exporting to JSON..."

  # Create JSON output
  sqlite3 "$DB_PATH" <<EOF > "$OUTPUT_FILE"
.mode json
SELECT
  id,
  timestamp,
  app_name,
  dialog_title,
  dialog_content,
  detection_method,
  trust_score,
  action_taken,
  automation_success,
  button_clicked,
  reason_blocked,
  tags,
  user_notes
FROM automation_events
WHERE timestamp > datetime('now', '-$DAYS_BACK days')
ORDER BY timestamp DESC;
EOF

  if [ -s "$OUTPUT_FILE" ]; then
    echo -e "${GREEN}✓ JSON export complete${NC}"
  else
    echo -e "${RED}✗ JSON export failed${NC}"
    exit 1
  fi
}

# Get file size function
get_file_size() {
  if command -v numfmt &> /dev/null; then
    ls -lh "$1" | awk '{print $5}'
  else
    du -h "$1" | awk '{print $1}'
  fi
}

# Export based on format
case "$FORMAT" in
  csv)
    export_csv
    ;;
  json)
    export_json
    ;;
esac

# Display summary
EXPORT_SIZE=$(get_file_size "$OUTPUT_FILE")
echo ""
echo "File: $OUTPUT_FILE"
echo "Size: $EXPORT_SIZE"
echo ""

# Get record count
RECORD_COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM automation_events WHERE timestamp > datetime('now', '-$DAYS_BACK days');")
echo -e "${GREEN}Records exported: $RECORD_COUNT${NC}"
echo ""

# Show data summary
echo "Data Summary:"
ALLOWED=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM automation_events WHERE action_taken = 'ALLOW_ONCE' AND timestamp > datetime('now', '-$DAYS_BACK days');")
BLOCKED=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM automation_events WHERE action_taken = 'BLOCK' AND timestamp > datetime('now', '-$DAYS_BACK days');")
MANUAL=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM automation_events WHERE action_taken = 'MANUAL' AND timestamp > datetime('now', '-$DAYS_BACK days');")

echo "  - Allowed: $ALLOWED"
echo "  - Blocked: $BLOCKED"
echo "  - Manual: $MANUAL"
echo ""
echo -e "${GREEN}✓ Export successful!${NC}"
