#!/bin/bash
# deploy-bulk.sh - Deploy PermissionPilot policies to multiple machines
# Usage: ./deploy-bulk.sh <hosts_file> <policy_file> [optional: ssh_key]

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
HOSTS_FILE="${1:-}"
POLICY_FILE="${2:-}"
SSH_KEY="${3:---}"

# Input validation
if [ -z "$HOSTS_FILE" ] || [ -z "$POLICY_FILE" ]; then
  echo -e "${RED}Usage: $0 <hosts_file> <policy_file> [optional: ssh_key]${NC}"
  echo ""
  echo "hosts_file format (one host per line):"
  echo "  user@host1.com"
  echo "  user@host2.com"
  echo "  user@host3.com"
  echo ""
  echo "Example:"
  echo "  ./deploy-bulk.sh ./machines.txt ./POLICIES/enterprise-secure.json ~/.ssh/id_rsa"
  exit 1
fi

if [ ! -f "$HOSTS_FILE" ]; then
  echo -e "${RED}Error: Hosts file not found: $HOSTS_FILE${NC}"
  exit 1
fi

if [ ! -f "$POLICY_FILE" ]; then
  echo -e "${RED}Error: Policy file not found: $POLICY_FILE${NC}"
  exit 1
fi

# Validate policy file
if ! jq empty "$POLICY_FILE" 2>/dev/null; then
  echo -e "${RED}Error: Invalid JSON in policy file${NC}"
  exit 1
fi

echo -e "${BLUE}PermissionPilot Bulk Policy Deployment${NC}"
echo ""
echo "Hosts File: $HOSTS_FILE"
echo "Policy File: $POLICY_FILE"
echo ""

# Count hosts
HOST_COUNT=$(grep -c . "$HOSTS_FILE" || echo 0)
echo "Target Hosts: $HOST_COUNT"
echo ""

# Get policy name
POLICY_NAME=$(jq -r '.name' "$POLICY_FILE")
echo "Policy: $POLICY_NAME"
echo ""

# Confirmation
read -p "Continue with deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Deployment cancelled."
  exit 0
fi

echo ""
echo -e "${BLUE}Deployment Starting...${NC}"
echo ""

# Counters
DEPLOYED=0
FAILED=0
SKIPPED=0

# Deploy to each host
while IFS= read -r HOST; do
  # Skip empty lines and comments
  [ -z "$HOST" ] && continue
  [[ "$HOST" =~ ^# ]] && continue

  echo -ne "Deploying to $HOST... "

  # Create temporary file
  TEMP_POLICY="/tmp/pp_policy_$RANDOM.json"

  # Prepare SSH command
  if [ "$SSH_KEY" != "--" ]; then
    SSH_CMD="ssh -i $SSH_KEY"
  else
    SSH_CMD="ssh"
  fi

  # Deploy steps:
  # 1. Copy policy file via SCP
  # 2. Create directory if needed
  # 3. Move policy to correct location
  # 4. Validate policy
  # 5. Reload daemon

  if scp ${SSH_KEY:+-i $SSH_KEY} "$POLICY_FILE" "$HOST:$TEMP_POLICY" > /dev/null 2>&1; then
    # Remote deployment commands
    DEPLOY_SCRIPT="
      set -e
      mkdir -p ~/Library/Application\ Support/PermissionPilot
      cp $TEMP_POLICY ~/Library/Application\ Support/PermissionPilot/policies.json
      rm $TEMP_POLICY

      # Validate
      if ! jq empty ~/Library/Application\ Support/PermissionPilot/policies.json; then
        exit 1
      fi

      # Reload daemon
      launchctl restart com.permissionpilot.daemon 2>/dev/null || true
    "

    if $SSH_CMD $HOST "$DEPLOY_SCRIPT" > /dev/null 2>&1; then
      echo -e "${GREEN}✓ Success${NC}"
      ((DEPLOYED++))
    else
      echo -e "${RED}✗ Failed${NC}"
      ((FAILED++))
    fi
  else
    echo -e "${RED}✗ Connection failed${NC}"
    ((FAILED++))
  fi

done < "$HOSTS_FILE"

# Summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Deployment Summary                           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Deployed:${NC}  $DEPLOYED/$HOST_COUNT"
echo -e "${RED}Failed:${NC}     $FAILED/$HOST_COUNT"
echo ""

if [ "$FAILED" -eq 0 ]; then
  echo -e "${GREEN}✓ Deployment successful!${NC}"
  exit 0
else
  echo -e "${YELLOW}⚠ Some deployments failed. Check output above.${NC}"
  exit 1
fi
