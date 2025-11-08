// Configuration for Kiosk UI

export const config = {
  // Backend API (local kiosk server)
  apiUrl: 'http://localhost:3000/api',

  // Home Assistant configuration
  homeAssistant: {
    url: process.env.REACT_APP_HA_URL || 'http://homeassistant.local:8123',
    token: process.env.REACT_APP_HA_TOKEN || '',
  },

  // Display settings
  display: {
    // Auto-dim settings
    dimBrightness: 10,        // Brightness when dimmed (%)
    normalBrightness: 80,     // Normal brightness (%)
    dimStartHour: 22,         // Hour to start dimming (24h format)
    dimEndHour: 7,            // Hour to end dimming (24h format)

    // Screen timeout
    screenTimeout: 30000,     // Time until dim (ms) - 30 seconds
  },

  // Weather settings
  weather: {
    entity: 'weather.home',   // HA weather entity
    updateInterval: 300000,   // 5 minutes
  },

  // Calendar settings
  calendar: {
    entity: 'calendar.personal', // HA calendar entity
    maxEvents: 3,              // Max events to display
    updateInterval: 600000,    // 10 minutes
  },

  // Media player settings
  media: {
    spotifyEntity: 'media_player.bedside_clock', // Spotify Connect entity in HA
    updateInterval: 5000,      // 5 seconds
  },

  // Alarm settings
  alarms: {
    updateInterval: 60000,     // 1 minute
  },

  // UI refresh rates
  clockUpdateInterval: 1000,   // 1 second
  statusUpdateInterval: 30000, // 30 seconds
};

export default config;
