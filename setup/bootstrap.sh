#!/bin/bash
# Bootstrap script for Bedside Voice Clock
# This script downloads and runs the full installer

set -e

echo "=========================================="
echo "Bedside Voice Clock Bootstrap Installer"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo:"
    echo "curl -sSL https://raw.githubusercontent.com/yourusername/bedside-voice-clock/main/setup/bootstrap.sh | sudo bash"
    exit 1
fi

# Detect non-root user
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(eval echo ~$REAL_USER)

echo "Installing for user: $REAL_USER"
echo "Home directory: $REAL_HOME"
echo ""

# Install git if not present
if ! command -v git &> /dev/null; then
    echo "Installing git..."
    apt-get update -qq
    apt-get install -y git
fi

# Clone repository
REPO_DIR="$REAL_HOME/bedside-voice-clock"

if [ -d "$REPO_DIR" ]; then
    echo "Repository already exists at $REPO_DIR"
    echo "Pulling latest changes..."
    cd "$REPO_DIR"
    sudo -u $REAL_USER git pull
else
    echo "Cloning repository..."
    cd "$REAL_HOME"
    sudo -u $REAL_USER git clone https://github.com/yourusername/bedside-voice-clock.git
    cd "$REPO_DIR"
fi

# Make scripts executable
chmod +x setup/*.sh
chmod +x tests/*.sh

# Run main installer
echo ""
echo "Starting main installation..."
echo ""
./setup/install_pi.sh

echo ""
echo "=========================================="
echo "Bootstrap complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Configure Home Assistant (see docs/CONFIG_HOME_ASSISTANT.md)"
echo "2. Set up Spotify credentials (see docs/CONFIG_SPOTIFY.md)"
echo "3. Run tests: cd $REPO_DIR && ./tests/test_audio.sh"
echo ""
echo "Reboot recommended: sudo reboot"
