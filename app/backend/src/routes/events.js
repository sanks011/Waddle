const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/eventController');
const auth = require('../middleware/auth');

router.get('/', auth, ctrl.getEvents);
router.get('/:id', auth, ctrl.getEvent);
router.post('/', auth, ctrl.createEvent);
router.post('/:id/join', auth, ctrl.joinEvent);
router.delete('/:id', auth, ctrl.deleteEvent);

router.get('/:id/messages', auth, ctrl.getMessages);
router.post('/:id/messages', auth, ctrl.sendMessage);

module.exports = router;
