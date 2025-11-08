#!/bin/bash
# Home Assistant connection test script

set -e

echo "========================================"
echo "Home Assistant Connection Test"
echo "========================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() {
    echo -e "${GREEN}✓ $1${NC}"
}

fail() {
    echo -e "${RED}✗ $1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Get HA URL from config
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$PROJECT_DIR/app/config/satellite.yaml"

if [ ! -f "$CONFIG_FILE" ]; then
    fail "Config file not found: $CONFIG_FILE"
    exit 1
fi

# Extract HA server from YAML (simple grep)
HA_SERVER=$(grep "wyoming_server:" "$CONFIG_FILE" | awk '{print $2}' | tr -d '"')
HA_PORT=$(grep "wyoming_port:" "$CONFIG_FILE" | awk '{print $2}')

if [ -z "$HA_SERVER" ] || [ "$HA_SERVER" = "127.0.0.1" ]; then
    fail "Home Assistant server not configured"
    echo "Edit $CONFIG_FILE and set wyoming_server to your HA IP"
    exit 1
fi

HA_URL="http://${HA_SERVER}:8123"
WYOMING_URL="tcp://${HA_SERVER}:${HA_PORT:-10300}"

echo "Configuration:"
echo "  HA URL: $HA_URL"
echo "  Wyoming: $WYOMING_URL"
echo ""

# Test 1: Ping HA server
echo "Test 1: Network Connectivity"
if ping -c 1 -W 2 "$HA_SERVER" &>/dev/null; then
    pass "Can reach HA server at $HA_SERVER"
else
    fail "Cannot reach HA server at $HA_SERVER"
    exit 1
fi
echo ""

# Test 2: HTTP connection to HA
echo "Test 2: Home Assistant HTTP API"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$HA_URL/api/" || echo "000")

if [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "200" ]; then
    pass "Home Assistant is responding (HTTP $HTTP_CODE)"
else
    fail "Home Assistant not responding (HTTP $HTTP_CODE)"
fi
echo ""

# Test 3: Wyoming port connectivity
echo "Test 3: Wyoming Server Port"
if timeout 2 bash -c "echo > /dev/tcp/$HA_SERVER/${HA_PORT:-10300}" 2>/dev/null; then
    pass "Wyoming port ${HA_PORT:-10300} is open"
else
    warn "Cannot connect to Wyoming port ${HA_PORT:-10300}"
    echo "Make sure Faster-Whisper and Piper addons are running in HA"
fi
echo ""

# Test 4: Satellite service status
echo "Test 4: Satellite Service Status"
if systemctl is-active --quiet satellite; then
    pass "Satellite service is running"
else
    warn "Satellite service is not running"
    echo "Start it with: sudo systemctl start satellite"
fi
echo ""

# Test 5: Check satellite logs
echo "Test 5: Satellite Service Logs (last 20 lines)"
sudo journalctl -u satellite -n 20 --no-pager
echo ""

echo "========================================"
echo "HA Connection Test Complete"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Ensure Wyoming server is configured in HA"
echo "  2. Install Faster-Whisper addon in HA"
echo "  3. Install Piper addon in HA"
echo "  4. Create an Assist pipeline in HA"
echo ""
echo "See docs/CONFIG_HOME_ASSISTANT.md for details"
