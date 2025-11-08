# Bedside Voice Clock for Raspberry Pi

A fast, privacy-focused smart alarm clock powered by Raspberry Pi and Home Assistant. Features voice control, Spotify playback, calendar integration, weather display, and reliable offline alarms.

## Features

- **Voice Control**: Wake word detection + fast command processing via Home Assistant Assist
- **Spotify Connect**: Pi appears as a Spotify Connect device for music playback
- **Smart Alarms**: Multiple alarms with Home Assistant integration and local failsafe
- **Calendar Integration**: Syncs with iCloud/CalDAV calendars
- **Weather Display**: Current and forecast weather
- **Touch Display**: Auto-dimming kiosk interface with clock, media controls, and quick toggles
- **Home Assistant Integration**: Control lights, scenes, and devices
- **Offline Resilient**: Critical functions (alarms, clock) work without network

## Architecture

This project uses a **Hybrid Pi + Home Assistant Server** architecture:

- **Raspberry Pi**: Wake word detection, audio I/O, Spotify endpoint, kiosk UI, alarm failsafe
- **Home Assistant Server**: ASR (Faster-Whisper), TTS (Piper), intent processing, automations
- **Protocol**: Wyoming for voice pipeline
- **Latency**: 800-1200ms wake word to response

## Testing Without a Raspberry Pi

Don't have a Pi yet? You can test and develop on any Linux machine, Proxmox, or Docker:

### Quick Test with Docker

```bash
git clone https://github.com/yourusername/bedside-voice-clock.git
cd bedside-voice-clock
cp .env.example .env
# Edit .env with your Home Assistant URL
./dev-start.sh
```

Access the UI at http://localhost:3001

**What works:** Kiosk UI, alarm logic, Home Assistant integration, backend APIs
**What doesn't:** Real wake word detection (uses mock), audio playback

### Full Testing on Proxmox

See [docs/PROXMOX_TESTING.md](docs/PROXMOX_TESTING.md) for detailed instructions on:
- LXC containers with audio passthrough
- Full VM testing with Pi OS
- Development workflow options

## Quick Start

### Prerequisites

- Raspberry Pi 4 or 5 with Raspberry Pi OS (64-bit recommended)
- USB microphone or ReSpeaker hat
- Speaker (3.5mm, USB, or HDMI audio)
- 7-10" touchscreen display
- Home Assistant server (2024.5+) with:
  - Faster-Whisper addon installed
  - Piper addon installed
  - Assist pipeline configured

### One-Command Installation

```bash
curl -sSL https://raw.githubusercontent.com/yourusername/bedside-voice-clock/main/setup/bootstrap.sh | bash
```

Or clone and run manually:

```bash
git clone https://github.com/yourusername/bedside-voice-clock.git
cd bedside-voice-clock
sudo ./setup/install_pi.sh
```

The installer will:
1. Install all dependencies
2. Configure audio devices
3. Set up wake word detection
4. Install Wyoming satellite
5. Configure Spotify Connect
6. Build and deploy kiosk UI
7. Create systemd services
8. Set up local alarm failsafe

### Post-Installation Configuration

After the Pi setup completes:

1. **Configure Home Assistant** (see [docs/CONFIG_HOME_ASSISTANT.md](docs/CONFIG_HOME_ASSISTANT.md))
   - Import intent sentences
   - Add automations
   - Set up calendar integration
   - Install Lovelace dashboard

2. **Configure Spotify** (see [docs/CONFIG_SPOTIFY.md](docs/CONFIG_SPOTIFY.md))
   - Get Spotify credentials
   - Update librespot config

3. **Test the System** (see [docs/TESTING.md](docs/TESTING.md))
   ```bash
   # Test audio
   ./tests/test_audio.sh

   # Test wake word
   ./tests/test_wakeword.sh

   # Test Home Assistant connection
   ./tests/test_ha_connection.sh

   # Test alarms
   ./tests/test_alarms.sh
   ```

## Repository Structure

