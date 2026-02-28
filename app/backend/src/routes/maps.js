const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');

// Get Ola Maps configuration (protected route)
router.get('/config', auth, async (req, res) => {
  try {
    // Return Ola Maps credentials from environment variables
    const config = {
      projectId: process.env.OLA_MAPS_PROJECT_ID,
      apiKey: process.env.OLA_MAPS_API_KEY,
      clientId: process.env.OLA_MAPS_CLIENT_ID,
      clientSecret: process.env.OLA_MAPS_CLIENT_SECRET,
      tileUrl: 'https://api.olamaps.io/tiles/vector/v1/styles/default-light-standard/{z}/{x}/{y}.png',
      baseUrl: 'https://api.olamaps.io',
    };

    res.json(config);
  } catch (error) {
    console.error('Error fetching Ola Maps config:', error);
    res.status(500).json({ error: 'Failed to fetch map configuration' });
  }
});

module.exports = router;
