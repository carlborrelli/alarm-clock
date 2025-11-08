#!/usr/bin/env python3
"""
Wake Word Detection Service
Listens for wake word and triggers Wyoming satellite for voice interaction
"""

import asyncio
import logging
import os
import signal
import sys
import yaml
from pathlib import Path
from openwakeword.model import Model
import pyaudio
import numpy as np
import requests

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Paths
PROJECT_DIR = Path(__file__).parent.parent.parent
CONFIG_PATH = PROJECT_DIR / "app" / "config" / "wakeword.yaml"

# Global flag for graceful shutdown
shutdown_flag = False


def signal_handler(signum, frame):
    """Handle shutdown signals"""
    global shutdown_flag
    logger.info(f"Received signal {signum}, shutting down gracefully...")
    shutdown_flag = True


class WakeWordDetector:
    """Wake word detection using openWakeWord"""

    def __init__(self, config):
        self.config = config
        self.model = None
        self.audio = None
        self.stream = None

    def initialize(self):
        """Initialize wake word model and audio stream"""
        logger.info("Initializing wake word detector...")

        # Load wake word model
        model_path = os.path.expanduser(self.config.get('model_dir', '~/.local/share/openwakeword'))
        wake_word_model = self.config.get('wake_word_model', 'hey_mycroft_v0.1.0.tflite')

        logger.info(f"Loading wake word model: {wake_word_model}")
        logger.info(f"Model directory: {model_path}")

        # Initialize openWakeWord model
        self.model = Model(
            wakeword_models=[os.path.join(model_path, wake_word_model)],
            inference_framework='tflite'
        )

        # Initialize PyAudio
        self.audio = pyaudio.PyAudio()

        # Audio settings
        sample_rate = self.config.get('sample_rate', 16000)
        chunk_size = self.config.get('chunk_size', 1024)

        # Open audio stream
        logger.info(f"Opening audio stream: {sample_rate}Hz, chunk size {chunk_size}")
        self.stream = self.audio.open(
            format=pyaudio.paInt16,
            channels=1,
            rate=sample_rate,
            input=True,
            frames_per_buffer=chunk_size
        )

        logger.info("Wake word detector initialized successfully")

    def run(self):
        """Main detection loop"""
        logger.info("Starting wake word detection...")
        threshold = self.config.get('threshold', 0.5)
        chunk_size = self.config.get('chunk_size', 1024)

        try:
            while not shutdown_flag:
                # Read audio chunk
                audio_data = self.stream.read(chunk_size, exception_on_overflow=False)
                audio_array = np.frombuffer(audio_data, dtype=np.int16)

                # Get predictions
                prediction = self.model.predict(audio_array)

                # Check for wake word detection
                for model_name, score in prediction.items():
                    if score >= threshold:
                        logger.info(f"Wake word detected! ({model_name}: {score:.2f})")
                        self.trigger_satellite()

        except KeyboardInterrupt:
            logger.info("Interrupted by user")
        except Exception as e:
            logger.error(f"Error in detection loop: {e}", exc_info=True)
        finally:
            self.cleanup()

    def trigger_satellite(self):
        """Trigger Wyoming satellite to start listening"""
        try:
            # The satellite service should be listening for wake word triggers
            # We can trigger it via a simple HTTP endpoint or file flag
            # For now, we'll use a simple flag file approach

            flag_file = PROJECT_DIR / "app" / "config" / ".wake_detected"
            flag_file.touch()

            # Optional: Play a confirmation sound
            # os.system("aplay /usr/share/sounds/alsa/Front_Center.wav &")

            logger.info("Satellite triggered")

        except Exception as e:
            logger.error(f"Error triggering satellite: {e}")

    def cleanup(self):
        """Clean up resources"""
        logger.info("Cleaning up...")
        if self.stream:
            self.stream.stop_stream()
            self.stream.close()
        if self.audio:
            self.audio.terminate()
        logger.info("Cleanup complete")


def load_config():
    """Load configuration from YAML file"""
    try:
        with open(CONFIG_PATH, 'r') as f:
            config = yaml.safe_load(f)
        logger.info(f"Configuration loaded from {CONFIG_PATH}")
        return config
    except FileNotFoundError:
        logger.error(f"Configuration file not found: {CONFIG_PATH}")
        logger.info("Using default configuration")
        return {
            'wake_word_model': 'hey_mycroft_v0.1.0.tflite',
            'threshold': 0.5,
            'sample_rate': 16000,
            'chunk_size': 1024,
            'model_dir': '~/.local/share/openwakeword'
        }
    except Exception as e:
        logger.error(f"Error loading configuration: {e}")
        sys.exit(1)


def main():
    """Main entry point"""
    # Set up signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    logger.info("Starting Wake Word Detection Service")
    logger.info(f"Project directory: {PROJECT_DIR}")

    # Load configuration
    config = load_config()

    # Create detector
    detector = WakeWordDetector(config)

    try:
        # Initialize
        detector.initialize()

        # Run detection loop
        detector.run()

    except Exception as e:
        logger.error(f"Fatal error: {e}", exc_info=True)
        sys.exit(1)

    logger.info("Wake Word Detection Service stopped")
    sys.exit(0)


if __name__ == "__main__":
    main()
