import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { format, parseISO } from 'date-fns';
import { FiCalendar } from 'react-icons/fi';
import config from '../config';
import './Calendar.css';

function Calendar() {
  const [events, setEvents] = useState([]);

  useEffect(() => {
    const fetchEvents = async () => {
      try {
        const response = await axios.get(
          `${config.apiUrl}/ha/state/${config.calendar.entity}`
        );

        // Parse calendar events from HA entity attributes
        const calendarEvents = response.data?.attributes?.events || [];
        setEvents(calendarEvents.slice(0, config.calendar.maxEvents));
      } catch (error) {
        console.error('Failed to fetch calendar:', error);
      }
    };

    fetchEvents();
    const interval = setInterval(fetchEvents, config.calendar.updateInterval);

    return () => clearInterval(interval);
  }, []);

  return (
    <div className="calendar-card card">
      <h2><FiCalendar className="icon" /> Calendar</h2>
      <div className="calendar-events">
        {events.length === 0 ? (
          <div className="no-events">No upcoming events</div>
        ) : (
          events.map((event, index) => (
            <div key={index} className="calendar-event">
              <div className="event-time">
                {format(parseISO(event.start), 'h:mm a')}
              </div>
              <div className="event-title">{event.summary}</div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}

export default Calendar;
