import React, { useState, useEffect } from 'react';
import { format } from 'date-fns';
import './Clock.css';

function Clock() {
  const [time, setTime] = useState(new Date());

  useEffect(() => {
    const interval = setInterval(() => {
      setTime(new Date());
    }, 1000);

    return () => clearInterval(interval);
  }, []);

  return (
    <div className="clock-card card">
      <div className="clock-display">
        <div className="clock-time">
          {format(time, 'h:mm')}
          <span className="clock-seconds">{format(time, ':ss')}</span>
          <span className="clock-period">{format(time, 'a')}</span>
        </div>
        <div className="clock-date">
          {format(time, 'EEEE, MMMM d, yyyy')}
        </div>
      </div>
    </div>
  );
}

export default Clock;