```
bedside-voice-clock/
├── README.md                          # This file
├── setup/
│   ├── bootstrap.sh                   # One-command installer
│   ├── install_pi.sh                  # Main Pi installation script
│   ├── install_audio.sh               # Audio device configuration
│   ├── install_kiosk.sh               # Kiosk UI setup
│   ├── install_services.sh            # Systemd service installation
│   └── requirements.txt               # Python dependencies
├── services/
│   ├── wakeword.service               # openWakeWord systemd service
│   ├── satellite.service              # Wyoming satellite service
│   ├── kiosk.service                  # Chromium kiosk service
│   ├── librespot.service              # Spotify Connect service
│   └── alarm-fallback.service         # Local alarm failsafe service
├── app/
│   ├── kiosk-ui/                      # React touchscreen interface
│   │   ├── package.json
│   │   ├── public/
│   │   └── src/
│   ├── scripts/
│   │   ├── wakeword_runner.py         # Wake word detection script
│   │   ├── satellite_runner.py        # Wyoming satellite script
│   │   ├── alarm_fallback.py          # Local alarm failsafe
│   │   └── kiosk_server.py            # Kiosk backend API
│   └── config/
│       ├── wakeword.yaml              # Wake word configuration
│       ├── satellite.yaml             # Wyoming satellite config
│       ├── librespot.conf             # Spotify Connect config
│       └── alarms.json                # Local alarm storage
├── home-assistant/
│   ├── intents/
│   │   └── custom_sentences.yaml      # Intent definitions
│   ├── automations/
│   │   ├── alarms.yaml                # Alarm automations
│   │   ├── lights.yaml                # Light control
│   │   └── calendar.yaml              # Calendar notifications
│   └── dashboards/
│       └── bedside.yaml               # Lovelace dashboard
├── docs/
│   ├── CONFIG_AUDIO.md                # Audio setup guide
│   ├── CONFIG_HOME_ASSISTANT.md       # HA configuration guide
│   ├── CONFIG_SPOTIFY.md              # Spotify setup guide
│   ├── TESTING.md                     # Testing procedures
│   └── TROUBLESHOOTING.md             # Common issues & fixes
└── tests/
    ├── test_audio.sh                  # Audio verification
    ├── test_wakeword.sh               # Wake word test
    ├── test_ha_connection.sh          # HA connectivity test
    └── test_alarms.sh                 # Alarm system test
```

## Voice Commands

Once configured, you can use commands like:

### Alarms
- "Set alarm for 6:30 AM"
- "Set alarm for 7 AM on weekdays"
- "What alarms are set?"
- "Cancel my 6 AM alarm"
- "Cancel all alarms"

### Lights
- "Turn on the bedroom light"
- "Turn off all lights"
- "Set bedroom to 50 percent"
- "Activate night mode"

### Music
- "Play my morning playlist"
- "Play music by The Beatles"
- "Pause music"
- "Skip this song"
- "Volume up"

### Information
- "What's the weather?"
- "What's the forecast for tomorrow?"
- "What's on my calendar today?"
- "What time is it?"

### Questions (via ChatGPT fallback)
- "What's the capital of France?"
- "How do I make pancakes?"

## Customization

### Change Wake Word
Edit `app/config/wakeword.yaml` and restart the service:
```bash
sudo systemctl restart wakeword
```

### Adjust Display Brightness
Edit kiosk UI settings in `app/kiosk-ui/src/config.js`

### Add New Intents
Add to `home-assistant/intents/custom_sentences.yaml` and reload HA automations

## Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for common issues.

Quick checks:
```bash
# Check service status
sudo systemctl status wakeword satellite kiosk librespot alarm-fallback

# View logs
sudo journalctl -u satellite -f

# Test microphone
arecord -d 3 test.wav && aplay test.wav

# Check HA connection
curl -H "Authorization: Bearer YOUR_TOKEN" http://YOUR_HA_IP:8123/api/
```

## Contributing

Contributions welcome! Please open issues or pull requests.

## License

MIT License - See LICENSE file for details

## Acknowledgments

- [Home Assistant](https://www.home-assistant.io/)
- [Wyoming Protocol](https://github.com/rhasspy/wyoming)
- [openWakeWord](https://github.com/dscripka/openWakeWord)
- [Piper TTS](https://github.com/rhasspy/piper)
- [Faster-Whisper](https://github.com/guillaumekln/faster-whisper)
- [librespot](https://github.com/librespot-org/librespot)
