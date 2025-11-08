#!/usr/bin/env python3
"""
Mock Wake Word Service for Development/Testing
Simulates wake word detection without requiring microphone
"""

import time
import logging
import signal
import sys
from pathlib import Path
import random

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Paths
PROJECT_DIR = Path(__file__).parent.parent.parent
WAKE_FLAG = PROJECT_DIR / "app" / "config" / ".wake_detected"

# Global flag for graceful shutdown
shutdown_flag = False


def signal_handler(signum, frame):
    """Handle shutdown signals"""
    global shutdown_flag
    logger.info(f"Received signal {signum}, shutting down gracefully...")
    shutdown_flag = True


class MockWakeWordDetector:
    """Mock wake word detector for testing"""

    def __init__(self, mode='manual'):
        self.mode = mode  # 'manual', 'auto', 'random'

    def run(self):
        """Main loop"""
        logger.info("Mock Wake Word Detector started")
        logger.info(f"Mode: {self.mode}")

        if self.mode == 'manual':
            logger.info("="*60)
            logger.info("MANUAL MODE")
            logger.info("To trigger wake word:")
            logger.info("  touch app/config/.wake_detected")
            logger.info("Or:")
            logger.info("  docker exec -it <container> touch /app/config/.wake_detected")
            logger.info("="*60)

            while not shutdown_flag:
                # Just monitor for manual trigger
                if WAKE_FLAG.exists():
                    logger.info("Wake word manually triggered!")
                    # Remove flag so it can be triggered again
                    try:
                        WAKE_FLAG.unlink()
                    except:
                        pass
                time.sleep(0.5)

        elif self.mode == 'auto':
            logger.info("AUTO MODE: Triggering wake word every 30 seconds")

            while not shutdown_flag:
                time.sleep(30)
                logger.info("Auto-triggering wake word...")
                WAKE_FLAG.touch()

        elif self.mode == 'random':
            logger.info("RANDOM MODE: Triggering wake word randomly (1-5 minutes)")

            while not shutdown_flag:
                # Random interval between 60-300 seconds
                interval = random.randint(60, 300)
                logger.info(f"Next wake word in {interval} seconds")
                time.sleep(interval)

                if not shutdown_flag:
                    logger.info("Randomly triggering wake word...")
                    WAKE_FLAG.touch()


def main():
    """Main entry point"""
    # Set up signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    logger.info("Starting Mock Wake Word Detection Service")

    # Determine mode from environment or default to manual
    import os
    mode = os.environ.get('MOCK_WAKE_MODE', 'manual')

    detector = MockWakeWordDetector(mode=mode)

    try:
        detector.run()
    except Exception as e:
        logger.error(f"Fatal error: {e}", exc_info=True)
        sys.exit(1)

    logger.info("Mock Wake Word Detection Service stopped")
    sys.exit(0)


if __name__ == "__main__":
    main()
