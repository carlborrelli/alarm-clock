#!/bin/bash
# Kiosk UI installation script
# Builds the React frontend for the touchscreen display

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
KIOSK_DIR="$PROJECT_DIR/app/kiosk-ui"

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

# Detect user
REAL_USER=${SUDO_USER:-$USER}

log_info "Building kiosk UI..."

# Install Node.js dependencies
cd "$KIOSK_DIR"

log_info "Installing npm dependencies..."
sudo -u $REAL_USER npm install

# Build production version
log_info "Building production bundle..."
sudo -u $REAL_USER npm run build

# Create kiosk launch script
log_info "Creating kiosk launch script..."

cat > "$PROJECT_DIR/app/scripts/launch_kiosk.sh" <<'EOF'
#!/bin/bash
# Kiosk launcher script

# Wait for X server
while ! xset q &>/dev/null; do
    echo "Waiting for X server..."
    sleep 1
done

# Disable screen blanking and power management
xset s off
xset -dpms
xset s noblank

# Hide cursor
unclutter -idle 0.1 -root &

# Set display to not sleep
export DISPLAY=:0
xset s off &

# Clear any existing Chromium sessions
rm -rf /home/$USER/.config/chromium/Singleton*

# Launch Chromium in kiosk mode
chromium-browser \
    --kiosk \
    --noerrdialogs \
    --disable-infobars \
    --no-first-run \
    --enable-features=OverlayScrollbar \
    --start-fullscreen \
    --window-position=0,0 \
    --disable-pinch \
    --overscroll-history-navigation=0 \
    --check-for-update-interval=31536000 \
    --disable-features=TranslateUI \
    --disk-cache-dir=/dev/null \
    --disk-cache-size=1 \
    http://localhost:3000
EOF

chmod +x "$PROJECT_DIR/app/scripts/launch_kiosk.sh"

log_info "Kiosk UI build complete!"
echo ""
echo "Kiosk will be accessible at: http://localhost:3000"
echo "Frontend files are in: $KIOSK_DIR/build"
echo ""
