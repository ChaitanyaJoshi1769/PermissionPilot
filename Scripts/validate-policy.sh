#!/bin/bash
# validate-policy.sh - Validate PermissionPilot policy JSON syntax and structure
# Usage: ./validate-policy.sh [policy_file]

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
POLICY_FILE="${1:-$HOME/Library/Application\ Support/PermissionPilot/policies.json}"

# Check if file exists
if [ ! -f "$POLICY_FILE" ]; then
  echo -e "${RED}Error: Policy file not found: $POLICY_FILE${NC}"
  exit 1
fi

echo -e "${BLUE}PermissionPilot Policy Validator${NC}"
echo ""
echo "File: $POLICY_FILE"
echo ""

# Counter
CHECKS_PASSED=0
CHECKS_WARNING=0
CHECKS_FAILED=0

# Helper functions
check_pass() {
  echo -e "  ${GREEN}✓${NC} $1"
  ((CHECKS_PASSED++))
}

check_warn() {
  echo -e "  ${YELLOW}⚠${NC} $1"
  ((CHECKS_WARNING++))
}

check_fail() {
  echo -e "  ${RED}✗${NC} $1"
  ((CHECKS_FAILED++))
}

# Check 1: Valid JSON
echo -e "${BLUE}▶ JSON Syntax${NC}"
if jq empty "$POLICY_FILE" 2>/dev/null; then
  check_pass "Valid JSON syntax"
else
  check_fail "Invalid JSON syntax"
  exit 1
fi

# Check 2: Required Fields
echo ""
echo -e "${BLUE}▶ Required Fields${NC}"

if jq -e '.name' "$POLICY_FILE" > /dev/null 2>&1; then
  check_pass "Name field present"
else
  check_fail "Missing 'name' field"
fi

if jq -e '.version' "$POLICY_FILE" > /dev/null 2>&1; then
  check_pass "Version field present"
else
  check_fail "Missing 'version' field"
fi

if jq -e '.policies' "$POLICY_FILE" > /dev/null 2>&1; then
  POLICY_COUNT=$(jq '.policies | length' "$POLICY_FILE")
  check_pass "Policies array present ($POLICY_COUNT policies)"
else
  check_fail "Missing 'policies' array"
fi

# Check 3: Policy Structure
echo ""
echo -e "${BLUE}▶ Policy Structure${NC}"

# Check each policy
INVALID_POLICIES=0
jq -r '.policies[] | "\(.id)"' "$POLICY_FILE" | while read -r POLICY_ID; do
  # Get policy object
  POLICY=$(jq ".policies[] | select(.id == \"$POLICY_ID\")" "$POLICY_FILE")

  # Check required fields
  if echo "$POLICY" | jq -e '.id' > /dev/null 2>&1; then
    true
  else
    echo -e "    ${RED}✗${NC} Policy missing 'id' field"
    ((INVALID_POLICIES++))
  fi

  if echo "$POLICY" | jq -e '.type' > /dev/null 2>&1; then
    POLICY_TYPE=$(echo "$POLICY" | jq -r '.type')
    VALID_TYPES="whitelist blacklist rule"
    if echo "$VALID_TYPES" | grep -q "$POLICY_TYPE"; then
      true
    else
      echo -e "    ${RED}✗${NC} Policy $POLICY_ID has invalid type: $POLICY_TYPE"
      ((INVALID_POLICIES++))
    fi
  fi

  if echo "$POLICY" | jq -e '.action' > /dev/null 2>&1; then
    POLICY_ACTION=$(echo "$POLICY" | jq -r '.action')
    VALID_ACTIONS="allow block ask"
    if echo "$VALID_ACTIONS" | grep -q "$POLICY_ACTION"; then
      true
    else
      echo -e "    ${RED}✗${NC} Policy $POLICY_ID has invalid action: $POLICY_ACTION"
      ((INVALID_POLICIES++))
    fi
  fi
done

if [ "$INVALID_POLICIES" -eq 0 ]; then
  check_pass "All policies have valid structure"
fi

# Check 4: Priority Values
echo ""
echo -e "${BLUE}▶ Priority Values${NC}"

MIN_PRIORITY=$(jq '.policies | map(.priority // 0) | min' "$POLICY_FILE")
MAX_PRIORITY=$(jq '.policies | map(.priority // 0) | max' "$POLICY_FILE")

if [ "$MIN_PRIORITY" -ge 0 ] && [ "$MAX_PRIORITY" -le 100 ]; then
  check_pass "Priority values in valid range (0-100): $MIN_PRIORITY to $MAX_PRIORITY"
else
  check_warn "Priority values outside recommended range (0-100): $MIN_PRIORITY to $MAX_PRIORITY"
fi

# Check for priority conflicts
DUPLICATE_PRIORITIES=$(jq '[.policies[].priority] | unique | length' "$POLICY_FILE")
TOTAL_PRIORITIES=$(jq '.policies | length' "$POLICY_FILE")

