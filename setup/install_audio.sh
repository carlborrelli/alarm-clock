#!/bin/bash
# Audio device configuration script
# Configures ALSA and PulseAudio for optimal voice and music playback

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_info "Configuring audio devices..."

# List available audio devices
log_info "Available audio playback devices:"
aplay -l

echo ""
log_info "Available audio capture devices:"
arecord -l

# Create ALSA configuration for better compatibility
log_info "Configuring ALSA..."

cat > /etc/asound.conf <<'EOF'
# ALSA configuration for Bedside Voice Clock

# Default PCM device
pcm.!default {
    type asym
    playback.pcm "playback"
    capture.pcm "capture"
}

# Playback device
pcm.playback {
    type plug
    slave.pcm "dmix"
}

# Capture device
pcm.capture {
    type plug
    slave.pcm "dsnoop"
}

# Software mixing
pcm.dmix {
    type dmix
    ipc_key 1024
    slave {
        pcm "hw:0,0"
        period_time 0
        period_size 1024
        buffer_size 4096
        rate 48000
    }
    bindings {
        0 0
        1 1
    }
}

# Software capture
pcm.dsnoop {
    type dsnoop
    ipc_key 2048
    slave {
        pcm "hw:0,0"
        channels 1
        period_time 0
        period_size 1024
        buffer_size 4096
        rate 16000
    }
}

# Control device
ctl.!default {
    type hw
    card 0
}
EOF

log_info "ALSA configuration created at /etc/asound.conf"

# Configure PulseAudio for system-wide use
log_info "Configuring PulseAudio..."

# Enable PulseAudio system mode (optional, for multi-user scenarios)
# For single-user kiosk, user mode is usually fine

# Set default sink and source volumes
log_info "Setting default audio volumes..."

# Unmute and set reasonable defaults
amixer set Master 80% unmute 2>/dev/null || log_warn "Could not set Master volume"
amixer set PCM 90% unmute 2>/dev/null || log_warn "Could not set PCM volume"
amixer set Capture 80% cap 2>/dev/null || log_warn "Could not set Capture volume"

# Test speakers
log_info "Testing speaker output..."
echo "You should hear a test tone in 2 seconds..."
sleep 2
speaker-test -t sine -f 440 -l 1 -c 2 &
SPEAKER_PID=$!
sleep 2
kill $SPEAKER_PID 2>/dev/null || true

echo ""
log_info "Audio configuration complete!"
echo ""
echo "To test your audio setup:"
echo "  Record: arecord -d 3 -f cd test.wav"
echo "  Playback: aplay test.wav"
echo ""
echo "If audio doesn't work:"
echo "  1. Check 'aplay -l' and 'arecord -l' for device numbers"
echo "  2. Update hw:0,0 in /etc/asound.conf to match your devices"
echo "  3. Run 'alsamixer' to adjust volumes"
echo "  4. See docs/TROUBLESHOOTING.md for more help"
echo ""
