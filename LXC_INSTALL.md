# LXC Installation Guide

Dead simple installation for Ubuntu LXC containers on Proxmox.

## Step 1: Create LXC Container

In Proxmox web UI:

1. Click **Create CT**
2. **General:**
   - Hostname: `bedside-clock`
   - Password: (your choice)
   - Unprivileged container: **NO** (uncheck - we need privileged for audio)
3. **Template:**
   - Storage: local
   - Template: `ubuntu-22.04-standard`
4. **Disks:**
   - Disk size: 16 GB
5. **CPU:**
   - Cores: 2
6. **Memory:**
   - Memory: 2048 MB
   - Swap: 512 MB
7. **Network:**
   - Bridge: vmbr0
   - IPv4: DHCP (or static)
8. Click **Finish**

## Step 2: Pass Through Audio (Optional but Recommended)

In Proxmox shell (or SSH to Proxmox host):

```bash
# Replace 100 with your container ID
CT_ID=100

# Add audio device access
pct set $CT_ID -mp0 /dev/snd,mp=/dev/snd

# Restart container
pct stop $CT_ID
pct start $CT_ID
```

Or edit config manually:

```bash
nano /etc/pve/lxc/100.conf
```

Add these lines:
```
lxc.cgroup2.devices.allow: c 116:* rwm
lxc.mount.entry: /dev/snd dev/snd none bind,optional,create=dir
```

## Step 3: Start Container & Get Console

In Proxmox UI:
- Select your container
- Click **Start**
- Click **Console**

Or use SSH:
```bash
# From Proxmox host
pct enter 100
```

## Step 4: Install Bedside Voice Clock

**Copy and paste this ONE command:**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/carlborrelli/alarm-clock/claude/test-connection-011CUumxkd9Hz4Zo9jsKuBLn/quick-install.sh)
```

That's it! Wait 5-10 minutes for installation.

## Step 5: Configure

```bash
cd ~/bedside-voice-clock

# 1. Set your Home Assistant IP
nano app/config/satellite.yaml
# Change: wyoming_server: "YOUR_HA_IP"

# 2. Restart services
./restart.sh

# 3. Check everything is running
./status.sh
```

## Step 6: Test

```bash
cd ~/bedside-voice-clock

# Test audio
./tests/test_audio.sh

# Test wake word
./tests/test_wakeword.sh

# Test HA connection
./tests/test_ha_connection.sh
```

## Useful Commands

```bash
cd ~/bedside-voice-clock

./status.sh          # Check service status
./restart.sh         # Restart all services
./update.sh          # Update to latest version

# View logs
sudo journalctl -u wakeword -f
sudo journalctl -u satellite -f

# Edit configs
nano app/config/satellite.yaml
nano app/config/wakeword.yaml
nano app/config/librespot.conf
```

## Live Development with Claude Code

If you have Claude Code installed, you can run it FROM INSIDE the container:

```bash
cd ~/bedside-voice-clock
claude
```

Then ask Claude to:
- "Change the wake word sensitivity"
- "Update the Home Assistant IP in the config"
- "Restart the satellite service"
- "Show me the logs for the alarm service"

Claude can edit files, restart services, run tests, and debug issues all from within the container!

## Updating

When we make changes to the code:

```bash
cd ~/bedside-voice-clock
./update.sh
```

This will:
- Pull latest code
- Preserve your configs
- Reinstall dependencies if needed
- Restart services

## Accessing the Kiosk UI

The kiosk UI runs on port 3000:

**From your computer's browser:**
```
http://CONTAINER_IP:3000
```

Find container IP:
```bash
hostname -I
```

## Troubleshooting

**Services not starting:**
```bash
./status.sh
sudo journalctl -u SERVICE_NAME -n 50
```

**Audio not working:**
```bash
ls -la /dev/snd/
aplay -l
```

If no audio devices, the passthrough didn't work. Redo Step 2.

**Can't reach Home Assistant:**
```bash
ping YOUR_HA_IP
cat app/config/satellite.yaml
```

**Update failed:**
```bash
cd ~/bedside-voice-clock
git reset --hard origin/claude/test-connection-011CUumxkd9Hz4Zo9jsKuBLn
./update.sh
```

## Complete Reinstall

If something breaks badly:

```bash
cd ~
sudo rm -rf bedside-voice-clock
bash <(curl -fsSL https://raw.githubusercontent.com/carlborrelli/alarm-clock/claude/test-connection-011CUumxkd9Hz4Zo9jsKuBLn/quick-install.sh)
```

## What Works in LXC

✅ **Everything except:**
- GPU acceleration (not needed)
- Fancy Chromium kiosk effects

✅ **What definitely works:**
- Wake word detection (with audio passthrough)
- Voice commands via Wyoming satellite
- Home Assistant integration
- Spotify Connect (with audio)
- Alarms
- All Python services
- React kiosk UI (access via browser)
- Audio playback and recording

## Resource Usage

Typical usage:
- RAM: ~1GB used
- CPU: 10-20% average
- Disk: ~4GB after install

## Tips

1. **Set static IP** for the container in Proxmox (easier to access UI)
2. **Snapshot** your container after successful setup
3. **Use the update script** instead of manually pulling git changes
4. **Run status.sh** regularly to check health
5. **Use Claude Code** from inside the container for easy changes!

## Need Help?

```bash
cd ~/bedside-voice-clock

# Check all logs
sudo journalctl -xe

# Run all tests
./tests/test_audio.sh
./tests/test_wakeword.sh
./tests/test_ha_connection.sh
./tests/test_alarms.sh

# Check service status
./status.sh
```

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for common issues.
