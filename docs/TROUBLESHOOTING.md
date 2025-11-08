# Troubleshooting Guide

Common issues and solutions for the Bedside Voice Clock.

## Quick Diagnostics

Run these commands to check overall system health:

```bash
# Check all service statuses
sudo systemctl status wakeword satellite kiosk librespot alarm-fallback

# Run test suite
cd ~/bedside-voice-clock
./tests/test_audio.sh
./tests/test_wakeword.sh
./tests/test_ha_connection.sh
./tests/test_alarms.sh

# View recent logs
sudo journalctl -u wakeword -n 50
sudo journalctl -u satellite -n 50
```

---

## Wake Word Issues

### Wake word not detected

**Symptoms:**
- Saying wake word does nothing
- No response from system

**Diagnosis:**
```bash
# Check service
sudo systemctl status wakeword

# View logs
sudo journalctl -u wakeword -f

# Test microphone
./tests/test_audio.sh
```

**Solutions:**

1. **Microphone not working:**
   ```bash
   arecord -d 3 test.wav && aplay test.wav
   ```
   If no sound, see [CONFIG_AUDIO.md](CONFIG_AUDIO.md)

2. **Threshold too high:**
   Edit `app/config/wakeword.yaml`:
   ```yaml
   threshold: 0.3  # Lower = more sensitive (default 0.5)
   ```
   Restart: `sudo systemctl restart wakeword`

3. **Wrong wake word model:**
   ```bash
   ls ~/.local/share/openwakeword/
   # Ensure .tflite file matches config
   ```

4. **Service not running:**
   ```bash
   sudo systemctl start wakeword
   sudo systemctl enable wakeword
   ```

### Too many false positives

**Solution:**

Increase threshold in `app/config/wakeword.yaml`:
```yaml
threshold: 0.7  # Higher = less sensitive
```

Restart service:
```bash
sudo systemctl restart wakeword
```

---

## Voice Recognition Issues

### Commands not recognized

**Symptoms:**
- Wake word works, but commands don't execute
- "Sorry, I didn't understand that"

**Diagnosis:**
```bash
# Check satellite service
sudo systemctl status satellite

# View logs
sudo journalctl -u satellite -f

# Test HA connection
./tests/test_ha_connection.sh
```

**Solutions:**

1. **Home Assistant not reachable:**
   ```bash
   # Test connectivity
   ping YOUR_HA_IP

   # Check config
   cat ~/bedside-voice-clock/app/config/satellite.yaml
   ```

   Update `wyoming_server` with correct HA IP.

2. **Wyoming server not running in HA:**
   - Go to HA → Settings → Add-ons
   - Check Faster-Whisper is started
   - Check Piper is started
   - Verify Wyoming protocol integrations are active

3. **Intent not configured:**
   - Check custom sentences are loaded in HA
   - Go to HA → Settings → Voice assistants → Assist
   - Test the same command in HA's assist interface

4. **Wrong language:**
   Ensure HA Assist pipeline is set to English (or your language).

### TTS not working (no voice response)

**Solutions:**

1. **Check Piper addon in HA:**
   - Ensure it's started
   - Check logs for errors

2. **Check speaker:**
   ```bash
   aplay /usr/share/sounds/alsa/Front_Center.wav
   ```

3. **Check media player entity:**
   In HA, verify `media_player.bedside_clock` exists

4. **Volume muted:**
   ```bash
   alsamixer
   # Unmute and increase volume
   ```

---

## Spotify Issues

### Device doesn't appear in Spotify

**Diagnosis:**
```bash
sudo systemctl status librespot
sudo journalctl -u librespot -f
```

**Solutions:**

1. **Service not running:**
   ```bash
   sudo systemctl start librespot
   sudo systemctl enable librespot
   ```

2. **Authentication failed:**
   ```bash
   # Stop service
   sudo systemctl stop librespot

   # Clear cache
   rm -rf ~/.cache/librespot

   # Run manually to re-authenticate
   /usr/local/bin/librespot --name "Bedside Clock" --device default --bitrate 320 --cache ~/.cache/librespot
   # Connect from Spotify app, then Ctrl+C

   # Restart service
   sudo systemctl start librespot
   ```

