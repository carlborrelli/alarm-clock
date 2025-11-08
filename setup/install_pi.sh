#!/bin/bash
# Main installation script for Raspberry Pi
# Installs all components for the Bedside Voice Clock

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run as root (use sudo)"
    exit 1
fi

# Detect actual user
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(eval echo ~$REAL_USER)

log_info "Installing Bedside Voice Clock for user: $REAL_USER"
log_info "Project directory: $PROJECT_DIR"

# Update system
log_info "Updating system packages..."
apt-get update

# Install base dependencies
log_info "Installing base dependencies..."
apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl \
    wget \
    unzip \
    alsa-utils \
    pulseaudio \
    chromium-browser \
    xorg \
    openbox \
    lightdm \
    nodejs \
    npm \
    jq \
    sox \
    ffmpeg

# Install Python packages
log_info "Setting up Python virtual environment..."
cd "$PROJECT_DIR"
sudo -u $REAL_USER python3 -m venv venv
source venv/bin/activate

log_info "Installing Python dependencies..."
pip install --upgrade pip
pip install -r setup/requirements.txt

deactivate

# Run audio configuration
log_info "Configuring audio devices..."
"$SCRIPT_DIR/install_audio.sh"

# Install Wyoming satellite and dependencies
log_info "Installing Wyoming satellite..."
pip3 install --break-system-packages wyoming wyoming-openwakeword

# Install openWakeWord models
log_info "Downloading openWakeWord models..."
mkdir -p "$REAL_HOME/.local/share/openwakeword"
cd "$REAL_HOME/.local/share/openwakeword"

# Download default wake word model (hey mycroft as example, can be changed)
wget -nc https://github.com/dscripka/openWakeWord/releases/download/v0.5.1/hey_mycroft_v0.1.0.tflite || true

chown -R $REAL_USER:$REAL_USER "$REAL_HOME/.local/share/openwakeword"

# Install Spotify Connect (librespot)
log_info "Installing Spotify Connect (librespot)..."
cd /tmp
if [ ! -f "/usr/local/bin/librespot" ]; then
    ARCH=$(uname -m)
    if [ "$ARCH" = "aarch64" ]; then
        LIBRESPOT_URL="https://github.com/librespot-org/librespot/releases/latest/download/librespot-linux-arm64-v4.tar.gz"
    else
        LIBRESPOT_URL="https://github.com/librespot-org/librespot/releases/latest/download/librespot-linux-armhf.tar.gz"
    fi

    wget -O librespot.tar.gz "$LIBRESPOT_URL"
    tar -xzf librespot.tar.gz
    mv librespot /usr/local/bin/
    chmod +x /usr/local/bin/librespot
    rm librespot.tar.gz
fi

# Build kiosk UI
log_info "Building kiosk UI..."
"$SCRIPT_DIR/install_kiosk.sh"

# Install systemd services
log_info "Installing systemd services..."
"$SCRIPT_DIR/install_services.sh"

# Configure auto-login for kiosk
log_info "Configuring auto-login..."
mkdir -p /etc/lightdm/lightdm.conf.d/
cat > /etc/lightdm/lightdm.conf.d/50-autologin.conf <<EOF
[Seat:*]
autologin-user=$REAL_USER
autologin-user-timeout=0
EOF

# Configure openbox to start kiosk
log_info "Configuring openbox..."
mkdir -p "$REAL_HOME/.config/openbox"
cat > "$REAL_HOME/.config/openbox/autostart" <<'EOF'
# Disable screen blanking
xset s off
xset -dpms
xset s noblank

# Hide cursor after inactivity
unclutter -idle 0.1 &

# Start kiosk (systemd will actually handle this, but this is a backup)
# The kiosk.service will be the primary method
EOF

chown -R $REAL_USER:$REAL_USER "$REAL_HOME/.config"

# Install unclutter for hiding mouse cursor
apt-get install -y unclutter

# Create config directories
log_info "Creating configuration directories..."
mkdir -p "$PROJECT_DIR/app/config"
mkdir -p "$PROJECT_DIR/logs"
chown -R $REAL_USER:$REAL_USER "$PROJECT_DIR"

# Set up default wake word config if not exists
if [ ! -f "$PROJECT_DIR/app/config/wakeword.yaml" ]; then
    log_info "Creating default wake word configuration..."
    cat > "$PROJECT_DIR/app/config/wakeword.yaml" <<EOF
