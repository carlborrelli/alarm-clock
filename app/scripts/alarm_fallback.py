#!/usr/bin/env python3
"""
Local Alarm Failsafe Service
Ensures alarms still ring even if Home Assistant or network is down
"""

import asyncio
import json
import logging
import os
import signal
import sys
from datetime import datetime, time as dt_time
from pathlib import Path
import subprocess
from typing import List, Dict
import requests

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Paths
PROJECT_DIR = Path(__file__).parent.parent.parent
ALARMS_CONFIG = PROJECT_DIR / "app" / "config" / "alarms.json"
ALARM_SOUND = PROJECT_DIR / "app" / "config" / "alarm.wav"

# Global flag for graceful shutdown
shutdown_flag = False


def signal_handler(signum, frame):
    """Handle shutdown signals"""
    global shutdown_flag
    logger.info(f"Received signal {signum}, shutting down gracefully...")
    shutdown_flag = True


class AlarmManager:
    """Local alarm management with HA sync"""

    def __init__(self):
        self.alarms: List[Dict] = []
        self.ha_url = None
        self.ha_token = None
        self.last_ha_sync = None

    def load_alarms(self):
        """Load alarms from local config file"""
        try:
            if ALARMS_CONFIG.exists():
                with open(ALARMS_CONFIG, 'r') as f:
                    data = json.load(f)
                    self.alarms = data.get('alarms', [])
                logger.info(f"Loaded {len(self.alarms)} alarms from local config")
            else:
                logger.info("No local alarms config found, starting empty")
                self.alarms = []
                self.save_alarms()
        except Exception as e:
            logger.error(f"Error loading alarms: {e}")
            self.alarms = []

    def save_alarms(self):
        """Save alarms to local config file"""
        try:
            with open(ALARMS_CONFIG, 'w') as f:
                json.dump({'alarms': self.alarms}, f, indent=2)
            logger.debug("Alarms saved to local config")
        except Exception as e:
            logger.error(f"Error saving alarms: {e}")

    async def sync_with_ha(self):
        """Sync alarms with Home Assistant"""
        if not self.ha_url or not self.ha_token:
            logger.debug("HA not configured, skipping sync")
            return

        try:
            # Query HA for alarm entities
            headers = {
                'Authorization': f'Bearer {self.ha_token}',
                'Content-Type': 'application/json'
            }

            response = requests.get(
                f'{self.ha_url}/api/states',
                headers=headers,
                timeout=5
            )

            if response.status_code == 200:
                states = response.json()

                # Look for alarm helper entities (input_datetime.alarm_*)
                ha_alarms = []
                for entity in states:
                    if entity['entity_id'].startswith('input_datetime.alarm_'):
                        try:
                            alarm_time = entity['state']
                            enabled = entity['attributes'].get('enabled', True)

                            ha_alarms.append({
                                'time': alarm_time,
                                'enabled': enabled,
                                'entity_id': entity['entity_id'],
                                'days': entity['attributes'].get('days', [])
                            })
                        except Exception as e:
                            logger.error(f"Error parsing alarm entity {entity['entity_id']}: {e}")

                # Update local alarms from HA
                self.alarms = ha_alarms
                self.save_alarms()
                self.last_ha_sync = datetime.now()

                logger.info(f"Synced {len(self.alarms)} alarms from Home Assistant")

            else:
                logger.warning(f"HA sync failed: {response.status_code}")

        except requests.exceptions.RequestException as e:
            logger.warning(f"Could not reach Home Assistant: {e}")
        except Exception as e:
            logger.error(f"Error syncing with HA: {e}")

    def check_alarms(self) -> List[Dict]:
        """Check if any alarms should trigger now"""
        now = datetime.now()
        current_time = now.time()
        current_day = now.strftime('%A').lower()

        triggered = []

        for alarm in self.alarms:
            if not alarm.get('enabled', True):
                continue

            try:
                # Parse alarm time
                alarm_time_str = alarm.get('time', '')
                if not alarm_time_str:
                    continue

                # Handle different time formats
                if 'T' in alarm_time_str:
                    # Format: "2024-01-01T06:30:00"
                    alarm_time = datetime.fromisoformat(alarm_time_str).time()
                else:
                    # Format: "06:30:00"
                    hour, minute = map(int, alarm_time_str.split(':')[:2])
                    alarm_time = dt_time(hour, minute)

                # Check if time matches (within current minute)
                if (current_time.hour == alarm_time.hour and
                    current_time.minute == alarm_time.minute):

                    # Check day of week if specified
                    alarm_days = alarm.get('days', [])
                    if alarm_days and current_day not in [d.lower() for d in alarm_days]:
                        continue

                    # Don't trigger same alarm multiple times in same minute
                    if not alarm.get('_triggered_at'):
                        alarm['_triggered_at'] = now.isoformat()
                        triggered.append(alarm)
                        logger.info(f"Alarm triggered: {alarm}")

                # Reset trigger flag if we're in a different minute
                elif alarm.get('_triggered_at'):
                    triggered_time = datetime.fromisoformat(alarm['_triggered_at'])
                    if now.minute != triggered_time.minute:
                        alarm['_triggered_at'] = None

            except Exception as e:
                logger.error(f"Error checking alarm {alarm}: {e}")

        return triggered

    async def play_alarm(self, alarm: Dict):
        """Play alarm sound"""
        logger.info(f"Playing alarm: {alarm}")

        try:
            # Use default alarm sound if custom not specified
            sound_file = alarm.get('sound', ALARM_SOUND)

            # If sound file doesn't exist, generate a beep
            if not Path(sound_file).exists():
                logger.warning(f"Alarm sound not found: {sound_file}, using system beep")
                # Play system beep
                for _ in range(10):
                    if shutdown_flag:
                        break
                    subprocess.run(['beep', '-f', '800', '-l', '500'])
                    await asyncio.sleep(1)
            else:
                # Play alarm sound in loop until stopped
                for _ in range(5):  # Play 5 times
                    if shutdown_flag:
                        break
                    subprocess.run(['aplay', str(sound_file)])
                    await asyncio.sleep(1)

        except Exception as e:
            logger.error(f"Error playing alarm: {e}")

    async def run(self):
        """Main alarm monitoring loop"""
        logger.info("Starting alarm failsafe service...")

        # Load local alarms
        self.load_alarms()

        # Try to load HA config
        try:
            satellite_config = PROJECT_DIR / "app" / "config" / "satellite.yaml"
            if satellite_config.exists():
                import yaml
                with open(satellite_config, 'r') as f:
                    config = yaml.safe_load(f)
                    ha_server = config.get('wyoming_server')
                    if ha_server and ha_server != '127.0.0.1':
                        self.ha_url = f'http://{ha_server}:8123'
                        # Note: Token should be provided separately for security
                        # For now, we'll only sync if explicitly configured
                        logger.info(f"HA URL detected: {self.ha_url}")
        except Exception as e:
            logger.debug(f"Could not load HA config: {e}")

        # Main loop
        last_sync = datetime.now()

        while not shutdown_flag:
            try:
                # Sync with HA every 5 minutes
                now = datetime.now()
                if (now - last_sync).total_seconds() > 300:
                    await self.sync_with_ha()
                    last_sync = now

                # Check alarms every second
                triggered = self.check_alarms()

                # Play triggered alarms
                for alarm in triggered:
                    await self.play_alarm(alarm)

                # Sleep for 1 second
                await asyncio.sleep(1)

            except Exception as e:
                logger.error(f"Error in alarm loop: {e}", exc_info=True)
                await asyncio.sleep(5)


async def main():
    """Main entry point"""
    # Set up signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    logger.info("Starting Local Alarm Failsafe Service")
    logger.info(f"Project directory: {PROJECT_DIR}")

    # Create alarm manager
    manager = AlarmManager()

    try:
        # Run alarm monitoring
        await manager.run()

    except Exception as e:
        logger.error(f"Fatal error: {e}", exc_info=True)
        sys.exit(1)

    logger.info("Alarm Failsafe Service stopped")
    sys.exit(0)


if __name__ == "__main__":
    asyncio.run(main())
