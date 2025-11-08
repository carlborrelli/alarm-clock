# Spotify Configuration Guide

This guide explains how to set up Spotify Connect on your Bedside Voice Clock.

## What is Spotify Connect?

Spotify Connect allows your Raspberry Pi to appear as a playback device in the Spotify app. You can:
- Play music from any Spotify client (phone, computer, etc.) to the bedside clock
- Control playback via voice commands
- See "now playing" information on the kiosk display

## Prerequisites

- Spotify Premium account (required for Connect)
- Raspberry Pi with speakers configured

## Option 1: Using Cached Credentials (Recommended)

This method is simpler and doesn't require Spotify API credentials.

### Step 1: Stop the librespot service

```bash
sudo systemctl stop librespot
```

### Step 2: Run librespot manually once

```bash
/usr/local/bin/librespot \
  --name "Bedside Clock" \
  --device "default" \
  --bitrate 320 \
  --cache /home/$USER/.cache/librespot \
  --enable-volume-normalisation
```

### Step 3: Connect from Spotify app

1. Open Spotify on your phone or computer
2. Start playing a song
3. Tap the "Devices Available" button (icon with a speaker and waves)
4. Select "Bedside Clock" from the list
5. Librespot will authenticate and cache credentials

### Step 4: Press Ctrl+C to stop

Once you see "Connected" or music starts playing, press Ctrl+C.

### Step 5: Restart the service

```bash
sudo systemctl start librespot
sudo systemctl enable librespot
```

Your credentials are now cached, and the device will appear automatically when the service runs.

## Option 2: Using Spotify API Credentials

For more control, you can use Spotify API credentials.

### Step 1: Get Spotify API Credentials

1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Log in with your Spotify account
3. Click **Create App**
4. Fill in:
   - **App name**: Bedside Clock
   - **App description**: Personal voice-controlled alarm clock
   - **Redirect URI**: http://localhost:8888/callback
   - **API**: Check "Web Playback SDK" and "Web API"
5. Click **Create**
6. Note your **Client ID** and **Client Secret**

### Step 2: Configure librespot

Edit the configuration file:

```bash
nano ~/bedside-voice-clock/app/config/librespot.conf
```

Update with your credentials:

```bash
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
CACHE_DIR="/home/$USER/.cache/librespot"

# Credentials
USERNAME="your_spotify_email@example.com"
PASSWORD="your_spotify_password"
```

**Note:** For security, it's better to use cached credentials (Option 1) rather than storing your password in plaintext.

### Step 3: Restart librespot

```bash
sudo systemctl restart librespot
```

## Customization

### Change Device Name

Edit `~/bedside-voice-clock/app/config/librespot.conf`:

```bash
DEVICE_NAME="Your Custom Name"
```

Then restart:
```bash
sudo systemctl restart librespot
```

### Adjust Audio Quality

Lower bitrate for bandwidth savings:
```bash
BITRATE="160"  # or 96 for lowest
```

Higher bitrate for best quality (requires good network):
```bash
BITRATE="320"
```

### Change Audio Output Device

List available devices:
```bash
aplay -L
```

Update config:
```bash
AUDIO_DEVICE="hw:0,0"  # or your device
```

### Volume Normalization

Keeps volume consistent across tracks. Already enabled by default:
```bash
--enable-volume-normalisation
```

To disable, remove this flag from the systemd service file.

## Home Assistant Integration

To control Spotify from Home Assistant:

### Option 1: Spotify Integration (Official)

1. Go to **Settings** → **Devices & Services** → **Add Integration**
2. Search for "Spotify"
3. Click **Configure**
4. Follow OAuth flow to authorize
5. Your Spotify account and devices will be added as `media_player` entities

### Option 2: Spotcast (Advanced)

For more features like playing specific playlists:

1. Install via HACS: **Spotcast**
2. Configure with your Spotify credentials
3. Use service calls to start playback

## Voice Commands for Spotify

Once configured, you can use voice commands:

- "Play music" - Resume playback
- "Pause music" - Pause
- "Skip this song" - Next track
- "Volume up" / "Volume down"
- "Play my morning playlist" (requires Home Assistant Spotify integration)

## Testing

### Test 1: Device Visibility

```bash
# Check if librespot is running
sudo systemctl status librespot

# View logs
sudo journalctl -u librespot -f
```

Open Spotify on your phone and check if "Bedside Clock" appears in the device list.

### Test 2: Playback

1. Select "Bedside Clock" in Spotify
2. Play a song
3. Music should play through the Pi's speakers

### Test 3: Voice Control

1. Say wake word: "Hey Mycroft"
2. Say: "Pause music"
3. Music should pause

## Troubleshooting

### Device doesn't appear in Spotify

**Check service status:**
```bash
sudo systemctl status librespot
```

**Check logs for errors:**
```bash
sudo journalctl -u librespot -n 50
```

**Common fixes:**
- Restart service: `sudo systemctl restart librespot`
- Clear cache: `rm -rf ~/.cache/librespot`
- Check network connection
- Verify Spotify Premium subscription

### Authentication failed

**Cached credentials expired:**
```bash
sudo systemctl stop librespot
rm -rf ~/.cache/librespot
# Run manual authentication again (see Option 1)
```

**Wrong username/password:**
- Update `librespot.conf` with correct credentials
- Use cached auth method instead

### No audio output

**Check audio device:**
```bash
aplay -l
```

**Test speaker:**
```bash
./tests/test_audio.sh
```

**Update audio device in config:**
```bash
nano ~/bedside-voice-clock/app/config/librespot.conf
```

### Audio quality issues

**Increase bitrate:**
```bash
BITRATE="320"
```

**Check network bandwidth:**
```bash
ping -c 10 spotify.com
```

### Volume too low/high

**Adjust initial volume in config:**
```bash
INITIAL_VOLUME="70"  # 0-100
```

**Adjust system volume:**
```bash
alsamixer
```

## Advanced Configuration

### Running Multiple Instances

To have multiple Spotify devices:

1. Copy service file: `cp /etc/systemd/system/librespot.service /etc/systemd/system/librespot2.service`
2. Edit with different name and cache directory
3. Enable: `sudo systemctl enable librespot2`

### Custom Backend

Use different audio backend:

```bash
--backend pulseaudio
# or
--backend pipe
```

### Format and Normalization

```bash
--format F32        # Audio format
--normalisation-pregain -10  # Adjust volume scaling
```

See `librespot --help` for all options.

## Security Notes

- **Don't commit credentials to Git**: Add `librespot.conf` to `.gitignore`
- **Use cached authentication**: Safer than storing passwords
- **Restrict file permissions**: `chmod 600 librespot.conf`

## Additional Resources

- [librespot Documentation](https://github.com/librespot-org/librespot)
- [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
- [Spotify Web API](https://developer.spotify.com/documentation/web-api/)
