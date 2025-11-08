# Testing Guide

This guide explains how to test your Bedside Voice Clock to ensure everything is working correctly.

## Test Suite Overview

The project includes automated test scripts in the `tests/` directory:

- `test_audio.sh` - Test speakers and microphone
- `test_wakeword.sh` - Test wake word detection
- `test_ha_connection.sh` - Test Home Assistant connectivity
- `test_alarms.sh` - Test alarm system

## Initial Testing (After Installation)

Run these tests in order after completing the installation:

### 1. Audio System Test

**Purpose:** Verify speakers and microphone are working

```bash
cd ~/bedside-voice-clock
./tests/test_audio.sh
```

**What it tests:**
- Lists all audio devices
- Plays a test tone through speakers
- Records and plays back microphone input
- Shows volume levels
- Checks ALSA configuration

**Expected results:**
- You should hear a 440Hz test tone
- You should hear your voice played back
- No errors in output

**If it fails:** See [CONFIG_AUDIO.md](CONFIG_AUDIO.md)

### 2. Wake Word Detection Test

**Purpose:** Verify wake word service is detecting the trigger phrase

```bash
./tests/test_wakeword.sh
```

**What it tests:**
- Wake word service status
- Wake word model files exist
- Configuration is valid
- Live wake word detection (30 seconds)

**How to test:**
1. Script will monitor logs for 30 seconds
2. Say your wake word (default: "Hey Mycroft")
3. You should see "Wake word detected" in the logs

**Expected results:**
- Service is running
- Models found in `~/.local/share/openwakeword/`
- Detection logged when you say the wake word

