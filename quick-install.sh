#!/bin/bash
# One-command installer for Ubuntu LXC/VM
# Run with: bash <(curl -fsSL https://raw.githubusercontent.com/carlborrelli/alarm-clock/claude/test-connection-011CUumxkd9Hz4Zo9jsKuBLn/quick-install.sh)

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║                                                      ║"
echo "║         Bedside Voice Clock Quick Installer         ║"
echo "║                                                      ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run with sudo:${NC}"
    echo "bash <(curl -fsSL https://raw.githubusercontent.com/carlborrelli/alarm-clock/claude/test-connection-011CUumxkd9Hz4Zo9jsKuBLn/quick-install.sh)"
    exit 1
fi

# Detect actual user
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(eval echo ~$REAL_USER)

echo -e "${GREEN}Installing for user: $REAL_USER${NC}"
echo ""

# Update system
echo -e "${BLUE}[1/5] Updating system packages...${NC}"
apt-get update -qq
apt-get upgrade -y -qq

# Install git if needed
if ! command -v git &> /dev/null; then
    echo -e "${BLUE}Installing git...${NC}"
    apt-get install -y git curl
fi

# Clone repository
INSTALL_DIR="$REAL_HOME/bedside-voice-clock"

if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Directory already exists. Updating...${NC}"
    cd "$INSTALL_DIR"
    sudo -u $REAL_USER git fetch origin
    sudo -u $REAL_USER git reset --hard origin/claude/test-connection-011CUumxkd9Hz4Zo9jsKuBLn
    sudo -u $REAL_USER git clean -fd
else
    echo -e "${BLUE}[2/5] Cloning repository...${NC}"
    cd "$REAL_HOME"
    sudo -u $REAL_USER git clone https://github.com/carlborrelli/alarm-clock.git bedside-voice-clock
    cd bedside-voice-clock
    sudo -u $REAL_USER git checkout claude/test-connection-011CUumxkd9Hz4Zo9jsKuBLn
fi

# Make scripts executable
chmod +x setup/*.sh
chmod +x tests/*.sh

# Run main installer
echo -e "${BLUE}[3/5] Running main installation...${NC}"
./setup/install_pi.sh

# Create update script
echo -e "${BLUE}[4/5] Creating update script...${NC}"
cat > "$INSTALL_DIR/update.sh" <<'UPDATESCRIPT'
#!/bin/bash
# Update Bedside Voice Clock to latest version

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Updating Bedside Voice Clock...${NC}"

cd "$(dirname "$0")"

# Stop services
echo "Stopping services..."
sudo systemctl stop wakeword satellite kiosk librespot alarm-fallback 2>/dev/null || true

# Pull latest changes
echo "Pulling latest code..."
git fetch origin
git reset --hard origin/claude/test-connection-011CUumxkd9Hz4Zo9jsKuBLn
git clean -fd

# Make scripts executable
chmod +x setup/*.sh
chmod +x tests/*.sh

# Reinstall (preserves configs)
echo "Updating installation..."
sudo ./setup/install_pi.sh

# Restart services
echo "Restarting services..."
sudo systemctl restart wakeword satellite kiosk librespot alarm-fallback

echo -e "${GREEN}✓ Update complete!${NC}"
echo ""
echo "Check status: sudo systemctl status wakeword satellite"
UPDATESCRIPT

chmod +x "$INSTALL_DIR/update.sh"
chown $REAL_USER:$REAL_USER "$INSTALL_DIR/update.sh"

# Create quick status script
echo -e "${BLUE}[5/5] Creating helper scripts...${NC}"
cat > "$INSTALL_DIR/status.sh" <<'STATUSSCRIPT'
#!/bin/bash
# Quick status check

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Service Status:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for service in wakeword satellite kiosk librespot alarm-fallback; do
    if systemctl is-active --quiet $service 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $service"
    else
        echo -e "${RED}✗${NC} $service"
    fi
done

echo ""
echo "Quick commands:"
echo "  View logs:    sudo journalctl -u SERVICE_NAME -f"
echo "  Restart all:  sudo systemctl restart wakeword satellite kiosk librespot alarm-fallback"
echo "  Run tests:    ./tests/test_audio.sh"
echo "  Update:       ./update.sh"
STATUSSCRIPT

chmod +x "$INSTALL_DIR/status.sh"
chown $REAL_USER:$REAL_USER "$INSTALL_DIR/status.sh"

# Create restart script
cat > "$INSTALL_DIR/restart.sh" <<'RESTARTSCRIPT'
#!/bin/bash
# Restart all services

echo "Restarting all Bedside Voice Clock services..."
sudo systemctl restart wakeword satellite kiosk librespot alarm-fallback
echo "Done! Check status with: ./status.sh"
RESTARTSCRIPT

chmod +x "$INSTALL_DIR/restart.sh"
chown $REAL_USER:$REAL_USER "$INSTALL_DIR/restart.sh"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                      ║${NC}"
echo -e "${GREEN}║              Installation Complete! 🎉               ║${NC}"
echo -e "${GREEN}║                                                      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Installation directory:${NC} $INSTALL_DIR"
echo ""
echo -e "${BLUE}Quick Commands:${NC}"
echo "  cd ~/bedside-voice-clock"
echo "  ./status.sh          # Check if services are running"
echo "  ./update.sh          # Update to latest version"
echo "  ./restart.sh         # Restart all services"
echo "  ./tests/test_audio.sh   # Test audio"
echo ""
echo -e "${BLUE}Configuration files:${NC}"
echo "  ~/bedside-voice-clock/app/config/satellite.yaml   # HA connection"
echo "  ~/bedside-voice-clock/app/config/wakeword.yaml    # Wake word settings"
echo "  ~/bedside-voice-clock/app/config/librespot.conf   # Spotify"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Configure Home Assistant connection:"
echo "     nano ~/bedside-voice-clock/app/config/satellite.yaml"
echo ""
echo "  2. Check status and logs:"
echo "     cd ~/bedside-voice-clock && ./status.sh"
echo ""
echo "  3. Run tests:"
echo "     ./tests/test_audio.sh"
echo ""
echo -e "${GREEN}For live development with Claude Code:${NC}"
echo "  Just run 'claude' from inside the container!"
echo "  Claude can make changes and restart services automatically."
echo ""