# Wake word configuration
wake_word_model: "hey_mycroft_v0.1.0.tflite"
threshold: 0.5
trigger_level: 1

# Audio settings
sample_rate: 16000
chunk_size: 1024

# Model directory
model_dir: "$REAL_HOME/.local/share/openwakeword"
EOF
    chown $REAL_USER:$REAL_USER "$PROJECT_DIR/app/config/wakeword.yaml"
fi

# Set up default satellite config if not exists
if [ ! -f "$PROJECT_DIR/app/config/satellite.yaml" ]; then
    log_info "Creating default satellite configuration..."
    cat > "$PROJECT_DIR/app/config/satellite.yaml" <<EOF
# Wyoming satellite configuration
# IMPORTANT: Update these values with your Home Assistant details

# Home Assistant Wyoming server
wyoming_server: "127.0.0.1"  # CHANGE THIS to your HA IP
wyoming_port: 10300

# Audio settings
microphone:
  device: "default"
  rate: 16000
  channels: 1
  width: 2

speaker:
  device: "default"
  rate: 22050
  channels: 1
  width: 2

# Wake word
wake_word_enabled: false  # We use separate openWakeWord service
awake_wav: null
done_wav: null

# Volume ducking during voice interaction
auto_duck: true
duck_volume: 0.3

# Debug
debug: false
EOF
    chown $REAL_USER:$REAL_USER "$PROJECT_DIR/app/config/satellite.yaml"
fi

# Create default alarms config
if [ ! -f "$PROJECT_DIR/app/config/alarms.json" ]; then
    log_info "Creating default alarms configuration..."
    echo '{"alarms": []}' > "$PROJECT_DIR/app/config/alarms.json"
    chown $REAL_USER:$REAL_USER "$PROJECT_DIR/app/config/alarms.json"
fi

# Create default librespot config
if [ ! -f "$PROJECT_DIR/app/config/librespot.conf" ]; then
    log_info "Creating default librespot configuration..."
    cat > "$PROJECT_DIR/app/config/librespot.conf" <<EOF
# Spotify Connect configuration
# Get credentials from: https://developer.spotify.com/dashboard

# Device name (appears in Spotify Connect list)
DEVICE_NAME="Bedside Clock"

# Audio device
AUDIO_DEVICE="default"

# Bitrate (96, 160, 320)
BITRATE="320"

# Volume control
VOLUME_CTRL="softvol"
INITIAL_VOLUME="50"

# Cache settings
CACHE_DIR="$REAL_HOME/.cache/librespot"

# Credentials (CHANGE THESE)
USERNAME=""
PASSWORD=""

# Or use token authentication (recommended)
# Run librespot manually once to get cached credentials
EOF
    chown $REAL_USER:$REAL_USER "$PROJECT_DIR/app/config/librespot.conf"
fi

log_info "Installation complete!"
echo ""
echo "=========================================="
echo "Next Steps:"
echo "=========================================="
echo ""
echo "1. Configure Home Assistant connection:"
echo "   Edit: $PROJECT_DIR/app/config/satellite.yaml"
echo "   Set your Home Assistant IP and Wyoming port"
echo ""
echo "2. Configure Spotify (see docs/CONFIG_SPOTIFY.md):"
echo "   Edit: $PROJECT_DIR/app/config/librespot.conf"
echo ""
echo "3. Update kiosk UI settings:"
echo "   Edit: $PROJECT_DIR/app/kiosk-ui/src/config.js"
echo "   Set your Home Assistant URL and access token"
echo ""
echo "4. Enable and start services:"
echo "   sudo systemctl enable wakeword satellite kiosk librespot alarm-fallback"
echo "   sudo systemctl start wakeword satellite kiosk librespot alarm-fallback"
echo ""
echo "5. Run tests:"
echo "   cd $PROJECT_DIR"
echo "   ./tests/test_audio.sh"
echo "   ./tests/test_wakeword.sh"
echo ""
echo "6. Configure Home Assistant (see docs/CONFIG_HOME_ASSISTANT.md)"
echo ""
echo "7. Reboot to start kiosk mode:"
echo "   sudo reboot"
echo ""
echo "=========================================="
