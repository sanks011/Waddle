const express = require('express');
const router = express.Router();
const sessionController = require('../controllers/sessionController');
const auth = require('../middleware/auth');

// Create new session
router.post('/', auth, sessionController.createSession);

// Complete session
router.put('/:sessionId/complete', auth, sessionController.completeSession);

// Get user sessions
router.get('/my', auth, sessionController.getUserSessions);

module.exports = router;
