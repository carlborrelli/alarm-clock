#!/bin/bash
# Alarm system test script

set -e

echo "========================================"
echo "Alarm System Test"
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

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ALARMS_FILE="$PROJECT_DIR/app/config/alarms.json"

# Test 1: Alarm service status
echo "Test 1: Alarm Fallback Service Status"
if systemctl is-active --quiet alarm-fallback; then
    pass "Alarm fallback service is running"
else
    fail "Alarm fallback service is not running"
    echo "Start it with: sudo systemctl start alarm-fallback"
fi
echo ""

# Test 2: Alarms config file
echo "Test 2: Alarms Configuration"
if [ -f "$ALARMS_FILE" ]; then
    pass "Alarms config exists"
    echo "Current alarms:"
    cat "$ALARMS_FILE" | jq '.' 2>/dev/null || cat "$ALARMS_FILE"
else
    warn "No alarms configured yet"
fi
echo ""

# Test 3: Set a test alarm
echo "Test 3: Create Test Alarm"
echo "Creating a test alarm for 1 minute from now..."

# Calculate time 1 minute from now
TEST_TIME=$(date -d '+1 minute' '+%H:%M:00')
echo "Test alarm time: $TEST_TIME"

# Create test alarm
cat > "$ALARMS_FILE" <<EOF
{
  "alarms": [
    {
      "time": "$TEST_TIME",
      "enabled": true,
      "days": []
    }
  ]
}
EOF

pass "Test alarm created"
echo ""

# Test 4: Check service logs
echo "Test 4: Service Logs (last 20 lines)"
sudo journalctl -u alarm-fallback -n 20 --no-pager
echo ""

# Test 5: Wait for alarm
echo "Test 5: Waiting for Alarm to Trigger"
echo "The test alarm should trigger at $TEST_TIME"
echo "Watching logs for 90 seconds..."
echo "You should hear an alarm sound when it triggers."
echo ""

timeout 90 sudo journalctl -u alarm-fallback -f --since "1 minute ago" | grep -m 1 "Alarm triggered" || warn "Alarm did not trigger within 90 seconds"

echo ""
echo "========================================"
echo "Alarm Test Complete"
echo "========================================"
echo ""
echo "If the alarm didn't trigger:"
echo "  1. Check service logs: sudo journalctl -u alarm-fallback -f"
echo "  2. Verify alarm config: cat $ALARMS_FILE"
echo "  3. Check system time: date"
echo "  4. See docs/TROUBLESHOOTING.md"
echo ""
echo "To remove test alarm:"
echo "  echo '{\"alarms\": []}' > $ALARMS_FILE"
