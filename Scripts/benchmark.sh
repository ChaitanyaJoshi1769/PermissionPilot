#!/bin/bash
# benchmark.sh - PermissionPilot Performance Benchmark
# Measure and compare PermissionPilot performance on your system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BENCHMARK_DURATION=30
TEST_COUNT=5

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     PermissionPilot Performance Benchmark Suite            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "System: $(uname -s) $(uname -m)"
echo -e "Time: $(date)"
echo ""

# Check if PermissionPilot is running
if ! pgrep -f "PermissionPilot" > /dev/null; then
  echo -e "${YELLOW}⚠ PermissionPilot is not running${NC}"
  echo "  Starting daemon..."
  launchctl start com.permissionpilot.daemon
  sleep 3
fi

# Test 1: Idle CPU and Memory
echo -e "${BLUE}Test 1: Idle CPU & Memory (${BENCHMARK_DURATION}s)${NC}"
echo "Measuring baseline performance..."

CPU_SAMPLES=()
MEM_SAMPLES=()

for i in $(seq 1 $BENCHMARK_DURATION); do
  CPU=$(ps aux | grep "[P]ermissionPilot" | awk '{print $3}' 2>/dev/null || echo "0")
  MEM=$(ps aux | grep "[P]ermissionPilot" | awk '{print $6}' 2>/dev/null || echo "0")

  CPU_SAMPLES+=("$CPU")
  MEM_SAMPLES+=("$MEM")

  sleep 1
done

# Calculate averages
AVG_CPU=$(printf '%.1f' $(echo "scale=1; ($(IFS=+; echo "${CPU_SAMPLES[*]}")) / ${#CPU_SAMPLES[@]}" | bc))
AVG_MEM=$(printf '%.0f' $(echo "scale=0; ($(IFS=+; echo "${MEM_SAMPLES[*]}")) / ${#MEM_SAMPLES[@]}" | bc))
MAX_CPU=$(printf '%.1f' $(echo "${CPU_SAMPLES[@]}" | tr ' ' '\n' | sort -rn | head -1))
MAX_MEM=$(echo "${MEM_SAMPLES[@]}" | tr ' ' '\n' | sort -rn | head -1)

# Evaluate
CPU_OK=$(( $(echo "$AVG_CPU < 1.0" | bc -l) ))
MEM_OK=$(( $(echo "$AVG_MEM < 150" | bc -l) ))

echo -e "  Average CPU: $AVG_CPU% (max: $MAX_CPU%)"
echo -e "  Average Memory: ${AVG_MEM}MB (max: ${MAX_MEM}MB)"
[ $CPU_OK -eq 1 ] && echo -e "  ${GREEN}✓ CPU within acceptable range${NC}" || echo -e "  ${RED}✗ CPU usage high${NC}"
[ $MEM_OK -eq 1 ] && echo -e "  ${GREEN}✓ Memory within acceptable range${NC}" || echo -e "  ${RED}✗ Memory usage high${NC}"
echo ""

# Test 2: Database Performance
echo -e "${BLUE}Test 2: Database Performance${NC}"
echo "Running database queries..."

DB_PATH="$HOME/Library/Application Support/PermissionPilot/audit.db"

if [ ! -f "$DB_PATH" ]; then
  echo -e "${YELLOW}⚠ Database not found, skipping test${NC}"
else
  # Query 1: Count events (fast)
  START=$(date +%s%N)
  EVENT_COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM automation_events;" 2>/dev/null || echo "0")
  END=$(date +%s%N)
  QUERY_TIME=$(( (END - START) / 1000000 ))
  echo -e "  Total events in database: $EVENT_COUNT"
  echo -e "  Query time: ${QUERY_TIME}ms"

  # Query 2: Statistics (medium)
  START=$(date +%s%N)
  STATS=$(sqlite3 "$DB_PATH" "SELECT COUNT(*), AVG(trust_score) FROM automation_events WHERE timestamp > datetime('now', '-24 hours');" 2>/dev/null || echo "0|0")
  END=$(date +%s%N)
  QUERY_TIME=$(( (END - START) / 1000000 ))
  echo -e "  24-hour statistics query: ${QUERY_TIME}ms"

  # Query 3: Recent events (slower)
  START=$(date +%s%N)
  RECENT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM automation_events WHERE timestamp > datetime('now', '-1 hour');" 2>/dev/null || echo "0")
  END=$(date +%s%N)
  QUERY_TIME=$(( (END - START) / 1000000 ))
  echo -e "  Recent events (1h): $RECENT"
  echo -e "  Query time: ${QUERY_TIME}ms"

  # Database size
  DB_SIZE=$(du -sh "$DB_PATH" | awk '{print $1}')
  echo -e "  Database size: $DB_SIZE"
  echo ""