3. **Network issue:**
   ```bash
   ping spotify.com
   ```

4. **Wrong device name:**
   Check `app/config/librespot.conf` - device name must be unique

See [CONFIG_SPOTIFY.md](CONFIG_SPOTIFY.md) for more details.

### Music plays but can't control it

**Solution:**

Ensure Home Assistant Spotify integration is set up:
- Settings → Integrations → Add → Spotify
- Authorize your account

---

## Alarm Issues

### Alarms not triggering

**Diagnosis:**
```bash
# Check service
sudo systemctl status alarm-fallback

# View logs
sudo journalctl -u alarm-fallback -f

# Check config
cat ~/bedside-voice-clock/app/config/alarms.json
```

**Solutions:**

1. **Service not running:**
   ```bash
   sudo systemctl start alarm-fallback
   sudo systemctl enable alarm-fallback
   ```

2. **Alarm not enabled:**
   Check `alarms.json`:
   ```json
   {
     "alarms": [
       {
         "time": "07:00:00",
         "enabled": true  // Must be true
       }
     ]
   }
   ```

3. **Time format wrong:**
   Use 24-hour format: `"07:00:00"` not `"7:00 AM"`

4. **System time incorrect:**
   ```bash
   date
   # If wrong, set timezone:
   sudo timedatectl set-timezone America/New_York
   ```

5. **HA automation not firing:**
   - Check HA → Settings → Automations
   - Verify alarm automations are enabled
   - Check input_datetime and input_boolean helpers exist

### Alarm plays but won't stop

**Solutions:**

1. **Say:** "Stop alarm"

2. **Touch kiosk screen** (if configured)

3. **Manually stop:**
   ```bash
   sudo systemctl restart alarm-fallback
   ```

---

## Kiosk Display Issues

### Kiosk not showing

**Diagnosis:**
```bash
sudo systemctl status kiosk
sudo journalctl -u kiosk -f
```

**Solutions:**

1. **Service not running:**
   ```bash
   sudo systemctl start kiosk
   sudo systemctl enable kiosk
   ```

2. **X server not running:**
   Ensure you're using the desktop version of Raspberry Pi OS (not Lite).

3. **Build missing:**
   ```bash
   cd ~/bedside-voice-clock/app/kiosk-ui
   npm install
   npm run build
   ```

4. **Port conflict:**
   Check if port 3000 is in use:
   ```bash
   sudo lsof -i :3000
   ```

### Kiosk showing but data not loading

**Solutions:**

1. **Check Home Assistant connection:**
   Edit `app/kiosk-ui/src/config.js`:
   ```javascript
   homeAssistant: {
     url: 'http://YOUR_HA_IP:8123',
     token: 'YOUR_LONG_LIVED_ACCESS_TOKEN'
   }
   ```

2. **Create HA long-lived token:**
   - HA → Profile → Long-Lived Access Tokens
   - Create token and copy to config

3. **Rebuild after config changes:**
   ```bash
   cd ~/bedside-voice-clock/app/kiosk-ui
   npm run build
   sudo systemctl restart kiosk
   ```

### Display too bright/dim

**Solutions:**

1. **Adjust in config:**
   Edit `app/kiosk-ui/src/config.js`:
   ```javascript
   display: {
     dimBrightness: 10,
     normalBrightness: 80,
   }
   ```

2. **Manual brightness:**
   ```bash
   # For official Pi touchscreen (0-255)
   echo 200 > /sys/class/backlight/rpi_backlight/brightness
   ```

3. **Disable auto-dimming:**
   Edit config, set both brightnesses to same value.

---

## Network Issues

### Can't reach Home Assistant

**Diagnosis:**
```bash
ping YOUR_HA_IP
curl http://YOUR_HA_IP:8123/api/
```

**Solutions:**

1. **Wrong IP:**
   Update all configs with correct HA IP:
   - `app/config/satellite.yaml`
   - `app/kiosk-ui/src/config.js`

2. **Firewall blocking:**
   On HA server, ensure ports 8123 and 10300 are open.

3. **WiFi disconnected:**
   ```bash
   ifconfig
   # Check if wlan0 has an IP

   # Reconnect
   sudo systemctl restart NetworkManager
   ```