if [ "$DUPLICATE_PRIORITIES" -lt "$TOTAL_PRIORITIES" ]; then
  check_warn "Duplicate priority values found - evaluate policy order"
fi

# Check 5: Regex Pattern Validation
echo ""
echo -e "${BLUE}▶ Regular Expressions${NC}"

INVALID_REGEX=0
jq -r '.policies[] | select(.target_pattern != null) | "\(.id):\(.target_pattern)"' "$POLICY_FILE" | while read -r PATTERN_LINE; do
  POLICY_ID=$(echo "$PATTERN_LINE" | cut -d: -f1)
  PATTERN=$(echo "$PATTERN_LINE" | cut -d: -f2-)

  # Test regex validity
  if echo "" | grep -E "$PATTERN" > /dev/null 2>&1; then
    true
  else
    echo -e "    ${RED}✗${NC} Policy $POLICY_ID has invalid regex: $PATTERN"
    ((INVALID_REGEX++))
  fi
done

if [ "$INVALID_REGEX" -eq 0 ]; then
  check_pass "All regex patterns are valid"
fi

# Check 6: Settings Validation
echo ""
echo -e "${BLUE}▶ Settings${NC}"

if jq -e '.settings' "$POLICY_FILE" > /dev/null 2>&1; then
  check_pass "Settings section present"

  # Check default action
  DEFAULT_ACTION=$(jq -r '.settings.default_action // "ask"' "$POLICY_FILE")
  if [ "$DEFAULT_ACTION" = "allow" ] || [ "$DEFAULT_ACTION" = "block" ] || [ "$DEFAULT_ACTION" = "ask" ]; then
    check_pass "Valid default_action: $DEFAULT_ACTION"
  else
    check_fail "Invalid default_action: $DEFAULT_ACTION"
  fi

  # Check trust threshold
  TRUST_THRESHOLD=$(jq -r '.settings.trust_threshold // 0.70' "$POLICY_FILE")
  if (( $(echo "$TRUST_THRESHOLD >= 0 && $TRUST_THRESHOLD <= 1" | bc -l) )); then
    check_pass "Valid trust_threshold: $TRUST_THRESHOLD"
  else
    check_warn "Trust threshold outside range (0-1): $TRUST_THRESHOLD"
  fi

  # Check log level
  LOG_LEVEL=$(jq -r '.settings.log_level // "info"' "$POLICY_FILE")
  VALID_LEVELS="debug info warn error"
  if echo "$VALID_LEVELS" | grep -q "$LOG_LEVEL"; then
    check_pass "Valid log_level: $LOG_LEVEL"
  else
    check_warn "Unusual log_level: $LOG_LEVEL"
  fi
else
  check_warn "Settings section missing (using defaults)"
fi

# Check 7: Sanity Checks
echo ""
echo -e "${BLUE}▶ Policy Logic${NC}"

# Check for conflicting whitelist/blacklist
WHITELIST_COUNT=$(jq '[.policies[] | select(.type == "whitelist")] | length' "$POLICY_FILE")
BLACKLIST_COUNT=$(jq '[.policies[] | select(.type == "blacklist")] | length' "$POLICY_FILE")

if [ "$WHITELIST_COUNT" -gt 0 ] && [ "$BLACKLIST_COUNT" -gt 0 ]; then
  check_warn "Both whitelist and blacklist policies present - verify interaction"
fi

# Check for unreachable policies (very low priority)
LOW_PRIORITY_COUNT=$(jq '[.policies[] | select(.priority < 10)] | length' "$POLICY_FILE")
if [ "$LOW_PRIORITY_COUNT" -gt 2 ]; then
  check_warn "Many policies with low priority (<10) - may be unreachable"
fi

# Check for orphaned allow policies with no matching whitelist/rules
ALLOW_COUNT=$(jq '[.policies[] | select(.action == "allow")] | length' "$POLICY_FILE")
WHITELIST_OR_RULE=$(jq '[.policies[] | select((.action == "allow") and ((.type == "whitelist") or (.type == "rule")))] | length' "$POLICY_FILE")

if [ "$ALLOW_COUNT" -eq "$WHITELIST_OR_RULE" ]; then
  check_pass "All allow policies have proper type (whitelist or rule)"
else
  check_warn "Some allow policies may have unexpected structure"
fi

# Summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                 Validation Summary                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Passed:${NC}   $CHECKS_PASSED"
echo -e "${YELLOW}Warnings:${NC} $CHECKS_WARNING"
echo -e "${RED}Failed:${NC}   $CHECKS_FAILED"
echo ""

if [ "$CHECKS_FAILED" -eq 0 ]; then
  if [ "$CHECKS_WARNING" -eq 0 ]; then
    echo -e "${GREEN}✓ Policy validation passed!${NC}"
    exit 0
  else
    echo -e "${YELLOW}⚠ Policy validation passed with warnings. Review above.${NC}"
    exit 0
  fi
else
  echo -e "${RED}✗ Policy validation failed. Fix errors above.${NC}"
  exit 1
fi
