import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { FiPlay, FiPause, FiSkipForward, FiMusic } from 'react-icons/fi';
import config from '../config';
import './MediaPlayer.css';

function MediaPlayer() {
  const [mediaState, setMediaState] = useState(null);

  useEffect(() => {
    const fetchMediaState = async () => {
      try {
        const response = await axios.get(
          `${config.apiUrl}/ha/state/${config.media.spotifyEntity}`
        );
        setMediaState(response.data);
      } catch (error) {
        // Spotify entity might not exist yet
        console.debug('Media player not available');
      }
    };

    fetchMediaState();
    const interval = setInterval(fetchMediaState, config.media.updateInterval);

    return () => clearInterval(interval);
  }, []);

  const callMediaService = async (service) => {
    try {
      await axios.post(`${config.apiUrl}/ha/service`, {
        domain: 'media_player',
        service: service,
        entity_id: config.media.spotifyEntity
      });
    } catch (error) {
      console.error('Failed to call media service:', error);
    }
  };

  const isPlaying = mediaState?.state === 'playing';
  const track = mediaState?.attributes?.media_title || 'No media playing';
  const artist = mediaState?.attributes?.media_artist || '';

  return (
    <div className="media-card card">
      <h2><FiMusic className="icon" /> Now Playing</h2>
      <div className="media-info">
        <div className="media-track">{track}</div>
        {artist && <div className="media-artist">{artist}</div>}
      </div>
      <div className="media-controls">
        <button
          className="button media-button"
          onClick={() => callMediaService(isPlaying ? 'media_pause' : 'media_play')}
        >
          {isPlaying ? <FiPause /> : <FiPlay />}
        </button>
        <button
          className="button media-button"
          onClick={() => callMediaService('media_next_track')}
        >
          <FiSkipForward />
        </button>
      </div>
    </div>
  );
}

export default MediaPlayer;
