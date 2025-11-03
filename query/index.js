// query/index.js
const express = require('express');
const cors = require('cors');
const axios = require('axios');

const app = express();
app.use(express.json());
app.use(cors());

// Combined view of posts and comments
const posts = {};

// Handle events
app.post('/events', (req, res) => {
  const { type, data } = req.body;

  console.log(`Received event: ${type}`);

  if (type === 'PostCreated') {
    const { id, title } = data;
    posts[id] = { id, title, comments: [] };
    console.log(`Stored post: ${id}`);
  }

  if (type === 'CommentCreated') {
    const { id, content, postId } = data;
    const post = posts[postId];

    if (post) {
      post.comments.push({ id, content });
      console.log(`Added comment to post ${postId}`);
    }
  }

  res.send({});
});

// Get all posts with comments
app.get('/posts', (req, res) => {
  console.log('Fetching all posts with comments');
  res.send(posts);
});

const PORT = 4003;

app.listen(PORT, async () => {
  console.log(`Query Service listening on port ${PORT}`);
  console.log(`   GET http://localhost:${PORT}/posts`);

  // Sync with existing events
  console.log('Syncing with existing events...');

  try {
    const res = await axios.get('http://localhost:4005/events');

    for (let event of res.data) {
      console.log(`  Processing: ${event.type}`);

      if (event.type === 'PostCreated') {
        const { id, title } = event.data;
        posts[id] = { id, title, comments: [] };
      }

      if (event.type === 'CommentCreated') {
        const { id, content, postId } = event.data;
        const post = posts[postId];
        if (post) {
          post.comments.push({ id, content });
        }
      }
    }

    console.log(`Synced ${res.data.length} events`);
  } catch (err) {
    console.log('Sync failed:', err.message);
  }
});