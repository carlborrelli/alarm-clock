#!/bin/bash
# Systemd services installation script
# Installs all systemd service files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Detect user
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(eval echo ~$REAL_USER)

log_info "Installing systemd services..."

# Copy service files to systemd directory
for service in "$PROJECT_DIR/services"/*.service; do
    if [ -f "$service" ]; then
        service_name=$(basename "$service")
        log_info "Installing $service_name..."

        # Replace placeholders in service files
        sed -e "s|{PROJECT_DIR}|$PROJECT_DIR|g" \
            -e "s|{USER}|$REAL_USER|g" \
            -e "s|{HOME}|$REAL_HOME|g" \
            "$service" > "/etc/systemd/system/$service_name"
    fi
done

# Reload systemd
log_info "Reloading systemd daemon..."
systemctl daemon-reload

log_info "Systemd services installed!"
echo ""
echo "Available services:"
echo "  - wakeword.service       (Wake word detection)"
echo "  - satellite.service      (Wyoming satellite for ASR/TTS)"
echo "  - kiosk.service         (Touchscreen UI)"
echo "  - librespot.service     (Spotify Connect)"
echo "  - alarm-fallback.service (Local alarm failsafe)"
echo ""
echo "To enable all services:"
echo "  sudo systemctl enable wakeword satellite kiosk librespot alarm-fallback"
echo ""
echo "To start all services:"
echo "  sudo systemctl start wakeword satellite kiosk librespot alarm-fallback"
echo ""
echo "To check status:"
echo "  sudo systemctl status wakeword satellite kiosk librespot alarm-fallback"
echo ""
