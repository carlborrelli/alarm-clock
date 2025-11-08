# Testing on Proxmox

This guide explains how to test the Bedside Voice Clock on Proxmox without a physical Raspberry Pi.

## Testing Options

| Option | Complexity | Features Available | Best For |
|--------|-----------|-------------------|----------|
| **Docker Compose** | Easy | UI, logic, HA integration | Quick testing, development |
| **LXC Container** | Medium | Everything except GPU | Full testing with audio |
| **VM** | Medium | Everything | Most realistic testing |

---

## Option 1: Docker Compose (Quickest)

Test the logic, UI, and Home Assistant integration without audio/display hardware.

### Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/carlborrelli/alarm-clock.git
   cd alarm-clock
   ```

2. **Create environment file:**
   ```bash
   cp .env.example .env
   nano .env
   ```

   Update with your Home Assistant details:
   ```bash
   HA_URL=http://192.168.1.100:8123
   HA_TOKEN=your_token_here
   ```

3. **Start services:**
   ```bash
   docker-compose up -d
   ```

### What's Available

**Running services:**
- `kiosk-backend` - Flask API server on port 3000
- `kiosk-dev` - React development server with hot reload on port 3001
- `alarm-fallback` - Alarm service (works without audio)
- `wakeword-mock` - Simulated wake word detection

**Access the UI:**
- Production build: http://localhost:3000
- Development (hot reload): http://localhost:3001

**Trigger mock wake word:**
```bash
# Manual trigger
docker exec -it bedside-clock-wakeword-mock-1 touch /app/config/.wake_detected

# Or use auto mode
# Edit docker-compose.yml, set: MOCK_WAKE_MODE=auto
docker-compose restart wakeword-mock
```

**View logs:**
```bash
docker-compose logs -f kiosk-backend
docker-compose logs -f alarm-fallback
docker-compose logs -f wakeword-mock
```

**Run tests:**
```bash
docker-compose run --rm test-runner
# Inside container:
# cd /tests && ./test_ha_connection.sh
```

### Limitations

- No real wake word detection (uses mock)
- No audio playback
- No Spotify Connect
- Display in browser instead of kiosk mode

### Development Workflow

1. Edit React files in `app/kiosk-ui/src/`
2. Changes auto-reload at http://localhost:3001
3. Edit Python scripts in `app/scripts/`
4. Restart service: `docker-compose restart SERVICE_NAME`

---

## Option 2: LXC Container (Recommended for Full Testing)

Privileged LXC container with audio passthrough - closest to real hardware.

### Create LXC Container in Proxmox

1. **Create Ubuntu LXC container:**
   - Proxmox web UI → Create CT
   - Template: Ubuntu 22.04
   - Disk: 16GB
   - RAM: 2GB
   - CPU: 2 cores
   - **Important:** Check "Unprivileged container" = NO (need privileged for audio)

2. **Start container and get console**

3. **Pass through audio devices (on Proxmox host):**

   Find your container ID (e.g., 100):
   ```bash
   # On Proxmox host
   pct set 100 -mp0 /dev/snd,mp=/dev/snd
   ```

   Or edit config manually:
   ```bash
   nano /etc/pve/lxc/100.conf
   ```

   Add:
   ```
   lxc.cgroup2.devices.allow: c 116:* rwm
   lxc.mount.entry: /dev/snd dev/snd none bind,optional,create=dir
   ```

4. **Restart container:**
   ```bash
   pct stop 100
   pct start 100
   ```

### Setup Inside LXC Container

1. **Update system:**
   ```bash
   apt update && apt upgrade -y
   ```

2. **Install dependencies:**
   ```bash
   apt install -y git curl sudo alsa-utils pulseaudio
   ```

3. **Clone and install:**
   ```bash
   git clone https://github.com/carlborrelli/alarm-clock.git
   cd alarm-clock
   sudo ./setup/install_pi.sh
   ```

4. **Configure audio:**

   Test if audio devices are accessible:
   ```bash
   ls -la /dev/snd/
   aplay -l
   ```

   If no devices, audio passthrough didn't work. Try:
   ```bash
   # Start PulseAudio
   pulseaudio --start
   pactl list sinks
   ```

5. **Configure services:**

   Edit configs as needed:
   ```bash
   nano ~/alarm-clock/app/config/satellite.yaml
   nano ~/alarm-clock/app/config/wakeword.yaml
   ```

6. **Start services:**
   ```bash
   sudo systemctl start wakeword satellite alarm-fallback
   sudo systemctl status wakeword satellite alarm-fallback
   ```

### Testing with Real Audio

**Test speaker (using host audio):**
```bash
speaker-test -t sine -f 440 -l 1
```

**Test microphone:**

If you have a USB mic plugged into Proxmox host, you can pass it through:

```bash
# On Proxmox host
lsusb
# Note Bus and Device numbers for your mic

