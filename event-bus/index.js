const express = require('express');
const axios = require('axios');

const app = express();
app.use(express.json());

// Store all events (for new services to catch up)
const events = [];

app.post('/events', async (req, res) => {
  const event = req.body;

  // Store event
  events.push(event);

  console.log(`Event received: ${event.type}`);

  // Send to all services
  const services = [
    'http://posts-srv:4001/events', // Posts
    'http://comments-srv:4002/events', // Comments
    'http://query-srv:4003/events', // Query
    'http://moderation-srv:4004/events', // Moderation
  ];

  for (const url of services) {
    try {
      await axios.post(url, event);
      console.log(`Sent to ${url}`);
    } catch (err) {
      console.log(`Failed to send to ${url}: ${err.message}`);
    }
  }

  res.send({ status: 'OK' });
});

app.get('/events', (req, res) => {
  console.log(`Returning ${events.length} events`);
  res.send(events);
});

const PORT = 4005;
app.listen(PORT, () => {
  console.log(`Event Bus listening on port ${PORT}`);
  console.log(`   POST http://localhost:${PORT}/events`);
  console.log(`   GET  http://localhost:${PORT}/events`);
});