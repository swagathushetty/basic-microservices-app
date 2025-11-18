const express = require('express');
const cors = require('cors');
const axios = require('axios');

const app = express();
app.use(express.json());
app.use(cors());

const posts = {};

app.post('/events', (req, res) => {
  const { type, data } = req.body;

  console.log(`Received event: ${type}`);

  if (type === 'PostCreated') {
    const { id, title } = data;
    posts[id] = { id, title, comments: [] };
    console.log(`Stored post: ${id}`);
  }

  if (type === 'CommentCreated') {
    const { id, content, postId, status, version } = data;
    const post = posts[postId];

    if (post) {
      post.comments.push({ id, content, status, version });
      console.log(`Added comment to post ${postId} (${status})`);
    }
  }

  if (type === 'CommentUpdated') {
    const { id, postId, status, content, version } = data;
    const post = posts[postId];

    if (post) {
      const comment = post.comments.find(c => c.id === id);

      if (comment) {
        if(version <= comment.version){
          res.send({});
          return;
        }
        comment.status = status;
        comment.content = content;
        comment.version += 1
        console.log(`Updated comment ${id} status to: ${status}`);
      }
    }
  }

  res.send({});
});

app.get('/posts', (req, res) => {
  console.log('Fetching all posts with comments');
  res.send(posts);
});

const PORT = 4003;

app.listen(PORT, async () => {
  console.log(`Query Service listening on port ${PORT}`);

  // Sync with existing events
  console.log('Syncing with existing events...');

  try {

    // as soon as server starts contact event bus and get all events
    const res = await axios.get('http://event-bus-srv:4005/events');

    for (let event of res.data) {
      console.log(`  Processing: ${event.type}`);

      if (event.type === 'PostCreated') {
        const { id, title } = event.data;
        posts[id] = { id, title, comments: [] };
      }

      if (event.type === 'CommentCreated') {
        const { id, content, postId, status, version = 0 } = event.data;
        const post = posts[postId];
        if (post) {
          post.comments.push({ id, content, status, version });
        }
      }

      if (event.type === 'CommentUpdated') {
        const { id, postId, status, content, version } = event.data;
        const post = posts[postId];
        if (post) {
          const comment = post.comments.find(c => c.id === id);
          if (comment && version > comment.version) {
            comment.status = status;
            comment.content = content;
            comment.version = version
          }
        }
      }
    }

    console.log(`Synced ${res.data.length} events`);
  } catch (err) {
    console.log('Sync failed:', err.message);
  }
});