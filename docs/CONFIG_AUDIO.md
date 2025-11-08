# Audio Configuration Guide

This guide helps you configure and troubleshoot audio on your Bedside Voice Clock.

## Audio Hardware

### Supported Audio Devices

The system works with:
- **Built-in Pi audio** (3.5mm jack) - Basic quality
- **USB sound cards** - Better quality, recommended
- **USB speakers/headsets** - All-in-one solution
- **HAT audio boards** - Best quality (e.g., ReSpeaker, HiFiBerry)
- **HDMI audio** - If using HDMI monitor with speakers

### Recommended Setup

For best results:
- **Microphone**: USB microphone or ReSpeaker HAT
- **Speaker**: USB speaker or dedicated speaker via USB DAC
- **Why?** USB audio is more reliable than built-in 3.5mm on Pi

## Initial Audio Configuration

The installer runs `setup/install_audio.sh` automatically, which:
1. Detects available audio devices
2. Creates ALSA configuration for software mixing
3. Sets default volumes
4. Tests speaker and microphone

### Manual Audio Setup

If needed, run the audio setup again:

```bash
cd ~/bedside-voice-clock
sudo ./setup/install_audio.sh
```

## Listing Audio Devices

### List Playback Devices

```bash
aplay -l
```

Output example:
```
card 0: Headphones [bcm2835 Headphones], device 0: bcm2835 Headphones [bcm2835 Headphones]
card 1: Device [USB Audio Device], device 0: USB Audio [USB Audio]
```

### List Capture Devices

```bash
arecord -l
```

Output example:
```
card 2: Device [USB Microphone], device 0: USB Audio [USB Audio]
```

### List All ALSA Devices

```bash
aplay -L
```

Shows all device aliases including `default`, `hw:0,0`, `plughw:1,0`, etc.

## Configuring Default Devices

### Method 1: Edit ALSA Configuration (Recommended)

Edit `/etc/asound.conf`:

```bash
sudo nano /etc/asound.conf
```

Update the hardware devices based on your `aplay -l` and `arecord -l` output:

```conf
# Playback device (change hw:0,0 to your speaker)
pcm.dmix {
    type dmix
    ipc_key 1024
    slave {
        pcm "hw:0,0"    # Change to your output card:device
        ...
    }
}

# Capture device (change hw:0,0 to your microphone)
pcm.dsnoop {
    type dsnoop
    ipc_key 2048
    slave {
        pcm "hw:1,0"    # Change to your input card:device
        ...
    }
}
```

Example for USB devices:
```conf
pcm "hw:1,0"    # Speaker on card 1
pcm "hw:2,0"    # Microphone on card 2
```

### Method 2: Home User Configuration

Create `~/.asoundrc`:

```bash
nano ~/.asoundrc
```

```conf
defaults.pcm.card 1
defaults.ctl.card 1
```

This sets card 1 as default for that user.

## Volume Control

### Graphical Mixer (Recommended)

```bash
alsamixer
```

Use arrow keys to navigate:
- **F6**: Select sound card
- **Left/Right**: Select channel
- **Up/Down**: Adjust volume
- **M**: Mute/Unmute
- **Esc**: Exit

### Command Line Volume

Set master volume:
```bash
amixer set Master 80%
```

Set PCM volume:
```bash
amixer set PCM 90%
```

Set capture (mic) volume:
```bash
amixer set Capture 80%
```

Unmute:
```bash
amixer set Master unmute
amixer set Capture cap
```

## Testing Audio

### Test Speakers

```bash
cd ~/bedside-voice-clock
./tests/test_audio.sh
```

Or manually:

```bash
# Play test tone
speaker-test -t sine -f 440 -l 1

# Play WAV file
aplay /usr/share/sounds/alsa/Front_Center.wav
```

### Test Microphone

Record and playback:
```bash
# Record 3 seconds
arecord -d 3 -f cd test.wav

# Play it back
aplay test.wav
```

### Full Audio Test

The automated test script checks everything:

```bash
./tests/test_audio.sh
```

## Common Audio Issues

### No Sound from Speakers

**1. Check volume:**
```bash
alsamixer
# Unmute and increase volume
```

**2. Check device:**
```bash
aplay -l
# Note the card number
```

**3. Test specific device:**
```bash
aplay -D hw:0,0 /usr/share/sounds/alsa/Front_Center.wav
# Try hw:1,0, hw:2,0, etc.
```

**4. Select output (for Pi built-in):**
```bash
# Force 3.5mm jack
amixer cset numid=3 1

# Force HDMI
amixer cset numid=3 2

# Auto
amixer cset numid=3 0
```

