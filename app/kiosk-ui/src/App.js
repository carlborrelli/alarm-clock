import React, { useState, useEffect } from 'react';
import './App.css';
import Clock from './components/Clock';
import Weather from './components/Weather';
import Calendar from './components/Calendar';
import Alarms from './components/Alarms';
import MediaPlayer from './components/MediaPlayer';
import QuickControls from './components/QuickControls';
import config from './config';

function App() {
  const [isDimmed, setIsDimmed] = useState(false);
  const [brightness, setBrightness] = useState(config.display.normalBrightness);
  const [lastInteraction, setLastInteraction] = useState(Date.now());

  // Handle screen dimming based on time and inactivity
  useEffect(() => {
    const checkDimming = () => {
      const now = new Date();
      const hour = now.getHours();

      // Auto-dim at night
      const shouldDimByTime = (
        hour >= config.display.dimStartHour ||
        hour < config.display.dimEndHour
      );

      // Dim after inactivity
      const inactiveTime = Date.now() - lastInteraction;
      const shouldDimByInactivity = inactiveTime > config.display.screenTimeout;

      const shouldDim = shouldDimByTime || shouldDimByInactivity;

      if (shouldDim !== isDimmed) {
        setIsDimmed(shouldDim);
        setBrightness(shouldDim ? config.display.dimBrightness : config.display.normalBrightness);
      }
    };

    const interval = setInterval(checkDimming, 5000);
    checkDimming(); // Check immediately

    return () => clearInterval(interval);
  }, [isDimmed, lastInteraction]);

  // Apply brightness changes
  useEffect(() => {
    fetch(`${config.apiUrl}/brightness`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ brightness })
    }).catch(err => console.error('Failed to set brightness:', err));
  }, [brightness]);

  // Handle user interaction (wake up screen)
  const handleInteraction = () => {
    setLastInteraction(Date.now());
    if (isDimmed) {
      setIsDimmed(false);
      setBrightness(config.display.normalBrightness);
    }
  };

  return (
    <div
      className={`app ${isDimmed ? 'dimmed' : ''}`}
      onClick={handleInteraction}
      onTouchStart={handleInteraction}
    >
      <div className="main-display">
        <div className="top-section">
          <Clock />
          <Weather />
        </div>

        <div className="middle-section">
          <Alarms />
          <Calendar />
        </div>

        <div className="bottom-section">
          <MediaPlayer />
          <QuickControls onInteraction={handleInteraction} />
        </div>
      </div>

      {isDimmed && (
        <div className="dim-overlay" />
      )}
    </div>
  );
}

export default App;
