#!/usr/bin/env python3
"""
Kiosk Backend Server
Provides API for the touchscreen UI to interact with HA and local services
"""

import os
import sys
import logging
from pathlib import Path
from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
import requests
import json
from datetime import datetime

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Paths
PROJECT_DIR = Path(__file__).parent.parent.parent
KIOSK_BUILD_DIR = PROJECT_DIR / "app" / "kiosk-ui" / "build"
CONFIG_DIR = PROJECT_DIR / "app" / "config"

# Create Flask app
app = Flask(__name__, static_folder=str(KIOSK_BUILD_DIR))
CORS(app)

# Configuration
HA_URL = os.environ.get('HA_URL', 'http://homeassistant.local:8123')
HA_TOKEN = os.environ.get('HA_TOKEN', '')


@app.route('/')
def serve_index():
    """Serve the React app"""
    return send_from_directory(str(KIOSK_BUILD_DIR), 'index.html')


@app.route('/<path:path>')
def serve_static(path):
    """Serve static files"""
    return send_from_directory(str(KIOSK_BUILD_DIR), path)


@app.route('/api/status')
def status():
    """Get system status"""
    return jsonify({
        'status': 'ok',
        'time': datetime.now().isoformat(),
        'services': {
            'wakeword': check_service_status('wakeword'),
            'satellite': check_service_status('satellite'),
            'librespot': check_service_status('librespot'),
            'alarm_fallback': check_service_status('alarm-fallback')
        }
    })


@app.route('/api/ha/state/<entity_id>')
def get_ha_state(entity_id):
    """Get Home Assistant entity state"""
    try:
        headers = {'Authorization': f'Bearer {HA_TOKEN}'}
        response = requests.get(
            f'{HA_URL}/api/states/{entity_id}',
            headers=headers,
            timeout=5
        )

        if response.status_code == 200:
            return jsonify(response.json())
        else:
            return jsonify({'error': 'Failed to get state'}), response.status_code

    except Exception as e:
        logger.error(f"Error getting HA state: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/ha/service', methods=['POST'])
def call_ha_service():
    """Call Home Assistant service"""
    try:
        data = request.json
        domain = data.get('domain')
        service = data.get('service')
        entity_id = data.get('entity_id')
        service_data = data.get('data', {})

        if entity_id:
            service_data['entity_id'] = entity_id

        headers = {
            'Authorization': f'Bearer {HA_TOKEN}',
            'Content-Type': 'application/json'
        }

        response = requests.post(
            f'{HA_URL}/api/services/{domain}/{service}',
            headers=headers,
            json=service_data,
            timeout=5
        )

        if response.status_code in [200, 201]:
            return jsonify({'success': True})
        else:
            return jsonify({'error': 'Service call failed'}), response.status_code

    except Exception as e:
        logger.error(f"Error calling HA service: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/alarms')
def get_alarms():
    """Get local alarms"""
    try:
        alarms_file = CONFIG_DIR / "alarms.json"
        if alarms_file.exists():
            with open(alarms_file, 'r') as f:
                return jsonify(json.load(f))
        else:
            return jsonify({'alarms': []})
    except Exception as e:
        logger.error(f"Error getting alarms: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/alarms', methods=['POST'])
def set_alarm():
    """Set a new alarm"""
    try:
        alarm = request.json
        alarms_file = CONFIG_DIR / "alarms.json"

        # Load existing alarms
        if alarms_file.exists():
            with open(alarms_file, 'r') as f:
                data = json.load(f)
        else:
            data = {'alarms': []}

        # Add new alarm
        data['alarms'].append(alarm)

        # Save
        with open(alarms_file, 'w') as f:
            json.dump(data, f, indent=2)

        return jsonify({'success': True})

    except Exception as e:
        logger.error(f"Error setting alarm: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/volume', methods=['POST'])
def set_volume():
    """Set system volume"""
    try:
        volume = request.json.get('volume', 50)
        os.system(f'amixer set Master {volume}%')
        return jsonify({'success': True})
    except Exception as e:
        logger.error(f"Error setting volume: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/brightness', methods=['POST'])
def set_brightness():
    """Set display brightness"""
    try:
        brightness = request.json.get('brightness', 50)
        # This depends on your display hardware
        # For official Pi touchscreen:
        brightness_val = int(brightness * 2.55)  # Convert 0-100 to 0-255
        os.system(f'echo {brightness_val} > /sys/class/backlight/rpi_backlight/brightness')
        return jsonify({'success': True})
    except Exception as e:
        logger.error(f"Error setting brightness: {e}")
        return jsonify({'error': str(e)}), 500


def check_service_status(service_name):
    """Check if a systemd service is running"""
    try:
        import subprocess
        result = subprocess.run(
            ['systemctl', 'is-active', service_name],
            capture_output=True,
            text=True
        )
        return result.stdout.strip() == 'active'
    except Exception:
        return False


def main():
    """Main entry point"""
    logger.info("Starting Kiosk Backend Server")
    logger.info(f"Serving from: {KIOSK_BUILD_DIR}")
    logger.info(f"Home Assistant URL: {HA_URL}")

    # Check if build directory exists
    if not KIOSK_BUILD_DIR.exists():
        logger.error(f"Build directory not found: {KIOSK_BUILD_DIR}")
        logger.error("Please run: cd app/kiosk-ui && npm run build")
        sys.exit(1)

    # Start Flask server
    app.run(host='0.0.0.0', port=3000, debug=False)


if __name__ == "__main__":
    main()
