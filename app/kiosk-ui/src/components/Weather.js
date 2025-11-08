import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { FiSun, FiCloud, FiCloudRain, FiCloudSnow } from 'react-icons/fi';
import config from '../config';
import './Weather.css';

function Weather() {
  const [weather, setWeather] = useState(null);

  useEffect(() => {
    const fetchWeather = async () => {
      try {
        const response = await axios.get(
          `${config.apiUrl}/ha/state/${config.weather.entity}`
        );
        setWeather(response.data);
      } catch (error) {
        console.error('Failed to fetch weather:', error);
      }
    };

    fetchWeather();
    const interval = setInterval(fetchWeather, config.weather.updateInterval);

    return () => clearInterval(interval);
  }, []);

  const getWeatherIcon = (condition) => {
    const cond = condition?.toLowerCase() || '';
    if (cond.includes('rain')) return <FiCloudRain />;
    if (cond.includes('snow')) return <FiCloudSnow />;
    if (cond.includes('cloud')) return <FiCloud />;
    return <FiSun />;
  };

  if (!weather) {
    return (
      <div className="weather-card card">
        <h2>Weather</h2>
        <div className="weather-loading">Loading...</div>
      </div>
    );
  }

  const temp = Math.round(weather.attributes?.temperature || 0);
  const condition = weather.state || 'Unknown';

  return (
    <div className="weather-card card">
      <h2>Weather</h2>
      <div className="weather-display">
        <div className="weather-icon">
          {getWeatherIcon(condition)}
        </div>
        <div className="weather-info">
          <div className="weather-temp">{temp}°</div>
          <div className="weather-condition">{condition}</div>
        </div>
      </div>
    </div>
  );
}

export default Weather;
