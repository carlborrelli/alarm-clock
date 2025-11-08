# Home Assistant Configuration Guide

This guide explains how to configure Home Assistant to work with your Bedside Voice Clock.

## Prerequisites

- Home Assistant 2024.5 or newer
- Access to Home Assistant configuration
- Administrator access to Home Assistant

## Step 1: Install Required Addons

### 1.1 Install Faster-Whisper Addon

1. Go to **Settings** → **Add-ons** → **Add-on Store**
2. Search for "Faster Whisper"
3. Click **Install**
4. After installation, go to the addon's **Configuration** tab
5. Set the model (recommended: `base` or `small` for Pi compatibility)
6. Click **Start** and enable **Start on boot**

### 1.2 Install Piper Addon

1. In the Add-on Store, search for "Piper"
2. Click **Install**
3. Go to the addon's **Configuration** tab
4. Select a voice (recommended: `en_US-lessac-medium` for quality/speed balance)
5. Click **Start** and enable **Start on boot**

### 1.3 Verify Wyoming Server

1. Go to **Settings** → **Devices & Services**
2. You should see "Wyoming Protocol" integrations for both Faster-Whisper and Piper
3. Note the ports (usually 10300 for Whisper, 10200 for Piper)

## Step 2: Create Assist Pipeline

1. Go to **Settings** → **Voice assistants** → **Assist**
2. Click **Add Assistant**
3. Configure:
   - **Name**: Bedside Clock
   - **Language**: English
   - **Conversation agent**: Home Assistant
   - **Speech-to-text**: Faster Whisper
   - **Text-to-speech**: Piper
   - **Wake word**: (Leave disabled - handled by Pi)
4. Click **Create**

## Step 3: Import Custom Intent Sentences

1. SSH into your Home Assistant server or use the File Editor addon
2. Navigate to `/config/custom_sentences/en/`
3. Create the directory if it doesn't exist:
   ```bash
   mkdir -p /config/custom_sentences/en/
   ```
4. Copy the contents of `home-assistant/intents/custom_sentences.yaml` from this repository
5. Save as `/config/custom_sentences/en/bedside_clock.yaml`
6. Restart Home Assistant or reload the configuration

## Step 4: Create Input Helpers

### 4.1 Alarm Input Helpers

Go to **Settings** → **Devices & Services** → **Helpers** and create:

**Alarm 1:**
- `input_datetime.alarm_1` - Time helper (time only)
- `input_boolean.alarm_1_enabled` - Toggle helper
- `input_select.alarm_1_days` - Dropdown helper with options: weekdays, weekends, monday, tuesday, etc.

**Alarm 2:**
- `input_datetime.alarm_2` - Time helper
- `input_boolean.alarm_2_enabled` - Toggle helper
- `input_select.alarm_2_days` - Dropdown helper

**Alarm 3:**
- `input_datetime.alarm_3` - Time helper
- `input_boolean.alarm_3_enabled` - Toggle helper
- `input_select.alarm_3_days` - Dropdown helper

**Stop Alarm Button:**
- `input_button.stop_alarm` - Button helper

### 4.2 Display Settings Helpers

- `input_number.display_brightness` - Number helper (0-100, step 1)
- `input_number.display_dim_brightness` - Number helper (0-100, step 1)
- `input_datetime.dim_start_time` - Time helper
- `input_datetime.dim_end_time` - Time helper

## Step 5: Import Automations

1. Copy the automation files from `home-assistant/automations/`:
   - `alarms.yaml`
   - `lights.yaml`
   - `calendar.yaml`
   - `media.yaml`

2. Add to your `configuration.yaml`:
   ```yaml
   automation: !include_dir_merge_list automations/
   ```

3. Or manually paste the automations into the HA UI:
   - Go to **Settings** → **Automations & Scenes**
   - Click **+ Create Automation** → **Create new automation**
   - Switch to YAML mode and paste each automation

4. Reload automations or restart Home Assistant