4. **Static IP recommended:**
   Set static IP for Pi and HA for reliability.

---

## Performance Issues

### System slow or laggy

**Solutions:**

1. **Check CPU usage:**
   ```bash
   top
   # Press 'q' to quit
   ```

2. **Reduce resource limits:**
   Edit service files in `/etc/systemd/system/`:
   ```ini
   CPUQuota=20%  # Reduce from default
   ```

3. **Use smaller models:**
   In HA, switch Faster-Whisper to `tiny` or `base` model (less accurate but faster).

4. **Disable services you don't need:**
   ```bash
   sudo systemctl disable bluetooth
   ```

5. **Overclock Pi (carefully):**
   Edit `/boot/config.txt`:
   ```ini
   over_voltage=4
   arm_freq=1750
   ```

   **Warning:** This may void warranty and requires adequate cooling.

### Audio stuttering

See [CONFIG_AUDIO.md](CONFIG_AUDIO.md) → "Crackling or Poor Quality"

---

## Service Management

### Restart all services

```bash
sudo systemctl restart wakeword satellite kiosk librespot alarm-fallback
```

### View all service logs

```bash
sudo journalctl -f -u wakeword -u satellite -u kiosk -u librespot -u alarm-fallback
```

### Disable a service

```bash
sudo systemctl stop SERVICE_NAME
sudo systemctl disable SERVICE_NAME
```

### Re-enable a service

```bash
sudo systemctl enable SERVICE_NAME
sudo systemctl start SERVICE_NAME
```

---

## Complete Reset

If nothing works, try a fresh install:

```bash
# Stop all services
sudo systemctl stop wakeword satellite kiosk librespot alarm-fallback

# Backup configs
cp -r ~/bedside-voice-clock/app/config ~/config-backup

# Re-run installer
cd ~/bedside-voice-clock
sudo ./setup/install_pi.sh

# Restore configs
cp ~/config-backup/* ~/bedside-voice-clock/app/config/

# Start services
sudo systemctl start wakeword satellite kiosk librespot alarm-fallback
```

---

## Getting Help

### Collect Debug Information

Before asking for help, gather this info:

```bash
# System info
uname -a
cat /etc/os-release

# Service statuses
sudo systemctl status wakeword satellite kiosk librespot alarm-fallback

# Recent logs
sudo journalctl -u wakeword -n 100 > wakeword.log
sudo journalctl -u satellite -n 100 > satellite.log

# Config files (redact sensitive info)
cat ~/bedside-voice-clock/app/config/satellite.yaml
cat ~/bedside-voice-clock/app/config/wakeword.yaml
```

### Report an Issue

Create an issue on GitHub with:
- Description of the problem
- Steps to reproduce
- Service logs (from above)
- What you've already tried

### Community Support

- Home Assistant Community Forums
- Reddit: r/homeassistant
- Discord: Home Assistant

---

## Prevention / Best Practices

1. **Use a good power supply:** Official Pi power supply recommended
2. **Keep system updated:**
   ```bash
   sudo apt update && sudo apt upgrade
   ```
3. **Regular backups:**
   ```bash
   cp -r ~/bedside-voice-clock ~/bedside-voice-clock-backup
   ```
4. **Monitor logs periodically:**
   ```bash
   sudo journalctl -u wakeword --since "1 hour ago"
   ```
5. **Set static IPs** for Pi and HA
6. **Keep HA updated** for latest features and fixes

---

## Useful Commands Reference

```bash
# Service control
sudo systemctl start|stop|restart|status SERVICE_NAME
sudo systemctl enable|disable SERVICE_NAME
sudo journalctl -u SERVICE_NAME -f

# Audio
aplay -l             # List playback devices
arecord -l           # List capture devices
alsamixer            # GUI volume control
amixer set Master 80%

# Network
ping IP_ADDRESS
curl http://IP:PORT/
ifconfig

# System
top                  # CPU/RAM usage
df -h                # Disk space
free -h              # Memory
date                 # Current time
sudo reboot          # Restart Pi

# Logs
journalctl -f        # All system logs live
journalctl -u SERVICE_NAME -f    # Specific service live
journalctl --since "1 hour ago"  # Recent logs
```
