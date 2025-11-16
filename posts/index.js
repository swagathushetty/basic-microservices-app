const express = require('express');
const { randomBytes } = require('crypto');
const cors = require('cors');
const axios = require('axios');

const app = express();
app.use(express.json());
app.use(cors());

// In-memory data store
// In production, this would be a database
const posts = {};

// Get all posts
app.get('/posts', (req, res) => {
  console.log('Fetching all posts');
  res.send(posts);
});

// Create a post
app.post('/posts', async (req, res) => {
  const id = randomBytes(4).toString('hex');
  const { title } = req.body;

  posts[id] = {
    id,
    title
  };

  console.log(`Post created: ${id} - "${title}"`);

  // Publish event to event bus
  await axios.post('http://event-bus:4005/events', {
    type: 'PostCreated',
    data: {
      id,
      title
    }
  }).catch(err => {
    console.log('Error sending event:', err.message);
  });

  res.status(201).send(posts[id]);
});

// Receive events from event bus
app.post('/events', (req, res) => {
  const { type, data } = req.body;
  console.log(`Received event: ${type}`);

  // Posts service doesn't need to react to any events yet
  // But we have the endpoint ready!

  res.send({});
});

const PORT = 4001;
app.listen(PORT, () => {
  console.log(`Posts Service listening on port ${PORT}`);
  console.log(`   GET  http://localhost:${PORT}/posts`);
  console.log(`   POST http://localhost:${PORT}/posts`);
});