## Step 6: Set Up Calendar Integration

### Option A: iCloud Calendar (Recommended)

1. Go to **Settings** → **Devices & Services** → **Add Integration**
2. Search for "iCloud" and add it
3. Sign in with your Apple ID
4. Enable 2FA and generate an app-specific password if required
5. Select your calendar to track
6. The calendar entity will be `calendar.icloud_<name>`

### Option B: Google Calendar

1. Add the Google Calendar integration
2. Follow the OAuth flow to authorize
3. Select calendars to sync

### Option C: CalDAV (Generic)

1. Add the CalDAV integration
2. Enter your CalDAV server URL
3. Provide credentials
4. Select calendar

**Update kiosk config:**

Edit `app/kiosk-ui/src/config.js` and set:
```javascript
calendar: {
  entity: 'calendar.your_calendar_entity_name',
  // ...
}
```

## Step 7: Configure Weather

1. Set up a weather integration:
   - **Settings** → **Devices & Services** → **Add Integration**
   - Search for your weather service (e.g., "Met.no", "OpenWeatherMap", "AccuWeather")
2. Configure the integration
3. Note the entity name (e.g., `weather.home`)

**Update kiosk config:**

Edit `app/kiosk-ui/src/config.js`:
```javascript
weather: {
  entity: 'weather.your_weather_entity',
  // ...
}
```

## Step 8: Install Lovelace Dashboard (Optional)

1. Go to **Settings** → **Dashboards**
2. Click **+ Add Dashboard**
3. Name it "Bedside Clock"
4. Switch to YAML mode
5. Paste the contents of `home-assistant/dashboards/bedside.yaml`
6. Save

This dashboard lets you manage alarms and settings from your phone or computer.

## Step 9: Configure Satellite on Pi

On your Raspberry Pi, edit the satellite configuration:

```bash
nano ~/bedside-voice-clock/app/config/satellite.yaml
```

Update these values:
```yaml
wyoming_server: "YOUR_HA_IP_ADDRESS"  # e.g., "192.168.1.100"
wyoming_port: 10300  # Faster-Whisper port
```

Save and restart the satellite service:
```bash
sudo systemctl restart satellite
```

## Step 10: Test Voice Commands

1. Say your wake word: "Hey Mycroft" (or your configured wake word)
2. Wait for the listening indicator
3. Try a command:
   - "What time is it?"
   - "Set alarm for 7 AM"
   - "Turn on bedroom light"
   - "What's the weather?"

Check the logs if commands don't work:
```bash
sudo journalctl -u satellite -f
```

## Optional: ChatGPT Fallback

For unmatched intents, you can configure a ChatGPT fallback:

1. Create an automation that catches failed intent matches
2. Send the text to OpenAI API
3. Speak the response

Example automation:
```yaml
- id: chatgpt_fallback
  alias: "ChatGPT Fallback"
  trigger:
    - platform: event
      event_type: intent_failed
  action:
    - service: rest_command.chatgpt_query
      data:
        query: "{{ trigger.event.data.text }}"
    - service: tts.speak
      data:
        message: "{{ response.content }}"
```

## Troubleshooting

### Voice commands not recognized

1. Check Faster-Whisper addon logs
2. Verify Assist pipeline is set as default
3. Test microphone: `./tests/test_audio.sh`

### TTS not working

1. Check Piper addon logs
2. Verify speaker output: `./tests/test_audio.sh`
3. Check media_player entity exists

### Alarms not triggering

1. Verify input helpers are created
2. Check automation is enabled
3. View logs: `sudo journalctl -u alarm-fallback -f`

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for more help.

## Additional Resources

- [Home Assistant Assist Documentation](https://www.home-assistant.io/voice_control/)
- [Wyoming Protocol](https://github.com/rhasspy/wyoming)
- [Piper TTS](https://github.com/rhasspy/piper)
- [Faster-Whisper](https://github.com/guillaumekln/faster-whisper)
