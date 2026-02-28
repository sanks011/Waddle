const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const auth = require('../middleware/auth');

// Get current user
router.get('/me', auth, authController.getCurrentUser);

// Update user profile
router.put('/me/profile', auth, authController.updateUserProfile);

module.exports = router;
