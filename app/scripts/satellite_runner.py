#!/usr/bin/env python3
"""
Wyoming Satellite Service
Handles ASR/TTS communication with Home Assistant Wyoming server
"""

import asyncio
import logging
import os
import signal
import sys
import yaml
from pathlib import Path
import subprocess
import time

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Paths
PROJECT_DIR = Path(__file__).parent.parent.parent
CONFIG_PATH = PROJECT_DIR / "app" / "config" / "satellite.yaml"
WAKE_FLAG = PROJECT_DIR / "app" / "config" / ".wake_detected"

# Global flag for graceful shutdown
shutdown_flag = False
satellite_process = None


def signal_handler(signum, frame):
    """Handle shutdown signals"""
    global shutdown_flag, satellite_process
    logger.info(f"Received signal {signum}, shutting down gracefully...")
    shutdown_flag = True
    if satellite_process:
        satellite_process.terminate()


class WyomingSatellite:
    """Wyoming satellite client manager"""

    def __init__(self, config):
        self.config = config
        self.process = None
        self.wyoming_server = config.get('wyoming_server', '127.0.0.1')
        self.wyoming_port = config.get('wyoming_port', 10300)

    async def run(self):
        """Run Wyoming satellite in wake word trigger mode"""
        logger.info("Starting Wyoming satellite service...")
        logger.info(f"Wyoming server: {self.wyoming_server}:{self.wyoming_port}")

        # Build command for wyoming-satellite
        cmd = [
            'python3', '-m', 'wyoming_satellite',
            '--uri', f'tcp://{self.wyoming_server}:{self.wyoming_port}',
            '--mic-device', self.config.get('microphone', {}).get('device', 'default'),
            '--snd-device', self.config.get('speaker', {}).get('device', 'default'),
        ]

        # Add optional parameters
        if self.config.get('debug', False):
            cmd.append('--debug')

        # We're using external wake word detection
        cmd.extend(['--wake-word-name', 'none'])

        logger.info(f"Command: {' '.join(cmd)}")

        try:
            while not shutdown_flag:
                # Wait for wake word trigger
                await self.wait_for_wake_word()

                if shutdown_flag:
                    break

                # Start listening session
                logger.info("Wake word detected, starting voice session...")
                await self.run_voice_session(cmd)

                # Small delay before listening again
                await asyncio.sleep(1)

        except KeyboardInterrupt:
            logger.info("Interrupted by user")
        except Exception as e:
            logger.error(f"Error in satellite loop: {e}", exc_info=True)

    async def wait_for_wake_word(self):
        """Wait for wake word flag file"""
        while not shutdown_flag:
            if WAKE_FLAG.exists():
                # Remove flag file
                try:
                    WAKE_FLAG.unlink()
                    logger.info("Wake word flag detected")
                    return
                except Exception as e:
                    logger.error(f"Error removing wake flag: {e}")

            # Check every 100ms
            await asyncio.sleep(0.1)

    async def run_voice_session(self, cmd):
        """Run a single voice interaction session"""
        try:
            # Optional: Play listening sound
            # subprocess.Popen(['aplay', '/usr/share/sounds/alsa/Front_Center.wav'])

            # Run Wyoming satellite for one interaction
            # For a one-shot mode, we'll run the satellite and let it process one command
            # The satellite will automatically disconnect after processing

            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )

            # Wait for completion with timeout
            try:
                stdout, stderr = await asyncio.wait_for(
                    process.communicate(),
                    timeout=30.0  # 30 second timeout for voice interaction
                )

                if stdout:
                    logger.debug(f"Satellite output: {stdout.decode()}")
                if stderr:
                    logger.debug(f"Satellite errors: {stderr.decode()}")

            except asyncio.TimeoutError:
                logger.warning("Voice session timed out")
                process.terminate()
                await process.wait()

        except Exception as e:
            logger.error(f"Error in voice session: {e}", exc_info=True)


def load_config():
    """Load configuration from YAML file"""
    try:
        with open(CONFIG_PATH, 'r') as f:
            config = yaml.safe_load(f)
        logger.info(f"Configuration loaded from {CONFIG_PATH}")

        # Validate required fields
        if not config.get('wyoming_server'):
            logger.error("wyoming_server not configured in satellite.yaml")
            logger.error("Please edit app/config/satellite.yaml and set your Home Assistant IP")
            sys.exit(1)

        return config
    except FileNotFoundError:
        logger.error(f"Configuration file not found: {CONFIG_PATH}")
        logger.error("Please run the installer to create default configuration")
        sys.exit(1)
    except Exception as e:
        logger.error(f"Error loading configuration: {e}")
        sys.exit(1)


async def main():
    """Main entry point"""
    # Set up signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    logger.info("Starting Wyoming Satellite Service")
    logger.info(f"Project directory: {PROJECT_DIR}")

    # Load configuration
    config = load_config()

    # Create satellite
    satellite = WyomingSatellite(config)

    try:
        # Run satellite
        await satellite.run()

    except Exception as e:
        logger.error(f"Fatal error: {e}", exc_info=True)
        sys.exit(1)

    logger.info("Wyoming Satellite Service stopped")
    sys.exit(0)


if __name__ == "__main__":
    asyncio.run(main())