**If it fails:** See "Wake Word Issues" in [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

### 3. Home Assistant Connection Test

**Purpose:** Verify Pi can communicate with Home Assistant

```bash
./tests/test_ha_connection.sh
```

**What it tests:**
- Network connectivity to HA
- HTTP API responsiveness
- Wyoming server port accessibility
- Satellite service status

**Expected results:**
- Can ping HA server
- HTTP returns 200 or 401 (normal)
- Wyoming port is open
- Satellite service running

**If it fails:** See "Network Issues" in [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

### 4. Alarm System Test

**Purpose:** Verify alarms trigger correctly

```bash
./tests/test_alarms.sh
```

**What it tests:**
- Alarm fallback service status
- Alarm configuration file
- Creates a test alarm 1 minute in the future
- Waits for alarm to trigger

**Expected results:**
- Service is running
- Test alarm is created
- Alarm triggers within 90 seconds
- You hear alarm sound

**Warning:** This test will play a loud alarm sound!

**If it fails:** See "Alarm Issues" in [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## Functional Testing

After running automated tests, verify each feature manually:

### Voice Command Testing

#### Test 1: Basic Wake and Response

1. Say wake word: "Hey Mycroft"
2. Wait for acknowledgment (beep or LED, depending on your setup)
3. Say: "What time is it?"
4. Should respond with current time

**Troubleshoot:**
- Wake word not detected → Check `test_wakeword.sh`
- No response → Check `test_ha_connection.sh`
- Wrong response → Check HA Assist pipeline

#### Test 2: Alarm Commands

1. "Hey Mycroft"
2. "Set alarm for 7 AM"
3. Should confirm: "Alarm set for 7 AM"

Verify:
```bash
# Check HA helpers
# Or check local config:
cat ~/bedside-voice-clock/app/config/alarms.json
```

#### Test 3: Light Control

1. "Hey Mycroft"
2. "Turn on bedroom light"
3. Light should turn on (if you have `light.bedroom` in HA)

**Note:** If you don't have this entity, customize the command in HA intent sentences.

#### Test 4: Music Control

1. Start playing music on Spotify
2. Select "Bedside Clock" as playback device
3. Music should play through Pi speakers
4. "Hey Mycroft"
5. "Pause music"
6. Music should pause

#### Test 5: Calendar Query

1. Ensure you have events in your calendar
2. "Hey Mycroft"
3. "What's on my calendar today?"
4. Should read your events

#### Test 6: Weather Query

1. "Hey Mycroft"
2. "What's the weather?"
3. Should read current temperature and conditions

### Kiosk UI Testing

#### Test 1: Display Shows

1. Kiosk should auto-start on boot
2. Shows large clock
3. Shows weather widget
4. Shows next alarm
5. Shows upcoming calendar events

**Troubleshoot:**
```bash
sudo systemctl status kiosk
sudo journalctl -u kiosk -f
```

#### Test 2: Touchscreen Interaction

1. Tap anywhere to wake screen (if dimmed)
2. Tap media player controls (play/pause)
3. Tap quick control buttons (lights)

**Expected:**
- Touch is responsive
- Controls work
- Screen stays bright after interaction

#### Test 3: Auto-Dimming

1. Don't interact with screen
2. After 30 seconds (default), should dim
3. Or if current time is between dimStart and dimEnd hours

**Adjust:**
Edit `app/kiosk-ui/src/config.js`:
```javascript
display: {
  dimBrightness: 10,
  normalBrightness: 80,
  dimStartHour: 22,  // 10 PM
  dimEndHour: 7,     // 7 AM
  screenTimeout: 30000,  // 30 seconds
}
```

### Spotify Integration Testing

#### Test 1: Device Appears

1. Open Spotify on phone/computer
2. Play any song
3. Tap "Devices Available" icon
4. "Bedside Clock" should appear in list

**Troubleshoot:**
```bash
sudo systemctl status librespot
sudo journalctl -u librespot -f
```

#### Test 2: Playback

1. Select "Bedside Clock" in Spotify
2. Music should play through Pi speakers
3. Control playback from Spotify app

#### Test 3: Voice Control

1. While music is playing:
2. "Hey Mycroft"
3. "Pause music"
4. Music should pause

### Alarm Testing

#### Test 1: Set Alarm via Voice

1. "Hey Mycroft"
2. "Set alarm for [TIME 2 minutes from now]"
3. Wait 2 minutes
4. Alarm should sound
5. Bedroom lights should fade on (if configured)

#### Test 2: Stop Alarm

When alarm rings:
1. "Hey Mycroft"
2. "Stop alarm"
3. Alarm should stop

Or:
1. Tap screen
2. Alarm should stop (if configured)

#### Test 3: Offline Alarm

1. Set an alarm via voice or HA
2. Disconnect Pi from network (turn off WiFi)
3. Wait for alarm time
4. Alarm should still ring (local fallback)

This tests the alarm-fallback service.

## Performance Testing

### Latency Testing

Measure response time for voice commands:

1. "Hey Mycroft" → Note time
2. Wait for wake → Note time
3. "What time is it?" → Note time
4. Wait for response → Note time

**Target:** 800-1200ms total from wake word to response start

**Factors affecting latency:**
- Network speed to HA
- HA server hardware
- ASR model size (base is fast, large is slow)

### Wake Word Accuracy

Test false positive rate:

1. Have normal conversation near the device for 10 minutes
2. Count unintended wake ups

**Target:** < 1 false positive per hour

**Adjust sensitivity:**
Edit `app/config/wakeword.yaml`:
```yaml
threshold: 0.6  # Increase to reduce false positives
```

Test false negative rate:

1. Say wake word 10 times from normal distance
2. Count how many times it doesn't wake

**Target:** 9-10 out of 10 detections

**Adjust sensitivity:**
```yaml
threshold: 0.4  # Decrease to improve detection
```

## Stress Testing

### Concurrent Operations

Test system handles multiple things at once:

1. Play Spotify music
2. Say "Hey Mycroft"
3. Ask: "What's the weather?"
4. Should pause music, respond, then resume

### Long Running

Leave system running for 24 hours:

```bash
# Monitor CPU and memory
top

# Check for crashes
sudo journalctl --since "24 hours ago" | grep -i error
```

**Expected:**
- No service crashes
- Memory usage stable
- CPU usage reasonable (< 50% average)

## Regression Testing

After making changes, re-run the full test suite:

```bash
cd ~/bedside-voice-clock

# Run all tests
./tests/test_audio.sh
./tests/test_wakeword.sh
./tests/test_ha_connection.sh
./tests/test_alarms.sh

# Verify services
sudo systemctl status wakeword satellite kiosk librespot alarm-fallback
```

## Continuous Monitoring

Set up a daily check:

```bash
# Add to crontab
crontab -e

# Add this line (runs daily at 3 AM):
0 3 * * * /home/$USER/bedside-voice-clock/tests/test_audio.sh >> /home/$USER/test.log 2>&1
```

## Reporting Issues

If you find bugs during testing:

1. Note the exact steps to reproduce
2. Collect logs:
   ```bash
   sudo journalctl -u SERVICE_NAME -n 200 > service.log
   ```
3. Note your environment:
   - Raspberry Pi model
   - OS version: `cat /etc/os-release`
   - Home Assistant version
4. Create an issue on GitHub with this information

## Test Coverage

Current test coverage:

| Feature | Automated Test | Manual Test |
|---------|---------------|-------------|
| Audio output | ✅ | ✅ |
| Microphone input | ✅ | ✅ |
| Wake word detection | ✅ | ✅ |
| HA connectivity | ✅ | ✅ |
| Voice commands | ❌ | ✅ |
| Alarm triggering | ✅ | ✅ |
| Alarm stopping | ❌ | ✅ |
| Kiosk display | ❌ | ✅ |
| Spotify playback | ❌ | ✅ |
| Calendar sync | ❌ | ✅ |
| Weather display | ❌ | ✅ |

## Future Testing Ideas

- Automated voice command testing with audio playback
- Network resilience testing (intermittent connectivity)
- Power failure recovery testing
- Multi-user testing (different voices)
- Long-term reliability testing (30+ days uptime)

## Getting Help

If tests fail and you can't resolve:

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Review relevant config guide:
   - [CONFIG_AUDIO.md](CONFIG_AUDIO.md)
   - [CONFIG_HOME_ASSISTANT.md](CONFIG_HOME_ASSISTANT.md)
   - [CONFIG_SPOTIFY.md](CONFIG_SPOTIFY.md)
3. Check service logs: `sudo journalctl -u SERVICE_NAME -f`
4. Ask for help on GitHub Issues with debug info
