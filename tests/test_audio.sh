#!/bin/bash
# Audio testing script for Bedside Voice Clock

set -e

echo "========================================"
echo "Audio System Test"
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

# Test 1: List audio devices
echo "Test 1: Audio Devices"
echo "Playback devices:"
aplay -l
echo ""
echo "Capture devices:"
arecord -l
echo ""

# Test 2: Test speaker
echo "Test 2: Speaker Output"
echo "Playing a test tone for 2 seconds..."
echo "You should hear a 440Hz tone."
echo ""
speaker-test -t sine -f 440 -l 1 -c 2 &
SPEAKER_PID=$!
sleep 2
kill $SPEAKER_PID 2>/dev/null || true
echo ""
read -p "Did you hear the tone? (y/n): " heard_tone

if [ "$heard_tone" = "y" ]; then
    pass "Speaker output working"
else
    fail "Speaker output not working"
    warn "Check speaker connection and volume"
fi
echo ""

# Test 3: Test microphone
echo "Test 3: Microphone Input"
echo "Recording 3 seconds of audio..."
arecord -d 3 -f cd /tmp/test_recording.wav
echo "Playing back recording..."
aplay /tmp/test_recording.wav
echo ""
read -p "Did you hear your voice played back? (y/n): " heard_voice

if [ "$heard_voice" = "y" ]; then
    pass "Microphone input working"
else
    fail "Microphone input not working"
    warn "Check microphone connection"
fi
rm -f /tmp/test_recording.wav
echo ""

# Test 4: Volume levels
echo "Test 4: Volume Levels"
amixer get Master
echo ""
amixer get Capture
echo ""

# Test 5: ALSA configuration
echo "Test 5: ALSA Configuration"
if [ -f /etc/asound.conf ]; then
    pass "ALSA config exists"
    echo "Config preview:"
    head -20 /etc/asound.conf
else
    warn "ALSA config not found"
fi
echo ""

echo "========================================"
echo "Audio Test Complete"
echo "========================================"
echo ""
echo "If any tests failed:"
echo "  1. Check connections"
echo "  2. Run 'alsamixer' to adjust volumes"
echo "  3. See docs/TROUBLESHOOTING.md"
