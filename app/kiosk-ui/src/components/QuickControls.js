import React, { useState } from 'react';
import axios from 'axios';
import { FiSun, FiMoon, FiZap } from 'react-icons/fi';
import config from '../config';
import './QuickControls.css';

function QuickControls({ onInteraction }) {
  const [loading, setLoading] = useState(false);

  const callService = async (domain, service, entityId = null) => {
    setLoading(true);
    onInteraction();

    try {
      await axios.post(`${config.apiUrl}/ha/service`, {
        domain,
        service,
        entity_id: entityId
      });
    } catch (error) {
      console.error('Failed to call service:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="controls-card card">
      <h2>Quick Controls</h2>
      <div className="controls-grid">
        <button
          className="button control-button"
          onClick={() => callService('light', 'turn_on', 'light.bedroom')}
          disabled={loading}
        >
          <FiSun className="icon" />
          <span>Bedroom On</span>
        </button>

        <button
          className="button control-button"
          onClick={() => callService('light', 'turn_off', 'light.bedroom')}
          disabled={loading}
        >
          <FiMoon className="icon" />
          <span>Bedroom Off</span>
        </button>

        <button
          className="button control-button"
          onClick={() => callService('scene', 'turn_on', 'scene.night_mode')}
          disabled={loading}
        >
          <FiZap className="icon" />
          <span>Night Mode</span>
        </button>
      </div>
    </div>
  );
}

export default QuickControls;
