#!/bin/bash
# database-maintenance.sh - Perform PermissionPilot database maintenance tasks
# Usage: ./database-maintenance.sh [backup|cleanup|vacuum|optimize|health]

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DB_PATH="$HOME/Library/Application Support/PermissionPilot/audit.db"
BACKUP_DIR="$HOME/Library/Application Support/PermissionPilot/backups"
RETENTION_DAYS=60

# Check database exists
if [ ! -f "$DB_PATH" ]; then
  echo -e "${RED}Error: Database not found at $DB_PATH${NC}"
  exit 1
fi

# Command selection
COMMAND="${1:-health}"

# Helper functions
backup_database() {
  echo -e "${BLUE}Creating database backup...${NC}"

  mkdir -p "$BACKUP_DIR"

  BACKUP_FILE="$BACKUP_DIR/audit_backup_$(date +%Y%m%d_%H%M%S).db"

  if cp "$DB_PATH" "$BACKUP_FILE"; then
    echo -e "${GREEN}✓ Backup created: $BACKUP_FILE${NC}"
    echo -e "  Size: $(du -h "$BACKUP_FILE" | awk '{print $1}')"
    return 0
  else
    echo -e "${RED}✗ Backup failed${NC}"
    return 1
  fi
}

cleanup_old_events() {
  echo -e "${BLUE}Cleaning up old events (keeping last $RETENTION_DAYS days)...${NC}"

  BEFORE=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM automation_events;")
  echo "  Before: $BEFORE events"

  # Delete old events
  sqlite3 "$DB_PATH" \
    "DELETE FROM automation_events WHERE timestamp < datetime('now', '-$RETENTION_DAYS days');"

  AFTER=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM automation_events;")
  DELETED=$((BEFORE - AFTER))

  echo "  After: $AFTER events"
  echo -e "${GREEN}✓ Deleted $DELETED old events${NC}"
}

vacuum_database() {
  echo -e "${BLUE}Vacuuming database...${NC}"

  BEFORE=$(du -h "$DB_PATH" | awk '{print $1}')
  echo "  Before: $BEFORE"

  # Run vacuum
  sqlite3 "$DB_PATH" "VACUUM;"

  AFTER=$(du -h "$DB_PATH" | awk '{print $1}')
  echo "  After: $AFTER"
  echo -e "${GREEN}✓ Vacuum complete${NC}"
}

optimize_database() {
  echo -e "${BLUE}Optimizing database...${NC}"

  # Analyze
  echo "  Analyzing database statistics..."
  sqlite3 "$DB_PATH" "ANALYZE;"

  # Reindex
  echo "  Reindexing..."
  sqlite3 "$DB_PATH" "REINDEX;"

  # Defragment
  echo "  Defragmenting..."
  sqlite3 "$DB_PATH" "PRAGMA optimize;"

  echo -e "${GREEN}✓ Optimization complete${NC}"
}

check_database_health() {
  echo -e "${BLUE}PermissionPilot Database Health Check${NC}"
  echo ""

  # Size
  SIZE=$(du -h "$DB_PATH" | awk '{print $1}')
  echo -e "Size: ${BLUE}$SIZE${NC}"

  # Event count
  TOTAL=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM automation_events;")
  echo -e "Events: ${BLUE}$TOTAL${NC}"

  # Date range
  OLDEST=$(sqlite3 "$DB_PATH" "SELECT timestamp FROM automation_events ORDER BY timestamp ASC LIMIT 1;" 2>/dev/null || echo "N/A")
  NEWEST=$(sqlite3 "$DB_PATH" "SELECT timestamp FROM automation_events ORDER BY timestamp DESC LIMIT 1;" 2>/dev/null || echo "N/A")
  echo -e "Date Range: ${BLUE}$OLDEST to $NEWEST${NC}"

  # Integrity check
  echo ""
  echo -ne "Running integrity check... "
  INTEGRITY=$(sqlite3 "$DB_PATH" "PRAGMA integrity_check;")
  if [ "$INTEGRITY" = "ok" ]; then
    echo -e "${GREEN}✓ OK${NC}"
  else
    echo -e "${RED}✗ CORRUPTED${NC}"
    echo "Details: $INTEGRITY"
  fi

  # Statistics
  echo ""
  echo "Action Distribution (Last 7 days):"
  sqlite3 "$DB_PATH" << 'EOF'
.mode column
.headers on
SELECT
  action_taken as action,
  COUNT(*) as count,
  ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM automation_events WHERE timestamp > datetime('now', '-7 days')), 1) as percentage
FROM automation_events
WHERE timestamp > datetime('now', '-7 days')
GROUP BY action_taken
ORDER BY count DESC;
EOF

  echo ""
  echo "Detection Method Distribution (Last 7 days):"
  sqlite3 "$DB_PATH" << 'EOF'
.mode column
.headers on
SELECT
  detection_method as method,
  COUNT(*) as count,
  ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM automation_events WHERE timestamp > datetime('now', '-7 days')), 1) as percentage
FROM automation_events
WHERE timestamp > datetime('now', '-7 days')
GROUP BY detection_method
ORDER BY count DESC;
EOF

  echo ""
  echo "Success Rate (Last 24 hours):"
  SUCCESS=$(sqlite3 "$DB_PATH" "SELECT ROUND(100.0 * SUM(CASE WHEN automation_success = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) FROM automation_events WHERE timestamp > datetime('now', '-24 hours');")
  echo -e "  ${GREEN}${SUCCESS}%${NC}"

  # Backup status
  echo ""
  echo "Recent Backups:"
  if [ -d "$BACKUP_DIR" ]; then
    ls -lt "$BACKUP_DIR"/*.db 2>/dev/null | head -5 | while read -r file; do
      SIZE=$(ls -lh "$file" | awk '{print $5}')
      DATE=$(ls -l "$file" | awk '{print $6, $7, $8}')
      FILE=$(basename "$file")
      printf "  %-40s %s (%s)\n" "$FILE" "$DATE" "$SIZE"
    done
  else
    echo "  No backups found"
  fi
}

# Main execution
echo ""
case "$COMMAND" in
  backup)
    backup_database
    ;;
  cleanup)
    backup_database
    cleanup_old_events
    ;;
  vacuum)
    echo -e "${YELLOW}⚠ Vacuum should be run when daemon is idle${NC}"
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      vacuum_database
    fi
    ;;
  optimize)
    echo -e "${YELLOW}⚠ Optimization may take a while on large databases${NC}"
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      optimize_database
    fi
    ;;
  health)
    check_database_health
    ;;
  *)
    echo -e "${RED}Unknown command: $COMMAND${NC}"
    echo "Available commands:"
    echo "  backup    - Create database backup"
    echo "  cleanup   - Delete old events (older than $RETENTION_DAYS days)"
    echo "  vacuum    - Reclaim unused space"
    echo "  optimize  - Analyze and reindex database"
    echo "  health    - Check database health and statistics"
    exit 1
    ;;
esac

echo ""
