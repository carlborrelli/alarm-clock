#!/bin/bash
# Wake word detection test script

set -e

echo "========================================"
echo "Wake Word Detection Test"
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

# Check if service is running
echo "Test 1: Wake Word Service Status"
if systemctl is-active --quiet wakeword; then
    pass "Wake word service is running"
else
    fail "Wake word service is not running"
    echo "Start it with: sudo systemctl start wakeword"
    exit 1
fi
echo ""

# Check logs
echo "Test 2: Service Logs (last 20 lines)"
sudo journalctl -u wakeword -n 20 --no-pager
echo ""

# Check for wake word models
echo "Test 3: Wake Word Models"
MODEL_DIR="$HOME/.local/share/openwakeword"
if [ -d "$MODEL_DIR" ]; then
    pass "Model directory exists"
    echo "Models found:"
    ls -lh "$MODEL_DIR"/*.tflite 2>/dev/null || warn "No .tflite models found"
else
    fail "Model directory not found"
fi
echo ""

# Check configuration
echo "Test 4: Configuration"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$PROJECT_DIR/app/config/wakeword.yaml"

if [ -f "$CONFIG_FILE" ]; then
    pass "Config file exists"
    echo "Config preview:"
    cat "$CONFIG_FILE"
else
    fail "Config file not found: $CONFIG_FILE"
fi
echo ""

# Live test
echo "Test 5: Live Wake Word Detection"
echo "The wake word service is now listening."
echo "Try saying the wake word (default: 'Hey Mycroft')..."
echo ""
echo "Monitoring logs for 30 seconds..."
echo "Press Ctrl+C to stop early."
echo ""

timeout 30 sudo journalctl -u wakeword -f --since "1 minute ago" | grep -i "wake word detected" || true

echo ""
echo "========================================"
echo "Wake Word Test Complete"
echo "========================================"
echo ""
echo "If wake word detection didn't work:"
echo "  1. Check microphone with: ./tests/test_audio.sh"
echo "  2. Adjust threshold in config: $CONFIG_FILE"
echo "  3. Check logs: sudo journalctl -u wakeword -f"
echo "  4. See docs/TROUBLESHOOTING.md"