fi

# Test 3: Event Statistics
echo -e "${BLUE}Test 3: Recent Activity Statistics${NC}"

if [ -f "$DB_PATH" ]; then
  # Success rate (last 24 hours)
  SUCCESS_RATE=$(sqlite3 "$DB_PATH" "SELECT ROUND(100.0 * SUM(CASE WHEN automation_success = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) FROM automation_events WHERE timestamp > datetime('now', '-24 hours');" 2>/dev/null || echo "N/A")

  # Action distribution
  ALLOW=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM automation_events WHERE action_taken = 'ALLOW_ONCE' AND timestamp > datetime('now', '-24 hours');" 2>/dev/null || echo "0")
  BLOCK=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM automation_events WHERE action_taken = 'BLOCK' AND timestamp > datetime('now', '-24 hours');" 2>/dev/null || echo "0")
  MANUAL=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM automation_events WHERE action_taken = 'MANUAL' AND timestamp > datetime('now', '-24 hours');" 2>/dev/null || echo "0")

  # Detection method distribution
  API=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM automation_events WHERE detection_method = 'ACCESSIBILITY_API' AND timestamp > datetime('now', '-24 hours');" 2>/dev/null || echo "0")
  OCR=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM automation_events WHERE detection_method = 'OCR' AND timestamp > datetime('now', '-24 hours');" 2>/dev/null || echo "0")

  echo -e "  Last 24 hours activity:"
  echo -e "    Success rate: $SUCCESS_RATE%"
  echo -e "    Allowed: $ALLOW"
  echo -e "    Blocked: $BLOCK"
  echo -e "    Manual: $MANUAL"
  echo -e "    Accessibility API: $API detections"
  echo -e "    OCR: $OCR detections"
  echo ""
fi

# Test 4: Top Applications
echo -e "${BLUE}Test 4: Top Applications (Last 7 days)${NC}"

if [ -f "$DB_PATH" ]; then
  sqlite3 "$DB_PATH" << 'EOF' 2>/dev/null || true
.mode column
.headers on
SELECT app_name, COUNT(*) as dialogs FROM automation_events
WHERE timestamp > datetime('now', '-7 days')
GROUP BY app_name ORDER BY dialogs DESC LIMIT 5;
EOF
  echo ""
fi

# Test 5: System Resources
echo -e "${BLUE}Test 5: System Resources${NC}"

# Available memory
AVAILABLE_MEM=$(vm_stat | grep "Pages free" | awk '{print int($3) * 4096 / 1024 / 1024 " MB"}')
echo -e "  Available memory: $AVAILABLE_MEM"

# Available disk
AVAILABLE_DISK=$(df -h / | tail -1 | awk '{print $4}')
echo -e "  Available disk: $AVAILABLE_DISK"

# Load average
LOAD=$(uptime | awk '{print $(NF-2), $(NF-1), $NF}')
echo -e "  Load average: $LOAD"
echo ""

# Summary
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    Benchmark Complete                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ $CPU_OK -eq 1 ] && [ $MEM_OK -eq 1 ]; then
  echo -e "${GREEN}✓ All tests passed! PermissionPilot is running optimally.${NC}"
  exit 0
else
  echo -e "${YELLOW}⚠ Some metrics are outside normal ranges. See PERFORMANCE_TUNING.md for optimization tips.${NC}"
  exit 1
fi