# Add to LXC config
pct set 100 -usb0 host=BUS:DEVICE
```

Then in container:
```bash
arecord -l
arecord -d 3 test.wav && aplay test.wav
```

### Display/Kiosk

For the kiosk UI in LXC:

**Option A: noVNC (easiest)**

1. **Install X server and noVNC:**
   ```bash
   apt install -y xorg openbox novnc websockify chromium-browser
   ```

2. **Start X server:**
   ```bash
   export DISPLAY=:0
   Xorg -noreset +extension GLX +extension RANDR +extension RENDER -config /etc/X11/xorg.conf :0 &
   ```

3. **Start VNC server:**
   ```bash
   x11vnc -display :0 -forever -shared &
   ```

4. **Start noVNC:**
   ```bash
   websockify --web=/usr/share/novnc/ 6080 localhost:5900 &
   ```

5. **Access:** http://PROXMOX_IP:6080/vnc.html

**Option B: Just test backend**

Skip the kiosk display and access the UI via browser:
```bash
# Don't start kiosk service
sudo systemctl disable kiosk

# Just run backend
cd ~/alarm-clock/app/kiosk-ui
npm install
npm run build
cd ..
python3 scripts/kiosk_server.py &

# Access from your computer
# http://LXC_IP:3000
```

### Spotify in LXC

Spotify Connect (librespot) will work if audio works:

```bash
sudo systemctl start librespot
sudo systemctl status librespot