### Microphone Not Working

**1. Check if detected:**
```bash
arecord -l
```

**2. Check volume:**
```bash
alsamixer
# Press F4 for Capture
# Increase mic volume, ensure not muted
```

**3. Test recording:**
```bash
arecord -D hw:2,0 -d 3 test.wav
aplay test.wav
```

**4. Check capture device in config:**
```bash
cat /etc/asound.conf | grep -A 10 dsnoop
```

### Crackling or Poor Quality

**1. Increase buffer size:**

Edit `/etc/asound.conf`:
```conf
slave {
    pcm "hw:0,0"
    period_size 2048    # Increase this
    buffer_size 8192    # And this
    rate 48000
}
```

**2. Reduce bitrate:**

For Spotify:
```bash
nano ~/bedside-voice-clock/app/config/librespot.conf
# Set BITRATE="160"
```

**3. Check USB power:**

Some USB devices need more power:
```bash
# Add to /boot/config.txt
max_usb_current=1
```

Reboot after changing.

### Echo or Feedback

**1. Enable echo cancellation:**

For PulseAudio (if used):
```bash
pactl load-module module-echo-cancel
```

**2. Reduce speaker volume during listening:**

The satellite service has auto-ducking built-in.

**3. Physical separation:**

Keep microphone away from speakers.

## Advanced Configuration

### Software Mixing (Multiple Apps Playing Audio)

The default `asound.conf` enables `dmix` for software mixing:

```conf
pcm.playback {
    type plug
    slave.pcm "dmix"
}
```

This allows wake word, TTS, and Spotify to play simultaneously.

### Resampling Quality

High-quality resampling (CPU intensive):

```conf
defaults.pcm.rate_converter "samplerate_best"
```

Low-CPU resampling:
```conf
defaults.pcm.rate_converter "linear"
```

### Custom Sample Rates

For specific hardware:

```conf
slave {
    pcm "hw:0,0"
    rate 44100      # Match your DAC's native rate
}
```

### PulseAudio (Alternative to ALSA)

If you prefer PulseAudio:

```bash
sudo apt-get install pulseaudio

# Start PulseAudio
pulseaudio --start

# Set default devices
pactl set-default-sink alsa_output.usb-...
pactl set-default-source alsa_input.usb-...
```

Update service configs to use PulseAudio devices.

## ReSpeaker HAT Configuration

If using ReSpeaker 2-Mic or 4-Mic HAT:

### Install Drivers

```bash
git clone https://github.com/respeaker/seeed-voicecard
cd seeed-voicecard
sudo ./install.sh
sudo reboot
```

### Configure ALSA

Update `/etc/asound.conf`:

```conf
pcm.dmix {
    slave {
        pcm "hw:seeed2micvoicec,0"
        ...
    }
}

pcm.dsnoop {
    slave {
        pcm "hw:seeed2micvoicec,0"
        channels 2
        ...
    }
}
```

### Test

```bash
arecord -D hw:seeed2micvoicec,0 -f S16_LE -r 16000 -c 2 test.wav
```

## Checking Service Audio Configuration

### Wake Word Service

Check microphone device:
```bash
sudo journalctl -u wakeword -n 50 | grep -i "audio\|device"
```

### Satellite Service

Check config:
```bash
cat ~/bedside-voice-clock/app/config/satellite.yaml
```

### Spotify (librespot)

Check device:
```bash
sudo journalctl -u librespot -n 50 | grep -i "audio\|device"
```

## Troubleshooting Commands Cheat Sheet

```bash
# List devices
aplay -l
arecord -l
aplay -L

# Test speaker
speaker-test -t sine -f 440 -l 1
aplay /usr/share/sounds/alsa/Front_Center.wav

# Test microphone
arecord -d 3 test.wav && aplay test.wav

# Volume control
alsamixer
amixer set Master 80%
amixer set Capture 80%

# Service logs
sudo journalctl -u wakeword -f
sudo journalctl -u satellite -f
sudo journalctl -u librespot -f

# Restart services
sudo systemctl restart wakeword satellite librespot
```

## Additional Resources

- [ALSA Documentation](https://alsa-project.org/wiki/Main_Page)
- [Raspberry Pi Audio Configuration](https://www.raspberrypi.com/documentation/computers/configuration.html#audio-config)
- [ReSpeaker Documentation](https://wiki.seeedstudio.com/ReSpeaker_2_Mics_Pi_HAT/)
