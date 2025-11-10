const express = require('express');
const axios = require('axios');

const app = express();
app.use(express.json());

// Handle events
app.post('/events', async (req, res) => {
  const { type, data } = req.body;

  console.log(`Received event: ${type}`);

  if (type === 'CommentCreated') {
    const { id, content, postId } = data;

    const status = content.includes('bad') ? 'rejected' : 'approved';

    console.log(`Moderating comment ${id}: ${status}`);

    // Publish moderation result
    await axios.post('http://localhost:4005/events', {
      type: 'CommentModerated',
      data: {
        id,
        postId,
        status
      }
    }).catch(err => {
      console.log('Error sending event:', err.message);
    });
  }

  res.send({});
});

const PORT = 4004;
app.listen(PORT, () => {
  console.log(`Moderation Service listening on port ${PORT}`);
});