# Check logs
sudo journalctl -u librespot -f
```

---

## Option 3: Full VM (Most Realistic)

Create a VM with Raspberry Pi OS or Ubuntu Desktop.

### Create VM in Proxmox

1. **Download Raspberry Pi OS (64-bit) or Ubuntu Desktop ISO**

2. **Create VM:**
   - Memory: 2GB
   - CPU: 2 cores
   - Disk: 16GB
   - Network: Bridge to your LAN

3. **Install OS**

4. **Pass through USB audio devices (optional):**

   In Proxmox:
   - Hardware → Add → USB Device
   - Select your USB mic/speaker

### Setup in VM

1. **Install as normal:**
   ```bash
   git clone https://github.com/carlborrelli/alarm-clock.git
   cd alarm-clock
   sudo ./setup/install_pi.sh
   ```

2. **Everything works just like on real Pi!**

3. **Access via console/VNC in Proxmox**

### Advantages

- Exact same environment as Pi
- Full audio support
- Full display support
- Realistic testing

### Disadvantages

- More resource intensive than LXC
- Takes longer to set up

---

## Quick Comparison

### Docker Compose
```bash
# Fastest to test
cd alarm-clock
cp .env.example .env
# Edit .env with your HA URL
docker-compose up -d
# Open http://localhost:3001
```

**Good for:** UI development, backend logic testing

### LXC Container
```bash
# Full testing without VM overhead
# Create LXC in Proxmox web UI
# Inside container:
git clone https://github.com/carlborrelli/alarm-clock.git
cd alarm-clock
sudo ./setup/install_pi.sh
```

**Good for:** Full system testing, audio testing, CI/CD

### VM
```bash
# Most realistic
# Create VM in Proxmox with Pi OS
# Inside VM:
git clone https://github.com/carlborrelli/alarm-clock.git
cd alarm-clock
sudo ./setup/install_pi.sh
# Reboot and done
```

**Good for:** Final testing before deploying to real Pi

---

## Recommended Testing Flow

1. **Start with Docker Compose** to test:
   - Home Assistant integration
   - UI appearance and functionality
   - Alarm logic
   - API endpoints

2. **Move to LXC** to test:
   - Audio configuration
   - Wake word detection (if you can pass through mic)
   - Spotify Connect
   - Service reliability

3. **Use VM** for final validation:
   - Exact Pi environment
   - Full kiosk mode
   - End-to-end testing

4. **Deploy to real Pi** when everything works

---

## Troubleshooting

### Docker Compose Issues

**Container won't start:**
```bash
docker-compose logs SERVICE_NAME
```

**Can't connect to HA:**
- Check .env file has correct HA_URL
- Ensure HA is accessible from Docker network
- Try HA IP instead of hostname

**UI not updating:**
```bash
docker-compose restart kiosk-dev
# Or rebuild
docker-compose build kiosk-dev
```

### LXC Audio Issues

**No /dev/snd:**
- Ensure container is privileged
- Check Proxmox host has audio devices
- Add bind mount in LXC config

**PulseAudio not starting:**
```bash
rm -rf ~/.config/pulse
pulseaudio --start --log-target=syslog
pactl info
```

**Permission denied:**
```bash
usermod -aG audio $USER
```

### VM Issues

**USB passthrough not working:**
- Check USB device isn't in use by host
- Try different USB port
- Check VM has USB controller enabled

**Slow performance:**
- Increase RAM to 4GB
- Add more CPU cores
- Enable KVM acceleration

---

## Development Tips

### Hot Reload for Python Services

Use this technique to develop without rebuilding:

```bash
# With Docker Compose
docker-compose up -d
docker-compose exec kiosk-backend bash

# Inside container
# Edit files on host, they're mounted via volume
# Restart service:
pkill -f kiosk_server.py
python3 /app/scripts/kiosk_server.py &
```

### Testing Wake Word Without Mic

Use the mock service in auto mode:

```yaml
# In docker-compose.yml
wakeword-mock:
  environment:
    - MOCK_WAKE_MODE=auto  # Triggers every 30 seconds
```

Or trigger manually:
```bash
# Docker
docker exec bedside-clock-wakeword-mock-1 touch /app/config/.wake_detected

# LXC/VM
touch ~/alarm-clock/app/config/.wake_detected
```

### Simulating Alarms

Set an alarm for 1 minute from now:

```bash
# Calculate time
TEST_TIME=$(date -d '+1 minute' '+%H:%M:00')

# Create test alarm
echo "{\"alarms\": [{\"time\": \"$TEST_TIME\", \"enabled\": true}]}" > ~/alarm-clock/app/config/alarms.json

# Watch logs
docker-compose logs -f alarm-fallback
# Or
sudo journalctl -u alarm-fallback -f
```

---

## Next Steps

Once testing is successful on Proxmox:

1. Document any issues found
2. Make configuration changes
3. Test thoroughly
4. Deploy to real Raspberry Pi with confidence!

---

## Resource Requirements

| Method | RAM | CPU | Disk | Setup Time |
|--------|-----|-----|------|------------|
| Docker | 512MB | 1 core | 2GB | 5 minutes |
| LXC | 1GB | 2 cores | 8GB | 15 minutes |
| VM | 2GB | 2 cores | 16GB | 30 minutes |

Choose based on your Proxmox resources and testing needs!
