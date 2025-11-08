import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { FiClock } from 'react-icons/fi';
import config from '../config';
import './Alarms.css';

function Alarms() {
  const [alarms, setAlarms] = useState([]);

  useEffect(() => {
    const fetchAlarms = async () => {
      try {
        const response = await axios.get(`${config.apiUrl}/alarms`);
        setAlarms(response.data.alarms || []);
      } catch (error) {
        console.error('Failed to fetch alarms:', error);
      }
    };

    fetchAlarms();
    const interval = setInterval(fetchAlarms, config.alarms.updateInterval);

    return () => clearInterval(interval);
  }, []);

  const getNextAlarm = () => {
    if (alarms.length === 0) return null;

    // Filter enabled alarms and sort by time
    const enabledAlarms = alarms.filter(a => a.enabled);
    if (enabledAlarms.length === 0) return null;

    // For simplicity, return the first enabled alarm
    return enabledAlarms[0];
  };

  const nextAlarm = getNextAlarm();

  return (
    <div className="alarms-card card">
      <h2><FiClock className="icon" /> Next Alarm</h2>
      <div className="alarms-display">
        {nextAlarm ? (
          <div className="next-alarm">
            <div className="alarm-time">{nextAlarm.time}</div>
            {nextAlarm.days && nextAlarm.days.length > 0 && (
              <div className="alarm-days">{nextAlarm.days.join(', ')}</div>
            )}
          </div>
        ) : (
          <div className="no-alarms">No alarms set</div>
        )}
      </div>
    </div>
  );
}

export default Alarms;
