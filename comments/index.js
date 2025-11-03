const express = require('express');
const { randomBytes } = require('crypto');
const cors = require('cors');
const axios = require('axios');

const app = express();
app.use(express.json());
app.use(cors());

// Comments are organized by post ID
// { postId: [ { id, content }, ... ] }
const commentsByPostId = {};

app.get('/posts/:id/comments', (req, res) => {
  const { id } = req.params;
  const comments = commentsByPostId[id] || [];

  console.log(`📋 Fetching comments for post ${id}: ${comments.length} found`);
  res.send(comments);
});

// Create a comment
app.post('/posts/:id/comments', async (req, res) => {
  const commentId = randomBytes(4).toString('hex');
  const { content } = req.body;
  const { id: postId } = req.params;

  const comments = commentsByPostId[postId] || [];

  comments.push({
    id: commentId,
    content
  });

  commentsByPostId[postId] = comments;

  console.log(`Comment created: ${commentId} on post ${postId}`);

  // Publish event to event bus
  await axios.post('http://localhost:4005/events', {
    type: 'CommentCreated',
    data: {
      id: commentId,
      content,
      postId
    }
  }).catch(err => {
    console.log('Error sending event:', err.message);
  });

  res.status(201).send(comments);
});

// Receive events from event bus
app.post('/events', (req, res) => {
  const { type, data } = req.body;
  console.log(`Received event: ${type}`);


  res.send({});
});

const PORT = 4002;
app.listen(PORT, () => {
  console.log(`Comments Service listening on port ${PORT}`);
  console.log(`   GET  http://localhost:${PORT}/posts/:id/comments`);
  console.log(`   POST http://localhost:${PORT}/posts/:id/comments`);
});